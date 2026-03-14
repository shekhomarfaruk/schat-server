import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/matrix_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 1;
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomListProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStories(),
            _buildSearchBar(),
            _buildMessagesHeader(),
            Expanded(
              child: roomsAsync.when(
                data: (rooms) => _buildRoomList(rooms),
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.purple)),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-chat'),
        backgroundColor: AppTheme.purple,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          const Text('Messages', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          _iconBtn(Icons.notifications_outlined, () {}),
          const SizedBox(width: 8),
          _iconBtn(Icons.menu, () {}),
        ],
      ),
    );
  }

  Widget _buildStories() {
    final client = ref.watch(matrixClientProvider);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _storyItem(null, 'Story', isAdd: true),
          ...client.rooms.take(8).map((r) => _storyItem(r, r.getLocalizedDisplayname())),
        ],
      ),
    );
  }

  Widget _storyItem(Room? room, String name, {bool isAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: isAdd ? Colors.white : AppTheme.purple,
              borderRadius: BorderRadius.circular(16),
              border: isAdd
                ? Border.all(color: AppTheme.purpleLight, width: 2, style: BorderStyle.solid)
                : Border.all(color: AppTheme.purple, width: 2.5),
            ),
            child: isAdd
              ? const Icon(Icons.add, color: AppTheme.purple, size: 22)
              : Center(child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                )),
          ),
          const SizedBox(height: 5),
          Text(
            name.length > 6 ? '${name.substring(0, 5)}...' : name,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(fontSize: 13),
          onChanged: (v) => setState(() => _searching = v.isNotEmpty),
          decoration: const InputDecoration(
            hintText: 'Search People',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      child: Row(
        children: [
          const Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          const Icon(Icons.grid_view_rounded, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.person_add_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          const Icon(Icons.more_vert, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildRoomList(List<Room> rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No conversations yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/new-chat'),
              child: const Text('Start a conversation', style: TextStyle(color: AppTheme.purple)),
            ),
          ],
        ),
      );
    }

    final query = _searchCtrl.text.toLowerCase();
    final filtered = rooms.where((r) =>
      query.isEmpty || r.getLocalizedDisplayname().toLowerCase().contains(query)
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildRoomTile(filtered[i]),
    );
  }

  Widget _buildRoomTile(Room room) {
    final lastEvent = room.lastEvent;
    final unread = room.notificationCount;
    final name = room.getLocalizedDisplayname();
    final time = lastEvent?.originServerTs != null
      ? timeago.format(lastEvent!.originServerTs)
      : '';

    return GestureDetector(
      onTap: () => context.push('/chat/${room.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _colorFromName(name),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 3),
                  Text(
                    lastEvent?.body ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (unread > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.purple, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    final colors = [AppTheme.purple, AppTheme.pink, AppTheme.orange, const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFFFF5722)];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF1A1A2E)),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      Icons.home_outlined,
      Icons.chat_bubble_outline,
      Icons.phone_outlined,
      Icons.person_outline,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedTab == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedTab = i);
              if (i == 2) context.push('/calls');
              if (i == 3) context.push('/profile');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppTheme.cardBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(items[i], size: 24, color: active ? AppTheme.purple : Colors.grey),
            ),
          );
        }),
      ),
    );
  }
}
