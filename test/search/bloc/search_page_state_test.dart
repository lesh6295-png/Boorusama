// Dart imports:
import 'dart:async';

// Package imports:
import 'package:rxdart/subjects.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/application/post/post_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/search/search.dart';
import 'package:boorusama/boorus/danbooru/application/tag/tag.dart';
import '../common.dart';

SearchBloc optionsState(
  Stream<TagSearchState> tagSearchStream,
  Stream<PostState> postStream,
  bool allowSearch,
) =>
    SearchBloc(
      initial: SearchState(
        displayState: DisplayState.options,
        allowSearch: allowSearch,
      ),
      tagSearchStream: tagSearchStream,
      postStream: postStream,
    );

SearchBloc suggestionsState(
  Stream<TagSearchState> tagSearchStream,
  Stream<PostState> postStream,
  bool allowSearch,
) =>
    SearchBloc(
      initial: SearchState(
        displayState: DisplayState.suggestion,
        allowSearch: allowSearch,
      ),
      tagSearchStream: tagSearchStream,
      postStream: postStream,
    );

SearchBloc resultState(
  Stream<TagSearchState> tagSearchStream,
  Stream<PostState> postStream,
  bool allowSearch,
) =>
    SearchBloc(
      initial: SearchState(
        displayState: DisplayState.result,
        allowSearch: allowSearch,
      ),
      tagSearchStream: tagSearchStream,
      postStream: postStream,
    );

void main() {
  group(
    '[when in options state]',
    () {
      test(
        'enter a tag will switch to suggestions state',
        () {
          final tagInitState = TagSearchState.initial();
          final tagStream = BehaviorSubject.seeded(tagInitState);
          final bloc = optionsState(tagStream, const Stream.empty(), false);

          tagStream.add(tagInitState.copyWith(
            query: 'a',
          ));

          expect(
              bloc.stream,
              emitsInOrder(
                [
                  const SearchState(displayState: DisplayState.suggestion),
                ],
              ));

          tagStream.close();
        },
      );

      test(
        'enable search when selected tags is not empty',
        () {
          final tagInitState = TagSearchState.initial().copyWith(
            selectedTags: [],
          );
          final tagStream = BehaviorSubject.seeded(tagInitState);
          final bloc = optionsState(tagStream, const Stream.empty(), false);

          tagStream.add(tagInitState.copyWith(
            selectedTags: [
              tagSearchItemFromString('a'),
            ],
          ));

          expect(
              bloc.stream,
              emitsInOrder(
                [
                  const SearchState(
                    displayState: DisplayState.options,
                    allowSearch: true,
                  ),
                ],
              ));

          tagStream.close();
        },
      );

      test(
        'disable search when selected tags is empty',
        () {
          final tagInitState = TagSearchState.initial().copyWith(
            selectedTags: [
              tagSearchItemFromString('a'),
            ],
          );
          final tagStream = BehaviorSubject.seeded(tagInitState);
          final bloc = optionsState(tagStream, const Stream.empty(), false);

          tagStream.add(tagInitState.copyWith(
            selectedTags: [],
          ));

          expect(
              bloc.stream,
              emitsInOrder(
                [
                  const SearchState(
                    displayState: DisplayState.options,
                    // ignore: avoid_redundant_argument_values
                    allowSearch: false,
                  ),
                ],
              ));

          tagStream.close();
        },
      );

      test(
        'switch to result state when search requested and allow search is true',
        () {
          final tagInitState = TagSearchState.initial().copyWith(
            selectedTags: [
              tagSearchItemFromString('a'),
            ],
          );
          final tagStream = BehaviorSubject.seeded(tagInitState);
          final bloc = optionsState(tagStream, const Stream.empty(), true);

          // ignore: cascade_invocations
          bloc.add(const SearchRequested());

          expect(
              bloc.stream,
              emitsInOrder(
                [
                  emitsAnyOf([
                    const SearchState(
                      displayState: DisplayState.result,
                      allowSearch: true,
                    ),
                    const SearchState(
                      displayState: DisplayState.result,
                      // ignore: avoid_redundant_argument_values
                      allowSearch: false,
                    ),
                  ]),
                ],
              ));

          tagStream.close();
        },
      );

      test(
          'stay at options state when search requested but allow search is false',
          () {
        final tagInitState = TagSearchState.initial().copyWith(
          selectedTags: [],
        );
        final tagStream = BehaviorSubject.seeded(tagInitState);
        final bloc = optionsState(tagStream, const Stream.empty(), false);

        // ignore: cascade_invocations
        bloc.add(const SearchRequested());

        expect(
            bloc.stream,
            emitsInOrder(
              [],
            ));

        tagStream.close();
      });
    },
  );

  group('[when in suggestions state]', () {
    test('delete all text will switch to options state', () {
      final tagInitState = TagSearchState.initial().copyWith(
        query: 'a',
      );
      final tagStream = BehaviorSubject.seeded(tagInitState);
      final bloc = suggestionsState(tagStream, const Stream.empty(), false);

      tagStream.add(tagInitState.copyWith(
        query: '',
      ));

      expect(
          bloc.stream,
          emitsInOrder(
            [
              const SearchState(displayState: DisplayState.options),
            ],
          ));

      tagStream.close();
    });

    test('select a tag will switch to options state', () {
      final tagInitState = TagSearchState.initial().copyWith(
        query: 'a',
      );
      final tagStream = BehaviorSubject.seeded(tagInitState);
      final bloc = suggestionsState(tagStream, const Stream.empty(), false);

      tagStream.add(tagInitState.copyWith(
        query: 'a',
        selectedTags: [
          tagSearchItemFromString('a'),
        ],
      ));

      expect(
          bloc.stream,
          emitsInOrder(
            [
              const SearchState(
                displayState: DisplayState.options,
                allowSearch: true,
              ),
            ],
          ));

      tagStream.close();
    });

    test('always disable search', () {
      final bloc =
          suggestionsState(const Stream.empty(), const Stream.empty(), true);

      // ignore: cascade_invocations
      bloc
        ..add(const SearchRequested())
        ..close();

      expect(
        bloc.stream,
        emitsInOrder([
          emitsDone,
        ]),
      );
    });
  });

  group('[when in result state]', () {
    test('remove all selected tags will switch to options state', () {
      final tagInitState = TagSearchState.initial().copyWith(
        selectedTags: [
          tagSearchItemFromString('a'),
        ],
      );
      final tagStream = BehaviorSubject.seeded(tagInitState);
      final bloc = resultState(tagStream, const Stream.empty(), false);

      tagStream.add(tagInitState.copyWith(
        selectedTags: [],
      ));

      expect(
          bloc.stream,
          emitsInOrder(
            [
              const SearchState(displayState: DisplayState.options),
            ],
          ));

      tagStream.close();
    });

    test("stay at current state if doesn't remove all tags", () {
      final tagInitState = TagSearchState.initial().copyWith(
        selectedTags: [
          tagSearchItemFromString('a'),
          tagSearchItemFromString('b'),
        ],
      );
      final tagStream = BehaviorSubject.seeded(tagInitState);
      final bloc = resultState(tagStream, const Stream.empty(), false);

      tagStream.add(tagInitState.copyWith(
        selectedTags: [
          tagSearchItemFromString('b'),
        ],
      ));

      bloc.close();

      expect(
          bloc.stream,
          emitsInOrder(
            [
              emitsDone,
            ],
          ));

      tagStream.close();
    });

    test('always disable search', () {
      final bloc =
          resultState(const Stream.empty(), const Stream.empty(), true);

      // ignore: cascade_invocations
      bloc
        ..add(const SearchRequested())
        ..close();

      expect(
        bloc.stream,
        emitsInOrder([
          emitsDone,
        ]),
      );
    });

    test('if error happen when loading posts, switch to error state', () {
      final postInitState = PostState.initial();
      final postStream = BehaviorSubject.seeded(postInitState);

      final bloc = resultState(const Stream.empty(), postStream, false)
        ..emit(const SearchState(
          displayState: DisplayState.result,
        ));

      postStream.add(postInitState.copyWith(
        status: LoadStatus.failure,
      ));

      expect(
        bloc.stream,
        emitsInOrder([const SearchState(displayState: DisplayState.error)]),
      );

      postStream.close();
    });

    test('if no posts returned, switch to no data state', () {
      final postInitState = PostState.initial();
      final postStream = BehaviorSubject.seeded(postInitState);

      final bloc = resultState(const Stream.empty(), postStream, false)
        ..emit(const SearchState(
          displayState: DisplayState.result,
        ));

      postStream.add(postInitState.copyWith(
        status: LoadStatus.success,
        posts: [],
      ));

      expect(
        bloc.stream,
        emitsInOrder([const SearchState(displayState: DisplayState.noResult)]),
      );

      postStream.close();
    });

    test(
      'enter a tag will switch to suggestions state',
      () {
        final tagInitState = TagSearchState.initial();
        final tagStream = BehaviorSubject.seeded(tagInitState);
        final bloc = resultState(tagStream, const Stream.empty(), false);

        tagStream.add(tagInitState.copyWith(
          query: 'a',
        ));

        expect(
            bloc.stream,
            emitsInOrder(
              [
                const SearchState(displayState: DisplayState.suggestion),
              ],
            ));

        tagStream.close();
      },
    );
  });
}
