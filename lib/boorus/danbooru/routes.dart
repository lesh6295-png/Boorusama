// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:context_menus/context_menus.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/artist/artist.dart';
import 'package:boorusama/boorus/danbooru/application/authentication/authentication.dart';
import 'package:boorusama/boorus/danbooru/application/blacklisted_tags/blacklisted_tags.dart';
import 'package:boorusama/boorus/danbooru/application/downloads/bulk_image_download_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/downloads/bulk_post_download_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/favorites/favorites.dart';
import 'package:boorusama/boorus/danbooru/application/pool/pool.dart';
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/application/profile/profile.dart';
import 'package:boorusama/boorus/danbooru/application/saved_search/saved_search_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/saved_search/saved_search_feed_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/search/search.dart';
import 'package:boorusama/boorus/danbooru/application/search_history/search_history.dart';
import 'package:boorusama/boorus/danbooru/application/tag/tag.dart';
import 'package:boorusama/boorus/danbooru/application/user/current_user_bloc.dart';
import 'package:boorusama/boorus/danbooru/application/wiki/wiki_bloc.dart';
import 'package:boorusama/boorus/danbooru/domain/accounts/accounts.dart';
import 'package:boorusama/boorus/danbooru/domain/favorites/favorites.dart';
import 'package:boorusama/boorus/danbooru/domain/notes/notes.dart';
import 'package:boorusama/boorus/danbooru/domain/pools/pools.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/post_count_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/searches/search_history_repository.dart';
import 'package:boorusama/boorus/danbooru/domain/tags/tags.dart';
import 'package:boorusama/boorus/danbooru/infra/services/bulk_downloader.dart';
import 'package:boorusama/boorus/danbooru/ui/features/accounts/login/login_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/artists/artist_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/blacklisted_tags/blacklisted_tags_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/characters/character_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/downloads/bulk_download_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/favorites/favorite_group_details_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/favorites/favorite_groups_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/favorites/favorites_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/pool/pool_detail_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/post_detail/post_detail_page.dart';
import 'package:boorusama/boorus/danbooru/ui/features/settings/settings_page.dart';
import 'package:boorusama/boorus/danbooru/ui/shared/shared.dart';
import 'package:boorusama/core/application/api/api.dart';
import 'package:boorusama/core/application/app_rating.dart';
import 'package:boorusama/core/application/search/search.dart';
import 'package:boorusama/core/application/settings/settings.dart';
import 'package:boorusama/core/application/tags/tags.dart';
import 'package:boorusama/core/application/theme/theme.dart';
import 'package:boorusama/core/core.dart';
import 'package:boorusama/core/domain/autocompletes/autocompletes.dart';
import 'package:boorusama/core/domain/settings/settings.dart';
import 'package:boorusama/core/infra/services/tag_info_service.dart';
import 'package:boorusama/core/ui/widgets/conditional_parent_widget.dart';
import 'router.dart';
import 'ui/features/accounts/profile/profile_page.dart';
import 'ui/features/home/home_page.dart';
import 'ui/features/home/home_page_desktop.dart';
import 'ui/features/saved_search/saved_search_feed_page.dart';
import 'ui/features/saved_search/saved_search_page.dart';
import 'ui/features/search/search_page.dart';

final rootHandler = Handler(
  handlerFunc: (context, parameters) => ConditionalParentWidget(
    condition: canRate(),
    conditionalBuilder: (child) => createAppRatingWidget(child: child),
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyF,
          control: true,
        ): () => goToSearchPage(context!),
      },
      child: CustomContextMenuOverlay(
        child: Focus(
          autofocus: true,
          child:
              isMobilePlatform() ? const HomePage() : const HomePageDesktop(),
        ),
      ),
    ),
  ),
);

class CustomContextMenuOverlay extends StatelessWidget {
  const CustomContextMenuOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ContextMenuOverlay(
      cardBuilder: (context, children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(children: children),
        ),
      ),
      buttonBuilder: (context, config, [__]) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 200),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              hoverColor: Theme.of(context).colorScheme.primary,
              onTap: config.onPressed,
              title: Text(config.label),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              minVerticalPadding: 0,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

final artistHandler = Handler(handlerFunc: (
  context,
  Map<String, List<String>> params,
) {
  final args = context!.settings!.arguments as List;

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => PostBloc.of(context)
          ..add(PostRefreshed(
            tag: args.first,
            fetcher: SearchedPostFetcher.fromTags(args.first),
          )),
      ),
      BlocProvider.value(
        value: context.read<ArtistBloc>()..add(ArtistFetched(name: args.first)),
      ),
    ],
    child: CustomContextMenuOverlay(
      child: ArtistPage(
        artistName: args.first,
        backgroundImageUrl: args[1],
      ),
    ),
  );
});

final characterHandler = Handler(handlerFunc: (
  context,
  Map<String, List<String>> params,
) {
  final args = context!.settings!.arguments as List;

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => PostBloc.of(context)
          ..add(PostRefreshed(
            tag: args.first,
            fetcher: SearchedPostFetcher.fromTags(args.first),
          )),
      ),
      BlocProvider.value(
        value: context.read<WikiBloc>()..add(WikiFetched(tag: args.first)),
      ),
    ],
    child: CustomContextMenuOverlay(
      child: CharacterPage(
        characterName: args.first,
        backgroundImageUrl: args[1],
      ),
    ),
  );
});

final postDetailHandler = Handler(handlerFunc: (
  context,
  Map<String, List<String>> params,
) {
  final args = context!.settings!.arguments as List;
  final postDatas = args.first as List<PostData>;
  final index = args[1] as int;

  final AutoScrollController? controller = args[2];
  final PostBloc? postBloc = args[3];

  final tags = postDatas
      .map((e) => e.post)
      .map((p) => [
            ...p.artistTags.map((e) => PostDetailTag(
                  name: e,
                  category: TagCategory.artist.stringify(),
                  postId: p.id,
                )),
            ...p.characterTags.map((e) => PostDetailTag(
                  name: e,
                  category: TagCategory.charater.stringify(),
                  postId: p.id,
                )),
            ...p.copyrightTags.map((e) => PostDetailTag(
                  name: e,
                  category: TagCategory.copyright.stringify(),
                  postId: p.id,
                )),
            ...p.generalTags.map((e) => PostDetailTag(
                  name: e,
                  category: TagCategory.general.stringify(),
                  postId: p.id,
                )),
            ...p.metaTags.map((e) => PostDetailTag(
                  name: e,
                  category: TagCategory.meta.stringify(),
                  postId: p.id,
                )),
          ])
      .expand((e) => e)
      .toList();

  return BlocSelector<SettingsCubit, SettingsState, Settings>(
    selector: (state) => state.settings,
    builder: (context, settings) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SliverPostGridBloc()),
          BlocProvider.value(value: context.read<AuthenticationCubit>()),
          BlocProvider.value(value: context.read<ApiEndpointCubit>()),
          BlocProvider.value(value: context.read<ThemeBloc>()),
          BlocProvider(
            create: (context) => PostDetailBloc(
              noteRepository: context.read<NoteRepository>(),
              defaultDetailsStyle: settings.detailsDisplay,
              posts: postDatas,
              initialIndex: index,
              postRepository: context.read<PostRepository>(),
              favoritePostRepository: context.read<FavoritePostRepository>(),
              accountRepository: context.read<AccountRepository>(),
              postVoteRepository: context.read<PostVoteRepository>(),
              tags: tags,
              onPostChanged: (post) {
                if (postBloc != null && !postBloc.isClosed) {
                  postBloc.add(PostUpdated(post: post));
                }
              },
              tagCache: {},
            ),
          ),
        ],
        child: RepositoryProvider.value(
          value: context.read<TagRepository>(),
          child: Builder(
            builder: (context) =>
                BlocListener<SliverPostGridBloc, SliverPostGridState>(
              listenWhen: (previous, current) =>
                  previous.nextIndex != current.nextIndex,
              listener: (context, state) {
                if (controller == null) return;
                controller.scrollToIndex(
                  state.nextIndex,
                  duration: const Duration(milliseconds: 200),
                );
              },
              child: PostDetailPage(
                intitialIndex: index,
                posts: postDatas,
              ),
            ),
          ),
        ),
      );
    },
  );
});

final postSearchHandler = Handler(handlerFunc: (
  context,
  Map<String, List<String>> params,
) {
  final args = context!.settings!.arguments as List;

  return BlocBuilder<ApiEndpointCubit, ApiEndpointState>(
    builder: (context, state) {
      return BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final tagSearchBloc = TagSearchBloc(
            tagInfo: context.read<TagInfo>(),
            autocompleteRepository: context.read<AutocompleteRepository>(),
          );

          final postBloc = PostBloc.of(
            context,
            pagination: settingsState.settings.contentOrganizationCategory ==
                ContentOrganizationCategory.pagination,
          );
          final searchHistoryCubit = SearchHistoryBloc(
            searchHistoryRepository: context.read<SearchHistoryRepository>(),
          );
          final relatedTagBloc = RelatedTagBloc(
            relatedTagRepository: context.read<RelatedTagRepository>(),
          );
          final searchHistorySuggestions = SearchHistorySuggestionsBloc(
            searchHistoryRepository: context.read<SearchHistoryRepository>(),
          );

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: searchHistoryCubit),
              BlocProvider.value(
                value: context.read<FavoriteTagBloc>()
                  ..add(const FavoriteTagFetched()),
              ),
              BlocProvider.value(value: postBloc),
              BlocProvider.value(value: BlocProvider.of<ThemeBloc>(context)),
              BlocProvider.value(value: searchHistorySuggestions),
              BlocProvider(
                create: (context) => SearchBloc(
                  initial: DisplayState.options,
                  metatags: context.read<TagInfo>().metatags,
                  tagSearchBloc: tagSearchBloc,
                  searchHistoryBloc: searchHistoryCubit,
                  relatedTagBloc: relatedTagBloc,
                  searchHistorySuggestionsBloc: searchHistorySuggestions,
                  postBloc: postBloc,
                  postCountRepository: context.read<PostCountRepository>(),
                  initialQuery: args.first,
                  booruType: state.booru.booruType,
                ),
              ),
              BlocProvider.value(value: relatedTagBloc),
            ],
            child: CustomContextMenuOverlay(
              child: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  return SearchPage(
                    autoFocusSearchBar: state.settings.autoFocusSearchBar,
                    metatags: context.read<TagInfo>().metatags,
                    metatagHighlightColor:
                        Theme.of(context).colorScheme.primary,
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
});

final userHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  // final String userId = params["id"][0];

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: context!.read<ProfileCubit>()..getProfile()),
      BlocProvider.value(value: context.read<FavoritesCubit>()),
    ],
    child: const ProfilePage(),
  );
});

final loginHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: BlocProvider.of<AuthenticationCubit>(context!)),
    ],
    child: const LoginPage(),
  );
});

final settingsHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return const SettingsPage();
});

final poolDetailHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  final args = context!.settings!.arguments as List;
  final pool = args.first as Pool;

  return BlocBuilder<ApiEndpointCubit, ApiEndpointState>(
    builder: (context, state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: PoolDescriptionBloc(
              endpoint: state.booru.url,
              poolDescriptionRepository:
                  context.read<PoolDescriptionRepository>(),
            )..add(PoolDescriptionFetched(poolId: pool.id)),
          ),
          BlocProvider(
            create: (context) => PostBloc.of(context)
              ..add(
                PostRefreshed(
                  fetcher: PoolPostFetcher(
                    postIds: pool.postIds.reversed.take(20).toList(),
                  ),
                ),
              ),
          ),
        ],
        child: CustomContextMenuOverlay(
          child: PoolDetailPage(
            pool: pool,
            // https://github.com/dart-code-checker/dart-code-metrics/issues/1046
            // ignore: prefer-iterable-of
            postIds: QueueList.from(pool.postIds.reversed.skip(20)),
          ),
        ),
      );
    },
  );
});

final favoritesHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  final args = context!.settings!.arguments as List;
  final String username = args.first;

  return BlocBuilder<ApiEndpointCubit, ApiEndpointState>(
    builder: (context, state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => PostBloc.of(context)
              ..add(PostRefreshed(
                tag: 'ordfav:$username',
                fetcher: SearchedPostFetcher.fromTags(
                  'ordfav:$username',
                ),
              )),
          ),
        ],
        child: CustomContextMenuOverlay(
          child: FavoritesPage(
            username: username,
          ),
        ),
      );
    },
  );
});

final favoriteGroupsHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return BlocBuilder<CurrentUserBloc, CurrentUserState>(
    builder: (context, state) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FavoriteGroupsBloc.of(
              context,
              currentUser: state.user,
            )..add(const FavoriteGroupsRefreshed(includePreviews: true)),
          ),
        ],
        child: const FavoriteGroupsPage(),
      );
    },
  );
});

final favoriteGroupDetailsHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  final args = context!.settings!.arguments as List;

  final FavoriteGroup group = args.first;
  final FavoriteGroupsBloc bloc = args[1];

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => PostBloc.of(context)
          ..add(PostRefreshed(
            fetcher:
                FavoriteGroupPostFetcher(ids: group.postIds.take(60).toList()),
          )),
      ),
      BlocProvider.value(value: bloc),
    ],
    child: CustomContextMenuOverlay(
      child: FavoriteGroupDetailsPage(
        group: group,
        postIds: QueueList.from(group.postIds.skip(60)),
      ),
    ),
  );
});

final blacklistedTagsHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(
        value: BlocProvider.of<BlacklistedTagsBloc>(context!)
          ..add(const BlacklistedTagRequested()),
      ),
    ],
    child: const BlacklistedTagsPage(),
  );
});

final bulkDownloadHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  final args = context!.settings!.arguments as List;
  final List<String>? initialSelectedTags = args.isNotEmpty ? args.first : null;

  final bulkPostDownloadBloc = BulkPostDownloadBloc(
    downloader: context.read<BulkDownloader<Post>>(),
    postCountRepository: context.read<PostCountRepository>(),
    postRepository: context.read<PostRepository>(),
    errorTranslator: getErrorMessage,
    onDownloadDone: (path) => MediaScanner.loadMedia(path: path),
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => BulkImageDownloadBloc(
          permissionChecker: () => Permission.storage.status,
          permissionRequester: () => Permission.storage.request(),
          bulkPostDownloadBloc: bulkPostDownloadBloc,
        )..add(BulkImageDownloadTagsAdded(tags: initialSelectedTags)),
      ),
    ],
    child: const BulkDownloadPage(),
  );
});

final savedSearchHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => PostBloc.of(context),
      ),
      BlocProvider(
        create: (context) => SavedSearchFeedBloc(
          savedSearchBloc: context.read<SavedSearchBloc>(),
        )..add(const SavedSearchFeedRefreshed()),
      ),
    ],
    child: const CustomContextMenuOverlay(child: SavedSearchFeedPage()),
  );
});

final savedSearchEditHandler =
    Handler(handlerFunc: (context, Map<String, List<String>> params) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(
        value: context!.read<SavedSearchBloc>()
          ..add(const SavedSearchFetched()),
      ),
    ],
    child: const SavedSearchPage(),
  );
});
