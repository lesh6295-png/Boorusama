// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/application/tag/tag.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required SearchState initial,
    required Stream<TagSearchState> tagSearchStream,
    required Stream<PostState> postStream,
  }) : super(initial) {
    on<SearchSuggestionReceived>((event, emit) =>
        emit(state.copyWith(displayState: DisplayState.suggestion)));

    on<SearchRequested>((event, emit) =>
        emit(state.copyWith(displayState: DisplayState.result)));

    on<SearchGoBackToSearchOptionsRequested>((event, emit) {
      emit(state.copyWith(displayState: DisplayState.options));
    });

    on<SearchSelectedTagCleared>((event, emit) {
      emit(state.copyWith(displayState: DisplayState.options));
    });

    on<SearchQueryEmpty>((event, emit) {
      if (state.displayState == DisplayState.result) return;
      emit(state.copyWith(displayState: DisplayState.options));
    });

    on<SearchNoData>((event, emit) {
      emit(state.copyWith(displayState: DisplayState.noResult));
    });

    on<SearchError>((event, emit) {
      emit(state.copyWith(displayState: DisplayState.error));
    });

    tagSearchStream
        .where((event) => event.suggestionTags.isNotEmpty)
        .listen((event) => add(const SearchSuggestionReceived()))
        .addTo(compositeSubscription);

    tagSearchStream
        .where((event) => event.query.isEmpty)
        .listen((event) => add(const SearchQueryEmpty()))
        .addTo(compositeSubscription);

    tagSearchStream
        .pairwise()
        .where((event) =>
            event[0].selectedTags.length == 1 && event[1].selectedTags.isEmpty)
        .listen((event) => add(const SearchSelectedTagCleared()))
        .addTo(compositeSubscription);

    Rx.combineLatest2<SearchState, PostState, Tuple2<SearchState, PostState>>(
      stream,
      postStream,
      (a, b) => Tuple2(a, b),
    )
        .where((event) =>
            event.item2.status == LoadStatus.success &&
            event.item2.posts.isEmpty &&
            event.item1.displayState == DisplayState.result)
        .listen((state) {
      add(const SearchNoData());
    }).addTo(compositeSubscription);

    Rx.combineLatest2<SearchState, PostState, Tuple2<SearchState, PostState>>(
      stream,
      postStream,
      (a, b) => Tuple2(a, b),
    )
        .where((event) =>
            event.item2.status == LoadStatus.failure &&
            event.item1.displayState == DisplayState.result)
        .listen((state) {
      add(SearchError(message: state.item2.exceptionMessage));
    }).addTo(compositeSubscription);
  }

  CompositeSubscription compositeSubscription = CompositeSubscription();

  @override
  Future<void> close() {
    compositeSubscription.cancel();
    return super.close();
  }
}
