import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/matrix_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarker,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.pink, AppTheme.orange],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('SChat', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Welcome back 👋', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Sign in to continue', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 40),

              // Google Sign In
              _buildSocialBtn(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                color: Colors.white,
                textColor: const Color(0xFF1A1A2E),
                onTap: _googleLogin,
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white12)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                  const Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 24),

              // Phone field
              _buildField(
                controller: _phoneCtrl,
                hint: 'Phone number or username',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _passCtrl,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: !_showPass,
                suffix: IconButton(
                  icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13)),
              ],

              const SizedBox(height: 28),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _register,
                  child: const Text("Don't have an account? Register", style: TextStyle(color: AppTheme.purpleLight, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    final service = ref.read(matrixServiceProvider);
    final ok = await service.loginWithPhone(
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        context.go('/home');
      } else {
        setState(() => _error = 'Invalid credentials. Please try again.');
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    final service = ref.read(matrixServiceProvider);
    final url = await service.getGoogleSSOUrl();
    setState(() => _loading = false);
    if (url != null && mounted) {
      // Launch SSO URL in browser
      // url_launcher to open the SSO
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google SSO: Opening browser...')),
      );
    }
  }

  Future<void> _register() async {
    // Show register dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RegisterSheet(ref: ref),
    );
  }
}

class _RegisterSheet extends StatefulWidget {
  final WidgetRef ref;
  const _RegisterSheet({required this.ref});
  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  final _userCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _field(_nameCtrl, 'Display Name', Icons.person_outline),
          const SizedBox(height: 12),
          _field(_userCtrl, 'Username', Icons.alternate_email),
          const SizedBox(height: 12),
          _field(_passCtrl, 'Password', Icons.lock_outline, obscure: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Register', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    final service = widget.ref.read(matrixServiceProvider);
    final ok = await service.register(
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
      displayName: _nameCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _loading = false);
      if (ok) {
        Navigator.pop(context);
        context.go('/home');
      }
    }
  }
}
