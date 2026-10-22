import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-AUTH-04 with the registration privacy notice (NFR-09).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.tenantId, required this.tenantName});

  final String tenantId;
  final String tenantName;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _number = TextEditingController();
  final _password = TextEditingController();
  String? _departmentId;
  int? _year;
  bool _agreed = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _number, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    setState(() => _errors = {});
    final ok = await runAction(
      context,
      () async {
        await app.auth.register(RegistrationDraft(
          tenantId: widget.tenantId,
          fullName: _name.text,
          email: _email.text,
          studentNumber: _number.text,
          departmentId: _departmentId,
          yearOfStudy: _year,
          password: _password.text,
        ));
        await app.auth.signIn(widget.tenantId, _email.text, _password.text);
      },
      onFieldErrors: (e) => setState(() => _errors = e),
    );
    if (ok && mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final departments = context.read<AppState>().auth.departmentsFor(widget.tenantId);
    return Scaffold(
      appBar: AppBar(title: const Text('Create student account')),
      body: Readable(child: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          Text(widget.tenantName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.l),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: 'Full name', errorText: _errors['fullName']),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Email', errorText: _errors['email']),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _number,
            decoration: InputDecoration(labelText: 'Student number', errorText: _errors['studentNumber']),
          ),
          const SizedBox(height: Space.m),
          DropdownButtonFormField<String>(
            initialValue: _departmentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Department', errorText: _errors['departmentId']),
            items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name))],
            onChanged: (v) => setState(() => _departmentId = v),
          ),
          const SizedBox(height: Space.m),
          DropdownButtonFormField<int>(
            initialValue: _year,
            decoration: InputDecoration(labelText: 'Year of study', errorText: _errors['yearOfStudy']),
            items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
            onChanged: (v) => setState(() => _year = v),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'At least 8 characters',
              errorText: _errors['password'],
            ),
          ),
          const SizedBox(height: Space.l),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy notice', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Space.s),
                  const Text(
                    'This is a demonstration app. Do not enter real personal details. Your institution sees your '
                    'name, student number and loans. Usage reports only count searches, views and quizzes; they '
                    'never show your name. ZutLib never asks for your NRC or any ID document.',
                  ),
                ],
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: const Text('I have read the privacy notice'),
          ),
          const SizedBox(height: Space.s),
          FilledButton(onPressed: _agreed ? _submit : null, child: const Text('Create account')),
        ],
      )),
    );
  }
}
