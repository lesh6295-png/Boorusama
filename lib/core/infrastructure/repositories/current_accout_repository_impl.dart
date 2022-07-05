// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

class CurrentAccountRepositoryImpl implements CurrentAccountRepository {
  CurrentAccountRepositoryImpl({
    required this.type,
  });

  final db = <BooruType, Account>{};
  final BooruType type;

  @override
  Future<Account?> get() async {
    return db[type];
  }

  @override
  Future<List<Account>> getAll() async {
    return db.values.toList();
  }

  @override
  Future<void> remove() async {
    db.remove(type);
  }

  @override
  Future<void> set(Account account) async {
    db[type] = account;
  }

  @override
  Future<void> clear() async {
    db.removeWhere((key, value) => key == type);
  }
}
