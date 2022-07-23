// Flutter imports:
import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/domain/posts/posts.dart';

//TODO: implement caching video
class PostVideo extends StatefulWidget {
  const PostVideo({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  State<PostVideo> createState() => _PostVideoState();
}

class _PostVideoState extends State<PostVideo> {
  @override
  Widget build(BuildContext context) {
    return BetterPlayer.network(
      widget.post.normalImageUrl,
      betterPlayerConfiguration: BetterPlayerConfiguration(
        aspectRatio: widget.post.aspectRatio,
        looping: true,
        autoPlay: true,
      ),
    );
  }
}
