-- Title: einvoice S4b invoice document operations
-- Kind: patch
-- Intent: einvoice_s4b_documents
-- Context: TH-08 / EP-03 / US-02
-- Touches: _invoice_document_command_id, get_invoice_documents, load_invoice_document_operation_context, record_invoice_document_result, request_invoice_document
-- Safety: idempotent ; medium
-- Depends on: 007_einvoice_issuance_schema_and_publish_rpcs.sql, 009_einvoice_issuance_reconciliation_rpcs.sql, 010_einvoice_official_view_rpcs.sql

create table if not exists einvoice.invoice_document_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  document_type text not null check (document_type in ('PDF','XML')),
  generation integer not null check (generation > 0),
  attempt_ordinal integer not null default 1 check (attempt_ordinal > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  idempotency_key varchar(150) not null,
  intent_hash varchar(128) not null,
  invoice_document_id uuid null,
  access_expires_at timestamptz null,
  failure_code text null,
  failure_message text null,
  requested_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, idempotency_key),
  unique (tenant_id, electronic_invoice_id, document_type, generation),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id)
);

create table if not exists einvoice.invoice_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  document_type text not null check (document_type in ('PDF','XML')),
  document_version integer not null check (document_version > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  provider_document_reference text null,
  storage_reference text null,
  content_type text null,
  file_name text null,
  file_size bigint null,
  checksum text null,
  requested_at timestamptz null,
  available_at timestamptz null,
  failure_code text null,
  failure_message text null,
  provider_interaction_reference uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, electronic_invoice_id, document_type, document_version),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id),
  check (status <> 'AVAILABLE' or (storage_reference is not null and checksum is not null))
);

alter table einvoice.invoice_document_operations
  drop constraint if exists invoice_document_operations_document_fk;
alter table einvoice.invoice_document_operations
  add constraint invoice_document_operations_document_fk
  foreign key (tenant_id, invoice_document_id)
  references einvoice.invoice_documents (tenant_id, id);

create index if not exists invoice_document_operations_invoice_type_idx
  on einvoice.invoice_document_operations (tenant_id, electronic_invoice_id, document_type, generation desc);

alter table einvoice.invoice_document_operations enable row level security;
alter table einvoice.invoice_documents enable row level security;
revoke all on einvoice.invoice_document_operations from anon, authenticated;
revoke all on einvoice.invoice_documents from anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'einvoice-documents',
  'einvoice-documents',
  false,
  20971520,
  array['application/pdf','application/xml','text/xml']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists einvoice_documents_select on storage.objects;
create policy einvoice_documents_select
on storage.objects for select to authenticated
using (
  bucket_id = 'einvoice-documents'
  and cardinality(storage.foldername(name)) >= 2
  and iam.has_permission(
    case
      when (storage.foldername(name))[1]
        ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      then ((storage.foldername(name))[1])::uuid
      else null::uuid
    end,
    'einvoice.download_document'
  )
);

create or replace function einvoice._invoice_document_command_id(
  p_operation_id uuid,
  p_attempt_ordinal integer
) returns uuid
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_hex text;
begin
  v_raw := p_operation_id::text || '|invoice_document|' || p_attempt_ordinal::text;
  v_hex := encode(sha256(v_raw::bytea), 'hex');
  return (
    substr(v_hex, 1, 8) || '-' ||
    substr(v_hex, 9, 4) || '-' ||
    substr(v_hex, 13, 4) || '-' ||
    substr(v_hex, 17, 4) || '-' ||
    substr(v_hex, 21, 12)
  )::uuid;
end;
$$;

create or replace function einvoice._document_type_supported(
  p_capabilities jsonb,
  p_document_type text
) returns boolean
language sql
immutable
as $$
  select exists (
    select 1
    from jsonb_array_elements_text(
      coalesce(p_capabilities->'supported_document_types', '[]'::jsonb)
    ) elem
    where elem = p_document_type
  );
$$;

create or replace function einvoice.request_invoice_document(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_document_type text,
  p_idempotency_key varchar(150)
) returns table(
  operation_id uuid,
  status text,
  storage_reference text,
  checksum text,
  access_expires_at timestamptz
) language plpgsql security definer set search_path = einvoice, iam, sales, extensions, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_connection einvoice.provider_connections%rowtype;
  v_intent jsonb;
  v_intent_hash text;
  v_existing einvoice.invoice_document_operations%rowtype;
  v_latest einvoice.invoice_document_operations%rowtype;
  v_document einvoice.invoice_documents%rowtype;
  v_generation integer;
  v_document_version integer;
  v_operation_id uuid;
  v_document_id uuid;
  v_attempt_ordinal integer;
  v_cmd_id uuid;
  v_doc_type text := upper(p_document_type);
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.view') then
    raise exception 'NO_PERMISSION: einvoice.view required';
  end if;

  if not sales.can_access_sales_order(
    p_tenant_id,
    p_actor_id,
    p_sales_order_id
  ) then
    raise exception 'NOT_FOUND: sales order not found';
  end if;

  if v_doc_type not in ('PDF', 'XML') then
    raise exception 'VALIDATION_ERROR: invalid document type';
  end if;

  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice not found';
  end if;

  select pc.*
  into v_connection
  from einvoice.provider_connections pc
  where pc.id = v_invoice.provider_connection_id
    and pc.tenant_id = p_tenant_id;

  if not einvoice._document_type_supported(v_connection.capabilities_snapshot, v_doc_type) then
    raise exception 'DOCUMENT_UNAVAILABLE: document type not supported by provider';
  end if;

  v_intent := jsonb_build_object(
    'electronic_invoice_id', v_invoice.id,
    'document_type', v_doc_type
  );
  v_intent_hash := encode(
    extensions.digest(convert_to(v_intent::text, 'UTF8'), 'sha256'),
    'hex'
  );

  select o.*
  into v_existing
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.idempotency_key = p_idempotency_key
  for update;

  if found then
    if v_existing.intent_hash <> v_intent_hash then
      raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
    end if;

    select d.storage_reference, d.checksum
    into v_document.storage_reference, v_document.checksum
    from einvoice.invoice_documents d
    where d.tenant_id = p_tenant_id
      and d.id = v_existing.invoice_document_id;

    return query select
      v_existing.id,
      v_existing.status,
      v_document.storage_reference,
      v_document.checksum,
      v_existing.access_expires_at;
    return;
  end if;

  select o.*
  into v_latest
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
    and o.document_type = v_doc_type
  order by o.generation desc
  limit 1;

  if found and v_latest.status = 'PENDING' then
    select d.storage_reference, d.checksum
    into v_document.storage_reference, v_document.checksum
    from einvoice.invoice_documents d
    where d.tenant_id = p_tenant_id
      and d.id = v_latest.invoice_document_id;

    return query select
      v_latest.id,
      v_latest.status,
      v_document.storage_reference,
      v_document.checksum,
      v_latest.access_expires_at;
    return;
  end if;

  if found and v_latest.status = 'CHECK_REQUIRED' then
    v_attempt_ordinal := v_latest.attempt_ordinal + 1;
    update einvoice.invoice_document_operations o
    set
      status = 'PENDING',
      attempt_ordinal = v_attempt_ordinal,
      version = o.version + 1,
      access_expires_at = null,
      failure_code = null,
      failure_message = null,
      completed_at = null,
      requested_at = now(),
      updated_at = now()
    where o.id = v_latest.id
      and o.tenant_id = p_tenant_id
      and o.version = v_latest.version;

    if not found then
      raise exception 'STATE_CHANGED: invoice document operation version mismatch';
    end if;

    v_cmd_id := einvoice._invoice_document_command_id(v_latest.id, v_attempt_ordinal);
    insert into einvoice.internal_commands (
      id, tenant_id, command_type, payload, source_event_id, enqueued_at
    ) values (
      v_cmd_id,
      p_tenant_id,
      'einvoice.download_invoice_document',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'operation_id', v_latest.id,
        'electronic_invoice_id', v_invoice.id,
        'document_type', v_doc_type,
        'operation_generation', v_latest.generation,
        'attempt_ordinal', v_attempt_ordinal,
        'correlation_id', v_latest.id
      ),
      v_cmd_id,
      now()
    ) on conflict (id) do nothing;

    select d.storage_reference, d.checksum
    into v_document.storage_reference, v_document.checksum
    from einvoice.invoice_documents d
    where d.tenant_id = p_tenant_id
      and d.id = v_latest.invoice_document_id;

    return query select
      v_latest.id,
      'PENDING'::text,
      v_document.storage_reference,
      v_document.checksum,
      null::timestamptz;
    return;
  end if;

  select d.*
  into v_document
  from einvoice.invoice_documents d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id
    and d.document_type = v_doc_type
    and d.status = 'AVAILABLE'
  order by d.document_version desc
  limit 1;

  if found then
    select o.*
    into v_latest
    from einvoice.invoice_document_operations o
    where o.tenant_id = p_tenant_id
      and o.electronic_invoice_id = v_invoice.id
      and o.document_type = v_doc_type
      and o.invoice_document_id = v_document.id
      and o.status = 'AVAILABLE'
    order by o.generation desc
    limit 1;

    if found then
      update einvoice.invoice_document_operations o
      set
        access_expires_at = now() + interval '5 minutes',
        updated_at = now()
      where o.id = v_latest.id
        and o.tenant_id = p_tenant_id;

      return query select
        v_latest.id,
        'AVAILABLE'::text,
        v_document.storage_reference,
        v_document.checksum,
        now() + interval '5 minutes';
      return;
    end if;

    v_operation_id := gen_random_uuid();
    select coalesce(max(o.generation), 0) + 1
    into v_generation
    from einvoice.invoice_document_operations o
    where o.tenant_id = p_tenant_id
      and o.electronic_invoice_id = v_invoice.id
      and o.document_type = v_doc_type;

    insert into einvoice.invoice_document_operations (
      id,
      tenant_id,
      version,
      electronic_invoice_id,
      document_type,
      generation,
      attempt_ordinal,
      status,
      idempotency_key,
      intent_hash,
      invoice_document_id,
      access_expires_at,
      requested_at
    ) values (
      v_operation_id,
      p_tenant_id,
      0,
      v_invoice.id,
      v_doc_type,
      v_generation,
      1,
      'AVAILABLE',
      p_idempotency_key,
      v_intent_hash,
      v_document.id,
      now() + interval '5 minutes',
      now()
    );

    return query select
      v_operation_id,
      'AVAILABLE'::text,
      v_document.storage_reference,
      v_document.checksum,
      now() + interval '5 minutes';
    return;
  end if;

  select coalesce(max(o.generation), 0) + 1
  into v_generation
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
    and o.document_type = v_doc_type;

  select coalesce(max(d.document_version), 0) + 1
  into v_document_version
  from einvoice.invoice_documents d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id
    and d.document_type = v_doc_type;

  v_document_id := gen_random_uuid();
  v_operation_id := gen_random_uuid();
  v_attempt_ordinal := 1;

  insert into einvoice.invoice_documents (
    id,
    tenant_id,
    version,
    electronic_invoice_id,
    document_type,
    document_version,
    status,
    requested_at
  ) values (
    v_document_id,
    p_tenant_id,
    0,
    v_invoice.id,
    v_doc_type,
    v_document_version,
    'PENDING',
    now()
  );

  insert into einvoice.invoice_document_operations (
    id,
    tenant_id,
    version,
    electronic_invoice_id,
    document_type,
    generation,
    attempt_ordinal,
    status,
    idempotency_key,
    intent_hash,
    invoice_document_id,
    requested_at
  ) values (
    v_operation_id,
    p_tenant_id,
    0,
    v_invoice.id,
    v_doc_type,
    v_generation,
    v_attempt_ordinal,
    'PENDING',
    p_idempotency_key,
    v_intent_hash,
    v_document_id,
    now()
  );

  v_cmd_id := einvoice._invoice_document_command_id(v_operation_id, v_attempt_ordinal);
  insert into einvoice.internal_commands (
    id, tenant_id, command_type, payload, source_event_id, enqueued_at
  ) values (
    v_cmd_id,
    p_tenant_id,
    'einvoice.download_invoice_document',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'operation_id', v_operation_id,
      'electronic_invoice_id', v_invoice.id,
      'document_type', v_doc_type,
      'operation_generation', v_generation,
      'attempt_ordinal', v_attempt_ordinal,
      'correlation_id', v_operation_id
    ),
    v_cmd_id,
    now()
  ) on conflict (id) do nothing;

  return query select
    v_operation_id,
    'PENDING'::text,
    null::text,
    null::text,
    null::timestamptz;
end;
$$;

create or replace function einvoice.get_invoice_documents(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  pdf_available boolean,
  xml_available boolean,
  retrieval_status text,
  pdf_operation_id uuid,
  pdf_status text,
  pdf_storage_reference text,
  pdf_checksum text,
  pdf_access_expires_at timestamptz,
  xml_operation_id uuid,
  xml_status text,
  xml_storage_reference text,
  xml_checksum text,
  xml_access_expires_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_connection einvoice.provider_connections%rowtype;
  v_pdf_op einvoice.invoice_document_operations%rowtype;
  v_xml_op einvoice.invoice_document_operations%rowtype;
  v_pdf_found boolean := false;
  v_xml_found boolean := false;
  v_pdf_storage text;
  v_pdf_checksum text;
  v_xml_storage text;
  v_xml_checksum text;
  v_retrieval_status text := 'PENDING';
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.view') then
    raise exception 'NO_PERMISSION: einvoice.view required';
  end if;

  if not sales.can_access_sales_order(
    p_tenant_id,
    p_actor_id,
    p_sales_order_id
  ) then
    raise exception 'NOT_FOUND: sales order not found';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice not found';
  end if;

  select pc.*
  into v_connection
  from einvoice.provider_connections pc
  where pc.id = v_invoice.provider_connection_id
    and pc.tenant_id = p_tenant_id;

  select o.*
  into v_pdf_op
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
    and o.document_type = 'PDF'
  order by o.generation desc
  limit 1;
  v_pdf_found := found;

  select o.*
  into v_xml_op
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
    and o.document_type = 'XML'
  order by o.generation desc
  limit 1;
  v_xml_found := found;

  if v_pdf_found then
    select d.storage_reference, d.checksum
    into v_pdf_storage, v_pdf_checksum
    from einvoice.invoice_documents d
    where d.tenant_id = p_tenant_id
      and d.id = v_pdf_op.invoice_document_id;
  end if;

  if v_xml_found then
    select d.storage_reference, d.checksum
    into v_xml_storage, v_xml_checksum
    from einvoice.invoice_documents d
    where d.tenant_id = p_tenant_id
      and d.id = v_xml_op.invoice_document_id;
  end if;

  if (v_pdf_found and v_pdf_op.status = 'CHECK_REQUIRED')
     or (v_xml_found and v_xml_op.status = 'CHECK_REQUIRED') then
    v_retrieval_status := 'CHECK_REQUIRED';
  elsif (v_pdf_found and v_pdf_op.status = 'FAILED')
     and (not v_xml_found or v_xml_op.status = 'FAILED') then
    v_retrieval_status := 'FAILED';
  elsif (v_pdf_found and v_pdf_op.status = 'AVAILABLE')
     or (v_xml_found and v_xml_op.status = 'AVAILABLE') then
    v_retrieval_status := 'AVAILABLE';
  else
    v_retrieval_status := 'PENDING';
  end if;

  return query select
    einvoice._document_type_supported(v_connection.capabilities_snapshot, 'PDF'),
    einvoice._document_type_supported(v_connection.capabilities_snapshot, 'XML'),
    v_retrieval_status,
    case when v_pdf_found then v_pdf_op.id else null end,
    case when v_pdf_found then v_pdf_op.status else null end,
    v_pdf_storage,
    v_pdf_checksum,
    case when v_pdf_found then v_pdf_op.access_expires_at else null end,
    case when v_xml_found then v_xml_op.id else null end,
    case when v_xml_found then v_xml_op.status else null end,
    v_xml_storage,
    v_xml_checksum,
    case when v_xml_found then v_xml_op.access_expires_at else null end;
end;
$$;

create or replace function einvoice.load_invoice_document_operation_context(
  p_tenant_id uuid,
  p_operation_id uuid
) returns table(
  operation_id uuid,
  tenant_id uuid,
  electronic_invoice_id uuid,
  document_type text,
  generation integer,
  attempt_ordinal integer,
  document_version integer,
  status text,
  provider_connection_id uuid,
  provider_invoice_reference text,
  invoice_series text,
  expected_version bigint,
  invoice_document_id uuid
) language plpgsql security definer set search_path = einvoice, public as $$
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  return query
  select
    o.id,
    o.tenant_id,
    o.electronic_invoice_id,
    o.document_type,
    o.generation,
    o.attempt_ordinal,
    d.version::integer,
    o.status,
    ei.provider_connection_id,
    ei.provider_invoice_reference::text,
    ei.series::text,
    o.version,
    o.invoice_document_id
  from einvoice.invoice_document_operations o
  join einvoice.electronic_invoices ei
    on ei.tenant_id = o.tenant_id
   and ei.id = o.electronic_invoice_id
  join einvoice.invoice_documents d
    on d.tenant_id = o.tenant_id
   and d.id = o.invoice_document_id
  where o.tenant_id = p_tenant_id
    and o.id = p_operation_id;
end;
$$;

create or replace function einvoice.record_invoice_document_result(
  p_tenant_id uuid,
  p_operation_id uuid,
  p_status text,
  p_expected_operation_version bigint,
  p_provider_interaction_reference uuid,
  p_expected_document_version bigint,
  p_storage_reference text default null,
  p_checksum text default null,
  p_content_type text default null,
  p_file_name text default null,
  p_file_size bigint default null,
  p_failure_code text default null,
  p_failure_message text default null
) returns table(
  operation_id uuid,
  status text,
  storage_reference text,
  checksum text
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_operation einvoice.invoice_document_operations%rowtype;
  v_document einvoice.invoice_documents%rowtype;
  v_status text := upper(p_status);
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if v_status not in ('AVAILABLE', 'FAILED', 'CHECK_REQUIRED') then
    raise exception 'VALIDATION_ERROR: invalid invoice document result status';
  end if;

  select o.*
  into v_operation
  from einvoice.invoice_document_operations o
  where o.tenant_id = p_tenant_id
    and o.id = p_operation_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice document operation not found';
  end if;

  select d.*
  into v_document
  from einvoice.invoice_documents d
  where d.tenant_id = p_tenant_id
    and d.id = v_operation.invoice_document_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice document not found';
  end if;

  if v_operation.status in ('AVAILABLE', 'FAILED', 'CHECK_REQUIRED')
     and v_operation.status = v_status then
    return query select
      v_operation.id,
      v_operation.status,
      v_document.storage_reference,
      v_document.checksum;
    return;
  end if;

  if v_operation.status <> 'PENDING' then
    raise exception 'INVALID_STATUS: invoice document operation is not pending';
  end if;

  if v_operation.version <> p_expected_operation_version then
    raise exception 'STATE_CHANGED: invoice document operation version mismatch';
  end if;

  if v_document.version <> p_expected_document_version then
    raise exception 'STATE_CHANGED: invoice document version mismatch';
  end if;

  if v_status = 'AVAILABLE' then
    if coalesce(trim(p_storage_reference), '') = ''
       or coalesce(trim(p_checksum), '') = '' then
      raise exception 'VALIDATION_ERROR: storage metadata required for AVAILABLE';
    end if;
  end if;

  update einvoice.invoice_documents d
  set
    status = v_status,
    storage_reference = case when v_status = 'AVAILABLE' then p_storage_reference else null end,
    checksum = case when v_status = 'AVAILABLE' then p_checksum else null end,
    content_type = case when v_status = 'AVAILABLE' then p_content_type else null end,
    file_name = case when v_status = 'AVAILABLE' then p_file_name else null end,
    file_size = case when v_status = 'AVAILABLE' then p_file_size else null end,
    provider_interaction_reference = p_provider_interaction_reference,
    failure_code = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_code else null end,
    failure_message = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_message else null end,
    available_at = case when v_status = 'AVAILABLE' then now() else null end,
    version = d.version + 1,
    updated_at = now()
  where d.id = v_document.id
    and d.tenant_id = p_tenant_id
    and d.version = p_expected_document_version;

  if not found then
    raise exception 'STATE_CHANGED: invoice document version mismatch';
  end if;

  update einvoice.invoice_document_operations o
  set
    status = v_status,
    access_expires_at = case
      when v_status = 'AVAILABLE' then now() + interval '5 minutes'
      else null
    end,
    failure_code = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_code else null end,
    failure_message = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_message else null end,
    completed_at = now(),
    version = o.version + 1,
    updated_at = now()
  where o.id = p_operation_id
    and o.tenant_id = p_tenant_id
    and o.version = p_expected_operation_version;

  if not found then
    raise exception 'STATE_CHANGED: invoice document operation version mismatch';
  end if;

  return query
  select
    o.id,
    o.status,
    d.storage_reference,
    d.checksum
  from einvoice.invoice_document_operations o
  join einvoice.invoice_documents d
    on d.tenant_id = o.tenant_id
   and d.id = o.invoice_document_id
  where o.id = p_operation_id
    and o.tenant_id = p_tenant_id;
end;
$$;

revoke all on function einvoice._invoice_document_command_id(uuid, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice._document_type_supported(jsonb, text)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.request_invoice_document(uuid, uuid, uuid, text, varchar)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_invoice_documents(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.load_invoice_document_operation_context(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.record_invoice_document_result(
  uuid, uuid, text, bigint, uuid, bigint, text, text, text, text, bigint, text, text
) from public, anon, authenticated, service_role;

grant execute on function einvoice.request_invoice_document(uuid, uuid, uuid, text, varchar)
  to authenticated;
grant execute on function einvoice.get_invoice_documents(uuid, uuid, uuid)
  to authenticated;

grant execute on function einvoice._invoice_document_command_id(uuid, integer)
  to service_role;
grant execute on function einvoice._document_type_supported(jsonb, text)
  to service_role;
grant execute on function einvoice.load_invoice_document_operation_context(uuid, uuid)
  to service_role;
grant execute on function einvoice.record_invoice_document_result(
  uuid, uuid, text, bigint, uuid, bigint, text, text, text, text, bigint, text, text
) to service_role;
