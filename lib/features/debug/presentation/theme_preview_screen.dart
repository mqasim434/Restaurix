import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_data_table.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';

class ThemePreviewScreen extends StatefulWidget {
  const ThemePreviewScreen({super.key});

  @override
  State<ThemePreviewScreen> createState() => _ThemePreviewScreenState();
}

class _ThemePreviewScreenState extends State<ThemePreviewScreen> {
  String? _dropdownValue;
  final _textController = TextEditingController(text: 'Sample input');

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Design System Preview',
          style: typography.titleLarge.copyWith(color: colors.onSurface),
        ),
        backgroundColor: colors.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Palette',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            _ColorSwatchGrid(),
            SizedBox(height: spacing.xxl),
            Text(
              'Typography',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            _TypographyPreview(),
            SizedBox(height: spacing.xxl),
            Text(
              'Buttons',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                AppButton(
                  label: 'Primary',
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Secondary',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Danger',
                  variant: AppButtonVariant.danger,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Ghost',
                  variant: AppButtonVariant.ghost,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Loading',
                  isLoading: true,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Very long button label that should truncate gracefully',
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: spacing.xxl),
            Text(
              'Form Controls',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            AppCard(
              title: 'Inputs',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _textController,
                    label: 'Text Field',
                    hint: 'Enter text...',
                  ),
                  SizedBox(height: spacing.md),
                  AppDropdown<String>(
                    label: 'Dropdown',
                    hint: 'Select an option',
                    value: _dropdownValue,
                    items: const ['Option A', 'Option B', 'Option C'],
                    itemLabel: (item) => item,
                    onChanged: (value) => setState(() => _dropdownValue = value),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xxl),
            Text(
              'Data Table',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            AppDataTable<_SampleRow>(
              columns: [
                AppDataColumn(
                  label: 'Name',
                  cellBuilder: (context, row) => Text(
                    row.name,
                    style: typography.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                ),
                AppDataColumn(
                  label: 'Category',
                  cellBuilder: (context, row) => Text(
                    row.category,
                    style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                AppDataColumn(
                  label: 'Price',
                  alignment: Alignment.centerRight,
                  cellBuilder: (context, row) => Text(
                    row.price,
                    style: typography.bodyMedium.copyWith(color: colors.onSurface),
                  ),
                ),
              ],
              rows: const [
                _SampleRow('Margherita Pizza', 'Pizza', '\$12.99'),
                _SampleRow('Caesar Salad', 'Salads', '\$8.50'),
                _SampleRow('Grilled Chicken', 'Mains', '\$15.00'),
              ],
            ),
            SizedBox(height: spacing.xxl),
            Text(
              'Feedback',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                AppButton(
                  label: 'Success Snackbar',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => AppSnackbar.success(
                    context,
                    'Operation completed successfully.',
                  ),
                ),
                AppButton(
                  label: 'Error Snackbar',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => AppSnackbar.error(
                    context,
                    'Something went wrong. Please try again.',
                  ),
                ),
                AppButton(
                  label: 'Info Snackbar',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => AppSnackbar.info(
                    context,
                    'New orders are waiting in the kitchen.',
                  ),
                ),
                AppButton(
                  label: 'Show Dialog',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => AppDialog.show(
                    context: context,
                    title: 'Confirm Action',
                    content: Text(
                      'Are you sure you want to proceed with this action?',
                      style: typography.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),
            Row(
              children: [
                Expanded(child: AppLoadingIndicator(message: 'Loading...')),
                Expanded(
                  child: AppEmptyState(
                    title: 'No items yet',
                    message: 'Add your first item to get started.',
                    actionLabel: 'Add Item',
                    onAction: () {},
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xxl),
            Text(
              'Spacing & Radius',
              style: typography.headlineSmall.copyWith(color: colors.onSurface),
            ),
            SizedBox(height: spacing.md),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.sm,
              children: [
                _SpacingDemo(label: 'xs', size: spacing.xs, color: colors.primary),
                _SpacingDemo(label: 'sm', size: spacing.sm, color: colors.secondary),
                _SpacingDemo(label: 'md', size: spacing.md, color: colors.primary),
                _SpacingDemo(label: 'lg', size: spacing.lg, color: colors.secondary),
                _SpacingDemo(label: 'xl', size: spacing.xl, color: colors.primary),
                _SpacingDemo(label: 'xxl', size: spacing.xxl, color: colors.secondary),
              ],
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                _RadiusDemo(label: 'sm', radius: radius.smBorder, color: colors.surfaceVariant),
                SizedBox(width: spacing.sm),
                _RadiusDemo(label: 'md', radius: radius.mdBorder, color: colors.surfaceVariant),
                SizedBox(width: spacing.sm),
                _RadiusDemo(label: 'lg', radius: radius.lgBorder, color: colors.surfaceVariant),
                SizedBox(width: spacing.sm),
                _RadiusDemo(label: 'full', radius: radius.fullBorder, color: colors.surfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleRow {
  const _SampleRow(this.name, this.category, this.price);

  final String name;
  final String category;
  final String price;
}

class _ColorSwatchGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    final swatches = <(String, Color, Color)>[
      ('Primary', colors.primary, colors.onPrimary),
      ('Secondary', colors.secondary, colors.onSecondary),
      ('Surface', colors.surface, colors.onSurface),
      ('Background', colors.background, colors.onBackground),
      ('Error', colors.error, colors.onError),
      ('Success', colors.success, colors.onSuccess),
      ('Warning', colors.warning, colors.onWarning),
      ('Border', colors.border, colors.onSurface),
      ('Divider', colors.divider, colors.onSurface),
    ];

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: swatches
          .map(
            (swatch) => _ColorSwatch(
              name: swatch.$1,
              color: swatch.$2,
              labelColor: swatch.$3,
              typography: typography,
            ),
          )
          .toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.labelColor,
    required this.typography,
  });

  final String name;
  final Color color;
  final Color labelColor;
  final AppTypographyTheme typography;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;
    final spacing = context.appSpacing;

    return SizedBox(
      width: spacing.xxl * 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: spacing.xxl + spacing.md,
            decoration: BoxDecoration(
              color: color,
              borderRadius: radius.mdBorder,
              border: Border.all(color: context.appColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: typography.labelMedium.copyWith(color: labelColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: typography.labelSmall.copyWith(
              color: context.appColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypographyPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    final styles = <(String, TextStyle)>[
      ('Display Large', typography.displayLarge),
      ('Display Medium', typography.displayMedium),
      ('Display Small', typography.displaySmall),
      ('Headline Large', typography.headlineLarge),
      ('Headline Medium', typography.headlineMedium),
      ('Headline Small', typography.headlineSmall),
      ('Title Large', typography.titleLarge),
      ('Title Medium', typography.titleMedium),
      ('Title Small', typography.titleSmall),
      ('Body Large', typography.bodyLarge),
      ('Body Medium', typography.bodyMedium),
      ('Body Small', typography.bodySmall),
      ('Label Large', typography.labelLarge),
      ('Label Medium', typography.labelMedium),
      ('Label Small', typography.labelSmall),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: styles
            .map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.$1,
                      style: typography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'The quick brown fox',
                      style: entry.$2.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SpacingDemo extends StatelessWidget {
  const _SpacingDemo({
    required this.label,
    required this.size,
    required this.color,
  });

  final String label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          color: color,
        ),
        SizedBox(height: context.appSpacing.xs),
        Text(
          label,
          style: typography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RadiusDemo extends StatelessWidget {
  const _RadiusDemo({
    required this.label,
    required this.radius,
    required this.color,
  });

  final String label;
  final BorderRadius radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return Column(
      children: [
        Container(
          width: spacing.xxl + spacing.lg,
          height: spacing.xxl,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(color: colors.border),
          ),
        ),
        SizedBox(height: spacing.xs),
        Text(
          label,
          style: typography.labelSmall.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
