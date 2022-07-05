// Package imports:
import 'package:boorusama/core/domain/accounts/accounts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/comment/comment.dart';
import 'package:boorusama/boorus/danbooru/application/common.dart';
import 'package:boorusama/boorus/danbooru/domain/comments/comments.dart';

class CommentBloc extends Bloc<CommentEvent, CommentState> {
  CommentBloc({
    required ICommentRepository commentRepository,
    required CurrentAccountRepository accountRepository,
    required CommentVoteRepository commentVoteRepository,
  }) : super(CommentState.initial()) {
    on<CommentFetched>((event, emit) async {
      await tryAsync<List<Comment>>(
          action: () => commentRepository.getCommentsFromPostId(event.postId),
          onFailure: (stackTrace, error) =>
              emit(state.copyWith(status: LoadStatus.failure)),
          onLoading: () => emit(state.copyWith(status: LoadStatus.initial)),
          onSuccess: (comments) async {
            final commentList = comments.where(notDeleted);
            final votes = await commentVoteRepository
                .getCommentVotes(commentList.map((e) => e.id).toList());

            final account = await accountRepository.get();
            final commentData = commentList
                .map((e) => commentDataFrom(
                      e,
                      e.creator,
                      account ?? AnonymousAccount(),
                      votes,
                    ))
                .toList();

            emit(state.copyWith(
              comments: commentData..sort((a, b) => a.id.compareTo(b.id)),
              hiddenComments: [],
              status: LoadStatus.success,
            ));
          });
    });

    on<CommentSent>((event, emit) async {
      await tryAsync<bool>(
        action: () =>
            commentRepository.postComment(event.postId, event.content),
        onSuccess: (success) async {
          add(CommentFetched(postId: event.postId));
        },
      );
    });

    on<CommentUpdated>((event, emit) async {
      await tryAsync<bool>(
        action: () =>
            commentRepository.updateComment(event.commentId, event.content),
        onSuccess: (success) async {
          add(CommentFetched(postId: event.postId));
        },
      );
    });

    on<CommentDeleted>((event, emit) async {
      await tryAsync<bool>(
        action: () => commentRepository.deleteComment(event.commentId),
        onSuccess: (success) async {
          add(CommentFetched(postId: event.postId));
        },
      );
    });

    on<CommentUpvoted>((event, emit) async {
      await tryAsync<CommentVote>(
        action: () => commentVoteRepository.upvote(event.commentId),
        onSuccess: (vote) async {
          final comments = _updateWith(
            state.comments,
            vote,
            CommentVoteState.upvoted,
          );
          emit(state.copyWith(comments: comments));
        },
      );
    });

    on<CommentDownvoted>((event, emit) async {
      await tryAsync<CommentVote>(
        action: () => commentVoteRepository.downvote(event.commentId),
        onSuccess: (vote) async {
          final comments = _updateWith(
            state.comments,
            vote,
            CommentVoteState.downvoted,
          );
          emit(state.copyWith(comments: comments));
        },
      );
    });

    on<CommentVoteRemoved>((event, emit) async {
      await tryAsync<bool>(
        action: () => commentVoteRepository.removeVote(event.commentVoteId),
        onSuccess: (success) async {
          final comments = {for (var c in state.comments) c.id: c};
          final old = comments[event.commentId]!;
          final $new = old.copyWith(
            score: event.voteState == CommentVoteState.downvoted
                ? old.score + 1
                : old.score - 1,
            voteState: CommentVoteState.unvote,
          );
          comments[event.commentId] = $new;
          emit(state.copyWith(comments: comments.values.toList()));
        },
      );
    });
  }
}

List<CommentData> _updateWith(
  List<CommentData> comments,
  CommentVote vote,
  CommentVoteState voteState,
) {
  final cmts = {for (var c in comments) c.id: c};
  final old = cmts[vote.commentId]!;
  final $new = old.copyWith(
    score: old.score + vote.score,
    voteState: voteState,
    voteId: vote.id,
  );
  cmts[vote.commentId] = $new;

  return cmts.values.toList();
}
