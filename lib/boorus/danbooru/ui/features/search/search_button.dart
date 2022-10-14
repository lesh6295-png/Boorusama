// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/post/post.dart';
import 'package:boorusama/boorus/danbooru/application/search/search.dart';
import 'package:boorusama/boorus/danbooru/application/search_history/search_history.dart';
import 'package:boorusama/boorus/danbooru/application/tag/tag.dart';
import 'package:boorusama/core/ui/widgets/conditional_render_widget.dart';

class SearchButton extends StatelessWidget {
  const SearchButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      buildWhen: (previous, current) =>
          previous.allowSearch != current.allowSearch,
      builder: (context, state) {
        return ConditionalRenderWidget(
          condition: state.allowSearch,
          childBuilder: (context) => BlocBuilder<TagSearchBloc, TagSearchState>(
            builder: (context, state) => FloatingActionButton(
              onPressed: () => _onPress(context, state.selectedTags),
              heroTag: null,
              child: const Icon(Icons.search),
            ),
          ),
        );
      },
    );
  }

  void _onPress(BuildContext context, List<TagSearchItem> selectedTags) {
    final tags = selectedTags.map((e) => e.toString()).join(' ');
    context.read<SearchBloc>().add(const SearchRequested());
    context.read<PostBloc>().add(PostRefreshed(
          tag: tags,
          fetcher: SearchedPostFetcher.fromTags(tags),
        ));
    context.read<SearchHistoryCubit>().addHistory(tags);
  }
}

// bool _shouldShowSearchButton(
//   DisplayState displayState,
//   List<TagSearchItem> selectedTags,
// ) {
//   if (displayState == DisplayState.options) {
//     if (selectedTags.isEmpty) {
//       return false;
//     } else {
//       return true;
//     }
//   }
//   if (displayState == DisplayState.suggestion) return false;
//   return false;
// }
