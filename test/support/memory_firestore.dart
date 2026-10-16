// Small deterministic test double for repository calls, not security rules or
// Firestore conflict semantics (those run against the real CLI emulator).
// Test doubles intentionally implement FlutterFire's sealed public interfaces.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef Data = Map<String, dynamic>;

class MemoryAuth implements FirebaseAuth {
  MemoryAuth(String uid) : currentUser = MemoryUser(uid);
  @override
  User? currentUser;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryUser implements User {
  MemoryUser(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryFirestore implements FirebaseFirestore {
  final documents = <String, Data>{};
  final reads = <String>[];
  final commits = <List<String>>[];
  final queryLimits = <int>[];
  Future<void> Function()? beforeTransaction;
  Future<void> Function(String path)? beforeDocumentRead;
  bool failCommit = false;
  @override
  CollectionReference<Data> collection(String path) =>
      MemoryCollection(this, path);
  @override
  WriteBatch batch() => MemoryBatch(this);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    await beforeTransaction?.call();
    final tx = MemoryTransaction(this);
    final result = await handler(tx);
    await tx.batch.commit();
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryDocument implements DocumentReference<Data> {
  MemoryDocument(this.db, this.path);
  final MemoryFirestore db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Data> collection(String name) =>
      MemoryCollection(db, '$path/$name');
  @override
  Future<DocumentSnapshot<Data>> get([GetOptions? options]) async {
    db.reads.add(path);
    await db.beforeDocumentRead?.call(path);
    final data = db.documents[path];
    return data == null
        ? MissingMemorySnapshot(this)
        : MemorySnapshot(this, data);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MissingMemorySnapshot implements DocumentSnapshot<Data> {
  MissingMemorySnapshot(this.reference);
  @override
  final MemoryDocument reference;
  @override
  String get id => reference.id;
  @override
  bool get exists => false;
  @override
  Data? data() => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemorySnapshot implements QueryDocumentSnapshot<Data> {
  MemorySnapshot(this.reference, Data? data)
    : _data = data == null ? null : Map.of(data);
  final Data? _data;
  @override
  final MemoryDocument reference;
  @override
  String get id => reference.id;
  @override
  bool get exists => _data != null;
  @override
  Data data() => Map.of(_data!);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryQuery implements Query<Data> {
  MemoryQuery(
    this.db,
    this.path, {
    this.maxDocs,
    this.after,
    this.sorted = false,
  });
  final MemoryFirestore db;
  final String path;
  final int? maxDocs;
  final String? after;
  final bool sorted;
  @override
  Query<Data> orderBy(Object field, {bool descending = false}) =>
      MemoryQuery(db, path, maxDocs: maxDocs, after: after, sorted: true);
  @override
  Query<Data> startAfterDocument(DocumentSnapshot documentSnapshot) =>
      MemoryQuery(
        db,
        path,
        maxDocs: maxDocs,
        after: documentSnapshot.id,
        sorted: sorted,
      );
  @override
  Query<Data> limit(int limit) =>
      MemoryQuery(db, path, maxDocs: limit, after: after, sorted: sorted);
  @override
  Future<QuerySnapshot<Data>> get([GetOptions? options]) async {
    db.reads.add('$path/*');
    if (maxDocs != null) db.queryLimits.add(maxDocs!);
    var entries = db.documents.entries
        .where(
          (e) =>
              e.key.startsWith('$path/') &&
              !e.key.substring(path.length + 1).contains('/'),
        )
        .toList();
    if (sorted) {
      entries.sort(
        (a, b) =>
            (b.value['date'] as String).compareTo(a.value['date'] as String),
      );
    }
    if (after != null) {
      final index = entries.indexWhere((e) => e.key.split('/').last == after);
      entries = entries.skip(index + 1).toList();
    }
    return MemoryQuerySnapshot(
      entries
          .take(maxDocs ?? entries.length)
          .map((e) => MemorySnapshot(MemoryDocument(db, e.key), e.value))
          .toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryCollection extends MemoryQuery
    implements CollectionReference<Data> {
  MemoryCollection(super.db, super.path);
  @override
  DocumentReference<Data> doc([String? path]) =>
      MemoryDocument(db, '${this.path}/$path');
}

class MemoryQuerySnapshot implements QuerySnapshot<Data> {
  MemoryQuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Data>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryBatch implements WriteBatch {
  MemoryBatch(this.db);
  final MemoryFirestore db;
  final operations = <(String, Data?, bool)>[];
  @override
  void delete(DocumentReference document) =>
      operations.add((document.path, null, false));
  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) =>
      operations.add((
        document.path,
        Map<String, dynamic>.of(data as Data),
        options?.merge ?? false,
      ));
  @override
  Future<void> commit() async {
    if (db.failCommit) throw StateError('offline');
    if (operations.isNotEmpty) {
      db.commits.add(operations.map((e) => e.$1).toList());
    }
    for (final (path, data, merge) in operations) {
      if (data == null) {
        db.documents.remove(path);
      } else {
        db.documents[path] = {...?merge ? db.documents[path] : null, ...data};
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryTransaction implements Transaction {
  MemoryTransaction(MemoryFirestore db) : batch = MemoryBatch(db);
  final MemoryBatch batch;
  @override
  Transaction update(DocumentReference document, Data data) {
    batch.set(document, data, SetOptions(merge: true));
    return this;
  }

  @override
  Transaction delete(DocumentReference document) {
    batch.delete(document);
    return this;
  }

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async =>
      await (documentReference as MemoryDocument).get() as DocumentSnapshot<T>;
  @override
  Transaction set<T>(
    DocumentReference<T> document,
    T data, [
    SetOptions? options,
  ]) {
    batch.set(document, data, options);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
