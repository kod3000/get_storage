import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart' as web;
import '../value.dart';

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  web.Storage get localStorage => web.window.localStorage;

  final String? path;
  final String fileName;

  ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  void clear() {
    localStorage.removeItem(fileName);
    subject.value?.clear();
    subject.changeValue("", null);
  }

  Future<bool> _exists() async {
    return localStorage.getItem(fileName) != null;
  }

  Future<void> flush() async {
    await _writeToStorage(subject.value ?? <String, dynamic>{});
  }

  T? read<T>(String key) {
    return subject.value?[key] as T?;
  }

  List<String> getKeys() {
    return subject.value?.keys.toList() ?? [];
  }

  List<dynamic> getValues() {
    return subject.value?.values.toList() ?? [];
  }

  Future<void> init([Map<String, dynamic>? initialData]) async {
    subject.value = initialData ?? <String, dynamic>{};
    if (await _exists()) {
      await _readFromStorage();
    } else {
      await _writeToStorage(subject.value ?? <String, dynamic>{});
    }
  }

  void remove(String key) {
    subject.value?.remove(key);
    subject.changeValue(key, null);
    flush();
  }

  void write(String key, dynamic value) {
    subject.value?[key] = value;
    subject.changeValue(key, value);
    flush();
  }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    localStorage.setItem(fileName, json.encode(data));
  }

  Future<void> _readFromStorage() async {
    final dataFromLocal = localStorage.getItem(fileName);
    if (dataFromLocal != null) {
      subject.value = json.decode(dataFromLocal) as Map<String, dynamic>;
    } else {
      await _writeToStorage(<String, dynamic>{});
    }
  }
}

extension FirstWhereExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
