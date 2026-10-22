import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Empty list state: one icon, one sentence, one action (design conventions).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: Space.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Space.l),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.s, Space.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Fixed semantic colours per loan status (design conventions, "Colour").
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      LoanStatus.requested => (s.secondaryContainer, s.onSecondaryContainer),
      LoanStatus.approved => (s.primaryContainer, s.onPrimaryContainer),
      LoanStatus.collected => (s.tertiaryContainer, s.onTertiaryContainer),
      LoanStatus.overdue || LoanStatus.rejected || LoanStatus.expired => (s.errorContainer, s.onErrorContainer),
      LoanStatus.returned || LoanStatus.cancelled => (s.surfaceContainerHighest, s.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}

/// Tenant logo placeholder: short code on the tenant colour (design conventions).
class TenantMark extends StatelessWidget {
  const TenantMark(this.tenant, {super.key, this.size = 40});

  final Tenant tenant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = Color(tenant.colourValue);
    final onColour = ThemeData.estimateBrightnessForColor(colour) == Brightness.dark ? Colors.white : Colors.black;
    return Semantics(
      label: '${tenant.name} logo',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(size / 5)),
        child: Text(
          tenant.shortCode,
          style: TextStyle(color: onColour, fontWeight: FontWeight.w700, fontSize: size * 0.3),
        ),
      ),
    );
  }
}

/// Label-value row for detail panels.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: t.bodyMedium)),
        ],
      ),
    );
  }
}

/// A number with its label, for dashboards. Only for figures someone acts on.
class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, {super.key, this.highlight = false, this.onTap});

  final String label;
  final int value;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      color: highlight && value > 0 ? s.errorContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value', style: t.headlineSmall),
              const SizedBox(height: Space.xs),
              Text(label, style: t.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays stat tiles out in two columns that wrap at large text sizes.
class StatGrid extends StatelessWidget {
  const StatGrid(this.children, {super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Space.screen,
      child: LayoutBuilder(builder: (context, c) {
        final width = (c.maxWidth - Space.s) / 2;
        return Wrap(
          spacing: Space.s,
          runSpacing: Space.s,
          children: [for (final child in children) SizedBox(width: width, child: child)],
        );
      }),
    );
  }
}
