import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_collections_provider.dart';
import '../widgets/wallpaper_card.dart';

class CollectionScreen extends StatelessWidget {
  final String title;
  final bool isFavorites;

  const CollectionScreen({
    super.key,
    required this.title,
    required this.isFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<UserCollectionsProvider>(
        builder: (context, provider, child) {
          final list = isFavorites ? provider.favorites : provider.downloads;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFavorites
                        ? Icons.favorite_border
                        : Icons.download_outlined,
                    size: 80,
                    color: Colors.white10,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your $title will appear here',
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) =>
                WallpaperCard(wallpaper: list[index]),
          );
        },
      ),
    );
  }
}
