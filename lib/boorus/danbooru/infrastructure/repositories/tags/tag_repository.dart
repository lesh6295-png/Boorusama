// Package imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/tags/tags.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/api.dart';
import 'package:boorusama/core/infrastructure/http_parser.dart';

List<Tag> parseTag(HttpResponse<dynamic> value) => parse(
      value: value,
      converter: (item) => Tag.fromJson(item),
    ).toList();

class TagRepository implements ITagRepository {
  TagRepository(
    this._api,
    this._accountRepository,
  );

  final Api _api;
  final CurrentAccountRepository _accountRepository;

  @override
  Future<List<Tag>> getTagsByNamePattern(String stringPattern, int page) =>
      _accountRepository
          .get()
          .then(useAnonymousAccountIfNull)
          .then(
            (account) => _api.getTagsByNamePattern(
              account.name,
              account.key,
              page,
              'yes',
              '$stringPattern*',
              'count',
              30,
            ),
          )
          .then(parseTag)
          .catchError((Object obj) =>
              throw Exception('Failed to get tags for $stringPattern'));

  @override
  Future<List<Tag>> getTagsByNameComma(
    String stringComma,
    int page, {
    CancelToken? cancelToken,
  }) async {
    try {
      return _accountRepository
          .get()
          .then(useAnonymousAccountIfNull)
          .then((account) => _api.getTagsByNameComma(
                account.name,
                account.key,
                page,
                'yes',
                stringComma,
                'count',
                1000,
                cancelToken: cancelToken,
              ))
          .then(parseTag);
    } on DioError catch (e) {
      if (e.type == DioErrorType.cancel) {
        // Cancel token triggered, skip this request
        return [];
      } else {
        throw Exception('Failed to get posts for $stringComma');
      }
    }
  }
}
