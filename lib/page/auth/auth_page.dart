import 'package:flutter/material.dart';
import 'package:chatmcp/echo/auth_service.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onAuthenticated;
  const AuthPage({super.key, required this.onAuthenticated});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = false;
  String? _error;

  // Login fields
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();

  // Register fields
  final _regEmail = TextEditingController();
  final _regUsername = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  bool _obscureLogin = true;
  bool _obscureReg = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regUsername.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.trim().isEmpty || _loginPassword.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService().login(
      email: _loginEmail.text.trim(),
      password: _loginPassword.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onAuthenticated();
    }
  }

  Future<void> _register() async {
    if (_regEmail.text.trim().isEmpty || _regUsername.text.trim().isEmpty || _regPassword.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }
    if (_regPassword.text != _regConfirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_regPassword.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await AuthService().register(
      email: _regEmail.text.trim(),
      username: _regUsername.text.trim(),
      password: _regPassword.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / brand
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.psychology_alt, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Echo',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Your personal AI companion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Tab bar
                          TabBar(
                            controller: _tabs,
                            tabs: const [Tab(text: 'Sign In'), Tab(text: 'Create Account')],
                            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 24),

                          // Tab views
                          SizedBox(
                            height: _tabs.index == 0 ? 200 : 280,
                            child: TabBarView(
                              controller: _tabs,
                              children: [_buildLogin(), _buildRegister()],
                            ),
                          ),

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, size: 16, color: theme.colorScheme.onErrorContainer),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Action button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _loading ? null : (_tabs.index == 0 ? _login : _register),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(_tabs.index == 0 ? 'Sign In' : 'Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your data stays on your device.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _field(
          controller: _loginEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onSubmit: (_) => _login(),
        ),
        const SizedBox(height: 12),
        _field(
          controller: _loginPassword,
          label: 'Password',
          icon: Icons.lock_outlined,
          obscure: _obscureLogin,
          toggleObscure: () => setState(() => _obscureLogin = !_obscureLogin),
          onSubmit: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildRegister() {
    return Column(
      children: [
        _field(
          controller: _regEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _regUsername,
          label: 'Username',
          icon: Icons.person_outlined,
        ),
        const SizedBox(height: 10),
        _field(
          controller: _regPassword,
          label: 'Password',
          icon: Icons.lock_outlined,
          obscure: _obscureReg,
          toggleObscure: () => setState(() => _obscureReg = !_obscureReg),
        ),
        const SizedBox(height: 10),
        _field(
          controller: _regConfirm,
          label: 'Confirm Password',
          icon: Icons.lock_outlined,
          obscure: _obscureReg,
          onSubmit: (_) => _register(),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    void Function(String)? onSubmit,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: toggleObscure,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }
}
