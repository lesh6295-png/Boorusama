// Project imports:
import 'package:boorusama/boorus/danbooru/infrastructure/apis/api.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

class AccountVerificationService implements AccountVerifier {
  const AccountVerificationService({
    required this.api,
  });

  final Api api;

  @override
  Future<bool> isValid(AccountAddData account) => api
      .getProfile(account.name, account.key)
      .then((value) => true)
      .catchError((_) => false);
}
