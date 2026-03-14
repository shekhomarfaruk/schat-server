// call_history_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import '../services/matrix_service.dart';
import '../theme/app_theme.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});
  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  int _filter = 0;
  final _filters = ['All', 'Incoming', 'Outgoing', 'Missed'];

  final _calls = [
    {'name': 'Ronald Richards', 'type': 'audio', 'dir': 'incoming', 'time': '9:41 AM', 'duration': '04:32', 'color': AppTheme.pink},
    {'name': 'Joseph Parker', 'type': 'video', 'dir': 'outgoing', 'time': '8:15 AM', 'duration': '12:45', 'color': AppTheme.purple},
    {'name': 'Theresa Webb', 'type': 'audio', 'dir': 'missed', 'time': '7:30 AM', 'duration': null, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Lorry Machigo', 'type': 'audio', 'dir': 'incoming', 'time': '6:20 PM', 'duration': '08:10', 'color': AppTheme.orange},
    {'name': 'Sara Wilson', 'type': 'video', 'dir': 'outgoing', 'time': '3:45 PM', 'duration': '22:03', 'color': AppTheme.green},
    {'name': 'Guy Hawkins', 'type': 'audio', 'dir': 'missed', 'time': '11:00 AM', 'duration': null, 'color': const Color(0xFF5865F2)},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 0 ? _calls : _calls.where((c) {
      final dirs = ['', 'incoming', 'outgoing', 'missed'];
      return c['dir'] == dirs[_filter];
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        title: const Text('Call History', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: _filter == i ? AppTheme.purple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _filter == i ? AppTheme.purple.withOpacity(0.3) : Colors.black.withOpacity(0.06), blurRadius: 8)],
                  ),
                  child: Text(_filters[i], style: TextStyle(color: _filter == i ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length + 2,
              itemBuilder: (_, i) {
                if (i == 0) return const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('TODAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 1)));
                if (i == 3) return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('YESTERDAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 1)));
                final ci = i > 3 ? i - 2 : i - 1;
                if (ci >= filtered.length) return const SizedBox();
                return _buildCallTile(filtered[ci]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallTile(Map call) {
    final isVideo = call['type'] == 'video';
    final dir = call['dir'] as String;
    final missed = dir == 'missed';
    final dirColor = dir == 'incoming' ? AppTheme.green : dir == 'outgoing' ? AppTheme.purple : AppTheme.red;
    final dirIcon = dir == 'incoming' ? Icons.call_received : dir == 'outgoing' ? Icons.call_made : Icons.call_missed;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: call['color'] as Color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text((call['name'] as String)[0], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              ),
              Positioned(
                bottom: -3, right: -3,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Icon(isVideo ? Icons.videocam : Icons.phone, color: AppTheme.purple, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(call['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(dirIcon, color: dirColor, size: 12),
                    const SizedBox(width: 4),
                    Text(dir[0].toUpperCase() + dir.substring(1), style: TextStyle(color: dirColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Text('· ${isVideo ? 'Video' : 'Audio'}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(call['time'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 3),
              Text(
                missed ? 'Missed' : call['duration'] as String,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: missed ? AppTheme.red : const Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(isVideo ? Icons.videocam_outlined : Icons.phone_outlined, color: AppTheme.purple, size: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ============================================================
// profile_screen.dart
// ============================================================
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.purple, AppTheme.pink]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700))),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppTheme.green, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('SChat User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text('@user:matrix.softvibeitgarden.tech', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                _statCard('124', 'Contacts'),
                const SizedBox(width: 12),
                _statCard('38', 'Groups'),
                const SizedBox(width: 12),
                _statCard('1.2K', 'Messages'),
              ],
            ),
            const SizedBox(height: 24),

            // Settings items
            ...[
              (Icons.notifications_outlined, 'Notifications', AppTheme.purple),
              (Icons.lock_outline, 'Privacy & Security', AppTheme.pink),
              (Icons.storage_outlined, 'Storage & Data', AppTheme.orange),
              (Icons.palette_outlined, 'Appearance', const Color(0xFF5865F2)),
              (Icons.help_outline, 'Help & Support', AppTheme.green),
            ].map((item) => _settingsTile(item.$1, item.$2, item.$3)),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red.withOpacity(0.1),
                  foregroundColor: AppTheme.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: Column(
          children: [
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.purple)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final service = ref.read(matrixServiceProvider);
    await service.logout();
    if (context.mounted) context.go('/login');
  }
}

// ============================================================
// new_chat_screen.dart
// ============================================================
class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});
  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchCtrl = TextEditingController();
  List<Profile> _results = [];
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('New Chat'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or @username',
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: _search,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: AppTheme.purple),
          Expanded(
            child: _results.isEmpty
              ? Center(child: Text(_searchCtrl.text.isEmpty ? 'Search for people to chat with' : 'No results found', style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _results.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, i) {
                    final user = _results[i];
                    final name = user.displayName ?? user.userId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.purple,
                        child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(user.userId, style: const TextStyle(fontSize: 12)),
                      onTap: () => _startChat(user.userId),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _search(String query) async {
    if (query.length < 2) { setState(() => _results = []); return; }
    setState(() => _loading = true);
    final service = ref.read(matrixServiceProvider);
    final results = await service.searchUsers(query);
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  Future<void> _startChat(String userId) async {
    setState(() => _loading = true);
    final service = ref.read(matrixServiceProvider);
    final room = await service.createDirectChat(userId);
    if (mounted) {
      setState(() => _loading = false);
      if (room != null) context.pushReplacement('/chat/${room.id}');
    }
  }
}
