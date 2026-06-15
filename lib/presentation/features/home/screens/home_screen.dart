import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teams_chat/core/router/app_router.dart';
import 'package:teams_chat/core/theme/app_colors.dart';
import 'package:teams_chat/core/theme/app_text_styles.dart';
import 'package:teams_chat/core/theme/app_theme.dart';
import 'package:teams_chat/presentation/features/auth/providers/auth_provider.dart';
import 'package:teams_chat/presentation/features/home/providers/home_provider.dart';
import 'package:teams_chat/presentation/features/home/widgets/chat_room_tile.dart';
import 'package:teams_chat/presentation/features/home/widgets/online_users_bar.dart';
import 'package:teams_chat/presentation/shared/widgets/app_error_view.dart';
import 'package:teams_chat/presentation/shared/widgets/app_loading.dart';
import 'package:teams_chat/presentation/shared/widgets/user_avatar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);
    final authState = ref.watch(authProvider).asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: homeAsync.when(
          loading: () => const AppLoading(message: 'Loading chats…'),
          error: (e, _) => AppErrorView(
            message: e.toString(),
            onRetry: () => ref.read(homeProvider.notifier).refresh(),
          ),
          data: (home) => RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _Header(
                    userName: authState?.user?.firstName ?? 'You',
                    avatarUrl: authState?.user?.avatar,
                    userFullName: authState?.user?.fullName ?? '',
                    isDark: isDark,
                  ),
                ),

                // ── Search bar ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: ref.read(homeProvider.notifier).search,
                      decoration: InputDecoration(
                        hintText: 'Search rooms…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(homeProvider.notifier)
                                      .search('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // ── Online users ─────────────────────────────────────
                if (home.onlineUsers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 0, 10),
                      child: Text(
                        'Online Now  •  ${home.onlineUsers.length}',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: OnlineUsersBar(users: home.onlineUsers),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],

                // ── Section title ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Channels & DMs',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),

                // ── Room list ────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: home.filteredRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final room = home.filteredRooms[i];
                      return ChatRoomTile(
                        room: room,
                        onTap: () => context.push(
                          AppRoutes.chatPath(room.id, roomName: room.name),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header widget
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({
    required this.userName,
    required this.userFullName,
    this.avatarUrl,
    required this.isDark,
  });

  final String userName;
  final String userFullName;
  final String? avatarUrl;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          // Avatar
          UserAvatar(
            name: userFullName,
            avatarUrl: avatarUrl,
            radius: 22,
            showOnlineRing: true,
            isOnline: true,
          ),
          const SizedBox(width: 12),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey, $userName 👋',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  'What\'s on your mind?',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Dark-mode toggle
          IconButton(
            icon: Icon(
              isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle theme',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggle(),
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                    'Are you sure you want to sign out?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => ctx.pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => ctx.pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
