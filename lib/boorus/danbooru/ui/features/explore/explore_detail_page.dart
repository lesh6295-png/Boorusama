// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' hide LoadStatus;
import 'package:scroll_to_index/scroll_to_index.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/explore/explore.dart';
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';
import 'package:boorusama/boorus/danbooru/ui/shared/infinite_post_list.dart';
import 'datetime_selector.dart';
import 'time_scale_toggle_switch.dart';

class ExploreDetailPage extends StatelessWidget {
  const ExploreDetailPage({
    super.key,
    required this.title,
    required this.category,
  });

  final Widget title;
  final ExploreCategory category;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExploreDetailBloc>().state;

    return _ExploreDetail(
      // title: title,
      builder: (context, refreshController, scrollController) {
        return Column(
          children: [
            Expanded(
              child: InfinitePostList(
                refreshController: refreshController,
                scrollController: scrollController,
                onLoadMore: () => context.read<PostBloc>().add(PostFetched(
                      tags: '',
                      fetcher: categoryToFetcher(
                        category,
                        state.date,
                        state.scale,
                        context,
                      ),
                    )),
                onRefresh: (_) => context.read<PostBloc>().add(
                      PostRefreshed(
                        fetcher: categoryToFetcher(
                          category,
                          state.date,
                          state.scale,
                          context,
                        ),
                      ),
                    ),
                sliverHeaderBuilder: (context) => [
                  SliverAppBar(
                    title: title,
                    floating: true,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  ...categoryToListHeader(
                    context,
                    category,
                    state.date,
                    state.scale,
                  ).map((header) => SliverToBoxAdapter(child: header)),
                ],
              ),
            ),
            if (category != ExploreCategory.hot)
              Container(
                color:
                    Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                child: DateTimeSelector(
                  onDateChanged: (date) => context
                      .read<ExploreDetailBloc>()
                      .add(ExploreDetailDateChanged(date)),
                  date: state.date,
                  scale: state.scale,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ExploreDetail extends StatefulWidget {
  const _ExploreDetail({
    // required this.title,
    required this.builder,
  });

  // final Widget title;
  final Widget Function(
    BuildContext context,
    RefreshController refreshController,
    AutoScrollController scrollController,
  ) builder;

  @override
  State<_ExploreDetail> createState() => _ExploreDetailState();
}

class _ExploreDetailState extends State<_ExploreDetail> {
  final RefreshController _refreshController = RefreshController();
  final AutoScrollController _scrollController = AutoScrollController();

  @override
  void dispose() {
    _refreshController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExploreDetailBloc, ExploreDetailState>(
      listener: (context, state) {
        _scrollController.jumpTo(0);
        _refreshController.requestRefresh();
      },
      child: widget.builder(
        context,
        _refreshController,
        _scrollController,
      ),
    );
  }
}

PostFetcher categoryToFetcher(
  ExploreCategory category,
  DateTime date,
  TimeScale scale,
  BuildContext context,
) {
  switch (category) {
    case ExploreCategory.popular:
      return PopularPostFetcher(
        date: date,
        scale: scale,
        exploreRepository: context.read<ExploreRepository>(),
      );
    case ExploreCategory.mostViewed:
      return MostViewedPostFetcher(
        date: date,
        exploreRepository: context.read<ExploreRepository>(),
      );
    case ExploreCategory.hot:
      return HotPostFetcher(
        exploreRepository: context.read<ExploreRepository>(),
      );
  }
}

List<Widget> categoryToListHeader(
  BuildContext context,
  ExploreCategory category,
  DateTime date,
  TimeScale scale,
) {
  switch (category) {
    case ExploreCategory.popular:
      return [
        TimeScaleToggleSwitch(
          onToggle: (scale) => {
            context
                .read<ExploreDetailBloc>()
                .add(ExploreDetailTimeScaleChanged(scale)),
          },
        ),
        const SizedBox(height: 20),
      ];
    case ExploreCategory.mostViewed:
    case ExploreCategory.hot:
      return [];
  }
}
