import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

/// Helper functions for cloud-related operations using Amplify Storage (S3).
class TCloudHelperFunctions {
  static Widget? checkSingleRecordState<T>(AsyncSnapshot<T> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null) {
      return const Center(child: Text('No Data Found!'));
    }

    if (snapshot.hasError) {
      return const Center(child: Text('Something went wrong.'));
    }

    return null;
  }

  static Widget? checkMultiRecordState<T>({
    required AsyncSnapshot<List<T>> snapshot,
    Widget? loader,
    Widget? error,
    Widget? nothingFound,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      if (loader != null) return loader;
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
      if (nothingFound != null) return nothingFound;
      return const Center(child: Text('No Data Found!'));
    }

    if (snapshot.hasError) {
      if (error != null) return error;
      return const Center(child: Text('Something went wrong.'));
    }

    return null;
  }

  /// Get a public URL for a stored object in S3 using Amplify Storage.
  static Future<String> getURLFromFilePathAndName(String key) async {
    try {
      if (key.isEmpty) return '';
      final operation = Amplify.Storage.getUrl(
        path: StoragePath.fromString(key),
      );
      final result = await operation.result;
      return result.url.toString();
    } on StorageException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Something went wrong.';
    }
  }

  /// If given a pre-signed or public URL just return it; otherwise try to derive a URL.
  static Future<String> getURLFromURI(String uri) async {
    if (uri.isEmpty) return '';
    if (uri.startsWith('http')) return uri;
    // Otherwise assume it's a key and request a URL.
    return getURLFromFilePathAndName(uri);
  }
}
