import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:matrix/matrix.dart';
import 'matrix_service.dart';

final callServiceProvider = Provider<CallService>((ref) {
  return CallService(ref.watch(matrixClientProvider));
});

final activeCallProvider = StateNotifierProvider<ActiveCallNotifier, CallState?>((ref) {
  return ActiveCallNotifier();
});

class CallState {
  final String roomId;
  final String callId;
  final bool isVideo;
  final bool isIncoming;
  final String remoteUserId;
  final CallStatus status;
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOff;
  final Duration duration;

  const CallState({
    required this.roomId,
    required this.callId,
    required this.isVideo,
    required this.isIncoming,
    required this.remoteUserId,
    required this.status,
    this.localRenderer,
    this.remoteRenderer,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isCameraOff = false,
    this.duration = Duration.zero,
  });

  CallState copyWith({
    CallStatus? status,
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOff,
    Duration? duration,
  }) => CallState(
    roomId: roomId,
    callId: callId,
    isVideo: isVideo,
    isIncoming: isIncoming,
    remoteUserId: remoteUserId,
    status: status ?? this.status,
    localRenderer: localRenderer ?? this.localRenderer,
    remoteRenderer: remoteRenderer ?? this.remoteRenderer,
    isMuted: isMuted ?? this.isMuted,
    isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    isCameraOff: isCameraOff ?? this.isCameraOff,
    duration: duration ?? this.duration,
  );
}

enum CallStatus { ringing, connecting, connected, ended, missed }

class ActiveCallNotifier extends StateNotifier<CallState?> {
  ActiveCallNotifier() : super(null);
  void setCall(CallState call) => state = call;
  void updateCall(CallState Function(CallState) updater) {
    if (state != null) state = updater(state!);
  }
  void endCall() => state = null;
}

class CallService {
  final Client _client;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  CallService(this._client);

  // STUN/TURN servers
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Add your TURN server here for better connectivity
      // {
      //   'urls': 'turn:turn.softvibeitgarden.tech:3478',
      //   'username': 'schat',
      //   'credential': 'your_password',
      // },
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<void> init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> startCall({
    required String roomId,
    required String remoteUserId,
    required bool isVideo,
  }) async {
    await init();

    // Get media stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      } : false,
    });

    _localRenderer.srcObject = _localStream;

    // Create peer connection
    _peerConnection = await createPeerConnection(_iceConfig);

    // Add tracks
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Handle remote stream
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Send via Matrix
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    final room = _client.getRoomById(roomId);
    if (room != null) {
      await room.sendEvent({
        'msgtype': 'm.call.invite',
        'call_id': callId,
        'version': 1,
        'lifetime': 60000,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        },
        'org.matrix.msc3077.sdp_stream_metadata': {
          'audio': {'purpose': 'm.usermedia'},
          if (isVideo) 'video': {'purpose': 'm.usermedia'},
        },
      }, type: 'm.call.invite');
    }
  }

  Future<void> answerCall({
    required String roomId,
    required String callId,
    required Map<String, dynamic> offerSdp,
    required bool isVideo,
  }) async {
    await init();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo,
    });
    _localRenderer.srcObject = _localStream;
    _peerConnection = await createPeerConnection(_iceConfig);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams[0];
      }
    };

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offerSdp['sdp'], offerSdp['type']),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    final room = _client.getRoomById(roomId);
    if (room != null) {
      await room.sendEvent({
        'msgtype': 'm.call.answer',
        'call_id': callId,
        'version': 1,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        },
      }, type: 'm.call.answer');
    }
  }

  Future<void> endCall(String roomId, String callId) async {
    final room = _client.getRoomById(roomId);
    if (room != null) {
      await room.sendEvent({
        'msgtype': 'm.call.hangup',
        'call_id': callId,
        'version': 1,
      }, type: 'm.call.hangup');
    }
    await _cleanup();
  }

  Future<void> toggleMute(bool mute) async {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !mute);
  }

  Future<void> toggleCamera(bool off) async {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !off);
  }

  Future<void> switchCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> _cleanup() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    _localStream = null;
    _peerConnection = null;
  }

  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
}
