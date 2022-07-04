// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/rxdart.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/account/account.dart';
import 'package:boorusama/common/stream/stream.dart';
import 'package:boorusama/core/application/accounts/accounts.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:boorusama/core/presentation/account_verification_provider.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API key management'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bloc = context.read<AccountBloc>();
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
        },
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
                _CurrentUserTile(
                  title: Text(currentAccState.account!.name),
                  icon: const FaIcon(FontAwesomeIcons.user),
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
                          )),
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

class _CurrentUserTile extends StatelessWidget {
  const _CurrentUserTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  final Widget icon;
  final Widget title;
  final Widget? subtitle;

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
              label: const Text('Invalid'),
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
            decoration: _getDecoration(context, 'Account name'),
          ),
          const SizedBox(
            height: 16,
          ),
          TextField(
            controller: keyTextController,
            decoration: _getDecoration(context, 'API key'),
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

InputDecoration _getDecoration(
  BuildContext context,
  String hint,
) =>
    InputDecoration(
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
