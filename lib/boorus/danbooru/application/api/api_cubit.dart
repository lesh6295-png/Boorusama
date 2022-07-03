// Package imports:
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/boorus/booru_factory.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/api.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/apis/danbooru/danbooru_api.dart';

Dio newDio(String url) => Dio(BaseOptions(baseUrl: url));

//TODO: simplify ApiEndpoint and Api
class ApiEndpointState extends Equatable {
  const ApiEndpointState({
    required this.booru,
  });

  final Booru booru;

  @override
  List<Object?> get props => [booru];
}

class ApiEndpointCubit extends Cubit<ApiEndpointState> {
  ApiEndpointCubit({
    required Booru initialValue,
    required this.factory,
  }) : super(ApiEndpointState(booru: initialValue));

  final BooruFactory factory;

  void changeApi({
    required bool isSafeMode,
  }) {
    final booru = factory.create(
      isSafeMode: isSafeMode,
    );

    emit(ApiEndpointState(
      booru: booru,
    ));
  }
}

class ApiState extends Equatable {
  const ApiState({
    required this.api,
    required this.booru,
  });
  factory ApiState.initial(
    Dio dio,
    Booru booru,
  ) =>
      ApiState(api: DanbooruApi(dio), booru: booru);

  final Api api;
  final Booru booru;

  ApiState copyWith({
    Api? api,
    Booru? booru,
  }) =>
      ApiState(
        api: api ?? this.api,
        booru: booru ?? this.booru,
      );

  @override
  List<Object?> get props => [api, booru];
}

class ApiCubit extends Cubit<ApiState> {
  ApiCubit({
    required Booru defaultBooru,
  }) : super(ApiState.initial(newDio(defaultBooru.url), defaultBooru));

  void changeApi(Booru booru) {
    final dio = newDio(booru.url);
    emit(state.copyWith(
      api: DanbooruApi(dio),
      booru: booru,
    ));
  }
}
