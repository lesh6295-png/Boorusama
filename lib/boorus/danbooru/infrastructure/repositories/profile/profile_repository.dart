// Package imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/dio.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/profile/i_profile_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/profile/profile.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/api.dart';

class ProfileRepository implements IProfileRepository {
  ProfileRepository(
      {required CurrentAccountRepository accountRepository, required Api api})
      : _api = api,
        _accountRepository = accountRepository;

  final CurrentAccountRepository _accountRepository;
  final Api _api;

  @override
  Future<Profile?> getProfile({
    CancelToken? cancelToken,
    String? apiKey,
    String? username,
  }) async {
    HttpResponse value;
    try {
      if (apiKey != null && username != null) {
        value =
            await _api.getProfile(username, apiKey, cancelToken: cancelToken);
      } else {
        final account =
            await _accountRepository.get().then(useAnonymousAccountIfNull);
        value = await _api.getProfile(
          account.name,
          account.key,
          cancelToken: cancelToken,
        );
      }
      return Profile.fromJson(value.response.data);
    } on DioError catch (e) {
      if (e.type == DioErrorType.cancel) {
        // Cancel token triggered, skip this request
        return null;
      } else {
        throw InvalidUsernameOrPassword();
      }
    }
  }
}

class InvalidUsernameOrPassword implements Exception {}
