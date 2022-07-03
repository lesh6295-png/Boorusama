// Project imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';

class AccountRepositoryImpl implements AccountRepository {
  final db = <int, Account>{};

  @override
  Future<Account?> add(AccountAddArg args) async {
    final nextId = db.keys.isEmpty ? 1 : db.keys.last + 1;
    final account = Account(
      id: nextId,
      name: args.name,
      key: args.key,
      booruType: args.type,
      createdAt: args.createdAt,
      updatedAt: args.createdAt,
    );

    db.putIfAbsent(nextId, () => account);

    return account;
  }

  @override
  Future<bool> delete(AccountId id) async {
    db.remove(id);
    return true;
  }

  @override
  Future<List<Account>> getAll() async {
    return db.values.toList();
  }

  @override
  Future<Account?> getById(AccountId id) async {
    return db[id];
  }
}
