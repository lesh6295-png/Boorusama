// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'account.dart';

abstract class AccountRepository {
  Future<Account?> getById(AccountId id);
  Future<List<Account>> getAll();
  Future<Account?> add(AccountAddArg args);
  Future<bool> delete(AccountId id);
}

class AccountAddArg {
  const AccountAddArg({
    required this.name,
    required this.key,
    required this.type,
    required this.createdAt,
  });

  final String name;
  final String key;
  final BooruType type;
  final DateTime createdAt;
}
