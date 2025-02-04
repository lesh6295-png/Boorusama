// Package imports:
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/domain/accounts/accounts.dart';
import 'package:boorusama/boorus/danbooru/domain/favorites/favorites.dart';
import 'package:boorusama/boorus/danbooru/domain/notes/notes.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/tags/tags.dart';
import 'package:boorusama/core/domain/settings/settings.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockFavoritesRepository extends Mock implements FavoritePostRepository {}

class MockAccountRepository extends Mock implements AccountRepository {}

class MockPostVoteRepository extends Mock implements PostVoteRepository {}

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  final postRepo = MockPostRepository();
  final favRepo = MockFavoritesRepository();
  final accountRepo = MockAccountRepository();
  final postVoteRepo = MockPostVoteRepository();
  final noteRepo = MockNoteRepository();

  group('[post detail test]', () {
    blocTest<PostDetailBloc, PostDetailState>(
      'add new tag',
      setUp: () {
        when(() => postRepo.putTag(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
      },
      tearDown: () {
        reset(postRepo);
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [
          PostDetailTag(
            name: 'foo',
            category: TagCategory.general.stringify(),
            postId: 1,
          ),
        ],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(PostDetailTagUpdated(
        tag: 'bar',
        category: TagCategory.artist.stringify(),
        postId: 1,
      )),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          tags: [
            PostDetailTag(
              name: 'foo',
              category: TagCategory.general.stringify(),
              postId: 1,
            ),
          ],
        ),
        PostDetailState.initial().copyWith(
          id: 1,
          currentIndex: 0,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          tags: [
            PostDetailTag(
              name: 'bar',
              category: TagCategory.artist.stringify(),
              postId: 1,
            ),
            PostDetailTag(
              name: 'foo',
              category: TagCategory.general.stringify(),
              postId: 1,
            ),
          ],
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'index changed',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => false);
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailIndexChanged(index: 1)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          nextPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'index changed with notes load',
      setUp: () {
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
        when(() => noteRepo.getNotesFrom(any())).thenAnswer((_) async => [
              Note.empty(),
              Note.empty(),
            ]);
      },
      tearDown: () {
        reset(accountRepo);
        reset(noteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 2, tags: ['translated']),
          ),
          PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 3, tags: ['translated']),
          ),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailIndexChanged(index: 1)),
      wait: const Duration(seconds: 1),
      verify: (bloc) => verify(() => noteRepo.getNotesFrom(any())).called(2),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          nextPost: () => PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 2, tags: ['translated']),
          ),
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          nextPost: () => PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 3, tags: ['translated']),
          ),
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          nextPost: () => PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 3, tags: ['translated']),
          ),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 2),
            notes: [
              Note.empty(),
              Note.empty(),
            ],
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'index changed with recommends load',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => false);
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
        when(() => postRepo.getPosts('foo', any(), limit: any(named: 'limit')))
            .thenAnswer((invocation) async => [Post.empty().copyWith(id: 3)]);
        when(() => postRepo.getPosts('bar', any(), limit: any(named: 'limit')))
            .thenAnswer((invocation) async => [Post.empty().copyWith(id: 4)]);
      },
      tearDown: () {
        reset(favRepo);
        reset(postRepo);
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 2,
              artistTags: ['foo'],
              characterTags: ['bar'],
            ),
            isFavorited: false,
          ),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailIndexChanged(index: 1)),
      wait: const Duration(seconds: 1),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          nextPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          recommends: [
            Recommend(
              title: 'foo',
              posts: [
                PostData.empty().copyWith(post: Post.empty().copyWith(id: 3)),
              ],
              type: RecommendType.artist,
            ),
          ],
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 1,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 2)),
          previousPost: () =>
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
          recommends: [
            Recommend(
              title: 'foo',
              posts: [
                PostData.empty().copyWith(post: Post.empty().copyWith(id: 3)),
              ],
              type: RecommendType.artist,
            ),
            Recommend(
              title: 'bar',
              posts: [
                PostData.empty().copyWith(post: Post.empty().copyWith(id: 4)),
              ],
              type: RecommendType.character,
            ),
          ],
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'mode changed',
      setUp: () {
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
      },
      tearDown: () {
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) =>
          bloc.add(const PostDetailModeChanged(enableSlideshow: true)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          enableSlideShow: true,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'slide show config changed',
      setUp: () {
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
      },
      tearDown: () {
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(PostDetailSlideShowConfigChanged(
        config: bloc.state.slideShowConfig.copyWith(skipAnimation: true),
      )),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          slideShowConfig: PostDetailState.initial()
              .slideShowConfig
              .copyWith(skipAnimation: true),
          currentPost:
              PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'favorite a post -> success',
      setUp: () {
        when(() => favRepo.addToFavorites(any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(id: 1, apiKey: '', username: ''));
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailFavoritesChanged(favorite: true)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: true,
            voteState: VoteState.upvoted,
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'favorite a post when anonymous -> nothing happen',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => false);
        when(() => favRepo.addToFavorites(any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get())
            .thenAnswer((invocation) async => Account.empty);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailFavoritesChanged(favorite: true)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: false,
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'favorite a post -> fail then revert state',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => false);
        when(() => favRepo.addToFavorites(any()))
            .thenAnswer((invocation) async => false);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(id: 1, apiKey: '', username: ''));
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailFavoritesChanged(favorite: true)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: true,
            voteState: VoteState.upvoted,
          ),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: false,
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'unfavorite a post -> success',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => favRepo.removeFromFavorites(any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(apiKey: '', username: '', id: 100));
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(post: Post.empty().copyWith(id: 1)),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) =>
          bloc.add(const PostDetailFavoritesChanged(favorite: false)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: false,
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'unfavorite a post -> fail then revert state',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => favRepo.removeFromFavorites(any()))
            .thenAnswer((invocation) async => false);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(id: 1, apiKey: '', username: ''));
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: true,
          ),
        ],
        idGenerator: () => 1,
        tagCache: {},
      ),
      act: (bloc) =>
          bloc.add(const PostDetailFavoritesChanged(favorite: false)),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: true,
          ),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: false,
          ),
        ),
        PostDetailState.initial().copyWith(
          currentIndex: 0,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(id: 1),
            isFavorited: true,
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'upvote',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(apiKey: '', username: '', id: 100));
        when(() => postVoteRepo.upvote(any()))
            .thenAnswer((invocation) async => PostVote.empty());
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailUpvoted()),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.upvoted,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 1,
              downScore: 0,
            ),
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'upvote failed -> restore state',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(apiKey: '', username: '', id: 100));
        when(() => postVoteRepo.upvote(any()))
            .thenAnswer((invocation) async => null);
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailUpvoted()),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.upvoted,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 1,
              downScore: 0,
            ),
          ),
        ),
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.unvote,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'downvote',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(apiKey: '', username: '', id: 100));
        when(() => postVoteRepo.downvote(any()))
            .thenAnswer((invocation) async => PostVote.empty());
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailDownvoted()),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.downvoted,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: -1,
            ),
          ),
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'downvote failed -> restore state',
      setUp: () {
        when(() => favRepo.checkIfFavoritedByUser(any(), any()))
            .thenAnswer((invocation) async => true);
        when(() => accountRepo.get()).thenAnswer((invocation) async =>
            const Account(apiKey: '', username: '', id: 100));
        when(() => postVoteRepo.downvote(any()))
            .thenAnswer((invocation) async => null);
        when(() => postVoteRepo.getPostVotes(any()))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(favRepo);
        reset(accountRepo);
        reset(postVoteRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc.add(const PostDetailDownvoted()),
      expect: () => [
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.downvoted,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: -1,
            ),
          ),
        ),
        PostDetailState.initial().copyWith(
          currentPost: PostData.empty().copyWith(
            voteState: VoteState.unvote,
            post: Post.empty().copyWith(
              id: 1,
              upScore: 0,
              downScore: 0,
            ),
          ),
        ),
      ],
    );
  });

  group('[post detail app logic tests]', () {
    blocTest<PostDetailBloc, PostDetailState>(
      'exit fullscreen mode will fetch recommends if it is empty',
      setUp: () {
        when(() => postRepo.getPosts(any(), any(), limit: any(named: 'limit')))
            .thenAnswer((invocation) async => []);
      },
      tearDown: () {
        reset(postRepo);
      },
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        defaultDetailsStyle: DetailsDisplay.imageFocus,
        posts: [
          PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              artistTags: ['foo'],
              characterTags: ['bar'],
            ),
          ),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) =>
          bloc.add(const PostDetailDisplayModeChanged(fullScreen: false)),
      expect: () => [
        PostDetailState.initial().copyWith(
          fullScreen: false,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              artistTags: ['foo'],
              characterTags: ['bar'],
            ),
          ),
        ),
        PostDetailState.initial().copyWith(
          fullScreen: false,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              artistTags: ['foo'],
              characterTags: ['bar'],
            ),
          ),
          recommends: [
            const Recommend(
              title: 'foo',
              posts: [],
              type: RecommendType.artist,
            ),
          ],
        ),
        PostDetailState.initial().copyWith(
          fullScreen: false,
          currentPost: PostData.empty().copyWith(
            post: Post.empty().copyWith(
              id: 1,
              artistTags: ['foo'],
              characterTags: ['bar'],
            ),
          ),
          recommends: [
            const Recommend(
              title: 'foo',
              posts: [],
              type: RecommendType.artist,
            ),
            const Recommend(
              title: 'bar',
              posts: [],
              type: RecommendType.character,
            ),
          ],
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'ignore overlay changed request if not in fullscreen mode',
      build: () => PostDetailBloc(
        initialIndex: 0,
        noteRepository: noteRepo,
        postRepository: postRepo,
        favoritePostRepository: favRepo,
        accountRepository: accountRepo,
        postVoteRepository: postVoteRepo,
        tags: [],
        posts: [
          PostData.empty(),
        ],
        idGenerator: () => 1,
        fireIndexChangedAtStart: false,
        tagCache: {},
      ),
      act: (bloc) => bloc
          .add(const PostDetailOverlayVisibilityChanged(enableOverlay: false)),
      expect: () => [],
    );
  });
}
