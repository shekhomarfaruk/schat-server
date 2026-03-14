import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarker,
      body: Stack(
        children: [
          // Purple radial glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.8,
                  colors: [
                    AppTheme.purple.withOpacity(0.5),
                    AppTheme.bgDarker,
                  ],
                ),
              ),
            ),
          ),

          // Dashed lines
          CustomPaint(
            size: Size.infinite,
            painter: _DashedLinesPainter(),
          ),

          // Floating message cards
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMessageCard(
                  name: 'Wade Warren',
                  message: 'Hi, guys 👋',
                  avatarColor: const Color(0xFF8B6B4A),
                  showHeart: true,
                  alignment: Alignment.centerLeft,
                  delay: 0,
                ),
                const SizedBox(height: 12),
                _buildMessageCard(
                  name: 'Jenny Wilson',
                  message: 'I Working on my garden 🌱',
                  avatarColor: const Color(0xFFD4854A),
                  showHeart: false,
                  alignment: Alignment.centerRight,
                  delay: 200,
                ),
                const SizedBox(height: 12),
                _buildMessageCard(
                  name: 'Guy Hawkins',
                  message: "What's Up? 😄",
                  avatarColor: const Color(0xFF556B8B),
                  showHeart: true,
                  alignment: Alignment.centerLeft,
                  delay: 400,
                ),
                const Spacer(),

                // Mail icon
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mail_outline, color: Colors.white, size: 26),
                ).animate().fadeIn(delay: 600.ms).scale(),

                const SizedBox(height: 20),

                Text(
                  'Stay Connected,\nYour Way',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3),

                const SizedBox(height: 10),
                Text(
                  'Experience seamless conversations\nlike never before.',
                  style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.6),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 32),

                // Google Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _buildGoogleBtn(context),
                      const SizedBox(height: 12),
                      _buildPhoneBtn(context),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

                const SizedBox(height: 32),
                Container(
                  width: 130, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required String name,
    required String message,
    required Color avatarColor,
    required bool showHeart,
    required Alignment alignment,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: avatarColor,
                radius: 20,
                child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    Text(message, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (showHeart) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFF4D6D), borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text('2', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(
      begin: alignment == Alignment.centerLeft ? -0.2 : 0.2,
    );
  }

  Widget _buildGoogleBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A2E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/google.png', width: 22, height: 22,
              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
            ),
            const SizedBox(width: 12),
            const Text('Continue with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneBtn(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white.withOpacity(0.07),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_outlined, size: 20),
            SizedBox(width: 12),
            Text('Continue with Phone Number', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DashedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    void drawDashed(Offset start, Offset end) {
      const dashLen = 8.0;
      const gapLen = 6.0;
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final len = (dx * dx + dy * dy).sqrt();
      final steps = (len / (dashLen + gapLen)).floor();
      for (int i = 0; i < steps; i++) {
        final t0 = i * (dashLen + gapLen) / len;
        final t1 = (i * (dashLen + gapLen) + dashLen) / len;
        canvas.drawLine(
          Offset(start.dx + dx * t0, start.dy + dy * t0),
          Offset(start.dx + dx * t1.clamp(0, 1), start.dy + dy * t1.clamp(0, 1)),
          paint,
        );
      }
    }

    drawDashed(Offset(0, size.height * 0.3), Offset(size.width * 0.8, size.height * 0.1));
    drawDashed(Offset(size.width * 0.2, size.height * 0.5), Offset(size.width, size.height * 0.3));
    drawDashed(Offset(0, size.height * 0.45), Offset(size.width * 0.6, size.height * 0.6));
  }

  @override
  bool shouldRepaint(_) => false;
}

extension on double {
  double sqrt() {
    double x = this;
    if (x <= 0) return 0;
    double z = x;
    for (int i = 0; i < 10; i++) {
      z -= (z * z - x) / (2 * z);
    }
    return z;
  }
}
