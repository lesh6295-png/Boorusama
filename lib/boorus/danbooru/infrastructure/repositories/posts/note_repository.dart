// Package imports:
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/posts/note_dto.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/i_api.dart';
import 'package:boorusama/core/infrastructure/http_parser.dart';

List<Note> parseNote(HttpResponse<dynamic> value) => parse(
      value: value,
      converter: (item) => NoteDto.fromJson(item),
    ).map((e) => e.toEntity()).toList();

class NoteRepository implements INoteRepository {

  NoteRepository(this._api);
  final IApi _api;

  @override
  Future<List<Note>> getNotesFrom(
    int postId, {
    CancelToken? cancelToken,
  }) async {
    try {
      return _api
          .getNotes(
            postId,
            cancelToken: cancelToken,
          )
          .then(parseNote);
    } on DioError catch (e) {
      if (e.type == DioErrorType.cancel) {
        // Cancel token triggered, skip this request
        return [];
      } else {
        throw Exception('Failed to get notes from $postId');
      }
    }
  }
}
