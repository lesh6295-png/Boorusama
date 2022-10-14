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
    on<SearchRequested>((event, emit) {
      if (state.displayState != DisplayState.options) return;
      if (state.allowSearch) {
        emit(state.copyWith(
          displayState: DisplayState.result,
          allowSearch: false,
        ));
      }
    });

    on<SearchOptionsRequested>((event, emit) {
      emit(state.copyWith(
        displayState: DisplayState.options,
        allowSearch: event.allowSearch,
      ));
    });

    on<SearchNoData>((event, emit) {
      emit(state.copyWith(
        displayState: DisplayState.noResult,
        allowSearch: false,
      ));
    });

    on<SearchError>((event, emit) {
      emit(state.copyWith(
        displayState: DisplayState.error,
        allowSearch: false,
      ));
    });

    on<SearchSuggestions>((event, emit) {
      emit(state.copyWith(
        displayState: DisplayState.suggestion,
        allowSearch: false,
      ));
    });

    on<SearchPermissionChanged>((event, emit) {
      emit(state.copyWith(allowSearch: event.allow));
    });

    tagSearchStream
        .pairwise()
        .where((event) => event[0].query.isEmpty && event[1].query.isNotEmpty)
        .listen((event) => add(const SearchSuggestions()))
        .addTo(compositeSubscription);

    // In Options state
    tagSearchStream
        .pairwise()
        .where((event) => state.displayState == DisplayState.options)
        .where((event) =>
            event[0].selectedTags.isEmpty && event[1].selectedTags.isNotEmpty)
        .listen((event) => add(const SearchPermissionChanged(allow: true)))
        .addTo(compositeSubscription);

    tagSearchStream
        .pairwise()
        .where((event) => state.displayState == DisplayState.options)
        .where((event) =>
            event[0].selectedTags.isNotEmpty && event[1].selectedTags.isEmpty)
        .listen((event) => add(const SearchPermissionChanged(allow: false)))
        .addTo(compositeSubscription);

    // In Suggestion state
    tagSearchStream
        .pairwise()
        .where((event) => state.displayState == DisplayState.suggestion)
        .where((event) =>
            event[0].query.isNotEmpty && event[1].query.isEmpty ||
            event[0].selectedTags.isEmpty && event[1].selectedTags.isNotEmpty)
        .listen((event) => add(SearchOptionsRequested(
            allowSearch: event[1].selectedTags.isNotEmpty)))
        .addTo(compositeSubscription);

    // In Result state
    tagSearchStream
        .pairwise()
        .where((event) => state.displayState == DisplayState.result)
        .where((event) =>
            event[0].selectedTags.isNotEmpty && event[1].selectedTags.isEmpty)
        .listen((event) => add(const SearchOptionsRequested()))
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
    ).where((event) {
      return event.item2.status == LoadStatus.failure &&
          event.item1.displayState == DisplayState.result;
    }).listen((state) {
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
