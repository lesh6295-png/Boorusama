// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Project imports:
import 'package:boorusama/app_constants.dart';
import 'package:boorusama/boorus/danbooru/application/settings/settings.dart';
import 'package:boorusama/boorus/danbooru/presentation/features/settings/appearance_page.dart';
import 'package:boorusama/boorus/danbooru/presentation/features/settings/language_page.dart';
import 'package:boorusama/boorus/danbooru/presentation/features/settings/privacy_page.dart';
import 'package:boorusama/core/presentation/widgets/parallax_slide_in_page_route.dart';
import 'package:boorusama/main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.settings'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final settings = state.settings;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSection(
                    label: 'settings.app_settings'.tr(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('settings.safe_mode').tr(),
                    trailing: Switch(
                        activeColor: Theme.of(context).colorScheme.primary,
                        value: settings.safeMode,
                        onChanged: (value) {
                          context
                              .read<SettingsCubit>()
                              .update(settings.copyWith(safeMode: value));
                        }),
                  ),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.paintRoller),
                    title: const Text('settings.appearance').tr(),
                    onTap: () =>
                        Navigator.of(context).push(ParallaxSlideInPageRoute(
                      enterWidget: const AppearancePage(),
                      oldWidget: this,
                    )),
                  ),
                  ListTile(
                    title: const Text('settings.language.language').tr(),
                    leading: const Icon(Icons.translate),
                    onTap: () =>
                        Navigator.of(context).push(ParallaxSlideInPageRoute(
                      enterWidget: const LanguagePage(),
                      oldWidget: this,
                    )),
                  ),
                  //TODO: Files downloaded in custom location won't show up in gallery app. Re-enable this feature when a better download support for Flutter landed.
                  // ListTile(
                  //   title: const Text('Download'),
                  //   leading: const FaIcon(FontAwesomeIcons.download),
                  //   onTap: () =>
                  //       Navigator.of(context).push(ParallaxSlideInPageRoute(
                  //     enterWidget: const DownloadPage(),
                  //     oldWidget: this,
                  //   )),
                  // ),
                  ListTile(
                    title: const Text('settings.privacy.privacy').tr(),
                    leading: const FaIcon(FontAwesomeIcons.shieldHalved),
                    onTap: () =>
                        Navigator.of(context).push(ParallaxSlideInPageRoute(
                      enterWidget: const PrivacyPage(),
                      oldWidget: this,
                    )),
                  ),
                  ListTile(
                    title: const Text('settings.information').tr(),
                    leading: const Icon(Icons.info),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationIcon: Image.asset(
                        'assets/icon/icon-512x512.png',
                        width: 64,
                        height: 64,
                      ),
                      applicationVersion: getVersion(
                          RepositoryProvider.of<PackageInfoProvider>(context)
                              .getPackageInfo()),
                      applicationLegalese: '\u{a9} 2020-2022 Nguyen Duc Khoa',
                      applicationName: AppConstants.appName,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    Key? key,
    required this.label,
  }) : super(key: key);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: Theme.of(context).hintColor),
      ),
    );
  }
}

String getVersion(PackageInfo info) => info.version;
String getVersionText(PackageInfo info) => info.version;
