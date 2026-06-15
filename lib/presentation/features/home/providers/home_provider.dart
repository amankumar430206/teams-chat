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
    this.isLoading = false,
    this.error,
  });

  const HomeState.initial()
      : rooms = const [],
        users = const [],
        searchQuery = '',
        isLoading = true,
        error = null;

  final List<ChatRoomEntity> rooms;
  final List<UserEntity> users;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<UserEntity> get onlineUsers =>
      users.where((u) => u.isOnline).toList();

  /// Rooms filtered by the current search query (case-insensitive).
  List<ChatRoomEntity> get filteredRooms {
    if (searchQuery.isEmpty) return rooms;
    final q = searchQuery.toLowerCase();
    return rooms.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  HomeState copyWith({
    List<ChatRoomEntity>? rooms,
    List<UserEntity>? users,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) =>
      HomeState(
        rooms: rooms ?? this.rooms,
        users: users ?? this.users,
        searchQuery: searchQuery ?? this.searchQuery,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.read(chatRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._repo) : super(const HomeState.initial()) {
    _load();
  }

  final ChatRepository _repo;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.fetchUsers();
      final rooms = _repo.buildRooms(users);
      state = HomeState(rooms: rooms, users: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refresh() => _load();
}
