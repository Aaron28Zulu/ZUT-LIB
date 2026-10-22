import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';

/// Three-screen walkthrough on first launch (NFR-05).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.search,
      'Find past papers',
      'Search by course code, name or topic, or browse by department, course and year. Open any paper on your phone.',
    ),
    (
      Icons.qr_code_2,
      'Borrow printed copies',
      'Request a copy in the app. When the librarian approves it, show the collection code at the desk. No ID card needed.',
    ),
    (
      Icons.school_outlined,
      'Revise with a plan',
      'Practise with quizzes and flashcards built from past papers, and follow a revision plan based on your exam dates.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<AppState>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final (icon, title, body) in _pages)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Space.xxl),
                          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: Space.xl),
                          Text(title, style: t.headlineSmall),
                          const SizedBox(height: Space.m),
                          Text(body, style: t.bodyLarge),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Row(
                children: [
                  Text('${_page + 1} of ${_pages.length}', style: t.labelLarge),
                  const Spacer(),
                  FilledButton(
                    onPressed: last
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            ),
                    child: Text(last ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
