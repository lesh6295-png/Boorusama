// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/settings/settings.dart';
import 'package:boorusama/boorus/danbooru/domain/settings/settings.dart';
import 'package:boorusama/boorus/danbooru/ui/shared/warning_container.dart';

// const String _basePath = '/storage/emulated/0/';
// const List<String> _allowedFolders = ['Download', 'Documents', 'Pictures'];

// bool _isInvalidDownloadPath(String? path) {
//   try {
//     if (path == null) return false;

//     final nonBasePath = path.replaceAll(_basePath, '');
//     final paths = nonBasePath.split('/');

//     if (paths.isEmpty) return true;
//     if (!_allowedFolders.contains(paths.first)) return true;
//     return false;
//   } catch (e) {
//     return false;
//   }
// }

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final changed = ValueNotifier(false);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) =>
          previous.settings.downloadPath != current.settings.downloadPath ||
          previous.settings.downloadMethod != current.settings.downloadMethod,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('download.download').tr(),
          ),
          body: SafeArea(
              child: Column(
            children: [
              //TODO: Files downloaded in custom location won't show up in gallery app. Re-enable this feature when a better download support for Flutter landed.

              // if (hasScopedStorage(context.read<DeviceInfo>()))
              //   _DownloadPathWarning(
              //     releaseName: context.read<DeviceInfo>().release,
              //     allowedFolders: _allowedFolders,
              //   ),
              // ListTile(
              //   leading: const FaIcon(FontAwesomeIcons.folder),
              //   onTap: () async {
              //     final bloc = context.read<SettingsCubit>();
              //     final path = await FilePicker.platform.getDirectoryPath();

              //     if (path == null) return;
              //     await bloc
              //         .update(state.settings.copyWith(downloadPath: path));
              //   },
              //   subtitle: state.settings.downloadPath != null
              //       ? Text(state.settings.downloadPath!)
              //       : FutureBuilder<String>(
              //           future: IOHelper.getDownloadPath(),
              //           builder: (_, snapshot) {
              //             if (snapshot.hasData) {
              //               return Text(snapshot.data!);
              //             } else {
              //               return const SizedBox.shrink();
              //             }
              //           },
              //         ),
              //   title: const Text('Download path'),
              // ),
              // if (hasScopedStorage(context.read<DeviceInfo>()) &&
              //     _isInvalidDownloadPath(state.settings.downloadPath))
              //   WarningContainer(
              //       contentBuilder: (context) =>
              //           const Text('Download might fail if using this path.'))
              ListTile(
                subtitle: const Text(
                    'Use this if the default method does not work. This method also has better notification support.'),
                title: const Text(
                    'Use alternative download method (EXPERIMENTAL)'),
                trailing: Switch(
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: state.settings.downloadMethod !=
                        DownloadMethod.flutterDownloader,
                    onChanged: (value) {
                      changed.value = true;
                      context
                          .read<SettingsCubit>()
                          .update(state.settings.copyWith(
                            downloadMethod: value
                                ? DownloadMethod.imageGallerySaver
                                : DownloadMethod.flutterDownloader,
                          ));
                    }),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: changed,
                builder: (context, value, _) => value
                    ? WarningContainer(
                        contentBuilder: (context) => const Text(
                            'You need to restart the app for this change to take effect'),
                      )
                    : const SizedBox.shrink(),
              )
            ],
          )),
        );
      },
    );
  }
}

// class _DownloadPathWarning extends StatelessWidget {
//   const _DownloadPathWarning({
//     Key? key,
//     required this.releaseName,
//     required this.allowedFolders,
//   }) : super(key: key);

//   final String releaseName;
//   final List<String> allowedFolders;

//   @override
//   Widget build(BuildContext context) {
//     return WarningContainer(
//       contentBuilder: (context) => RichText(
//           text: TextSpan(
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onBackground,
//               ),
//               children: [
//             const TextSpan(
//                 text: 'Only subfolders created inside public directories '),
//             TextSpan(
//                 text: '(${allowedFolders.join(',')}) ',
//                 style: const TextStyle(fontWeight: FontWeight.bold)),
//             const TextSpan(
//                 text:
//                     "are allowed in Android 11+. Picking anything else won't work."),
//             TextSpan(text: "\n\nThis device's version is $releaseName")
//           ])),
//     );
//   }
// }
