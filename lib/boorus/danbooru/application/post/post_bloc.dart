// Dart imports:
import 'dart:collection';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/repositories/repositories.dart';
import 'package:boorusama/core/application/exception.dart';
import 'package:boorusama/main.dart';
import 'common.dart';

class PostQueueItem {
  const PostQueueItem({
    required this.page,
    required this.posts,
  });

  final int page;
  final List<Post> posts;
}

class PostStore {
  PostStore({
    required this.totalPage,
  });
  final int totalPage;
  final Queue<PostQueueItem> _posts = Queue();

  List<Post> get() {
    return _posts.toList().expand((e) => e.posts).toList();
  }

  void addLast(int page, List<Post> posts) {
    if (_posts.length == totalPage) {
      _posts.removeFirst();
    }
    _posts.addLast(PostQueueItem(page: page, posts: posts));
  }

  void addFirst(int page, List<Post> posts) {
    if (_posts.length == totalPage) {
      _posts.removeLast();
    }
    _posts.addFirst(PostQueueItem(page: page, posts: posts));
  }

  void clear() {
    _posts.clear();
  }
}

enum PostsOrder {
  popular,
  newest,
}

enum PostFetchDirection {
  up,
  down,
}

@immutable
class PostState extends Equatable {
  const PostState({
    required this.status,
    required this.posts,
    required this.filteredPosts,
    required this.page,
    required this.hasMore,
    this.exceptionMessage,
  });

  factory PostState.initial() => const PostState(
        status: LoadStatus.initial,
        posts: [],
        filteredPosts: [],
        page: 1,
        hasMore: true,
      );

  final List<Post> posts;
  final List<Post> filteredPosts;
  final LoadStatus status;
  final int page;
  final bool hasMore;
  final String? exceptionMessage;

  PostState copyWith({
    LoadStatus? status,
    List<Post>? posts,
    List<Post>? filteredPosts,
    int? page,
    bool? hasMore,
    String? exceptionMessage,
  }) =>
      PostState(
        status: status ?? this.status,
        posts: posts ?? this.posts,
        filteredPosts: filteredPosts ?? this.filteredPosts,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        exceptionMessage: exceptionMessage ?? this.exceptionMessage,
      );

  @override
  List<Object?> get props =>
      [status, posts, filteredPosts, page, hasMore, exceptionMessage];
}

@immutable
abstract class PostEvent extends Equatable {
  const PostEvent();
}

class PostFetched extends PostEvent {
  const PostFetched({
    required this.tags,
    this.order,
    this.direction = PostFetchDirection.down,
  }) : super();
  final String tags;
  final PostsOrder? order;
  final PostFetchDirection direction;

  @override
  List<Object?> get props => [tags, order, direction];
}

class PostRefreshed extends PostEvent {
  const PostRefreshed({
    this.tag,
    this.order,
  }) : super();

  final String? tag;
  final PostsOrder? order;

  @override
  List<Object?> get props => [tag, order];
}

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({
    required IPostRepository postRepository,
    required BlacklistedTagsRepository blacklistedTagsRepository,
    required PostStore store,
  }) : super(PostState.initial()) {
    on<PostFetched>(
      (event, emit) async {
        final blacklisted =
            await blacklistedTagsRepository.getBlacklistedTags();
        final query = '${event.tags} ${_postsOrderToString(event.order)}';

        final page = event.direction == PostFetchDirection.down
            ? state.page + 1
            : state.page - 1;

        await tryAsync<List<Post>>(
          action: () => postRepository.getPosts(query, page),
          onLoading: () => emit(state.copyWith(status: LoadStatus.loading)),
          onFailure: (stackTrace, error) {
            if (error is CannotSearchMoreThanTwoTags) {
              emit(state.copyWith(
                status: LoadStatus.failure,
                exceptionMessage: error.message,
              ));
            } else {
              emit(state.copyWith(
                status: LoadStatus.failure,
                exceptionMessage:
                    'Unknown exception has occured, please try again later',
              ));
            }
          },
          onSuccess: (posts) async {
            // final filteredPosts = filterBlacklisted(posts, blacklisted);
            if (event.direction == PostFetchDirection.down) {
              store.addLast(page, posts);
            } else {
              store.addFirst(page, posts);
            }
            // print(
            //     '${filteredPosts.length} posts got filtered. Total: ${state.filteredPosts.length + filteredPosts.length}');
            emit(
              state.copyWith(
                status: LoadStatus.success,
                posts: [
                  // ...state.posts,
                  ...filter(store.get(), blacklisted),
                ],
                // filteredPosts: [
                //   ...state.filteredPosts,
                //   ...filteredPosts,
                // ],
                page: page,
                hasMore: posts.isNotEmpty,
              ),
            );
          },
        );
      },
      transformer: droppable(),
    );

    on<PostRefreshed>(
      (event, emit) async {
        final blacklisted =
            await blacklistedTagsRepository.getBlacklistedTags();
        final query = '${event.tag ?? ''} ${_postsOrderToString(event.order)}';

        await tryAsync<List<Post>>(
          action: () => postRepository.getPosts(query, 1),
          onLoading: () => emit(state.copyWith(status: LoadStatus.initial)),
          onFailure: (stackTrace, error) {
            if (error is BooruException) {
              emit(state.copyWith(
                status: LoadStatus.failure,
                exceptionMessage: error.message,
              ));
            } else {
              emit(state.copyWith(
                status: LoadStatus.failure,
                exceptionMessage:
                    'Unknown exception has occured, please try again later',
              ));
            }
          },
          onSuccess: (posts) async {
            store
              ..clear()
              ..addFirst(1, posts);
            emit(
              state.copyWith(
                status: LoadStatus.success,
                posts: filter(store.get(), blacklisted),
                filteredPosts: filterBlacklisted(store.get(), blacklisted),
                page: 1,
                hasMore: posts.isNotEmpty,
              ),
            );
          },
        );
      },
      transformer: restartable(),
    );
  }
}

String _postsOrderToString(PostsOrder? order) {
  switch (order) {
    case PostsOrder.popular:
      return 'order:favcount';
    default:
      return '';
  }
}
