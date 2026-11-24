# Maintain Flutter → HTML parity

1. Freeze the incoming Flutter package version.
2. Hash `lib/design_system.dart`, tokens/theme, component source and Flutter tests.
3. Diff public exports and source signatures against `contracts/`.
4. Port token/anatomy/variant/state changes into shared HTML source.
5. Regenerate `canonical-registry.json`, icon contracts and source hashes.
6. Run `./qa.sh` and browser computed-style/interaction smoke.
7. Release a new HTML DS version.
8. Themes consume that version; Themes do not patch the shared visual contract locally.

Flutter and HTML versions are independent. `contracts/flutter-source.json` records the exact Flutter package mirrored by this HTML release.
