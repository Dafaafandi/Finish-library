import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final Map<String, dynamic> result = await _apiService.register(
            _nameController.text,
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
            _confirmPasswordController.text);
        setState(() => _isLoading = false);
        if (!mounted) return;
        // Cek success dari API, fallback ke status jika tidak ada
        bool success = false;
        if (result.containsKey('success')) {
          success = result['success'] == true;
        } else if (result.containsKey('status')) {
          final status = result['status'];
          success = status == 200 || status == 201;
        }
        final String message = result['message']?.toString() ?? '';
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message.isNotEmpty
                    ? message
                    : 'Registrasi berhasil! Silakan login.')),
          );
          if (mounted) Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message.isNotEmpty
                    ? message
                    : 'Registrasi Gagal! Coba lagi.')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Buat Akun Anda',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Nama tidak boleh kosong'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Username tidak boleh kosong'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v == null || v.isEmpty || !v.contains('@')
                      ? 'Email tidak valid'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v == null || v.length < 8
                      ? 'Password minimal 8 karakter'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password',
                      prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != _passwordController.text
                      ? 'Password tidak cocok'
                      : null),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      child:
                          const Text('DAFTAR', style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}
