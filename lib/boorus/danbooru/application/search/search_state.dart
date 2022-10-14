part of 'search_bloc.dart';

enum DisplayState {
  options,
  suggestion,
  loadingResult,
  result,
  noResult,
  error,
}

@immutable
class SearchState extends Equatable {
  const SearchState({
    required this.displayState,
    this.errorMessage,
  });

  final DisplayState displayState;
  final String? errorMessage;

  SearchState copyWith({
    DisplayState? displayState,
    String? errorMessage,
  }) =>
      SearchState(
        displayState: displayState ?? this.displayState,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [displayState, errorMessage];
}
