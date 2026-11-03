import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const contacts = ['Saved Messages', 'Ayesha Rahman', 'Rafi Ahmed', 'Nadia Islam', 'Design Circle', 'Tanvir Hasan'];
class LocalStore {
  late Database db;
  Future<void> open() async {
    db = await openDatabase(p.join(await getDatabasesPath(), 'nexchat.db'), version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE messages (id INTEGER PRIMARY KEY AUTOINCREMENT, chat INTEGER NOT NULL, body TEXT NOT NULL, mine INTEGER NOT NULL, created INTEGER NOT NULL, edited INTEGER NOT NULL DEFAULT 0, reaction TEXT, reply TEXT)');
        await db.execute('CREATE INDEX messages_chat_created ON messages(chat, created)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        for (var i = 0; i < contacts.length; i++) {
          await db.insert('messages', {'chat': i, 'body': i == 0 ? 'Your private offline notebook. Save an idea here.' : 'Welcome to NexChat ✨ This is a sample conversation.', 'mine': 0, 'created': DateTime.now().millisecondsSinceEpoch});
        }
      });
  }
  Future<List<Map<String, Object?>>> messages(int chat) => db.query('messages', where: 'chat = ?', whereArgs: [chat], orderBy: 'created ASC, id ASC');
  Future<void> send(int chat, String body, {String? reply}) async {
    await db.insert('messages', {'chat': chat, 'body': body, 'mine': 1, 'created': DateTime.now().millisecondsSinceEpoch, 'reply': reply});
  }
  Future<void> edit(int id, String body) async { await db.update('messages', {'body': body, 'edited': 1}, where: 'id = ?', whereArgs: [id]); }
  Future<void> react(int id, String emoji) async { await db.update('messages', {'reaction': emoji}, where: 'id = ?', whereArgs: [id]); }
  Future<void> delete(int id) async { await db.delete('messages', where: 'id = ?', whereArgs: [id]); }
  Future<void> clear(int chat) async { await db.delete('messages', where: 'chat = ?', whereArgs: [chat]); }
  Future<String?> setting(String key) async { final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]); return rows.isEmpty ? null : rows.first['value'] as String; }
  Future<void> set(String key, String value) async { await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace); }
}
