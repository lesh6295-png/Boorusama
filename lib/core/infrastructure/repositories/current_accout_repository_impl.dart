// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

class CurrentAccountRepositoryImpl implements CurrentAccountRepository {
  final db = <BooruType, Account>{};

  @override
  Future<Account?> get(BooruType booruType) async {
    return db[booruType];
  }

  @override
  Future<List<Account>> getAll() async {
    return db.values.toList();
  }

  @override
  Future<void> remove(BooruType type) async {
    db.remove(type);
  }

  @override
  Future<void> set(Account account, BooruType type) async {
    db[type] = account;
  }

  @override
  Future<void> clear(BooruType type) async {
    db.removeWhere((key, value) => key == type);
  }
}
