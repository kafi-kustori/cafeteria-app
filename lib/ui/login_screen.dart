import 'package:flutter/material.dart';

import '../data/cafeteria_repository.dart';
import 'admin_screen.dart';
import 'common_widgets.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.6);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kBrandTeal, kBrandTealDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kBrandTeal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'RUET Cafeteria',
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Self-service ordering',
                      style: textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _cardNo,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Card ID',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pin,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _busy ? null : _login,
                        child: Text(_busy ? 'Please wait...' : 'Log in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
