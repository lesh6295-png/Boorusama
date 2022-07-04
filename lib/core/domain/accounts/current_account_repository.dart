// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

abstract class CurrentAccountRepository {
  Future<List<Account>> getAll();
  Future<Account?> get(BooruType booruType);
  Future<void> set(Account account, BooruType type);
  Future<void> remove(BooruType type);
  Future<void> clear(BooruType type);
}
