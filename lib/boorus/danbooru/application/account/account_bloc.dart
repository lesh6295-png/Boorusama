// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/core/domain/accounts/account.dart';
import 'package:boorusama/core/domain/accounts/account_repository.dart';

class AccountState extends Equatable {
  const AccountState({
    required this.accounts,
    required this.status,
  });

  factory AccountState.initial() => const AccountState(
        accounts: [],
        status: LoadStatus.initial,
      );

  final LoadStatus status;
  final List<Account> accounts;

  AccountState copyWith({
    List<Account>? accounts,
    LoadStatus? status,
    String? errorMessage,
  }) =>
      AccountState(
        status: status ?? this.status,
        accounts: accounts ?? this.accounts,
      );

  @override
  List<Object?> get props => [accounts, status];
}

abstract class AccountEvent extends Equatable {
  const AccountEvent();
}

class AccountRequested extends AccountEvent {
  const AccountRequested();

  @override
  List<Object> get props => [];
}

class AccountAdded extends AccountEvent {
  const AccountAdded({
    required this.name,
    required this.key,
  });

  final String name;
  final String key;

  @override
  List<Object> get props => [name, key];
}

class AccountRemoved extends AccountEvent {
  const AccountRemoved({
    required this.id,
  });

  final AccountId id;

  @override
  List<Object> get props => [id];
}

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc({
    AccountState? initial,
    required AccountRepository accountRepository,
    required Booru booru,
  }) : super(initial ?? AccountState.initial()) {
    on<AccountRequested>((event, emit) async {
      await tryAsync<List<Account>>(
        action: () => accountRepository.getAll(),
        onFailure: (_, __) => emit(state.copyWith(status: LoadStatus.failure)),
        onSuccess: (accounts) async {
          emit(state.copyWith(
            accounts: accounts,
            status: LoadStatus.success,
          ));
        },
      );
    });

    //TODO: handle on another bloc?
    on<AccountAdded>((event, emit) async {
      final args = AccountAddArg(
        name: event.name,
        key: event.key,
        type: booru.booruType,
        createdAt: DateTime.now(),
      );
      await tryAsync<Account?>(
        action: () => accountRepository.add(args),
        onSuccess: (account) async {
          if (account == null) {
            return;
          }

          emit(state.copyWith(
            accounts: [
              ...state.accounts,
              account,
            ],
          ));
        },
      );
    });

    //TODO: handle on another bloc?
    on<AccountRemoved>((event, emit) async {
      await tryAsync<bool>(
        action: () => accountRepository.delete(event.id),
        onSuccess: (success) async {
          if (!success) {
            return;
          }
          emit(state.copyWith(
            accounts: [
              ...[...state.accounts]..removeWhere((e) => e.id == event.id),
            ],
          ));
        },
      );
    });
  }
}
