import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/cafeteria_repository.dart';
import 'data/supabase_cafeteria_repository.dart';
import 'ui/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: Config.supabaseUrl, anonKey: Config.supabaseAnonKey);

  // On the web, turn on the accessibility tree so every button gets a label.
  // Selenium uses these labels to find and click buttons.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();

  runApp(CafeteriaApp(repo: SupabaseCafeteriaRepository(Supabase.instance.client)));
}

class CafeteriaApp extends StatelessWidget {
  final CafeteriaRepository repo;
  const CafeteriaApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUET Cafeteria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: LoginScreen(repo: repo),
    );
  }
}
