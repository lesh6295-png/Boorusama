// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/application/wiki/wiki_bloc.dart';
import 'package:boorusama/boorus/danbooru/ui/shared/tag_detail_page_desktop.dart';
import 'package:boorusama/boorus/danbooru/ui/shared/tag_other_names.dart';

class CharacterPageDesktop extends StatelessWidget {
  const CharacterPageDesktop({
    super.key,
    required this.characterName,
  });

  final String characterName;

  @override
  Widget build(BuildContext context) {
    return TagDetailPageDesktop(
      tagName: characterName,
      otherNamesBuilder: (context) => BlocBuilder<WikiBloc, WikiState>(
        builder: (context, state) {
          switch (state.status) {
            case LoadStatus.initial:
            case LoadStatus.loading:
              return const SizedBox(height: 40, width: 40);
            case LoadStatus.success:
              return state.wiki != null
                  ? TagOtherNames(otherNames: state.wiki!.otherNames)
                  : const SizedBox.shrink();
            case LoadStatus.failure:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
