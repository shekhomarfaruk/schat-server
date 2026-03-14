import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../services/call_service.dart';
import '../theme/app_theme.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String roomId;
  const VideoCallScreen({super.key, required this.roomId});
  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _muted = false;
  bool _cameraOff = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String get _timeStr {
    final m = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarker,
      body: Stack(
        children: [
          // Main video (remote)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1e0a45), Color(0xFF0a0a1a)],
                ),
              ),
              child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            ),
          ),

          // Fallback: show avatar if no video
          Positioned.fill(
            child: Center(
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2d1b5e), Color(0xFF160830)]),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
                ),
                child: const Center(child: Text('J', style: TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w700))),
              ),
            ),
          ),

          // Self video PiP
          Positioned(
            top: 100, right: 18,
            child: Container(
              width: 100, height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white30, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _cameraOff
                  ? Container(
                      color: AppTheme.purpleDark,
                      child: const Center(child: Icon(Icons.videocam_off, color: Colors.white38, size: 28)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.purpleDark, AppTheme.purple]),
                      ),
                      child: const Center(child: Text('Y', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700))),
                    ),
              ),
            ),
          ),

          // Top overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Joseph Parker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          Row(
                            children: [
                              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(_timeStr, style: const TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      _topBtn(Icons.volume_up),
                      const SizedBox(width: 8),
                      _topBtn(Icons.more_vert),
                    ],
                  ),
                ),

                const Spacer(),

                // Participants strip
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _participantThumb('S', AppTheme.pink, 'Sara', speaking: true),
                      _participantThumb('M', AppTheme.orange, 'M.Lorry'),
                      _participantThumb('A', AppTheme.green, 'Any'),
                      _participantThumb('T', const Color(0xFFFF6B6B), 'Theresa'),
                      _participantThumb('G', const Color(0xFF5865F2), 'Guy'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ctrlBtn(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        active: _muted,
                        onTap: () => setState(() => _muted = !_muted),
                      ),
                      const SizedBox(width: 12),
                      _ctrlBtn(icon: Icons.mic_off, onTap: () {}),
                      const SizedBox(width: 12),
                      // End call
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                            color: AppTheme.red,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [BoxShadow(color: AppTheme.red.withOpacity(0.5), blurRadius: 16)],
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ctrlBtn(
                        icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                        active: !_cameraOff,
                        onTap: () => setState(() => _cameraOff = !_cameraOff),
                      ),
                      const SizedBox(width: 12),
                      _ctrlBtn(icon: Icons.back_hand_outlined, onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _participantThumb(String initial, Color color, String name, {bool speaking = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 70, height: 90,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: speaking ? AppTheme.green : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(initial, style: TextStyle(color: color == AppTheme.orange || color == AppTheme.green ? AppTheme.bgDarker : Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn({required IconData icon, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: active ? AppTheme.purple : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
