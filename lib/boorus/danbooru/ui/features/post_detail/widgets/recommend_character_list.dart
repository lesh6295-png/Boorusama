import 'package:boorusama/boorus/danbooru/application/post/post_detail_bloc.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/core/core.dart';
import 'package:flutter/material.dart';

import 'recommend_section.dart';

class RecommendCharacterList extends StatelessWidget {
  const RecommendCharacterList({
    Key? key,
    required this.recommends,
    this.useSeperator = false,
  }) : super(key: key);

  final bool useSeperator;
  final List<Recommend> recommends;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...recommends.map(
          (r) => RecommendPostSection(
            header: ListTile(
              onTap: () => AppRouter.router.navigateTo(
                context,
                '/character',
                routeSettings: RouteSettings(
                  arguments: [
                    r.title,
                    '',
                  ],
                ),
              ),
              title: Text(r.title.removeUnderscoreWithSpace()),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
            ),
            posts: r.posts,
            onTap: (index) => goToDetailPage(
              context: context,
              posts: r.posts,
              initialIndex: index,
            ),
          ),
        ),
      ],
    );
  }
}
