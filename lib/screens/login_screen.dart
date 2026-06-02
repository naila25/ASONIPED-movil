import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final resp = await ApiService.post(Endpoints.login, body: {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
      }, auth: false);

      if (resp.statusCode != 200) {
        final msg = resp.body.isNotEmpty ? resp.body : 'Login failed';
        setState(() { _error = msg; _loading = false; });
        return;
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);
      final token = data['token'] as String?;
      if (token == null) {
        setState(() { _error = 'Invalid server response'; _loading = false; });
        return;
      }

      final rolesData = data['user']?['roles'] ?? data['roles'];
      final List<String> roles = [];
      if (rolesData is String) {
        roles.add(rolesData);
      } else if (rolesData is Iterable) {
        roles.addAll(rolesData.whereType<String>());
      }

      if (!roles.contains('admin')) {
        setState(() {
          _error = 'Acceso restringido: solo usuarios con rol administrador pueden ingresar.';
          _loading = false;
        });
        return;
      }

      await AuthService.saveToken(token);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0C1324);
    const panelColor = Color(0xFF121B2F);
    const fieldColor = Color(0xFF1A2437);
    const accentColor = Color(0xFF1D4FF2);
    const accentEndColor = Color(0xFF0EA5D8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF10192A), Color(0xFF0C1324)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: panelColor),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2D7DFF),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'A',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Asoniped Digital',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 30, 18, 22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  '¡Bienvenido!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                    children: [
                                      TextSpan(text: 'Donde la inclusión\n'),
                                      TextSpan(
                                        text: 'encuentra el futuro.',
                                        style: TextStyle(color: Color(0xFF28B7E5)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Accede a tu cuenta personal de ASONIPED.',
                                  style: TextStyle(
                                    color: Color(0xFFB8C2D9),
                                    fontSize: 16,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: accentEndColor,
                                  decoration: InputDecoration(
                                    hintText: 'Usuario',
                                    hintStyle: const TextStyle(color: Color(0xFF8390A8)),
                                    filled: true,
                                    fillColor: fieldColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2A3550)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2D7DFF), width: 1.4),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: accentEndColor,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    hintStyle: const TextStyle(color: Color(0xFF8390A8)),
                                    filled: true,
                                    fillColor: fieldColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2A3550)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color(0xFF2D7DFF), width: 1.4),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 18),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(color: Colors.redAccent, height: 1.2),
                                    ),
                                  ),
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [accentColor, accentEndColor],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x332D7DFF),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      disabledBackgroundColor: Colors.transparent,
                                      disabledForegroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'CONECTAR',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '¿Olvidó su contraseña?',
                                    style: TextStyle(
                                      color: Color(0xFF79B9F4),
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFF79B9F4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
