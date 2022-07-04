// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/account/account.dart';
import 'package:boorusama/boorus/danbooru/application/api/api.dart';
import 'package:boorusama/boorus/danbooru/presentation/shared/shared.dart';
import 'package:boorusama/common/stream/stream.dart';
import 'package:boorusama/core/application/accounts/accounts.dart';
import 'package:boorusama/core/core.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:boorusama/core/presentation/account_verification_provider.dart';

Future<void> _showAddApiModalSheet(
  BuildContext context,
  AccountBloc bloc,
) =>
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      isScrollControlled: true,
      context: context,
      builder: (context) => AddAccountSheet(
        onSubmit: (name, key) => bloc.add(
          AccountAdded(
            name: name,
            key: key,
          ),
        ),
      ),
    );

class AccountPage extends StatelessWidget {
  AccountPage({Key? key}) : super(key: key);

  final showKey = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API key'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddApiModalSheet(context, context.read<AccountBloc>()),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CurrentAccountBloc, CurrentAccountState>(
        builder: (context, currentAccState) {
          return Column(
            children: [
              if (currentAccState.account == null)
                const _CurrentUserTile(
                  title: Text('Anonymous'),
                  subtitle: Text('Lurking...'),
                  icon: FaIcon(FontAwesomeIcons.userSecret),
                )
              else
                ValueListenableBuilder<bool>(
                  valueListenable: showKey,
                  builder: (context, show, _) => _CurrentUserTile(
                    subtitle: show ? Text(currentAccState.account!.key) : null,
                    title: Text(currentAccState.account!.name),
                    icon: const FaIcon(FontAwesomeIcons.user),
                    trailing: IconButton(
                      onPressed: () => showKey.value = !show,
                      icon: show
                          ? const FaIcon(FontAwesomeIcons.solidEyeSlash,
                              size: 20)
                          : const FaIcon(
                              FontAwesomeIcons.solidEye,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              const Divider(
                thickness: 2,
              ),
              BlocConsumer<AccountBloc, AccountState>(
                listener: (context, state) {
                  if (state.accounts.isEmpty) {
                    context
                        .read<CurrentAccountBloc>()
                        .add(const CurrentAccountCleared());
                  }

                  if (state.accounts.length == 1 &&
                      currentAccState.account == null) {
                    context.read<CurrentAccountBloc>().add(
                        CurrentAccountChanged(account: state.accounts.first));
                  }
                },
                builder: (context, state) {
                  return Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'API keys - ${state.accounts.length} key${state.accounts.length > 1 ? 's' : ''}'
                                  .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        if (state.accounts.isEmpty)
                          SliverToBoxAdapter(
                            child: WarningContainer(
                                contentBuilder: (context) => const Text(
                                    "The app don't need all permissions to work, however if some features are broken consider using a full permissions API key.")),
                          ),
                        if (state.accounts.isEmpty)
                          SliverToBoxAdapter(
                            child: BlocBuilder<ApiCubit, ApiState>(
                              builder: (context, state) => _AddApiKeyGuide(
                                profileUrl: '${state.booru.url}/profile',
                              ),
                            ),
                          ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final account = state.accounts[index];
                              final selected =
                                  currentAccState.account != null &&
                                      currentAccState.account!.id == account.id;
                              return ListTile(
                                visualDensity: VisualDensity.compact,
                                onTap: () => selected
                                    ? context
                                        .read<CurrentAccountBloc>()
                                        .add(const CurrentAccountCleared())
                                    : context.read<CurrentAccountBloc>().add(
                                        CurrentAccountChanged(
                                            account: account)),
                                title: Text(account.name),
                                selected: selected,
                                selectedColor:
                                    Theme.of(context).colorScheme.onBackground,
                                selectedTileColor:
                                    Theme.of(context).colorScheme.primary,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: Theme.of(context).cardColor,
                                    onPrimary:
                                        Theme.of(context).iconTheme.color,
                                  ),
                                  onPressed: () {
                                    context
                                        .read<AccountBloc>()
                                        .add(AccountRemoved(id: account.id));

                                    if (currentAccState.account != null &&
                                        currentAccState.account!.id ==
                                            account.id) {
                                      context
                                          .read<CurrentAccountBloc>()
                                          .add(const CurrentAccountCleared());
                                    }
                                  },
                                  child: const Text('Remove'),
                                ),
                              );
                            },
                            childCount: state.accounts.length,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddApiKeyGuide extends StatelessWidget {
  const _AddApiKeyGuide({
    Key? key,
    required this.profileUrl,
  }) : super(key: key);

  final String profileUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            'How to get an API key?',
            style: Theme.of(context).textTheme.headline6,
          ),
          const SizedBox(height: 40),
          const Text('1. Navigate to your profile'),
          TextButton.icon(
            onPressed: () => launchExternalUrl(
              Uri.parse(profileUrl),
              mode: LaunchMode.platformDefault,
            ),
            icon: const FaIcon(
              FontAwesomeIcons.arrowUpRightFromSquare,
              size: 16,
            ),
            label: const Text(
              'tap here to open your profile',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Text('2.  Find and copy your API key'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () =>
                _showAddApiModalSheet(context, context.read<AccountBloc>()),
            icon: const FaIcon(FontAwesomeIcons.paste),
            label: const Text('Paste'),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserTile extends StatelessWidget {
  const _CurrentUserTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  final Widget icon;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListTile(
              visualDensity: VisualDensity.comfortable,
              leading: icon,
              title: title,
              trailing: trailing,
              subtitle: subtitle,
            ),
          ),
        ),
      ],
    );
  }
}

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  final void Function(String name, String key) onSubmit;

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final accountTextController = TextEditingController();
  final keyTextController = TextEditingController();

  final compositeSubscription = CompositeSubscription();

  final enableOk = ValueNotifier(false);
  final accountNameHasText = ValueNotifier(false);
  final apiKeyHasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    Rx.combineLatest2<String, String, bool>(
      accountTextController.textAsStream(),
      keyTextController.textAsStream(),
      (a, b) => a.isNotEmpty && b.isNotEmpty,
    )
        .distinct()
        .listen((event) => enableOk.value = event)
        .addTo(compositeSubscription);

    accountTextController
        .textAsStream()
        .distinct()
        .listen((event) => accountNameHasText.value = event.isNotEmpty)
        .addTo(compositeSubscription);

    keyTextController
        .textAsStream()
        .distinct()
        .listen((event) => apiKeyHasText.value = event.isNotEmpty)
        .addTo(compositeSubscription);
  }

  @override
  void dispose() {
    accountTextController.dispose();
    keyTextController.dispose();
    compositeSubscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 30,
        right: 30,
        top: 1,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Add an API key',
              style: Theme.of(context).textTheme.headline6,
            ),
          ),
          AccountVerificationProvider(
            initialBuilder: (context, verify) => TextButton(
              onPressed: () => verify(
                AccountAddData(
                  name: accountTextController.text,
                  key: keyTextController.text,
                ),
              ),
              child: const Text('Verify'),
            ),
            invalidBuilder: (context, verify) => TextButton.icon(
              onPressed: () => verify(
                AccountAddData(
                  name: accountTextController.text,
                  key: keyTextController.text,
                ),
              ),
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
              label: const Text('Invalid, tap again to retry'),
            ),
            maybeInvalidBuilder: (context, verify) => TextButton.icon(
              onPressed: () => verify(
                AccountAddData(
                  name: accountTextController.text,
                  key: keyTextController.text,
                ),
              ),
              icon: const Icon(
                Icons.warning,
                color: Colors.yellow,
              ),
              label: const Text('Maybe invalid'),
            ),
            validBuilder: (context, verify) => TextButton.icon(
              onPressed: () => verify(
                AccountAddData(
                  name: accountTextController.text,
                  key: keyTextController.text,
                ),
              ),
              icon: const Icon(
                Icons.verified,
                color: Colors.green,
              ),
              label: const Text('Verified'),
            ),
            validatingBuilder: (context) => const TextButton(
              onPressed: null,
              child: Text('Validating...'),
            ),
          ),
          TextField(
            autofocus: true,
            controller: accountTextController,
            decoration: _getDecoration(
              context: context,
              hint: 'Account name',
              suffixIcon: ValueListenableBuilder<bool>(
                valueListenable: accountNameHasText,
                builder: (context, hasText, _) => hasText
                    ? IconButton(
                        onPressed: () => accountTextController.clear(),
                        icon: const Icon(Icons.close),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextField(
            controller: keyTextController,
            decoration: _getDecoration(
              context: context,
              hint: 'API key',
              suffixIcon: ValueListenableBuilder<bool>(
                valueListenable: apiKeyHasText,
                builder: (context, hasText, _) => hasText
                    ? IconButton(
                        onPressed: () => keyTextController.clear(),
                        icon: const Icon(Icons.close),
                      )
                    : IconButton(
                        onPressed: () => Clipboard.getData('text/plain').then(
                            (value) =>
                                keyTextController.text = value?.text ?? ''),
                        icon: const FaIcon(
                          FontAwesomeIcons.paste,
                          size: 20,
                        ),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).cardColor,
                    onPrimary: Theme.of(context).iconTheme.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: enableOk,
                  builder: (context, enable, _) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).cardColor,
                      onPrimary: Theme.of(context).iconTheme.color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: enable
                        ? () {
                            widget.onSubmit(
                              accountTextController.text,
                              keyTextController.text,
                            );
                            Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

InputDecoration _getDecoration({
  required BuildContext context,
  required String hint,
  Widget? suffixIcon,
}) =>
    InputDecoration(
      suffixIcon: suffixIcon,
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.all(12),
    );
