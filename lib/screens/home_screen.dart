import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/wallpaper_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/wallpaper_card.dart';
import '../providers/auth_provider.dart';
import '../utils/theme.dart';
import 'profile_screen.dart';
import 'collection_screen.dart';
import 'ai_generator_screen.dart';
import 'custom_creator_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final List<String> _categories = [
    'All',
    'Premium',
    'Nature',
    'Travel',
    'Architecture',
    'Business',
    'Technology',
    'People',
  ];
  String _selectedCategory = 'All';

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WallpaperProvider>(context, listen: false).fetchWallpapers();
      _animationController.forward();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 400) {
        Provider.of<WallpaperProvider>(
          context,
          listen: false,
        ).fetchWallpapers();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isNotEmpty) {
      Provider.of<WallpaperProvider>(
        context,
        listen: false,
      ).searchWallpapers(query);
    } else {
      Provider.of<WallpaperProvider>(
        context,
        listen: false,
      ).fetchWallpapers(isRefresh: true);
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (category == 'All') {
      Provider.of<WallpaperProvider>(
        context,
        listen: false,
      ).fetchWallpapers(isRefresh: true);
    } else {
      _onSearch(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AiGeneratorScreen()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text(
          'AI Generator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildSearchBar(), _buildCategories()],
              ),
            ),
          ),
          _buildWallpaperGrid(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      title: const Text(
        'WallFlow',
        style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900),
      ),
      centerTitle: true,
      backgroundColor: AppTheme.darkBg.withOpacity(0.8),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [const SizedBox(width: 8)],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Material(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: TextField(
            controller: _searchController,
            onSubmitted: _onSearch,
            decoration: InputDecoration(
              hintText: 'Search for inspiration...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.accentColor,
              ),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == _categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: InkWell(
              onTap: () => _onCategorySelected(_categories[index]),
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWallpaperGrid() {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width > 1200) {
      crossAxisCount = 4;
    } else if (width > 800) {
      crossAxisCount = 3;
    }

    return Consumer<WallpaperProvider>(
      builder: (ctx, wpProvider, _) {
        final wallpapers = _selectedCategory == 'Premium'
            ? wpProvider.wallpapers.where((w) => w.isPremium).toList()
            : wpProvider.wallpapers;

        if (wpProvider.isLoading && wallpapers.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor),
            ),
          );
        }

        if (wallpapers.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'No wallpapers found in this category',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: wallpapers.length,
            itemBuilder: (context, index) {
              return WallpaperCard(wallpaper: wallpapers[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.darkBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<AuthProvider>(
            builder: (ctx, auth, _) => Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                image: auth.profileImagePath != null
                    ? DecorationImage(
                        image: FileImage(File(auth.profileImagePath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Beautiful Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Centered placeholder icon if no image
                  if (auth.profileImagePath == null)
                    Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 80,
                        color: AppTheme.accentColor.withOpacity(0.2),
                      ),
                    ),
                  // Account Info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.displayName ??
                              auth.email?.split('@')[0] ??
                              'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (auth.email != null)
                          Text(
                            auth.email!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.person_rounded,
              color: AppTheme.accentColor,
            ),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.favorite_rounded,
              color: Colors.pinkAccent,
            ),
            title: const Text('Favorites'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CollectionScreen(
                    title: 'Favorites',
                    isFavorites: true,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history_rounded,
              color: Colors.blueAccent,
            ),
            title: const Text('Recent'),
            onTap: () => Navigator.pop(context),
          ),

          // Premium Features Section
          const Divider(color: Colors.white10, height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Premium Features',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentColor,
                  ),
                ),
                const Spacer(),
                Consumer<SubscriptionProvider>(
                  builder: (ctx, subscription, _) {
                    if (subscription.isPremium) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.accentColor,
            ),
            title: const Text('AI Generator'),
            trailing: Consumer<SubscriptionProvider>(
              builder: (ctx, subscription, _) {
                if (!subscription.isPremium) {
                  return const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: Colors.white24,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiGeneratorScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Colors.purpleAccent),
            title: const Text('Custom Creator'),
            trailing: Consumer<SubscriptionProvider>(
              builder: (ctx, subscription, _) {
                if (!subscription.isPremium) {
                  return const Icon(
                    Icons.lock_rounded,
                    size: 18,
                    color: Colors.white24,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomCreatorScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
            ),
            title: const Text('Premium'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
          ),

          const Divider(color: Colors.white10, height: 40),
          ListTile(
            leading: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.redAccent,
            ),
            title: const Text('Logout'),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
