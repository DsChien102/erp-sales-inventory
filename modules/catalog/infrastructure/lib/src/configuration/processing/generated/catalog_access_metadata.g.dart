// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

final catalogAccessMetadataRegistry = AccessMetadataRegistry({
  CheckDuplicateProductCodeQuery: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  CreateProductCommand: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
  RequestProductImageUploadCommand: AccessMetadata(
    permission: 'catalog.product.create',
    requiresTenant: true,
  ),
});

