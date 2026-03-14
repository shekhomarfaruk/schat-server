// ============================================================
// audio_call_screen.dart
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/call_service.dart';
import '../theme/app_theme.dart';

class AudioCallScreen extends ConsumerStatefulWidget {
  final String roomId;
  const AudioCallScreen({super.key, required this.roomId});
  @override
  ConsumerState<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends ConsumerState<AudioCallScreen> {
  bool _muted = false;
  bool _speaker = false;
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeStr {
    final m = _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '00:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarker,
      body: Stack(
        children: [
          // Glow
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 0.7,
                colors: [AppTheme.pink.withOpacity(0.3), AppTheme.bgDarker],
              ),
            ),
          )),
          SafeArea(child: Column(
            children: [
              const SizedBox(height: 60),
              // Connected badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('Connected', style: TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(_timeStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 32),
              // Avatar with ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.pink.withOpacity(0.4), width: 3),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.pink, AppTheme.purple]),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [BoxShadow(color: AppTheme.pink.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w700))),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Ronald Richards', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Speaking...', style: TextStyle(color: AppTheme.green, fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              // Sound wave
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(11, (i) {
                  final heights = [18.0, 32.0, 48.0, 62.0, 48.0, 32.0, 18.0, 38.0, 52.0, 38.0, 22.0];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 400 + i * 80),
                      width: 4,
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: AppTheme.pink.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quickBtn(icon: _muted ? Icons.mic_off : Icons.mic_outlined, label: 'Mute', active: _muted, onTap: () => setState(() => _muted = !_muted)),
                    _quickBtn(icon: _speaker ? Icons.volume_up : Icons.volume_down, label: 'Speaker', active: _speaker, onTap: () => setState(() => _speaker = !_speaker)),
                    _quickBtn(icon: Icons.videocam_outlined, label: 'Video', onTap: () => context.pushReplacement('/call/video/${widget.roomId}')),
                    _quickBtn(icon: Icons.dialpad, label: 'Keypad', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // End call
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    color: AppTheme.red,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppTheme.red.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 10),
              const Text('End Call', style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 40),
            ],
          )),
        ],
      ),
    );
  }

  Widget _quickBtn({required IconData icon, required String label, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: active ? AppTheme.purple : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
