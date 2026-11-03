import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/supabase_config.dart';
import 'core/auth/secure_session_storage.dart';
import 'features/auth/account_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'core/design_system/glass.dart';
import 'core/motion/tokens.dart';
import 'data/store.dart';
import 'features/chat/chat_screen.dart';

final store = LocalStore();
final recoveryRequired = ValueNotifier<bool>(false);
String? authStartupError;
final lightProvider = StateProvider<bool>((ref) => false);
final reduceProvider = StateProvider<bool>((ref) => false);
final banglaProvider = StateProvider<bool>((ref) => false);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await store.open();
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(localStorage: const SecureSessionStorage()),
      );
      Supabase.instance.client.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) recoveryRequired.value = true;
      }, onError: (Object _) {});
    } catch (_) {
      authStartupError = 'Account services could not start. Restart NexChat to retry. Offline demo is available.';
    }
    final light = await store.setting('light') == 'true';
    final reduced = await store.setting('reduced') == 'true';
    final bangla = await store.setting('bangla') == 'true';
    runApp(ProviderScope(overrides: [lightProvider.overrideWith((ref) => light), reduceProvider.overrideWith((ref) => reduced), banglaProvider.overrideWith((ref) => bangla)], child: const NexChat()));
  } catch (_) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('NexChat could not open local storage. Free some device space and restart the app.'))))));
  }
}
class NexChat extends ConsumerWidget {
  const NexChat({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = ref.watch(lightProvider);
    return MaterialApp(title: 'NexChat', debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: light ? Brightness.light : Brightness.dark,
        scaffoldBackgroundColor: light ? const Color(0xFFF0F2FA) : Palette.background,
        colorSchemeSeed: Palette.violet, appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: light ? Colors.white70 : Colors.white.withValues(alpha: .05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: recoveryRequired,
        builder: (context, recovery, _) => recovery
          ? ResetPasswordScreen(onComplete: () => recoveryRequired.value = false)
          : child!,
      ),
      home: const Welcome());
  }
}
class Welcome extends ConsumerStatefulWidget {
  const Welcome({super.key});
  @override
  ConsumerState<Welcome> createState() => _WelcomeState();
}
class _WelcomeState extends ConsumerState<Welcome> {
  int page = 0;
  final pager = PageController();
  @override
  void dispose() { pager.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(banglaProvider);
    final titles = bn ? ['তোমার পৃথিবী। তোমার কথা।', 'কথা থাকুক হাতের কাছে', 'তোমার মতো করে সাজাও'] : ['Your world. Your voice.', 'Keep your conversations close', 'Make space for your people'];
    return Scaffold(body: DecoratedBox(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(.7, -.5), radius: 1.4, colors: [Color(0x443F287C), Colors.transparent])), child: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      Row(children: [const Icon(Icons.blur_on_rounded, color: Palette.cyan), const SizedBox(width: 8), const Text('NEXCHAT', style: TextStyle(letterSpacing: 4)), const Spacer(), TextButton(onPressed: () { final value = !bn; ref.read(banglaProvider.notifier).state = value; store.set('bangla', '$value'); }, child: Text(bn ? 'English' : 'বাংলা'))]),
      Expanded(child: PageView.builder(controller: pager, itemCount: 3, onPageChanged: (v) => setState(() => page = v), itemBuilder: (context, i) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Hero(tag: 'logo', child: Container(width: 148, height: 148, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Palette.cyan, Palette.violet]), boxShadow: [BoxShadow(color: Palette.violet.withValues(alpha: .25), blurRadius: 64)]), child: Icon([Icons.forum_outlined, Icons.lock_outline, Icons.auto_awesome][i], size: 66, color: Palette.background))),
        const SizedBox(height: 42), Text(titles[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.15)), const SizedBox(height: 20),
        Text(bn ? 'অ্যাকাউন্টে সাইন ইন করো অথবা অফলাইন চ্যাট ডেমো দেখো। অনলাইন মেসেজিং এখনও চালু হয়নি।' : 'Beautifully connected. A liquid glass offline sandbox, made for exploring what comes next.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6)),
      ]))),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => AnimatedContainer(duration: MotionTokens.quick, width: page == i ? 28 : 7, height: 7, margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: page == i ? Palette.violet : Colors.grey, borderRadius: BorderRadius.circular(8))))),
      const SizedBox(height: 26), GlassButton(bn ? 'ডেমো শুরু করো' : 'Explore Demo', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const Home()))),
      TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => accountScreen(context))), child: Text(bn ? 'লগইন / সাইন আপ' : 'Sign in / Create account')),
      const Text('PHASE 1 • OFFLINE DEMO', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Palette.cyan)),
    ])))));
  }
}
Widget accountScreen(BuildContext context) {
  if (authStartupError != null) {
    return Scaffold(appBar: AppBar(title: const Text('Account unavailable')),
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(authStartupError!))));
  }
  return AccountScreen(onDemo: () => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const Home()), (_) => false));
}
class Home extends ConsumerStatefulWidget {
  const Home({super.key});
  @override
  ConsumerState<Home> createState() => _HomeState();
}
class _HomeState extends ConsumerState<Home> {
  int tab = 0;
  String query = '';
  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(banglaProvider);
    final labels = bn ? ['চ্যাট', 'স্টোরি', 'বন্ধু', 'কল', 'প্রোফাইল'] : ['Chats', 'Stories', 'Friends', 'Calls', 'Profile'];
    return Scaffold(appBar: AppBar(title: Text(tab == 0 ? 'NexChat' : labels[tab], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -.7)), actions: [IconButton(tooltip: 'Settings', onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.tune_rounded))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(children: [
        Container(margin: const EdgeInsets.fromLTRB(20, 0, 20, 16), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), decoration: BoxDecoration(color: Palette.cyan.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.science_outlined, color: Palette.cyan, size: 16), const SizedBox(width: 8), Expanded(child: Text(bn ? 'অফলাইন ডেমো • মেসেজ শুধু এই ফোনে থাকবে' : 'Offline Demo • Messages stay on this device', style: const TextStyle(fontSize: 12)))])),
        Expanded(child: tab == 0 ? chats() : tab == 4 ? profile() : tab == 2 ? friends() : upcoming(tab == 1 ? 'Stories & Reels' : 'Voice & video calls', tab == 1 ? Icons.auto_awesome_motion : Icons.phone_in_talk_outlined)),
      ])))),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: ClipRRect(borderRadius: BorderRadius.circular(32), child: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: List.generate(5, (i) => NavigationDestination(icon: Icon([Icons.chat_bubble_outline, Icons.play_circle_outline, Icons.people_outline, Icons.call_outlined, Icons.person_outline][i]), label: labels[i])))))));
  }
  Widget chats() => ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
    TextField(onChanged: (v) => setState(() => query = v.toLowerCase()), decoration: const InputDecoration(hintText: 'Search conversations', prefixIcon: Icon(Icons.search))), const SizedBox(height: 22),
    SizedBox(height: 90, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: contacts.length, separatorBuilder: (_, i) => const SizedBox(width: 20), itemBuilder: (context, i) => InkWell(onTap: () => openChat(i), child: Column(children: [GlassAvatar(contacts[i], index: i, online: i.isOdd), const SizedBox(height: 9), Text(contacts[i].split(' ').first, style: const TextStyle(fontSize: 12))])))),
    const SizedBox(height: 10), const Text('MESSAGES', style: TextStyle(fontSize: 11, letterSpacing: 2, color: Palette.violet)), const SizedBox(height: 16),
    ...List.generate(contacts.length, (i) { if (!contacts[i].toLowerCase().contains(query)) { return const SizedBox.shrink(); }
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(reduced: ref.watch(reduceProvider), padding: EdgeInsets.zero, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), leading: GlassAvatar(contacts[i], index: i, online: i.isOdd), title: Text(contacts[i], style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: FutureBuilder<List<Map<String, Object?>>>(future: store.messages(i), builder: (_, snap) => Text(snap.data?.isNotEmpty == true ? snap.data!.last['body'] as String : 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis)), trailing: const Icon(Icons.chevron_right, size: 18), onTap: () => openChat(i)))); }),
  ]);
  Future<void> openChat(int i) async { await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(chat: i, store: store))); if (mounted) { setState(() {}); } }
  Widget friends() => ListView(padding: const EdgeInsets.all(20), children: [const Text('Sample contacts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('These are fictional demo contacts. Friend requests will be available with the backend.')), ...List.generate(contacts.length - 1, (n) => ListTile(leading: GlassAvatar(contacts[n + 1], index: n), title: Text(contacts[n + 1]), trailing: IconButton(tooltip: 'Message', icon: const Icon(Icons.chat_outlined), onPressed: () => openChat(n + 1))))]);
  Widget upcoming(String title, IconData icon) => Center(child: Padding(padding: const EdgeInsets.all(28), child: GlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: Palette.violet), const SizedBox(height: 24), Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 12), const Text('Planned for a later phase. This feature is not connected yet.', textAlign: TextAlign.center)]))));
  Widget profile() => ListView(padding: const EdgeInsets.all(20), children: [GlassCard(child: Column(children: [const GlassAvatar('Bushrat', radius: 48), const SizedBox(height: 18), const Text('Bushrat', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)), const Text('@bushrat • Demo profile', style: TextStyle(color: Palette.cyan)), const SizedBox(height: 20), const Text('Your world. Your voice. Your people.'), const SizedBox(height: 22), GlassButton('Saved Messages', icon: Icons.bookmark_outline, onPressed: () => openChat(0))])), const SizedBox(height: 18), const GlassCard(child: ListTile(leading: Icon(Icons.storage_rounded, color: Palette.violet), title: Text('Local & offline'), subtitle: Text('Chats persist after restarting. Demo data is not encrypted.')))]);
}
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(20), children: [
    ListTile(leading: const Icon(Icons.manage_accounts_outlined), title: const Text('My account'), subtitle: const Text('Sign in, verification and sign out'), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => accountScreen(context)))),
    GlassCard(child: Column(children: [SwitchListTile(title: const Text('Light appearance'), value: ref.watch(lightProvider), onChanged: (v) { ref.read(lightProvider.notifier).state = v; store.set('light', '$v'); }), SwitchListTile(title: const Text('Reduce effects'), subtitle: const Text('Disable glass blur on conversation cards'), value: ref.watch(reduceProvider), onChanged: (v) { ref.read(reduceProvider.notifier).state = v; store.set('reduced', '$v'); }), SwitchListTile(title: const Text('বাংলা'), subtitle: const Text('Welcome and navigation language'), value: ref.watch(banglaProvider), onChanged: (v) { ref.read(banglaProvider.notifier).state = v; store.set('bangla', '$v'); })])),
    const SizedBox(height: 20), const GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('NexChat 0.1.0', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 12), Text('Phase 1 • Offline demo\n\nSupabase email accounts are connected. Online messaging, delivery receipts, calls, cloud uploads and end-to-end encryption are not enabled. Do not use this sandbox for sensitive information.\n\nDeveloper: Rakib Chowdhury')]))
  ]));
}
