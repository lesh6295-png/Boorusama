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
    this.allowSearch = false,
  });

  final DisplayState displayState;
  final bool allowSearch;
  final String? errorMessage;

  SearchState copyWith({
    DisplayState? displayState,
    String? errorMessage,
    bool? allowSearch,
  }) =>
      SearchState(
        displayState: displayState ?? this.displayState,
        errorMessage: errorMessage ?? this.errorMessage,
        allowSearch: allowSearch ?? this.allowSearch,
      );

  @override
  List<Object?> get props => [displayState, allowSearch];
}
