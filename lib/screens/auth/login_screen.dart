import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:perpus_app/providers/auth_provider.dart';
import 'package:perpus_app/screens/auth/register_screen.dart';
import 'package:perpus_app/screens/admin/admin_dashboard_screen.dart';
import '../member/member_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
          _usernameController.text, _passwordController.text);

      if (success && mounted) {
        // Cek role dari authProvider, misal: authProvider.userRole
        final role = authProvider.userRole?.toLowerCase() ?? '';
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MemberDashboardScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Gagal! Username atau Password salah.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 200,
                          child: Center(
                            child: Image.asset(
                              'assets/images/Mamorasoft.png',
                              width: 200,
                              height: 200,
                            ),
                          ),
                        ),
                        const Text('Selamat Datang Pecinta Buku!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Login untuk melanjutkan ke Mamorasoft Library',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline)),
                          validator: (value) => value!.isEmpty
                              ? 'Username tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Password tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return authProvider.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                        onPressed: _login,
                                        child: const Text('LOGIN',
                                            style: TextStyle(fontSize: 16))),
                                  );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Belum punya akun?"),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                              child: const Text('Daftar di sini'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
