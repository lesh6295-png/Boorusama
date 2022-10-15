import 'package:boorusama/boorus/danbooru/domain/users/users.dart';
import 'package:equatable/equatable.dart';

class Creator extends Equatable {
  const Creator({
    required this.id,
    required this.name,
    required this.level,
  });

  final CreatorId id;
  final CreatorName name;
  final UserLevel level;

  @override
  List<Object?> get props => [id, name, level];
}

typedef CreatorId = int;
typedef CreatorName = String;
