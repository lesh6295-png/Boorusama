// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/account/account_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
      body: BlocBuilder<AccountBloc, AccountState>(
        buildWhen: (previous, current) =>
            previous.accounts.length != current.accounts.length,
        builder: (context, state) {
          if (state.accounts.isEmpty) {
            return const Center(
              child: Text('No account added'),
            );
          }

          return ListView.builder(
            itemBuilder: (context, index) {
              final account = state.accounts[index];
              return ListTile(
                title: Text(account.name),
                subtitle: Text(account.key),
                trailing: IconButton(
                  onPressed: () => context
                      .read<AccountBloc>()
                      .add(AccountRemoved(id: account.id)),
                  icon: const Icon(Icons.close),
                ),
              );
            },
            itemCount: state.accounts.length,
          );
        },
      ),
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

  @override
  void dispose() {
    accountTextController.dispose();
    keyTextController.dispose();
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
              'Add an account',
              style: Theme.of(context).textTheme.headline6,
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Theme.of(context).cardColor,
                    onPrimary: Theme.of(context).iconTheme.color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    widget.onSubmit(
                      accountTextController.text,
                      keyTextController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
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
