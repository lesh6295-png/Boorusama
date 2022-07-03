// Package imports:
import 'package:equatable/equatable.dart';

// Project imports:
import 'package:boorusama/boorus/booru.dart';

typedef AccountName = String;
typedef AccountId = int;
typedef AccountKey = String;

class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.key,
    required this.booruType,
    required this.createdAt,
    required this.updatedAt,
  });

  final AccountId id;
  final AccountName name;
  final AccountKey key;
  final BooruType booruType;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, name, key, booruType, createdAt, updatedAt];
}

class AnonymousAccount extends Account {
  AnonymousAccount()
      : super(
          id: 0,
          name: '',
          key: '',
          booruType: BooruType.unknown,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
}
