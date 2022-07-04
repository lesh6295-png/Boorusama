// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/core/application/accounts/current_account_bloc.dart';
import 'package:boorusama/core/utils.dart';
import 'package:boorusama/main.dart';

class SideBarMenu extends StatelessWidget {
  const SideBarMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: BlocBuilder<CurrentAccountBloc, CurrentAccountState>(
                  builder: (context, state) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.account_box),
                            title: const Text('Account'),
                            onTap: () {
                              Navigator.of(context).pop();
                              AppRouter.router.navigateTo(context, '/account');
                            },
                          ),
                          if (state.account != null) ...[
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: Text('sideMenu.profile'.tr()),
                              onTap: () {
                                Navigator.of(context).pop();
                                AppRouter.router
                                    .navigateTo(context, '/users/profile');
                              },
                            ),
                            ListTile(
                              leading:
                                  const FaIcon(FontAwesomeIcons.solidHeart),
                              title: Text('profile.favorites'.tr()),
                              onTap: () {
                                Navigator.of(context).pop();
                                AppRouter.router.navigateTo(
                                    context, '/favorites',
                                    routeSettings: RouteSettings(
                                        arguments: [state.account!.name]));
                              },
                            ),
                            ListTile(
                              leading: const FaIcon(FontAwesomeIcons.ban),
                              title: const Text('Blacklisted tags'),
                              onTap: () {
                                Navigator.of(context).pop();
                                AppRouter.router.navigateTo(
                                    context, '/users/blacklisted_tags',
                                    routeSettings: RouteSettings(
                                        arguments: [state.userId]));
                              },
                            ),
                          ],
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: Text('sideMenu.settings'.tr()),
                            onTap: () {
                              Navigator.of(context).pop();
                              AppRouter.router.navigateTo(context, '/settings');
                            },
                          ),
                        ]);
                  },
                ),
              ),
            ),
            const Divider(
              height: 4,
              indent: 8,
              endIndent: 8,
              thickness: 2,
            ),
            SizedBox(
              height: 50,
              child: ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => launchExternalUrl(
                      Uri.parse(
                          context.read<AppInfoProvider>().appInfo.githubUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.githubSquare),
                  ),
                  IconButton(
                    onPressed: () => launchExternalUrl(
                      Uri.parse(
                          context.read<AppInfoProvider>().appInfo.discordUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const FaIcon(FontAwesomeIcons.discord),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
