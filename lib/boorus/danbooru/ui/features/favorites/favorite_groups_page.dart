import 'package:boorusama/boorus/danbooru/application/favorites/favorites.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteGroupsPage extends StatelessWidget {
  const FavoriteGroupsPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          BlocBuilder<FavoriteGroupsBloc, FavoriteGroupsState>(
            builder: (context, state) {
              return SliverList(
                  delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = state.favoriteGroups[index];
                  return ListTile(
                    title: Text(group.name),
                    subtitle: Text(group.creator.name),
                  );
                },
                childCount: state.favoriteGroups.length,
              ));
            },
          )
        ],
      )),
    );
  }
}
