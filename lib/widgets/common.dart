import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Keeps page content at a readable line length on tablets and desktops and
/// centres it, the way course platforms frame their catalogue pages.
class Readable extends StatelessWidget {
  const Readable({super.key, required this.child, this.maxWidth = Breakpoints.readable});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Empty list state: one icon, one sentence, one action (design conventions).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message, this.actionLabel, this.onAction});

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
            ExcludeSemantics(child: Icon(icon, size: 36, color: scheme.onSurfaceVariant)),
            const SizedBox(height: Space.l),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Space.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section title in the serif heading face, with an optional "See all" style
/// action on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.s, Space.s),
      child: Row(
        crossAxisAlignment: subtitle == null ? CrossAxisAlignment.center : CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.titleLarge),
                  if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppText.muted(context))],
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A large page heading with an optional line under it. Used at the top of
/// tabs, the way course platforms open a page ("Welcome back, Ana").
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.subtitle, this.leading});

  final String title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Space.m)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: t.headlineSmall)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: Space.xs),
                  Text(subtitle!, style: AppText.muted(context)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loan status tag. Colour is a supporting signal only: every status also has
/// its own icon and its label (design conventions, "Colour").
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (fg, bg, icon) = switch (status) {
      LoanStatus.requested => (p.warning, p.warningBg, AppIcons.pending),
      LoanStatus.approved => (p.info, p.infoBg, AppIcons.qr),
      LoanStatus.collected => (p.success, p.successBg, AppIcons.paper),
      LoanStatus.overdue => (p.danger, p.dangerBg, AppIcons.warning),
      LoanStatus.rejected || LoanStatus.expired => (p.danger, p.dangerBg, AppIcons.cancelled),
      LoanStatus.returned => (p.neutral, p.neutralBg, AppIcons.done),
      LoanStatus.cancelled => (p.neutral, p.neutralBg, AppIcons.cancelled),
    };
    return Tag(status.label, icon: icon, foreground: fg, background: bg);
  }
}

/// Flat label with an optional icon, for statuses, paper types and counts.
class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.icon, this.foreground, this.background});

  final String label;
  final IconData? icon;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fg = foreground ?? p.neutral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: background ?? p.neutralBg, borderRadius: Radii.tagRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 13, color: fg)),
            const SizedBox(width: Space.xs),
          ],
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// Tenant logo placeholder: short code on the tenant colour. This badge is
/// where each institution's own colour appears (FR-TEN-04).
class TenantMark extends StatelessWidget {
  const TenantMark(this.tenant, {super.key, this.size = 40});

  final Tenant tenant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colour = Color(tenant.colourValue);
    final onColour = ThemeData.estimateBrightnessForColor(colour) == Brightness.dark
        ? AppPalette.of(context).onBrand
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: '${tenant.name} logo',
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colour, borderRadius: Radii.tagRadius),
        child: ExcludeSemantics(child: Text(tenant.shortCode, style: AppText.badge(onColour, size))),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 132, child: Text(label, style: AppText.muted(context))),
          Expanded(
            child: Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Label, percentage and a flat bar. Used for quiz scores, plan progress and
/// topic strengths, so progress always reads the same way.
class ProgressRow extends StatelessWidget {
  const ProgressRow({super.key, required this.label, required this.value, this.caption, this.colour});

  final String label;

  /// 0..1
  final double value;
  final String? caption;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).round();
    return Semantics(
      label: '$label, $pct percent${caption == null ? '' : ', $caption'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text('$pct%', style: AppText.code(context)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: Radii.tagRadius,
              child: LinearProgressIndicator(value: v, color: colour),
            ),
            if (caption != null) ...[
              const SizedBox(height: Space.xs),
              Text(caption!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

/// A number with its label, for dashboards. Only for figures someone acts on.
/// Flat panel with a hairline border; a highlighted figure gets a coloured
/// border and a warning icon, not just a colour.
class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, {super.key, this.highlight = false, this.onTap});

  final String label;
  final int value;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final p = AppPalette.of(context);
    final alert = highlight && value > 0;
    return Material(
      color: alert ? p.dangerBg : s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.controlRadius,
        side: BorderSide(color: alert ? p.danger : s.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(label, style: AppText.muted(context))),
                  if (alert) ExcludeSemantics(child: Icon(AppIcons.warning, size: 16, color: p.danger)),
                  if (onTap != null && !alert)
                    ExcludeSemantics(child: Icon(AppIcons.next, size: 16, color: s.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: Space.s),
              Text('$value', style: AppText.figure(context).copyWith(color: alert ? p.danger : null)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays stat tiles out in a grid: two columns on phones, four on wide screens,
/// one when text is very large.
class StatGrid extends StatelessWidget {
  const StatGrid(this.children, {super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: Space.screen,
      child: LayoutBuilder(
        builder: (context, c) {
          var cols = c.maxWidth >= Breakpoints.medium ? 4 : 2;
          if (scale > 1.6) cols = 1;
          final width = (c.maxWidth - Space.s * (cols - 1)) / cols;
          return Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [for (final child in children) SizedBox(width: width, child: child)],
          );
        },
      ),
    );
  }
}

/// Flat tinted rectangle standing in for a paper's cover, like a course
/// thumbnail. The tint is picked from the course code so a shelf scans by
/// colour, and the code is printed on it so colour is never the only cue.
class PaperThumb extends StatelessWidget {
  const PaperThumb({
    super.key,
    required this.code,
    required this.caption,
    this.width = Sizes.thumbWidth,
    this.height = Sizes.thumbHeight,
  });

  final String code;
  final String caption;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final large = width > Sizes.thumbWidth * 1.5;
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(large ? Space.m : Space.s),
        decoration: BoxDecoration(color: p.thumbFor(code), borderRadius: Radii.tagRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.paper, size: large ? 20 : 14, color: p.thumbInk),
            // The code sits at the bottom; at large text it clips rather than
            // overflowing, since the thumb is decorative and the row repeats it.
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Text(code, style: AppText.thumb(context, p.thumbInk, large: large), maxLines: 2),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.thumbInk),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of items under a section header, like the
/// "Recommended for you" shelves on course platforms.
class Shelf extends StatelessWidget {
  const Shelf({super.key, required this.children, this.itemWidth = Sizes.shelfCardWidth});

  final List<Widget> children;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: Space.screen,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(width: Space.m),
              SizedBox(width: itemWidth, child: c),
            ],
          ],
        ),
      ),
    );
  }
}

/// Flat bordered panel for grouping detail content.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(Space.l), this.colour});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    // A Material, not a DecoratedBox, so list tiles inside keep their ink.
    return Material(
      color: colour ?? s.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.controlRadius,
        side: BorderSide(color: s.outlineVariant),
      ),
      child: Padding(
        padding: padding,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
