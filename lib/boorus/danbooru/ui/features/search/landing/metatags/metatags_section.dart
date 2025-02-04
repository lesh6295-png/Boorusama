// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/search/search.dart';
import 'package:boorusama/boorus/danbooru/infra/local/repositories/metatags/user_metatag_repository.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/core/core.dart';
import 'package:boorusama/core/domain/tags/metatag.dart';
import 'package:boorusama/main.dart';
import '../common/option_tags_arena.dart';

class MetatagsSection extends StatefulWidget {
  const MetatagsSection({
    super.key,
    required this.onOptionTap,
  });

  final ValueChanged<String>? onOptionTap;

  @override
  State<MetatagsSection> createState() => _MetatagsSectionState();
}

class _MetatagsSectionState extends State<MetatagsSection> {
  @override
  Widget build(BuildContext context) {
    final metatags = context.select((SearchBloc bloc) => bloc.state.metatags);

    return OptionTagsArena(
      title: 'Metatags',
      titleTrailing: (editMode) => IconButton(
        onPressed: () {
          launchExternalUrl(
            Uri.parse(cheatsheetUrl),
            mode: LaunchMode.platformDefault,
          );
        },
        icon: const FaIcon(
          FontAwesomeIcons.circleQuestion,
          size: 18,
        ),
      ),
      childrenBuilder: (editMode) =>
          _buildMetatags(context, editMode, metatags),
    );
  }

  List<Widget> _buildMetatags(
    BuildContext context,
    bool editMode,
    List<Metatag> metatags,
  ) {
    return [
      ...context.read<UserMetatagRepository>().getAll().map((tag) => RawChip(
            label: Text(tag),
            onPressed: editMode ? null : () => widget.onOptionTap?.call(tag),
            deleteIcon: const Icon(
              Icons.close,
              size: 18,
            ),
            onDeleted: editMode
                ? () async {
                    await context.read<UserMetatagRepository>().delete(tag);
                    setState(() => {});
                  }
                : null,
          )),
      if (editMode)
        IconButton(
          iconSize: 28,
          splashRadius: 20,
          onPressed: () => goToMetatagsPage(
            context,
            metatags: metatags,
            onSelected: (tag) => setState(() {
              Navigator.of(context).pop();
              context.read<UserMetatagRepository>().put(tag.name);
            }),
          ),
          icon: const Icon(Icons.add),
        ),
    ];
  }
}
