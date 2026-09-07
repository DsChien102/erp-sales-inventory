import 'dart:typed_data';

import 'package:supabase/supabase.dart';
import 'package:vet45_einvoice_infrastructure/src/storage/invoice_document_signed_url_resolver.dart';

final class FakeInvoiceDocumentStorageSupabase implements SupabaseClient {
  FakeInvoiceDocumentStorageSupabase({RecordingStorageFileApi? fileApi}) {
    bucket = fileApi ?? RecordingStorageFileApi('einvoice-documents');
    _storage = FakeSupabaseStorageClient(bucket);
  }

  late RecordingStorageFileApi bucket;
  late FakeSupabaseStorageClient _storage;
  final FakeGoTrueClient _auth = FakeGoTrueClient();

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseStorageClient get storage => _storage;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class RecordingStorageFileApi implements StorageFileApi {
  RecordingStorageFileApi(this._bucketName);

  final String _bucketName;
  String? lastPath;
  Uint8List? lastBytes;
  FileOptions? lastFileOptions;
  final Map<String, Uint8List> objects = {};

  @override
  Future<String> uploadBinary(
    String path,
    Uint8List data, {
    FileOptions fileOptions = const FileOptions(),
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    lastPath = path;
    lastBytes = data;
    lastFileOptions = fileOptions;
    if (objects.containsKey(path)) {
      throw const StorageException('Duplicate', statusCode: '409');
    }
    objects[path] = lastBytes!;
    return path;
  }

  @override
  Future<String> upload(
    String path,
    dynamic file, {
    FileOptions fileOptions = const FileOptions(),
    int? retryAttempts,
    StorageRetryController? retryController,
  }) async {
    return uploadBinary(
      path,
      file is Uint8List ? file : Uint8List.fromList(file as List<int>),
      fileOptions: fileOptions,
      retryAttempts: retryAttempts,
      retryController: retryController,
    );
  }

  @override
  Future<Uint8List> download(
    String path, {
    String? cacheNonce,
    Map<String, String>? queryParams,
    TransformOptions? transform,
  }) async {
    final bytes = objects[path];
    if (bytes == null) {
      throw const StorageException('Not found', statusCode: '404');
    }
    return bytes;
  }

  @override
  Future<String> createSignedUrl(
    String path,
    int expiresIn, {
    String? cacheNonce,
    DownloadBehavior? download,
    TransformOptions? transform,
  }) async {
    return 'https://signed.example/$bucketId/$path?ttl=$expiresIn';
  }

  @override
  String get bucketId => _bucketName;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class FakeSupabaseStorageClient implements SupabaseStorageClient {
  FakeSupabaseStorageClient(this._bucket);

  final RecordingStorageFileApi _bucket;

  @override
  StorageFileApi from(String id) {
    if (id != InvoiceDocumentSignedUrlResolver.defaultBucketName) {
      throw UnsupportedError('unexpected bucket $id');
    }
    return _bucket;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
