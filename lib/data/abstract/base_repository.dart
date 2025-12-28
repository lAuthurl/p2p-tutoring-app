import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/exceptions/format_exceptions.dart';
import '../../utils/exceptions/platform_exceptions.dart';

/// A generic controller class for managing data tables using GetX state management.
/// This class provides common functionalities for handling data tables, including fetching, updating, and deleting items.
abstract class TBaseRepositoryController<T> extends GetxController {
  /// Abstract method to be implemented by subclasses for fetching all items.
  Future<List<T>> fetchAllItems();

  /// Abstract method to be implemented by subclasses for fetching a single item by ID.
  Future<T> fetchSingleItem(String id);

  /// Abstract method to be implemented by subclasses for adding a new item.
  Future<String> addItem(T item);

  /// Abstract method to be implemented by subclasses for updating an existing item.
  Future<void> updateItem(T item);

  /// Abstract method to be implemented by subclasses for updating a single field of an item by ID.
  Future<void> updateSingleField(String id, Map<String, dynamic> json);

  /// Abstract method to be implemented by subclasses for deleting an item.
  Future<void> deleteItem(T item);

  /// Fetches all items and handles exceptions using a centralized method.
  Future<List<T>> getAllItems() async {
    return await _handleOperation(() => fetchAllItems());
  }

  /// Fetches a single item by ID and handles exceptions.
  Future<T> getSingleItem(String id) async {
    return await _handleOperation(() => fetchSingleItem(id));
  }

  /// Adds a new item and handles exceptions.
  Future<String> addNewItem(T item) async {
    return await _handleOperation(() => addItem(item));
  }

  /// Updates an existing item and handles exceptions.
  Future<void> updateItemRecord(T item) async {
    await _handleOperation(() => updateItem(item));
  }

  /// Updates a single field of an item and handles exceptions.
  Future<void> updateSingleItemRecord(
    String id,
    Map<String, dynamic> json,
  ) async {
    await _handleOperation(() => updateSingleField(id, json));
  }

  /// Deletes an item and handles exceptions.
  Future<void> deleteItemRecord(T item) async {
    await _handleOperation(() => deleteItem(item));
  }

  /// Centralized method to handle Firestore operations and catch exceptions.
  Future<R> _handleOperation<R>(Future<R> Function() operation) async {
    try {
      return await operation();
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
