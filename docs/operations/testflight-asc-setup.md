# App Store Connect & TestFlight setup (manual)

Thực hiện một lần trên [App Store Connect](https://appstoreconnect.apple.com).

## 1. Tạo app records

| App name | Bundle ID | Mục đích |
|---|---|---|
| **VET45 Staging** | `com.agapi.vet45.staging` | TestFlight only — QA / UAT |
| **VET45** | `com.agapi.vet45` | TestFlight beta + App Store production |

**Không** gộp staging và production vào một app ASC.

## 2. Provisioning

- Xcode automatic signing hoặc fastlane match cho từng bundle ID
- Đảm bảo `flutter build ipa --flavor staging` ký đúng `com.agapi.vet45.staging`

## 3. API key (shared)

1. App Store Connect → Users and Access → Keys
2. Tạo API key với quyền Developer
3. Lưu vào `deploy/deploy.env` (local, dùng chung staging + production) hoặc CircleCI context `vet45-deploy`:
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - File `.p8` tại `~/.appstoreconnect/private_keys/AuthKey_<KEY_IDENTIFIER>.p8` (không commit)

## 4. TestFlight groups

**VET45 Staging app:**
- Internal: QA + Product + Dev
- (Optional) External: pilot khách — cần Beta App Review lần đầu

**VET45 production app:**
- Internal: beta testers hẹp
- Sau soak test → Submit App Store Review

## 5. Upload build đầu tiên

```bash
cp apps/erp/.env.staging.example apps/erp/.env.staging
# Điền Supabase staging credentials

./apps/erp/scripts/build_ios.sh --env staging
./apps/erp/deploy-ios.sh --env staging
```

Tăng build number (`version: x.y.z+N` trong `apps/erp/pubspec.yaml`) mỗi lần upload.

## 6. Checklist

- [ ] App **VET45 Staging** tạo với bundle `com.agapi.vet45.staging`
- [ ] App **VET45** có bundle `com.agapi.vet45`
- [ ] TestFlight group staging có QA
- [ ] Build staging upload thành công
- [ ] Build production upload thành công (app riêng)
- [ ] Staging app **không** submit public App Store Review
