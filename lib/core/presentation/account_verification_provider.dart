// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/api/api.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/services/account_verification_service.dart';
import 'package:boorusama/core/application/accounts/account_verification_bloc.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

typedef AccountVerifyDelegate = void Function(AccountAddData account);

class AccountVerificationProvider extends StatelessWidget {
  const AccountVerificationProvider({
    Key? key,
    required this.initialBuilder,
    required this.invalidBuilder,
    required this.maybeInvalidBuilder,
    required this.validBuilder,
    required this.validatingBuilder,
  }) : super(key: key);

  final Widget Function(
    BuildContext context,
    AccountVerifyDelegate verify,
  ) initialBuilder;

  final Widget Function(BuildContext context) validatingBuilder;
  final Widget Function(
    BuildContext context,
    AccountVerifyDelegate verify,
  ) maybeInvalidBuilder;
  final Widget Function(
    BuildContext context,
    AccountVerifyDelegate verify,
  ) invalidBuilder;
  final Widget Function(
    BuildContext context,
    AccountVerifyDelegate verify,
  ) validBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApiCubit, ApiState>(
      builder: (context, state) {
        return BlocProvider(
          create: (context) => AccountVerificationBloc(
            accountVerifierService: AccountVerificationService(
              api: state.api,
            ),
          ),
          child: Builder(builder: (context) {
            return BlocBuilder<AccountVerificationBloc,
                AccountVerificationState>(
              builder: (context, state) {
                if (state.validationStatus ==
                    AccountValidationStatus.validating) {
                  return validatingBuilder(context);
                } else if (state.validationStatus ==
                    AccountValidationStatus.maybeInvalid) {
                  return maybeInvalidBuilder(
                      context,
                      (account) => context
                          .read<AccountVerificationBloc>()
                          .add(AccountVerificationRequested(account: account)));
                } else if (state.validationStatus ==
                    AccountValidationStatus.invalid) {
                  return invalidBuilder(
                      context,
                      (account) => context
                          .read<AccountVerificationBloc>()
                          .add(AccountVerificationRequested(account: account)));
                } else if (state.validationStatus ==
                    AccountValidationStatus.valid) {
                  return validBuilder(
                      context,
                      (account) => context
                          .read<AccountVerificationBloc>()
                          .add(AccountVerificationRequested(account: account)));
                } else {
                  return initialBuilder(
                      context,
                      (account) => context
                          .read<AccountVerificationBloc>()
                          .add(AccountVerificationRequested(account: account)));
                }
              },
            );
          }),
        );
      },
    );
  }
}
