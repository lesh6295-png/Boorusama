// Package imports:
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/api/api.dart';
import 'package:boorusama/boorus/danbooru/domain/accounts/accounts.dart';
import 'package:boorusama/boorus/danbooru/domain/comments/comments.dart';
import 'package:boorusama/boorus/danbooru/domain/users/users.dart';
import 'package:boorusama/boorus/danbooru/infra/dtos/dtos.dart';
import 'package:boorusama/boorus/danbooru/infra/repositories/users/users.dart';
import 'package:boorusama/core/infra/http_parser.dart';

const String commentResourceApiParam =
    'creator,id,post_id,body,score,is_deleted,created_at,updated_at,is_sticky,do_not_bump_post,updater_id';

List<Comment> parseComment(HttpResponse<dynamic> value) => parse(
      value: value,
      converter: (item) => CommentDto.fromJson(item),
    ).map(commentDtoToComment).toList();

class CommentRepositoryApi implements CommentRepository {
  CommentRepositoryApi(
    Api api,
    AccountRepository accountRepository,
  )   : _api = api,
        _accountRepository = accountRepository;

  final Api _api;
  final AccountRepository _accountRepository;

  @override
  Future<List<Comment>> getCommentsFromPostId(
    int postId, {
    CancelToken? cancelToken,
  }) =>
      _api
          .getComments(
            postId,
            1000,
            only: commentResourceApiParam,
            cancelToken: cancelToken,
          )
          .then(parseComment)
          .catchError((Object error) {
        throw Exception('Failed to get comments for $postId');
      });

  @override
  Future<bool> postComment(int postId, String content) => _accountRepository
      .get()
      .then((account) => _api.postComment(
            account.username,
            account.apiKey,
            postId,
            content,
            true,
          ))
      .then((_) => true)
      .catchError((Object obj) => false);

  @override
  Future<bool> updateComment(int commentId, String content) =>
      _accountRepository
          .get()
          .then((account) => _api.updateComment(
                account.username,
                account.apiKey,
                commentId,
                content,
              ))
          .then((_) => true)
          .catchError((Object obj) => false);

  @override
  Future<bool> deleteComment(int commentId) => _accountRepository
      .get()
      .then((account) => _api.deleteComment(
            account.username,
            account.apiKey,
            commentId,
          ))
      .then((_) => true)
      .catchError((Object obj) => false);
}

Comment commentDtoToComment(CommentDto d) {
  return Comment(
    id: d.id ?? 0,
    score: d.score ?? 0,
    body: d.body ?? '',
    postId: d.postId ?? 0,
    createdAt: d.createdAt ?? DateTime.now(),
    updatedAt: d.updatedAt ?? DateTime.now(),
    isDeleted: d.isDeleted ?? false,
    creator:
        d.creator == null ? User.placeholder() : userDtoToUser(d.creator!, []),
  );
}
