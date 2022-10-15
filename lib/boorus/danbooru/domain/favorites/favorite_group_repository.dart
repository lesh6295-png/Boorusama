import 'package:boorusama/boorus/danbooru/domain/favorites/favorites.dart';

abstract class FavoriteGroupRepository {
  Future<FavoriteGroup> getFavoriteGroups();
}
