// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/infrastructure/services/account_verification_service.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

enum AccountValidationStatus {
  unknown,
  validating,
  valid,
  maybeInvalid,
  invalid,
}

class AccountVerificationState extends Equatable {
  const AccountVerificationState({
    required this.validationStatus,
  });

  factory AccountVerificationState.initial() => const AccountVerificationState(
      validationStatus: AccountValidationStatus.unknown);

  final AccountValidationStatus validationStatus;

  AccountVerificationState copyWith({
    AccountValidationStatus? validationStatus,
  }) =>
      AccountVerificationState(
        validationStatus: validationStatus ?? this.validationStatus,
      );

  @override
  List<Object> get props => [validationStatus];
}

abstract class AccountVerificationEvent extends Equatable {
  const AccountVerificationEvent();
}

class AccountVerificationRequested extends AccountVerificationEvent {
  const AccountVerificationRequested({
    required this.account,
  });

  final AccountAddData account;

  @override
  List<Object?> get props => [account];
}

class AccountVerificationBloc
    extends Bloc<AccountVerificationEvent, AccountVerificationState> {
  AccountVerificationBloc({
    required AccountVerificationService accountVerifierService,
  }) : super(AccountVerificationState.initial()) {
    on<AccountVerificationRequested>((event, emit) async {
      await tryAsync<bool>(
        action: () => accountVerifierService.isValid(event.account),
        onLoading: () => emit(state.copyWith(
            validationStatus: AccountValidationStatus.validating)),
        onFailure: (error, stackTrace) => emit(state.copyWith(
            validationStatus: AccountValidationStatus.maybeInvalid)),
        onSuccess: (valid) async {
          emit(
            state.copyWith(
              validationStatus: valid
                  ? AccountValidationStatus.valid
                  : AccountValidationStatus.invalid,
            ),
          );
        },
      );
    });
  }
}
