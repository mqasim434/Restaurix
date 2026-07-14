import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/deal.dart';
import 'deal_items_tab.dart';

class DealFormResult {
  const DealFormResult({
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.categoryId,
    required this.isAvailable,
    this.availabilityStart,
    this.availabilityEnd,
    this.clearDescription = false,
    this.clearImage = false,
    this.clearCategoryId = false,
    this.clearAvailabilityStart = false,
    this.clearAvailabilityEnd = false,
  });

  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final bool isAvailable;
  final DateTime? availabilityStart;
  final DateTime? availabilityEnd;
  final bool clearDescription;
  final bool clearImage;
  final bool clearCategoryId;
  final bool clearAvailabilityStart;
  final bool clearAvailabilityEnd;
}

class DealFormDialog extends StatefulWidget {
  const DealFormDialog({
    super.key,
    required this.categories,
    this.deal,
  });

  final List<Category> categories;
  final Deal? deal;

  static Future<DealFormResult?> show(
    BuildContext context, {
    required List<Category> categories,
    Deal? deal,
  }) {
    return showDialog<DealFormResult>(
      context: context,
      builder: (context) => DealFormDialog(categories: categories, deal: deal),
    );
  }

  @override
  State<DealFormDialog> createState() => _DealFormDialogState();
}

class _DealFormDialogState extends State<DealFormDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  String? _categoryId;
  String? _imagePath;
  late bool _isAvailable;
  bool _clearedImage = false;
  DateTime? _availabilityStart;
  DateTime? _availabilityEnd;
  bool _useAvailabilityWindow = false;

  bool get _isEditing => widget.deal != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController = TextEditingController(text: widget.deal?.name ?? '');
    _priceController = TextEditingController(
      text: widget.deal != null ? widget.deal!.price.toStringAsFixed(2) : '',
    );
    _descriptionController =
        TextEditingController(text: widget.deal?.description ?? '');
    _categoryId = widget.deal?.categoryId;
    _imagePath = widget.deal?.imageUrl;
    _isAvailable = widget.deal?.isAvailable ?? true;
    _availabilityStart = widget.deal?.availabilityStart;
    _availabilityEnd = widget.deal?.availabilityEnd;
    _useAvailabilityWindow =
        _availabilityStart != null || _availabilityEnd != null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final typography = context.appTypography;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Deal' : 'Add Deal',
        style: typography.titleLarge.copyWith(color: colors.onSurface),
      ),
      content: SizedBox(
        width: spacing.xxl * 9,
        height: spacing.xxl * 9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Bundle Items'),
              ],
            ),
            SizedBox(height: spacing.md),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(context),
                  _buildItemsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: _isEditing ? 'Save' : 'Add',
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;
    final dateFormat = DateFormat('MMM d, y · h:mm a');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'Deal name',
            hint: 'e.g. Lunch Combo',
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _priceController,
            label: 'Bundle price',
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: spacing.xs),
          Text(
            'Set explicitly — not calculated from component prices.',
            style: typography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          ),
          SizedBox(height: spacing.md),
          AppTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Optional',
            maxLines: 3,
          ),
          SizedBox(height: spacing.md),
          AppDropdown<String?>(
            label: 'POS category (optional)',
            value: _categoryId,
            items: [null, ...widget.categories.map((c) => c.id)],
            itemLabel: (id) {
              if (id == null) return 'Deals section only';
              return widget.categories.firstWhere((c) => c.id == id).name;
            },
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          SizedBox(height: spacing.md),
          Text(
            'Image',
            style: typography.labelLarge.copyWith(color: colors.onSurface),
          ),
          SizedBox(height: spacing.xs),
          Row(
            children: [
              _DealImageThumb(path: _imagePath),
              SizedBox(width: spacing.md),
              Wrap(
                spacing: spacing.sm,
                children: [
                  AppButton(
                    label: 'Choose file',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.small,
                    onPressed: _pickImage,
                  ),
                  if (_imagePath != null)
                    AppButton(
                      label: 'Remove',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      onPressed: () => setState(() {
                        _imagePath = null;
                        _clearedImage = true;
                      }),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Available',
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
            ),
            subtitle: Text(
              'Manual toggle — effective availability also depends on bundle items and schedule',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Time-limited availability',
              style: typography.bodyMedium.copyWith(color: colors.onSurface),
            ),
            subtitle: Text(
              'e.g. lunch specials with a start and end time',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            value: _useAvailabilityWindow,
            onChanged: (value) => setState(() {
              _useAvailabilityWindow = value;
              if (!value) {
                _availabilityStart = null;
                _availabilityEnd = null;
              }
            }),
          ),
          if (_useAvailabilityWindow) ...[
            SizedBox(height: spacing.sm),
            _DateTimePickerRow(
              label: 'Available from',
              value: _availabilityStart,
              onPick: () => _pickDateTime(isStart: true),
              onClear: () => setState(() => _availabilityStart = null),
              formatted: _availabilityStart == null
                  ? 'Not set'
                  : dateFormat.format(_availabilityStart!),
            ),
            SizedBox(height: spacing.sm),
            _DateTimePickerRow(
              label: 'Available until',
              value: _availabilityEnd,
              onPick: () => _pickDateTime(isStart: false),
              onClear: () => setState(() => _availabilityEnd = null),
              formatted: _availabilityEnd == null
                  ? 'Not set'
                  : dateFormat.format(_availabilityEnd!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsTab(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    if (!_isEditing || widget.deal == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Text(
            'Save the deal first, then edit it to add bundle items.',
            style: typography.bodyMedium.copyWith(color: colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return DealItemsTab(dealId: widget.deal!.id);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _imagePath = result.files.single.path;
      _clearedImage = false;
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart
        ? (_availabilityStart ?? DateTime.now())
        : (_availabilityEnd ?? DateTime.now().add(const Duration(hours: 2)));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _availabilityStart = combined;
      } else {
        _availabilityEnd = combined;
      }
    });
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < 0) return;

    final hadStart = widget.deal?.availabilityStart != null;
    final hadEnd = widget.deal?.availabilityEnd != null;

    Navigator.of(context).pop(
      DealFormResult(
        name: name,
        price: price,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: _imagePath,
        categoryId: _categoryId,
        isAvailable: _isAvailable,
        availabilityStart: _useAvailabilityWindow ? _availabilityStart : null,
        availabilityEnd: _useAvailabilityWindow ? _availabilityEnd : null,
        clearDescription: _descriptionController.text.trim().isEmpty && _isEditing,
        clearImage: _clearedImage,
        clearCategoryId: _categoryId == null && _isEditing,
        clearAvailabilityStart:
            !_useAvailabilityWindow && (_isEditing && hadStart),
        clearAvailabilityEnd: !_useAvailabilityWindow && (_isEditing && hadEnd),
      ),
    );
  }
}

class _DateTimePickerRow extends StatelessWidget {
  const _DateTimePickerRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    required this.formatted,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String formatted;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: typography.labelLarge.copyWith(color: colors.onSurface),
              ),
              SizedBox(height: spacing.xs),
              Text(
                formatted,
                style: typography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Pick',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.small,
          onPressed: onPick,
        ),
        if (value != null) ...[
          SizedBox(width: spacing.sm),
          AppButton(
            label: 'Clear',
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            onPressed: onClear,
          ),
        ],
      ],
    );
  }
}

class _DealImageThumb extends StatelessWidget {
  const _DealImageThumb({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final radius = context.appRadius;
    final spacing = context.appSpacing;
    final size = spacing.xxl + spacing.md;

    if (path != null && File(path!).existsSync()) {
      return ClipRRect(
        borderRadius: radius.mdBorder,
        child: Image.file(
          File(path!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context, size),
        ),
      );
    }

    return _placeholder(context, size);
  }

  Widget _placeholder(BuildContext context, double size) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: radius.mdBorder,
        border: Border.all(color: colors.border),
      ),
      child: Icon(Icons.local_offer_outlined, color: colors.onSurfaceVariant),
    );
  }
}
