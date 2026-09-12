#!/usr/bin/env python3
"""Collapse modules/*/presentation into apps/erp (and IAM into apps/admin)."""
from __future__ import annotations

import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# module -> list of (app_package_name, dest_feature_dir relative to app/lib)
MOVES = [
    ("sales", [("erp", "features/sales")]),
    ("partner", [("erp", "features/partner")]),
    ("pricing", [("erp", "features/pricing")]),
    ("catalog", [("erp", "features/catalog")]),
    ("dashboard", [("erp", "features/dashboard")]),
    ("iam", [("erp", "features/iam"), ("admin", "features/iam")]),
]

STUBS = ["accounting", "costing", "inventory"]


def rel_dart_files(src_root: Path) -> list[Path]:
    return sorted(p for p in src_root.rglob("*.dart") if p.is_file())


def merge_src(module: str, dest_pres: Path) -> list[str]:
    """Copy module lib/src/* into dest_pres/, skip if dest exists. Returns skipped rel paths."""
    src = ROOT / "modules" / module / "presentation" / "lib" / "src"
    skipped: list[str] = []
    if not src.is_dir():
        return skipped
    for path in src.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(src)
        dest = dest_pres / rel
        if dest.exists():
            skipped.append(str(rel))
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dest)
    return skipped


def write_barrel(module: str, dest_feature: Path, app_pkg: str) -> None:
    """Write presentation.dart (+ testing.dart) under features/<m>/ from module barrels."""
    mod_lib = ROOT / "modules" / module / "presentation" / "lib"
    for name in ("presentation.dart", "testing.dart"):
        src = mod_lib / name
        if not src.exists():
            continue
        text = src.read_text()
        # export 'src/foo.dart' -> export 'presentation/foo.dart'
        text = re.sub(
            r"export\s+'src/",
            "export 'presentation/",
            text,
        )
        text = re.sub(
            r'export\s+"src/',
            'export "presentation/',
            text,
        )
        out = dest_feature / name
        out.write_text(text)


def rewrite_file(path: Path, module: str, app_pkg: str) -> bool:
    text = path.read_text()
    orig = text
    pkg = f"vet45_{module}_presentation"
    # package:vet45_X_presentation/presentation.dart -> package:erp/features/X/presentation.dart
    text = text.replace(
        f"package:{pkg}/presentation.dart",
        f"package:{app_pkg}/features/{module}/presentation.dart",
    )
    text = text.replace(
        f"package:{pkg}/testing.dart",
        f"package:{app_pkg}/features/{module}/testing.dart",
    )
    # deep imports package:vet45_X_presentation/src/foo -> package:app/features/X/presentation/foo
    text = re.sub(
        rf"package:{pkg}/src/",
        f"package:{app_pkg}/features/{module}/presentation/",
        text,
    )
    if text != orig:
        path.write_text(text)
        return True
    return False


def rewrite_all_imports() -> int:
    changed = 0
    for module, targets in MOVES:
        for app_pkg, _feature in targets:
            # Prefer rewriting to the app that owns the file when possible.
            pass
    # Global rewrite: for each module package reference, map to erp except files under apps/admin
    for path in ROOT.rglob("*.dart"):
        if "modules/" in str(path) and "/presentation/" in str(path):
            continue  # will delete
        if "/.dart_tool/" in str(path) or "/build/" in str(path):
            continue
        text = path.read_text()
        orig = text
        under_admin = "/apps/admin/" in str(path)
        for module, _targets in MOVES:
            pkg = f"vet45_{module}_presentation"
            app_pkg = "admin" if under_admin and module == "iam" else "erp"
            # admin only gets iam; other modules in admin shouldn't exist
            if under_admin and module != "iam":
                app_pkg = "erp"  # shouldn't appear
            text = text.replace(
                f"package:{pkg}/presentation.dart",
                f"package:{app_pkg}/features/{module}/presentation.dart",
            )
            text = text.replace(
                f"package:{pkg}/testing.dart",
                f"package:{app_pkg}/features/{module}/testing.dart",
            )
            text = re.sub(
                rf"package:{pkg}/src/",
                f"package:{app_pkg}/features/{module}/presentation/",
                text,
            )
        if text != orig:
            path.write_text(text)
            changed += 1
    return changed


def move_tests(module: str, app: str) -> None:
    src = ROOT / "modules" / module / "presentation" / "test"
    if not src.is_dir():
        return
    dest = ROOT / "apps" / app / "test" / "features" / module / "presentation_module"
    if dest.exists():
        # merge
        for path in src.rglob("*"):
            if not path.is_file():
                continue
            rel = path.relative_to(src)
            out = dest / rel
            if out.exists():
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, out)
    else:
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(src, dest)


def build_erp_example() -> None:
    example = ROOT / "apps" / "erp" / "example"
    if example.exists():
        shutil.rmtree(example)
    example.mkdir(parents=True)
    (example / "lib").mkdir()

    # Copy sales + partner example trees
    for module in ("sales", "partner"):
        src = ROOT / "modules" / module / "presentation" / "example" / "lib"
        if not src.is_dir():
            continue
        dest = example / "lib" / module
        shutil.copytree(src, dest)

    pubspec = """name: erp_presentation_example
description: Preview catalog for ERP feature presentation widgets.
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.11.1 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  erp:
    path: ../
  vet45_design_system:
    path: ../../../packages/vet45_design_system
  vet45_sales_application:
    path: ../../../modules/sales/application
  vet45_sales_domain:
    path: ../../../modules/sales/domain
  vet45_partner_application:
    path: ../../../modules/partner/application
  vet45_partner_domain:
    path: ../../../modules/partner/domain
  vet45_shared_application:
    path: ../../../packages/vet45_shared/application
  vet45_shared_testing:
    path: ../../../packages/vet45_shared/testing

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

dependency_overrides:
  vet45_annotations:
    path: ../../../packages/vet45_annotations
  vet45_design_system:
    path: ../../../packages/vet45_design_system
  vet45_sales_application:
    path: ../../../modules/sales/application
  vet45_sales_domain:
    path: ../../../modules/sales/domain
  vet45_partner_application:
    path: ../../../modules/partner/application
  vet45_partner_domain:
    path: ../../../modules/partner/domain
  vet45_partner_integration_events:
    path: ../../../modules/partner/integration_events
  vet45_shared_application:
    path: ../../../packages/vet45_shared/application
  vet45_shared_domain:
    path: ../../../packages/vet45_shared/domain
  vet45_shared_infrastructure:
    path: ../../../packages/vet45_shared/infrastructure
  vet45_shared_testing:
    path: ../../../packages/vet45_shared/testing

flutter:
  uses-material-design: true
"""
    (example / "pubspec.yaml").write_text(pubspec)
    (example / "analysis_options.yaml").write_text(
        "include: package:flutter_lints/flutter.yaml\n"
    )

    main = '''import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import 'partner/main.dart' as partner show PartnerPreviewHomeScreen;
import 'sales/main.dart' as sales show SalesPreviewHomeScreen;

void main() {
  runApp(const ErpPresentationExampleApp());
}

class ErpPresentationExampleApp extends StatelessWidget {
  const ErpPresentationExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VET45 ERP Presentation Preview',
      theme: VTheme.lightTheme,
      home: const _CatalogHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _CatalogHome extends StatelessWidget {
  const _CatalogHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ERP presentation catalog')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Sales'),
            subtitle: const Text('SG-01 … SG-13 widget previews'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const sales.SalesPreviewHomeScreen(),
              ),
            ),
          ),
          ListTile(
            title: const Text('Partner'),
            subtitle: const Text('List / detail / create / sheets'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const partner.PartnerPreviewHomeScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'''
    (example / "lib" / "main.dart").write_text(main)

    # Fix nested mains: strip void main from feature mains — keep home widgets.
    for module in ("sales", "partner"):
        main_path = example / "lib" / module / "main.dart"
        if not main_path.exists():
            continue
        text = main_path.read_text()
        # Rewrite old package imports to erp
        text = text.replace(
            f"package:vet45_{module}_presentation/presentation.dart",
            f"package:erp/features/{module}/presentation.dart",
        )
        text = re.sub(
            rf"package:vet45_{module}_presentation/src/",
            f"package:erp/features/{module}/presentation/",
            text,
        )
        main_path.write_text(text)
        # rewrite all dart under example/lib/module
        for path in (example / "lib" / module).rglob("*.dart"):
            t = path.read_text()
            o = t
            t = t.replace(
                f"package:vet45_{module}_presentation/presentation.dart",
                f"package:erp/features/{module}/presentation.dart",
            )
            t = re.sub(
                rf"package:vet45_{module}_presentation/src/",
                f"package:erp/features/{module}/presentation/",
                t,
            )
            # also partner/sales may import each other rarely
            for m2, _ in MOVES:
                t = t.replace(
                    f"package:vet45_{m2}_presentation/presentation.dart",
                    f"package:erp/features/{m2}/presentation.dart",
                )
                t = re.sub(
                    rf"package:vet45_{m2}_presentation/src/",
                    f"package:erp/features/{m2}/presentation/",
                    t,
                )
            if t != o:
                path.write_text(t)


def strip_workspace_and_deps() -> None:
    root_pub = ROOT / "pubspec.yaml"
    text = root_pub.read_text()
    for module, _ in MOVES:
        text = re.sub(
            rf"\n\s*- modules/{module}/presentation\n",
            "\n",
            text,
        )
    for stub in STUBS:
        text = re.sub(
            rf"\n\s*- modules/{stub}/presentation\n",
            "\n",
            text,
        )
    root_pub.write_text(text)

    for app, deps in (
        (
            "erp",
            [
                "vet45_dashboard_presentation",
                "vet45_iam_presentation",
                "vet45_catalog_presentation",
                "vet45_partner_presentation",
                "vet45_pricing_presentation",
                "vet45_sales_presentation",
            ],
        ),
        ("admin", ["vet45_iam_presentation"]),
    ):
        pub = ROOT / "apps" / app / "pubspec.yaml"
        t = pub.read_text()
        for dep in deps:
            t = re.sub(rf"\n\s*{dep}:\s*\^[^\n]+\n", "\n", t)
        pub.write_text(t)


def delete_presentation_packages() -> None:
    modules = [m for m, _ in MOVES] + STUBS
    for module in modules:
        path = ROOT / "modules" / module / "presentation"
        if path.exists():
            shutil.rmtree(path)
    einvoice = ROOT / "modules" / "einvoice" / "presentation"
    if einvoice.exists():
        shutil.rmtree(einvoice)


def main() -> None:
    all_skipped: dict[str, list[str]] = {}
    for module, targets in MOVES:
        for app_pkg, feature_rel in targets:
            app_lib = ROOT / "apps" / app_pkg / "lib"
            dest_feature = app_lib / feature_rel
            dest_pres = dest_feature / "presentation"
            dest_pres.mkdir(parents=True, exist_ok=True)
            skipped = merge_src(module, dest_pres)
            if skipped:
                all_skipped[f"{app_pkg}/{module}"] = skipped
            write_barrel(module, dest_feature, app_pkg)
            # tests only once per module into primary app (erp), iam also to admin
            if app_pkg == "erp" or module == "iam":
                move_tests(module, app_pkg)

    build_erp_example()
    n = rewrite_all_imports()
    strip_workspace_and_deps()
    delete_presentation_packages()

    print("Import files rewritten:", n)
    print("Skipped existing dest files:")
    for k, v in sorted(all_skipped.items()):
        print(f"  {k}: {len(v)}")
        for s in v[:20]:
            print(f"    - {s}")
        if len(v) > 20:
            print(f"    ... +{len(v) - 20} more")


if __name__ == "__main__":
    main()
