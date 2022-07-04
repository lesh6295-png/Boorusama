// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/booru.dart';
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/domain/profile/i_profile_repository.dart';
import 'package:boorusama/core/domain/accounts/accounts.dart';

class CurrentAccountState extends Equatable {
  const CurrentAccountState({
    required this.account,
    required this.userId,
  });

  factory CurrentAccountState.initial() => const CurrentAccountState(
        account: null,
        userId: null,
      );

  final Account? account;
  final int? userId;

  CurrentAccountState copyWith({
    Account? account,
    int? userId,
  }) =>
      CurrentAccountState(
        account: account,
        userId: userId,
      );

  @override
  List<Object?> get props => [account, userId];
}

abstract class CurrentAccountEvent extends Equatable {
  const CurrentAccountEvent();
}

class CurrentAccountFetched extends CurrentAccountEvent {
  const CurrentAccountFetched();

  @override
  List<Object?> get props => [];
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
    required IProfileRepository profileRepository,
    required Booru currentBooru,
  }) : super(CurrentAccountState.initial()) {
    on<CurrentAccountFetched>((event, emit) async {
      await tryAsync<Account?>(
        action: () => currentAccountRepository.get(currentBooru.booruType),
        // onLoading: () => emit(loading),
        onFailure: (error, stackTrace) => emit(state.copyWith()),
        onSuccess: (data) async {
          if (data != null) {
            final profile = await profileRepository.getProfile(
              username: data.name,
              apiKey: data.key,
            );
            emit(state.copyWith(
              account: data,
              userId: profile?.id,
            ));
          } else {
            emit(state.copyWith());
          }
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
          final profile = await profileRepository.getProfile(
            username: event.account.name,
            apiKey: event.account.key,
          );
          emit(state.copyWith(
            account: event.account,
            userId: profile?.id,
          ));
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
