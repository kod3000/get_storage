import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:get/utils.dart';

import 'storage/html.dart' if (dart.library.io) 'storage/io.dart';
import 'value.dart';

/// Instantiate GetStorage to access storage driver apis
class GetStorage {
  factory GetStorage(
      [String container = 'GetStorage',
      String? path,
      Map<String, dynamic>? initialData]) {
    if (_sync.containsKey(container)) {
      return _sync[container]!;
    } else {
      final instance = GetStorage._internal(container, path, initialData);
      _sync[container] = instance;
      return instance;
    }
  }

  GetStorage._internal(String key,
      [String? path, Map<String, dynamic>? initialData]) {
    _concrete = StorageImpl(key, path);
    _initialData = initialData;

    initStorage = Future<bool>(() async {
      await _init();
      return true;
    });
  }

  static final Map<String, GetStorage> _sync = {};

  final microtask = Microtask();

  /// Start the storage drive. It's important to use await before calling this API, or side effects will occur.
  static Future<bool> init([String container = 'GetStorage']) {
    WidgetsFlutterBinding.ensureInitialized();
    return GetStorage(container).initStorage;
  }

  Future<void> _init() async {
    try {
      await _concrete.init(_initialData);
    } catch (err) {
      throw err;
    }
  }

  /// Reads a value in your container with the given key.
  T? read<T>(String key) {
    return _concrete.read(key);
  }

  List<String> getKeys() {
    return _concrete.getKeys();
  }

  List<dynamic> getValues() {
    return _concrete.getValues();
  }

  /// return data true if value is different of null;
  bool hasData(String key) {
    return (read(key) == null ? false : true);
  }

  Map<String, dynamic> get changes => _concrete.subject.changes;

  /// Listen changes in your container
  VoidCallback listen(VoidCallback value) {
    return _concrete.subject.addListener(value);
  }

  Map<Function, Function> _keyListeners = <Function, Function>{};

  VoidCallback listenKey(String key, ValueSetter callback) {
    final VoidCallback listen = () {
      if (changes.keys.first == key) {
        callback(changes[key]);
      }
    };

    _keyListeners[callback] = listen;
    return _concrete.subject.addListener(listen);
  }

  /// Write data on your container
  Future<void> write(String key, dynamic value) async {
    writeInMemory(key, value);
    return _tryFlush();
  }

  void writeInMemory(String key, dynamic value) {
    _concrete.write(key, value);
  }

  /// Write data on your only if data is null
  Future<void> writeIfNull(String key, dynamic value) async {
    if (read(key) != null) return;
    return write(key, value);
  }

  /// remove data from container by key
  Future<void> remove(String key) async {
    _concrete.remove(key);
    return _tryFlush();
  }

  /// clear all data on your container
  Future<void> erase() async {
    _concrete.clear();
    return _tryFlush();
  }

  Future<void> save() async {
    return _tryFlush();
  }

  Future<void> _tryFlush() async {
    return microtask.exec(_addToQueue);
  }

  Future _addToQueue() {
    return queue.add(_flush);
  }

  Future<void> _flush() async {
    try {
      await _concrete.flush();
    } catch (e) {
      rethrow;
    }
    return;
  }

  late StorageImpl _concrete;

  GetQueue queue = GetQueue();

  /// listenable of container
  ValueStorage<Map<String, dynamic>> get listenable => _concrete.subject;

  /// Start the storage drive. Important: use await before calling this api, or side effects will happen.
  late Future<bool> initStorage;

  Map<String, dynamic>? _initialData;
}

class StorageImpl {
  StorageImpl(this.fileName, [this.path]);

  final String? path;
  final String fileName;

  ValueStorage<Map<String, dynamic>> subject =
      ValueStorage<Map<String, dynamic>>(<String, dynamic>{});

  void clear() {
    // This method will be implemented in platform-specific files (html.dart or io.dart)
  }

  Future<bool> _exists() async {
    // This method will be implemented in platform-specific files (html.dart or io.dart)
    return false;
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
  }

  void write(String key, dynamic value) {
    subject.value?[key] = value;
    subject.changeValue(key, value);
  }

  Future<void> _writeToStorage(Map<String, dynamic> data) async {
    // This method will be implemented in platform-specific files (html.dart or io.dart)
  }

  Future<void> _readFromStorage() async {
    // This method will be implemented in platform-specific files (html.dart or io.dart)
  }
}

class Microtask {
  int _version = 0;
  int _microtask = 0;

  void exec(Function callback) {
    if (_microtask == _version) {
      _microtask++;
      scheduleMicrotask(() {
        _version++;
        _microtask = _version;
        callback();
      });
    }
  }
}

typedef KeyCallback = Function(String);
