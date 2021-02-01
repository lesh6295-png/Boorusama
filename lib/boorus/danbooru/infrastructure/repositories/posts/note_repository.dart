// Package imports:
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:html/parser.dart' as html;

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/danbooru/danbooru_api.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/i_api.dart';

final noteProvider =
    Provider<INoteRepository>((ref) => NoteRepository(ref.watch(apiProvider)));

class NoteRepository implements INoteRepository {
  final IApi _api;

  NoteRepository(this._api);

  @override
  Future<List<Note>> getNotesFrom(
    int postId, {
    CancelToken cancelToken,
  }) async {
    try {
      final value = await _api.getNotes(postId, cancelToken: cancelToken);
      final data = value.response.data.toString();
      final document = html.parse(data);

      final notesNode = document.documentElement
          .querySelector("section[id='notes']")
          .children;

      final notes = List<Note>();

      for (var node in notesNode) {
        var w = node.attributes["data-width"];
        var h = node.attributes["data-height"];
        var x = node.attributes["data-x"];
        var y = node.attributes["data-y"];
        var coord = NoteCoordinate(
            double.parse(x), double.parse(y), double.parse(w), double.parse(h));
        var content = node.attributes["data-body"];
        notes.add(Note(coord, content));
      }

      return notes;
    } on DioError catch (e) {
      if (e.type == DioErrorType.CANCEL) {
        // Cancel token triggered, skip this request
        return [];
      } else {
        throw Exception("Failed to get comments from $postId");
      }
    }
  }
}
