part of 'search_bloc.dart';

@immutable
abstract class SearchEvent extends Equatable {
  const SearchEvent();
}

class SearchRequested extends SearchEvent {
  const SearchRequested();
  @override
  List<Object?> get props => [];
}

class SearchPermissionChanged extends SearchEvent {
  const SearchPermissionChanged({
    required this.allow,
  });

  final bool allow;

  @override
  List<Object?> get props => [allow];
}

class SearchNoData extends SearchEvent {
  const SearchNoData();
  @override
  List<Object?> get props => [];
}

class SearchError extends SearchEvent {
  const SearchError({
    this.message,
  });

  final String? message;

  @override
  List<Object?> get props => [message];
}

class SearchSuggestions extends SearchEvent {
  const SearchSuggestions();

  @override
  List<Object?> get props => [];
}

class SearchOptionsRequested extends SearchEvent {
  const SearchOptionsRequested({
    this.allowSearch = false,
  });

  final bool allowSearch;

  @override
  List<Object?> get props => [allowSearch];
}
