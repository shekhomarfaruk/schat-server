import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Matrix Server Config ────────────────────────────────
const String kMatrixHomeserver = 'https://matrix.softvibeitgarden.tech';
const String kAppName = 'SChat';

// ─── Providers ───────────────────────────────────────────
final matrixClientProvider = Provider<Client>((ref) {
  return Client(
    kAppName,
    databaseBuilder: (_) async {
      final db = HiveCollectionsDatabase(kAppName, '.schat_db');
      await db.open();
      return db;
    },
  );
});

final matrixServiceProvider = Provider<MatrixService>((ref) {
  final client = ref.watch(matrixClientProvider);
  return MatrixService(client);
});

final loginStateProvider = StateNotifierProvider<LoginStateNotifier, LoginState>((ref) {
  return LoginStateNotifier(ref.watch(matrixServiceProvider));
});

final roomListProvider = StreamProvider<List<Room>>((ref) {
  final client = ref.watch(matrixClientProvider);
  return client.onSync.stream.map((_) => client.rooms);
});

// ─── Login State ─────────────────────────────────────────
enum LoginState { loading, loggedOut, loggedIn, error }

class LoginStateNotifier extends StateNotifier<LoginState> {
  final MatrixService _service;
  LoginStateNotifier(this._service) : super(LoginState.loading) {
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await _service.init();
    state = loggedIn ? LoginState.loggedIn : LoginState.loggedOut;
  }
}

// ─── Matrix Service ───────────────────────────────────────
class MatrixService {
  final Client client;
  MatrixService(this.client);

  /// Initialize — restore session if exists
  Future<bool> init() async {
    try {
      await client.init();
      if (client.isLogged()) return true;

      // Try restore from prefs
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getString('user_id');
      final deviceId = prefs.getString('device_id');
      final homeserver = prefs.getString('homeserver');

      if (accessToken != null && userId != null) {
        await client.init(
          newToken: accessToken,
          newUserID: userId,
          newDeviceID: deviceId,
          newDeviceName: kAppName,
          newOlmAccount: prefs.getString('olm_account'),
        );
        return client.isLogged();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Login with phone number (via Matrix password)
  Future<bool> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      await client.checkHomeserver(Uri.parse(kMatrixHomeserver));
      await client.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(user: phone),
        password: password,
        initialDeviceDisplayName: kAppName,
      );
      await _saveSession();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Login with Google (SSO)
  Future<String?> getGoogleSSOUrl() async {
    try {
      await client.checkHomeserver(Uri.parse(kMatrixHomeserver));
      final ssoProviders = await client.getSsoProviders();
      final google = ssoProviders?.identityProviders
          ?.firstWhere((p) => p.brand == 'google',
              orElse: () => ssoProviders.identityProviders!.first);
      if (google != null) {
        return '$kMatrixHomeserver/_matrix/client/v3/login/sso/redirect/${google.id}?redirectUrl=schat://callback';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Register new user
  Future<bool> register({
    required String username,
    required String password,
    String? displayName,
  }) async {
    try {
      await client.checkHomeserver(Uri.parse(kMatrixHomeserver));
      await client.uiaRequestBackground(
        (auth) => client.register(
          username: username,
          password: password,
          initialDeviceDisplayName: kAppName,
          auth: auth,
        ),
      );
      if (displayName != null) {
        await client.setDisplayName(client.userID!, displayName);
      }
      await _saveSession();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await client.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Send text message
  Future<void> sendMessage(Room room, String message) async {
    await room.sendTextEvent(message);
  }

  /// Send image
  Future<void> sendImage(Room room, String filePath) async {
    final matrixFile = await MatrixImageFile.fromLocalFile(filePath);
    await room.sendFileEvent(matrixFile);
  }

  /// Send file (pdf, doc, etc)
  Future<void> sendFile(Room room, String filePath, String name) async {
    final matrixFile = MatrixFile(
      bytes: await MatrixFile.fromLocalFile(filePath).then((f) => f.bytes),
      name: name,
    );
    await room.sendFileEvent(matrixFile);
  }

  /// Send voice message
  Future<void> sendVoice(Room room, String filePath) async {
    final matrixFile = MatrixAudioFile(
      bytes: await MatrixFile.fromLocalFile(filePath).then((f) => f.bytes),
      name: 'voice_${DateTime.now().millisecondsSinceEpoch}.ogg',
    );
    await room.sendFileEvent(matrixFile, extraContent: {
      'org.matrix.msc3245.voice': {},
    });
  }

  /// Create direct chat with user
  Future<Room?> createDirectChat(String userId) async {
    try {
      final roomId = await client.startDirectChat(userId);
      return client.getRoomById(roomId);
    } catch (e) {
      return null;
    }
  }

  /// Create group
  Future<Room?> createGroup({
    required String name,
    String? topic,
    List<String>? invites,
  }) async {
    try {
      final roomId = await client.createRoom(
        name: name,
        topic: topic,
        invite: invites,
        preset: CreateRoomPreset.privateChat,
      );
      return client.getRoomById(roomId);
    } catch (e) {
      return null;
    }
  }

  /// Search users
  Future<List<Profile>> searchUsers(String query) async {
    final result = await client.searchUserDirectory(query);
    return result.results ?? [];
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', client.accessToken ?? '');
    await prefs.setString('user_id', client.userID ?? '');
    await prefs.setString('device_id', client.deviceID ?? '');
    await prefs.setString('homeserver', kMatrixHomeserver);
  }

  // ─── Current User ───────────────────────────────────
  String? get currentUserId => client.userID;
  String? get displayName => client.userID;
  bool get isLoggedIn => client.isLogged();
}
