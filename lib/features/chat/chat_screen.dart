import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/glass.dart';
import '../../data/store.dart';

class ChatScreen extends StatefulWidget {
  final int chat;
  final LocalStore store;
  const ChatScreen({super.key, required this.chat, required this.store});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<Map<String, Object?>> rows = [];
  String? reply;
  int? editing;
  String? error;
  @override
  void initState() { super.initState(); refresh(); }
  @override
  void dispose() { input.dispose(); scroll.dispose(); super.dispose(); }
  Future<void> refresh() async {
    try {
      final result = await widget.store.messages(widget.chat);
      if (mounted) { setState(() { rows = result; error = null; }); }
    } catch (_) { if (mounted) { setState(() => error = 'Could not read messages. Please try again.'); } }
  }
  Future<void> send() async {
    final body = input.text.trim();
    if (body.isEmpty) { return; }
    try {
      if (editing != null) { await widget.store.edit(editing!, body); }
      else { await widget.store.send(widget.chat, body, reply: reply); }
      input.clear();
      if (!mounted) { return; }
      setState(() { reply = null; editing = null; });
      await refresh();
      WidgetsBinding.instance.addPostFrameCallback((_) { if (scroll.hasClients) { scroll.jumpTo(scroll.position.maxScrollExtent); } });
    } catch (_) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message was not saved. Please retry.'))); } }
  }
  Future<void> actions(Map<String, Object?> row) async {
    final mine = row['mine'] == 1;
    final withinWindow = DateTime.now().millisecondsSinceEpoch - (row['created'] as int) < 15 * 60 * 1000;
    final action = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      for (final a in ['Reply', 'Copy', '❤️', '👍', if (mine && withinWindow) 'Edit', 'Delete locally']) ListTile(title: Text(a), onTap: () => Navigator.pop(context, a))
    ])));
    if (!mounted || action == null) { return; }
    final id = row['id'] as int;
    if (action == 'Reply') { setState(() { reply = row['body'] as String; editing = null; }); }
    else if (action == 'Copy') { await Clipboard.setData(ClipboardData(text: row['body'] as String)); }
    else if (action == 'Edit') { setState(() { editing = id; input.text = row['body'] as String; reply = null; }); }
    else if (action == 'Delete locally') { await widget.store.delete(id); await refresh(); }
    else { await widget.store.react(id, action); await refresh(); }
  }
  Future<void> clear() async {
    final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Clear local history?'), content: const Text('This deletes the messages in this demo conversation from this phone.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear'))]));
    if (yes == true) { await widget.store.clear(widget.chat); await refresh(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(titleSpacing: 0, title: Row(children: [GlassAvatar(contacts[widget.chat], radius: 20, index: widget.chat), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(contacts[widget.chat], style: const TextStyle(fontSize: 17)), const Text('Offline demo conversation', style: TextStyle(fontSize: 11, color: Palette.cyan))]))]), actions: [IconButton(tooltip: 'Clear local history', onPressed: clear, icon: const Icon(Icons.delete_outline))]), body: SafeArea(child: Column(children: [
    if (error != null) MaterialBanner(content: Text(error!), actions: [TextButton(onPressed: refresh, child: const Text('Retry'))]),
    Expanded(child: rows.isEmpty ? const Center(child: Text('Start a local conversation ✨')) : ListView.builder(controller: scroll, padding: const EdgeInsets.all(18), itemCount: rows.length, itemBuilder: (context, i) {
      final row = rows[i]; final mine = row['mine'] == 1;
      return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: GestureDetector(onLongPress: () => actions(row), child: Container(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: mine ? const LinearGradient(colors: [Color(0xFF9275CC), Color(0xFF6750A4)]) : null, color: mine ? null : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (row['reply'] != null) Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)), child: Text(row['reply'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: mine ? Colors.white70 : null))),
        Text(row['body'] as String, style: TextStyle(fontSize: 16, color: mine ? Colors.white : null)), const SizedBox(height: 5), Text('${row['edited'] == 1 ? 'edited · ' : ''}${mine ? 'Saved locally ✓' : 'Sample message'}', style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : null)), if (row['reaction'] != null) Text(row['reaction'] as String),
      ]))));
    })),
    if (reply != null || editing != null) ListTile(dense: true, title: Text(editing != null ? 'Editing message' : 'Replying to: $reply', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(onPressed: () => setState(() { reply = null; editing = null; input.clear(); }), icon: const Icon(Icons.close))),
    Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 14), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: TextField(controller: input, minLines: 1, maxLines: 5, maxLength: 4000, decoration: const InputDecoration(hintText: 'Write a message…', counterText: ''), onSubmitted: (_) => send())), const SizedBox(width: 10), IconButton.filled(tooltip: 'Save message locally', onPressed: send, icon: const Icon(Icons.arrow_upward), style: IconButton.styleFrom(backgroundColor: Palette.violet, foregroundColor: Palette.background, minimumSize: const Size(52, 52)))])),
  ])));
}
