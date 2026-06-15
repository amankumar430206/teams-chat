import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:teams_chat/core/constants/api_constants.dart';
import 'package:teams_chat/core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WebSocketState {
  const WebSocketState({
    required this.isConnected,
    this.isConnecting = false,
    this.error,
    this.reconnectAttempts = 0,
  });

  final bool isConnected;
  final bool isConnecting;
  final String? error;
  final int reconnectAttempts;

  WebSocketState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? error,
    int? reconnectAttempts,
  }) =>
      WebSocketState(
        isConnected: isConnected ?? this.isConnected,
        isConnecting: isConnecting ?? this.isConnecting,
        error: error,
        reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final webSocketProvider =
    NotifierProvider<WebSocketNotifier, WebSocketState>(WebSocketNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WebSocketNotifier extends Notifier<WebSocketState> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;

  // Broadcast stream so multiple listeners (e.g. different rooms) can subscribe.
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Incoming decoded WebSocket messages.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  @override
  WebSocketState build() {
    ref.onDispose(_dispose);
    return const WebSocketState(isConnected: false);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> connect() async {
    if (state.isConnected || state.isConnecting) return;
    if (state.reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) return;

    state = state.copyWith(isConnecting: true, error: null);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConstants.wsUrl));
      await _channel!.ready;

      _sub = _channel!.stream.listen(
        _onData,
        onDone: _onConnectionLost,
        onError: (_) => _onConnectionLost(),
        cancelOnError: false,
      );

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        reconnectAttempts: 0,
      );
    } catch (_) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        error: 'Connection failed',
      );
      _scheduleReconnect();
    }
  }

  /// Sends a pre-built map as a JSON string over the socket.
  void send(Map<String, dynamic> payload) {
    if (!state.isConnected) return;
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {
      state = state.copyWith(error: 'Send failed');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    state = const WebSocketState(isConnected: false);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      _messageController.add(data);
    } catch (_) {
      // Ignore malformed frames
    }
  }

  void _onConnectionLost() {
    state = state.copyWith(isConnected: false, isConnecting: false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (state.reconnectAttempts >= AppConstants.wsMaxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: AppConstants.wsReconnectDelaySeconds),
      () {
        state = state.copyWith(
          reconnectAttempts: state.reconnectAttempts + 1,
        );
        connect();
      },
    );
  }

  void _dispose() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
