import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'institution_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.tenantId, required this.tenantName, this.tenant});

  final String tenantId;
  final String tenantName;
  final Tenant? tenant;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn(String email, String password) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppState>().auth.signIn(widget.tenantId, email, password);
      if (mounted) context.read<AppState>().runScheduledJobs();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final demo = app.auth.demoAccounts(widget.tenantId);
    final t = Theme.of(context).textTheme;
    final isPlatform = widget.tenantId == platformTenantId;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in'), actions: const [
        Padding(padding: EdgeInsets.only(right: Space.l), child: DemoModeBanner()),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.l),
          children: [
            Row(
              children: [
                if (widget.tenant != null) ...[TenantMark(widget.tenant!), const SizedBox(width: Space.m)],
                Expanded(child: Text(widget.tenantName, style: t.titleMedium)),
              ],
            ),
            const SizedBox(height: Space.xl),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: Space.m),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _signIn(_email.text, _password.text),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _error,
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.l),
            FilledButton(
              onPressed: _busy ? null : () => _signIn(_email.text, _password.text),
              child: const Text('Sign in'),
            ),
            if (!isPlatform) ...[
              const SizedBox(height: Space.s),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(tenantId: widget.tenantId, tenantName: widget.tenantName),
                  ),
                ),
                child: const Text('New student? Create an account'),
              ),
            ],
            if (demo.isNotEmpty) ...[
              const SizedBox(height: Space.xl),
              Text('Quick demo sign-in', style: t.titleSmall),
              const SizedBox(height: Space.xs),
              Text('Fictional accounts. Password for all: demo1234', style: t.bodySmall),
              const SizedBox(height: Space.s),
              Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  for (final a in demo)
                    OutlinedButton(
                      onPressed: _busy ? null : () => _signIn(a.email, 'demo1234'),
                      child: Text('${a.role.label}: ${a.name}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
