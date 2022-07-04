abstract class AccountVerifier {
  Future<bool> isValid(AccountAddData account);
}

class AccountAddData {
  const AccountAddData({
    required this.name,
    required this.key,
  });

  final String name;
  final String key;
}
