import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In / Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isLogin, !isLogin],
              onPressed: (i) => setState(() => isLogin = i == 0),
              children: const [Padding(padding: EdgeInsets.all(8), child: Text('Sign In')), Padding(padding: EdgeInsets.all(8), child: Text('Sign Up'))],
            ),
            const SizedBox(height: 16),
            if (!isLogin)
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      try {
                        if (isLogin) {
                          await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
                        } else {
                          await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text.trim());
                        }
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: $e')));
                      }
                    },
              child: auth.isLoading ? const CircularProgressIndicator() : Text(isLogin ? 'Sign In' : 'Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
