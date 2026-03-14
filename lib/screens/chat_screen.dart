import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import '../services/matrix_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _showAttachMenu = false;
  Timeline? _timeline;

  Room? get _room => ref.read(matrixClientProvider).getRoomById(widget.roomId);

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final room = _room;
    if (room == null) return;
    final t = await room.getTimeline();
    setState(() => _timeline = t);
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    if (room == null) return const Scaffold(body: Center(child: Text('Room not found')));
    final name = room.getLocalizedDisplayname();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: _buildAppBar(name, room),
      body: Column(
        children: [
          Expanded(child: _buildMessages(room)),
          if (_showAttachMenu) _buildAttachMenu(room),
          _buildInputArea(room),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String name, Room room) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Text(room.membership.toString().contains('join') ? '● Online' : 'Offline',
                style: const TextStyle(fontSize: 11, color: AppTheme.green, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Color(0xFF1A1A2E)),
          onPressed: () => context.push('/call/video/${widget.roomId}'),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: AppTheme.purple, borderRadius: BorderRadius.circular(10)),
          child: IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.white, size: 20),
            onPressed: () => context.push('/call/audio/${widget.roomId}'),
          ),
        ),
      ],
    );
  }

  Widget _buildMessages(Room room) {
    if (_timeline == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.purple));
    }
    final events = _timeline!.events
      .where((e) => e.type == EventTypes.Message)
      .toList()
      .reversed
      .toList();

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Start the conversation!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: events.length,
      itemBuilder: (_, i) => _buildBubble(events[i], room),
    );
  }

  Widget _buildBubble(Event event, Room room) {
    final isMine = event.senderId == ref.read(matrixClientProvider).userID;
    final time = DateFormat('h:mm a').format(event.originServerTs);
    final body = event.body;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppTheme.purple, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(event.senderId[1].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppTheme.purple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [BoxShadow(color: isMine ? AppTheme.purple.withOpacity(0.3) : Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (event.messageType == MessageTypes.Image)
                    _buildImageBubble(event, isMine)
                  else if (event.messageType == MessageTypes.Audio)
                    _buildAudioBubble(event, isMine)
                  else if (event.messageType == MessageTypes.File)
                    _buildFileBubble(event, isMine)
                  else
                    Text(body, style: TextStyle(color: isMine ? Colors.white : const Color(0xFF1A1A2E), fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: TextStyle(fontSize: 10, color: isMine ? Colors.white54 : Colors.grey)),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 12, color: Colors.white60),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(Event event, bool isMine) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 200, height: 140,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _buildAudioBubble(Event event, bool isMine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_filled, color: isMine ? Colors.white : AppTheme.purple, size: 32),
        const SizedBox(width: 8),
        Container(
          width: 100, height: 2,
          decoration: BoxDecoration(
            color: isMine ? Colors.white38 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text('0:12', style: TextStyle(color: isMine ? Colors.white70 : Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildFileBubble(Event event, bool isMine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_outlined, color: isMine ? Colors.white : AppTheme.purple, size: 28),
        const SizedBox(width: 8),
        Flexible(child: Text(event.body, style: TextStyle(color: isMine ? Colors.white : const Color(0xFF1A1A2E), fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildAttachMenu(Room room) {
    final items = [
      (Icons.image_outlined, 'Gallery', _sendImage),
      (Icons.camera_alt_outlined, 'Camera', _sendCamera),
      (Icons.insert_drive_file_outlined, 'File', _sendFile),
      (Icons.gif_outlined, 'GIF', () {}),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => GestureDetector(
          onTap: () { setState(() => _showAttachMenu = false); item.$3(); },
          child: Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(item.$1, color: AppTheme.purple, size: 24),
              ),
              const SizedBox(height: 4),
              Text(item.$2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInputArea(Room room) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      color: Colors.white,
      child: Row(
        children: [
          // Attach
          GestureDetector(
            onTap: () => setState(() => _showAttachMenu = !_showAttachMenu),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(_showAttachMenu ? Icons.close : Icons.add, color: AppTheme.purple, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleRecording(room),
                    child: Icon(
                      _isRecording ? Icons.stop_circle : Icons.mic_outlined,
                      color: _isRecording ? AppTheme.red : Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send
          GestureDetector(
            onTap: () => _sendMessage(room),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppTheme.purple,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(Room room) async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    _msgCtrl.clear();
    final service = ref.read(matrixServiceProvider);
    await service.sendMessage(room, msg);
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final room = _room;
    if (room == null) return;
    final service = ref.read(matrixServiceProvider);
    await service.sendImage(room, file.path);
  }

  Future<void> _sendCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    final room = _room;
    if (room == null) return;
    final service = ref.read(matrixServiceProvider);
    await service.sendImage(room, file.path);
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final room = _room;
    if (room == null) return;
    final service = ref.read(matrixServiceProvider);
    await service.sendFile(room, result.files.single.path!, result.files.single.name);
  }

  Future<void> _toggleRecording(Room room) async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final service = ref.read(matrixServiceProvider);
        await service.sendVoice(room, path);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        await _recorder.start(
          RecordConfig(encoder: AudioEncoder.opus),
          path: '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.ogg',
        );
        setState(() => _isRecording = true);
      }
    }
  }
}

Future<Directory> getTemporaryDirectory() async {
  // path_provider
  return Directory.systemTemp;
}
