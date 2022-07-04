// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

class CurrentAccountState extends Equatable {
  const CurrentAccountState({
    required this.account,
  });

  factory CurrentAccountState.initial() =>
      const CurrentAccountState(account: null);

  final Account? account;

  CurrentAccountState copyWith({
    Account? account,
  }) =>
      CurrentAccountState(
        account: account,
      );

  @override
  List<Object?> get props => [account];
}

abstract class CurrentAccountEvent extends Equatable {
  const CurrentAccountEvent();
}

class CurrentAccountFetched extends CurrentAccountEvent {
  const CurrentAccountFetched({
    required this.account,
  });

  final Account? account;

  @override
  List<Object?> get props => [account];
}

class CurrentAccountChanged extends CurrentAccountEvent {
  const CurrentAccountChanged({
    required this.account,
  });

  final Account account;

  @override
  List<Object?> get props => [account];
}

class CurrentAccountCleared extends CurrentAccountEvent {
  const CurrentAccountCleared();

  @override
  List<Object?> get props => [];
}

class CurrentAccountBloc
    extends Bloc<CurrentAccountEvent, CurrentAccountState> {
  CurrentAccountBloc({
    required CurrentAccountRepository currentAccountRepository,
    required Booru currentBooru,
  }) : super(CurrentAccountState.initial()) {
    on<CurrentAccountFetched>((event, emit) async {
      await tryAsync<Account?>(
        action: () => currentAccountRepository.get(currentBooru.booruType),
        // onLoading: () => emit(loading),
        onFailure: (error, stackTrace) => emit(state.copyWith()),
        onSuccess: (data) async {
          emit(state.copyWith(account: data));
        },
      );
    });

    on<CurrentAccountChanged>((event, emit) async {
      await tryAsync<void>(
        action: () =>
            currentAccountRepository.set(event.account, currentBooru.booruType),
        // onLoading: () => emit(loading),
        // onFailure: (error, stackTrace) => emit(error),
        onSuccess: (_) async {
          emit(state.copyWith(account: event.account));
        },
      );
    });

    on<CurrentAccountCleared>((event, emit) async {
      await tryAsync<void>(
        action: () => currentAccountRepository.clear(currentBooru.booruType),
        // onLoading: () => emit(loading),
        // onFailure: (error, stackTrace) => emit(error),
        onSuccess: (_) async {
          emit(state.copyWith());
        },
      );
    });
  }
}
