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
    return Scaffold(
      body: Column(
        children: [
          TextField(
            controller: accountTextController,
          ),
          TextField(
            controller: keyTextController,
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSubmit(
                accountTextController.text,
                keyTextController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }
}
