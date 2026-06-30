import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Hand-maintained access metadata until IAM codegen is enabled (phase 2).
final IAccessMetadataRegistry iamAccessMetadataRegistry = AccessMetadataRegistry(
  <Type, AccessMetadata>{
    SignInCommand: const AccessMetadata(isPublic: true),
    SignOutCommand: const AccessMetadata(isPublic: true),
    GetCurrentSessionQuery: const AccessMetadata(isPublic: true),
  },
);
