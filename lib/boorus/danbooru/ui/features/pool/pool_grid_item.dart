// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:easy_localization/easy_localization.dart';

// Project imports:
import 'package:boorusama/boorus/danbooru/application/pool/pool.dart';
import 'package:boorusama/boorus/danbooru/router.dart';
import 'package:boorusama/core/core.dart';
import 'pool_image.dart';

class PoolGridItem extends StatelessWidget {
  const PoolGridItem({
    super.key,
    required this.pool,
  });

  final PoolItem pool;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        child: GestureDetector(
          onTap: () => goToPoolDetailPage(context, pool.pool),
          child: Column(
            children: [
              Expanded(
                child: PoolImage(pool: pool),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                subtitle: const Text('pool.item').plural(pool.pool.postCount),
                title: Text(
                  pool.pool.name.removeUnderscoreWithSpace(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 4,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
