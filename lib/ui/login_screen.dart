import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import 'admin_screen.dart';
import 'menu_screen.dart';

/// US1: log in with campus card ID and PIN.
class LoginScreen extends StatefulWidget {
  final CafeteriaRepository repo;
  const LoginScreen({super.key, required this.repo});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cardNo = TextEditingController();
  final _pin = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final card = await widget.repo.signIn(_cardNo.text, _pin.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => card.isAdmin
            ? AdminScreen(repo: widget.repo)
            : MenuScreen(repo: widget.repo, card: card),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong card ID or PIN')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RUET Cafeteria')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: _cardNo,
                decoration: const InputDecoration(labelText: 'Card ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pin,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'PIN'),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _login,
                child: Text(_busy ? 'Please wait...' : 'Log in'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
