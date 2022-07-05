// Project imports:
import 'dart:convert';

import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:hive/hive.dart';

class AccountDbObject {
  const AccountDbObject({
    required this.name,
    required this.key,
    required this.booruType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountDbObject.fromJson(Map<String, dynamic> json) =>
      AccountDbObject(
        name: json['name'],
        key: json['key'],
        booruType: BooruType.values[json['booruType']],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'key': key,
        'booruType': booruType.index,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  final AccountName name;
  final AccountKey key;
  final BooruType booruType;
  final DateTime createdAt;
  final DateTime updatedAt;
}

Account _accountDbObjectToAccount(int id, AccountDbObject accountDbObject) =>
    Account(
      id: id,
      name: accountDbObject.name,
      key: accountDbObject.key,
      booruType: accountDbObject.booruType,
      createdAt: accountDbObject.createdAt,
      updatedAt: accountDbObject.updatedAt,
    );

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required this.db,
    required this.dbName,
  });
  final Box<String> db;
  final String dbName;

  @override
  Future<Account?> add(AccountAddArg args) async {
    final accountDbObject = AccountDbObject(
      name: args.name,
      key: args.key,
      booruType: args.type,
      createdAt: args.createdAt,
      updatedAt: args.createdAt,
    );

    final id = await db.add(jsonEncode(accountDbObject.toJson()));

    return _accountDbObjectToAccount(id, accountDbObject);
  }

  @override
  Future<bool> delete(AccountId id) async {
    await db.deleteAt(id);

    return true;
  }

  @override
  Future<List<Account>> getAll() async {
    return db.keys
        .map((e) => [e, db.get(e)])
        .map((e) => [e[0], jsonDecode(e[1])])
        .map((e) => [e[0], AccountDbObject.fromJson(e[1])])
        .map((e) => _accountDbObjectToAccount(e[0], e[1]))
        .toList();
  }

  @override
  Future<Account?> getById(AccountId id) async {
    final json = db.getAt(id);
    if (json == null) return null;
    return Account.fromJson(jsonDecode(json));
  }
}
