// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/application/favorites/favorites.dart';
import 'package:boorusama/boorus/danbooru/application/pool/pool.dart';
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/application/recommended/recommended.dart';
import 'package:boorusama/boorus/danbooru/application/settings/settings.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/domain/settings/settings.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/core/core.dart';
import 'package:boorusama/core/presentation/widgets/conditional_parent_widget.dart';
import 'package:boorusama/core/presentation/widgets/shadow_gradient_overlay.dart';
import 'package:boorusama/main.dart';
import 'parent_child_post_page.dart';
import 'post_detail.dart';
import 'widgets/information_section.dart';
import 'widgets/pool_tiles.dart';
import 'widgets/post_action_toolbar.dart';
import 'widgets/post_video.dart';

// Flutter imports:
// import 'package:boorusama/core/presentation/download_provider_widget.dart';
// import 'package:boorusama/core/presentation/widgets/animated_spinning_icon.dart';


// import 'post_image_page.dart';

String _getPostParentChildTextDescription(Post post) {
  if (post.hasParent) return 'This post belongs to a parent and has siblings';
  return 'This post has children';
}

class PostDetailPageExperimental extends StatefulWidget {
  const PostDetailPageExperimental({
    Key? key,
    required this.initialIndex,
    required this.posts,
    required this.onPageChanged,
  }) : super(key: key);

  final int initialIndex;
  final List<Post> posts;
  final void Function(int index) onPageChanged;

  @override
  State<PostDetailPageExperimental> createState() => _DetailPageState();
}

class _DetailPageState extends State<PostDetailPageExperimental>
    with TickerProviderStateMixin {
  late final AnimationController _colorAnimationController;
  late Animation _colorTween;

  final scrollController = ScrollController(initialScrollOffset: 0.1);

  var offset = Offset.zero;
  var inDrag = ValueNotifier(false);
  var inDragUp = false;

  var inDetailMode = ValueNotifier(false);

  final imagePath = ValueNotifier<String?>(null);

  late final currentIndex = ValueNotifier<int>(widget.initialIndex);

  final showSlideShowConfig = ValueNotifier(false);
  // late final AnimationController _spinningIconAnimationController;
  // late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _colorTween = ColorTween(begin: Colors.black, end: Colors.transparent)
        .animate(_colorAnimationController);

    // _spinningIconAnimationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(milliseconds: 200),
    // );
    // _rotateAnimation = Tween<double>(begin: 0, end: 360)
    //     .animate(_spinningIconAnimationController);

    scrollController.addListener(() {
      if (scrollController.hasClients) {
        if (inDetailMode.value) {
          if (scrollController.position.maxScrollExtent > 0) {
            if (scrollController.offset == 0) {
              inDetailMode.value = false;
            }
          } else {
            //TODO: if the screen is unscrollable, can't exit from detail mode
          }
        }
      }
    });

    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () {
        _colorAnimationController.forward();
        return Future.value(true);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _colorAnimationController,
            builder: (context, child) =>
                Positioned.fill(child: Container(color: _colorTween.value)),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: size.width,
            child: CarouselSlider.builder(
              itemCount: widget.posts.length,
              itemBuilder: (context, index, rIndex) => GestureDetector(
                onPanUpdate: (details) {
                  if (details.delta.dy > 0.2 && details.delta.dx == 0.0) {
                    inDrag.value = true;
                    inDragUp = false;
                  }

                  if (details.delta.dy < 0.2 && details.delta.dx == 0) {
                    inDragUp = true;
                    inDrag.value = false;
                  }

                  if (inDrag.value) {
                    _colorAnimationController
                        .animateTo(details.localPosition.dy / 1000);
                    setState(() {
                      offset = Offset(
                        offset.dx + details.delta.dx,
                        offset.dy + details.delta.dy,
                      );
                    });
                  }

                  if (inDragUp) {
                    setState(() {
                      offset = Offset(
                        offset.dx,
                        offset.dy + details.delta.dy,
                      );
                    });
                  }
                },
                onPanEnd: (details) {
                  if (inDrag.value) {
                    inDrag.value = false;
                    Navigator.of(context).pop();
                    return;
                  }

                  if (inDragUp) {
                    if (offset.dy < -20) {
                      inDetailMode.value = true;
                      _refreshData(context, index);
                      setState(() {
                        offset = Offset.zero;
                      });
                    }
                    inDragUp = false;
                  }
                },
                child: ValueListenableBuilder<bool>(
                    valueListenable: inDetailMode,
                    builder: (context, value, _) {
                      final post = widget.posts[index];
                      final heroTag = ValueKey(post.normalImageUrl);

                      if (value) {
                        return AnnotatedRegion<SystemUiOverlayStyle>(
                          value: const SystemUiOverlayStyle(
                              statusBarColor: Colors.transparent),
                          child: BlocBuilder<SettingsCubit, SettingsState>(
                            buildWhen: (previous, current) =>
                                previous.settings.actionBarDisplayBehavior !=
                                current.settings.actionBarDisplayBehavior,
                            builder: (context, state) {
                              return Scaffold(
                                backgroundColor: Colors.transparent,
                                body: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    CustomScrollView(
                                      controller: scrollController,
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: Hero(
                                            tag: heroTag,
                                            child: _buildPostWidget(
                                                post: post, heroTag: heroTag),
                                          ),
                                        ),
                                        const PoolTiles(),
                                        _buildPostInformation(
                                          state,
                                          imagePath,
                                          post,
                                          context,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return Scaffold(
                          backgroundColor: Colors.transparent,
                          body: SafeArea(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Hero(
                                    tag: ValueKey(
                                        widget.posts[index].normalImageUrl),
                                    child: _buildPostWidget(
                                      post: post,
                                      heroTag: heroTag,
                                      hasTapImage: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),
              ),
              options: CarouselOptions(
                enableInfiniteScroll: false,
                initialPage: widget.initialIndex,
                height: size.height,
                onPageChanged: (index, _) {
                  _refreshData(context, index);
                  currentIndex.value = index;
                  widget.onPageChanged(index);
                },
                viewportFraction: 1,
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: inDetailMode,
              builder: (context, inDetail, child) {
                if (!inDetail) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: inDrag,
                    builder: (context, drag, child) =>
                        drag ? const SizedBox.shrink() : child!,
                    child: ValueListenableBuilder<int>(
                      valueListenable: currentIndex,
                      builder: (context, index, child) => Positioned(
                        bottom: widget.posts[index].isAnimated ? 65 : 1,
                        left: widget.posts[index].isAnimated ? 10 : null,
                        child: Material(
                          elevation: 12,
                          color: Theme.of(context).cardColor.withOpacity(0.7),
                          type: MaterialType.card,
                          child: widget.posts[index].isAnimated
                              ? _buildActionBar(
                                  imagePath,
                                  widget.posts[index],
                                  axis: Axis.vertical,
                                )
                              : SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: _buildActionBar(
                                    imagePath,
                                    widget.posts[index],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              }),
          ShadowGradientOverlay(
            alignment: Alignment.topCenter,
            colors: <Color>[
              const Color(0x5D000000),
              Colors.black12.withOpacity(0)
            ],
          ),
          _buildBackButton(),
          // ValueListenableBuilder<int>(
          //   valueListenable: currentIndex,
          //   builder: (context, index, child) => _buildSlideShowButton(
          //     widget.posts[index],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget _buildSlideShowButton(Post post) {
  //   return Align(
  //     alignment: const Alignment(0.9, -0.96),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: ValueListenableBuilder<bool>(
  //         valueListenable: showSlideShowConfig,
  //         builder: (context, slideshow, child) => ButtonBar(
  //           children: [
  //             if (slideshow)
  //               AnimatedSpinningIcon(
  //                 icon: const Icon(Icons.sync),
  //                 animation: _rotateAnimation,
  //                 onPressed: () => showSlideShowConfig.value = false,
  //               )
  //             else
  //               IconButton(
  //                 icon: const Icon(Icons.slideshow),
  //                 onPressed: () => showSlideShowConfig.value = true,
  //               ),
  //             DownloadProviderWidget(
  //               builder: (context, download) => PopupMenuButton<PostAction>(
  //                 onSelected: (value) async {
  //                   switch (value) {
  //                     case PostAction.download:
  //                       download(post);
  //                       break;
  //                     default:
  //                   }
  //                 },
  //                 itemBuilder: (BuildContext context) =>
  //                     <PopupMenuEntry<PostAction>>[
  //                   const PopupMenuItem<PostAction>(
  //                     value: PostAction.download,
  //                     child: ListTile(
  //                       leading: Icon(Icons.download_rounded),
  //                       title: Text('Download'),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPostWidget({
    required Post post,
    required Key heroTag,
    bool hasTapImage = true,
  }) {
    Widget postWidget;
    if (post.isVideo) {
      if (p.extension(post.normalImageUrl) == '.webm') {
        final String videoHtml =
            '''
            <center>
              <video controls allowfulscreen width="100%" height="100%" controlsList="nodownload" style="background-color:black;vertical-align: middle;display: inline-block;" autoplay muted loop>
                <source src=${post.normalImageUrl}#t=0.01 type="video/webm" />
              </video>
            </center>''';
        postWidget = Container(
          color: Colors.black,
          height: MediaQuery.of(context).size.height,
          child: WebView(
            backgroundColor: Colors.black,
            allowsInlineMediaPlayback: true,
            initialUrl: 'about:blank',
            onWebViewCreated: (controller) {
              controller.loadUrl(Uri.dataFromString(videoHtml,
                      mimeType: 'text/html',
                      encoding: Encoding.getByName('utf-8'))
                  .toString());
            },
          ),
        );
      } else {
        postWidget = PostVideo(post: post);
      }
    } else {
      postWidget = ConditionalParentWidget(
        condition: hasTapImage,
        conditionalBuilder: (child) => GestureDetector(
          onTap: () {
            AppRouter.router.navigateTo(context, '/posts/image',
                routeSettings: RouteSettings(arguments: [post]));
          },
          child: child,
        ),
        child: _PostDetailImage(
          post: post,
          onLoaded: (path) {
            if (!mounted) return;
            imagePath.value = path;
          },
        ),
      );
    }

    return postWidget;
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 30,
      left: 10,
      child: Material(
        color: Colors.transparent,
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                _colorAnimationController.forward();

                AppRouter.router.pop(context);
              },
            )),
      ),
    );
  }

  void _refreshData(BuildContext context, int index) {
    context
        .read<RecommendedArtistPostCubit>()
        .add(RecommendedPostRequested(tags: widget.posts[index].artistTags));
    context
        .read<RecommendedCharacterPostCubit>()
        .add(RecommendedPostRequested(tags: widget.posts[index].characterTags));
    context
        .read<PoolFromPostIdBloc>()
        .add(PoolFromPostIdRequested(postId: widget.posts[index].id));
    ReadContext(context)
        .read<IsPostFavoritedBloc>()
        .add(IsPostFavoritedRequested(postId: widget.posts[index].id));
  }

  Widget _buildPostInformation(
    SettingsState state,
    ValueNotifier<String?> imagePath,
    Post post,
    BuildContext context,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InformationSection(post: post),
          if (state.settings.actionBarDisplayBehavior ==
              ActionBarDisplayBehavior.scrolling)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildActionBar(imagePath, post),
            ),
          if (post.hasChildren || post.hasParent) ...[
            const _Divider(),
            _buildParentChildTile(context, post),
            const _Divider(),
          ],
          if (!post.hasChildren && !post.hasParent)
            const Divider(height: 8, thickness: 1),
          _buildRecommendedArtistList(post),
          _buildRecommendedCharacterList(post),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    ValueNotifier<String?> imagePath,
    Post post, {
    Axis axis = Axis.horizontal,
  }) {
    return ValueListenableBuilder<String?>(
      valueListenable: imagePath,
      builder: (context, value, child) => PostActionToolbar(
        post: post,
        imagePath: value,
        axis: axis,
      ),
    );
  }
}

class _PostDetailImage extends StatelessWidget {
  const _PostDetailImage({
    Key? key,
    required this.post,
    required this.onLoaded,
  }) : super(key: key);

  final Post post;
  final void Function(String filePath) onLoaded;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: post.normalImageUrl,
      imageBuilder: (context, imageProvider) {
        DefaultCacheManager()
            .getFileFromCache(post.normalImageUrl)
            .then((file) {
          onLoaded(file!.file.path);
        });
        return Image(image: imageProvider);
      },
      placeholderFadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      progressIndicatorBuilder: (context, url, progress) => FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          height: post.height,
          width: post.width,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(value: progress.progress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildParentChildTile(
  BuildContext context,
  Post post,
) {
  return ListTile(
    dense: true,
    tileColor: Theme.of(context).cardColor,
    title: Text(_getPostParentChildTextDescription(post)),
    trailing: Padding(
      padding: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: () => showBarModalBottomSheet(
          context: context,
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => PostBloc(
                  postRepository: context.read<IPostRepository>(),
                  blacklistedTagsRepository:
                      context.read<BlacklistedTagsRepository>(),
                )..add(PostRefreshed(
                    tag: post.hasParent
                        ? 'parent:${post.parentId}'
                        : 'parent:${post.id}')),
              )
            ],
            child: ParentChildPostPage(
                parentPostId: post.hasParent ? post.parentId! : post.id),
          ),
        ),
        child: const Text(
          'View',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
}

Widget _buildRecommendPostSection(
  BuildContext context,
  Post post,
  Recommended item,
) {
  return BlocBuilder<SettingsCubit, SettingsState>(
    builder: (context, state) {
      return RecommendPostSection(
        imageQuality: state.settings.imageQuality,
        header: ListTile(
          onTap: () => AppRouter.router.navigateTo(
            context,
            '/artist',
            routeSettings: RouteSettings(
              arguments: [
                item.rawTitle,
                post.normalImageUrl,
              ],
            ),
          ),
          title: Text(item.title),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        posts: item.posts,
      );
    },
  );
}

Widget _buildRecommendedArtistList(Post post) {
  if (post.artistTags.isEmpty) return const SizedBox.shrink();
  return BlocBuilder<RecommendedArtistPostCubit,
      AsyncLoadState<List<Recommended>>>(
    builder: (context, state) {
      if (state.status == LoadStatus.success) {
        final recommendedItems = state.data!;
        return Column(
          children: recommendedItems
              .map((item) => _buildRecommendPostSection(context, post, item))
              .toList(),
        );
      } else {
        final artists = post.artistTags;
        return Column(
          children: [
            ...List.generate(
              artists.length,
              (index) => RecommendPostSectionPlaceHolder(
                header: ListTile(
                  title: Text(artists[index].removeUnderscoreWithSpace()),
                  trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                ),
              ),
            )
          ],
        );
      }
    },
  );
}

Widget _buildRecommendedCharacterList(Post post) {
  if (post.characterTags.isEmpty) return const SizedBox.shrink();
  return BlocBuilder<RecommendedCharacterPostCubit,
      AsyncLoadState<List<Recommended>>>(
    builder: (context, state) {
      if (state.status == LoadStatus.success) {
        final recommendedItems = state.data!;
        return Column(
          children: recommendedItems
              .map((item) => _buildRecommendPostSection(context, post, item))
              .toList(),
        );
      } else {
        final characters = post.characterTags;
        return Column(
          children: [
            ...List.generate(
              characters.length,
              (index) => RecommendPostSectionPlaceHolder(
                header: ListTile(
                  title: Text(characters[index].removeUnderscoreWithSpace()),
                  trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                ),
              ),
            )
          ],
        );
      }
    },
  );
}

class _Divider extends StatelessWidget {
  const _Divider({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).hintColor,
      height: 1,
    );
  }
}
