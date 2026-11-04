create or replace function catalog._base32_sha256_prefix(p_input bytea, p_length int default 10)
returns text
language plpgsql
immutable
as $$
declare
  v_alphabet constant text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  v_digest bytea := digest(p_input, 'sha256');
  v_bits bigint := 0;
  v_bit_count int := 0;
  v_result text := '';
  v_i int;
  v_byte int;
begin
  for v_i in 0 .. length(v_digest) - 1 loop
    v_byte := get_byte(v_digest, v_i);
    v_bits := (v_bits << 8) | v_byte;
    v_bit_count := v_bit_count + 8;
    while v_bit_count >= 5 loop
      v_bit_count := v_bit_count - 5;
      v_result := v_result || substr(v_alphabet, (((v_bits >> v_bit_count) & 31) + 1)::int, 1);
      exit when length(v_result) >= p_length;
    end loop;
    exit when length(v_result) >= p_length;
  end loop;

  if length(v_result) < p_length and v_bit_count > 0 then
    v_result := v_result || substr(v_alphabet, (((v_bits << (5 - v_bit_count)) & 31) + 1)::int, 1);
  end if;

  return left(v_result, p_length);
end;
$$;
