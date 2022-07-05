// Project imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';

abstract class CurrentAccountRepository {
  Future<List<Account>> getAll();
  Future<Account?> get();
  Future<void> set(Account account);
  Future<void> remove();
  Future<void> clear();
}

Account useAnonymousAccountIfNull(Account? account) =>
    account ?? AnonymousAccount();
