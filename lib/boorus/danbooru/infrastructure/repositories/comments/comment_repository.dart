// Package imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/comments/comments.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/api.dart';
import 'package:boorusama/core/infrastructure/http_parser.dart';

List<Comment> parseComment(HttpResponse<dynamic> value) => parse(
      value: value,
      converter: (item) => CommentDto.fromJson(item),
    ).map(commentDtoToComment).toList();

class CommentRepository implements ICommentRepository {
  CommentRepository(
    Api api,
    CurrentAccountRepository accountRepository,
  )   : _api = api,
        _accountRepository = accountRepository;

  final Api _api;
  final CurrentAccountRepository _accountRepository;

  @override
  Future<List<Comment>> getCommentsFromPostId(
    int postId, {
    CancelToken? cancelToken,
  }) =>
      _api
          .getComments(
            postId,
            1000,
            only:
                'creator,id,post_id,body,score,is_deleted,created_at,updated_at,is_sticky,do_not_bump_post,updater_id',
            cancelToken: cancelToken,
          )
          .then(parseComment)
          .catchError((Object error) {
        throw Exception('Failed to get comments for $postId');
      });

  @override
  Future<bool> postComment(int postId, String content) => _accountRepository
      .get()
      .then(useAnonymousAccountIfNull)
      .then((account) => _api.postComment(
            account.name,
            account.key,
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
          .then(useAnonymousAccountIfNull)
          .then((account) => _api.updateComment(
                account.name,
                account.key,
                commentId,
                content,
              ))
          .then((_) => true)
          .catchError((Object obj) => false);

  @override
  Future<bool> deleteComment(int commentId) => _accountRepository
      .get()
      .then(useAnonymousAccountIfNull)
      .then((account) => _api.deleteComment(
            account.name,
            account.key,
            commentId,
          ))
      .then((_) => true)
      .catchError((Object obj) => false);
}
