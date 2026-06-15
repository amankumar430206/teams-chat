import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teams_chat/data/repositories/chat_repository.dart';
import 'package:teams_chat/domain/entities/chat_room_entity.dart';
import 'package:teams_chat/domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HomeState {
  const HomeState({
    required this.rooms,
    required this.users,
    this.searchQuery = '',
  });

  const HomeState.initial()
      : rooms = const [],
        users = const [],
        searchQuery = '';

  final List<ChatRoomEntity> rooms;
  final List<UserEntity> users;
  final String searchQuery;

  List<UserEntity> get onlineUsers =>
      users.where((u) => u.isOnline).toList();

  /// Rooms filtered by the current search query (case-insensitive).
  List<ChatRoomEntity> get filteredRooms {
    if (searchQuery.isEmpty) return rooms;
    final q = searchQuery.toLowerCase();
    return rooms
        .where((r) => r.name.toLowerCase().contains(q))
        .toList();
  }

  HomeState copyWith({
    List<ChatRoomEntity>? rooms,
    List<UserEntity>? users,
    String? searchQuery,
  }) =>
      HomeState(
        rooms: rooms ?? this.rooms,
        users: users ?? this.users,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider =
    AsyncNotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final repo = ref.read(chatRepositoryProvider);
    final users = await repo.fetchUsers();
    final rooms = repo.buildRooms(users);
    return HomeState(rooms: rooms, users: users);
  }

  void search(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(searchQuery: query));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(chatRepositoryProvider);
      final users = await repo.fetchUsers();
      final rooms = repo.buildRooms(users);
      return HomeState(rooms: rooms, users: users);
    });
  }
}
