# Vet45 Async Query - Agent Integration Playbook

Tai lieu nay la huong dan tich hop `vet45_async_query` vao he thong Vet45 cho AI agents va contributors.

## Muc tieu

- Giam boilerplate load/refetch o presentation
- Giu nguyen architecture backbone cua Vet45
- Chuan hoa query key, invalidation, va migration pattern

## Kien truc tich hop

```text
Widget (UseQuery/UseMutation)
  -> queryFn/mutationFn
  -> IModuleMediator (executeQueryAsync / executeCommandAsync)
  -> module application/infrastructure nhu hien tai
```

`vet45_async_query` la presentation-side server-state cache, khong thay doi domain/application contracts.

## Placement de nghi

1. Dat `QueryClientProvider` tai app shell hoac feature shell co vong doi dai
2. Dinh nghia query key helper theo feature folder
3. Dung `UseQuery` cho read-path
4. Dung `UseMutation` cho write-path
5. Dung `invalidateQueries` sau command thanh cong

## Query key convention

Format:

```dart
['<context>', '<resource>', tenantId, ...params]
```

Vi du:

```dart
['partner', 'list', tenantId, searchText, status]
['partner', 'detail', tenantId, partnerId]
['catalog', 'price-bands', tenantId, productId]
```

## Rendering safety rules

Trong `builder`, khong force unwrap `result.data!` neu chua co du lieu.

Pattern an toan:

```dart
if (!result.hasData && !result.isError) return Loading();
if (result.isError) return ErrorView(result.error);
final data = result.data!;
```

## Migration strategy (incremental)

1. Bat dau voi page read-only
2. Chuyen list+detail
3. Chuyen mutation-heavy screens
4. Sau moi buoc, verify test va behavior

## Verification checklist

- [ ] Query key co tenant scope cho tenant data
- [ ] `UseMutation.onSuccess` co invalidation phu hop
- [ ] Khong con `load()` thu cong lap lai sau mutation
- [ ] Khong direct Supabase/network call trong UI
- [ ] flutter tests pass cho feature da migrate

## Anti-patterns

- Gan random values vao query key
- Vua dung `UseQuery` vua maintain state machine loading/error duplicate o widget
- Invalidate qua rong (`all`) khong can thiet gay refetch storm
- Chuyen tat ca man hinh mot luc thay vi rollout theo slice
