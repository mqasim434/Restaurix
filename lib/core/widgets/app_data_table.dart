import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_empty_state.dart';
import 'app_pagination_bar.dart';

class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final Widget Function(BuildContext context, T row) cellBuilder;
  final int flex;
  final Alignment alignment;
}

class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyMessage = 'No data available',
    this.pageSize = 50,
    this.onRowTap,
  });

  final List<AppDataColumn<T>> columns;
  final List<T> rows;
  final String emptyMessage;

  /// Rows per page. Set to `null` to disable pagination entirely.
  final int? pageSize;

  /// Optional row tap handler (e.g. navigate to detail).
  final ValueChanged<T>? onRowTap;

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  var _pageIndex = 0;

  @override
  void didUpdateWidget(covariant AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pageCount = _pageCount;
    if (_pageIndex >= pageCount) {
      _pageIndex = pageCount > 0 ? pageCount - 1 : 0;
    }
  }

  int get _pageCount {
    final size = widget.pageSize;
    if (size == null || widget.rows.isEmpty) return 1;
    return (widget.rows.length / size).ceil();
  }

  List<T> get _visibleRows {
    final size = widget.pageSize;
    if (size == null || widget.rows.length <= size) {
      return widget.rows;
    }
    final start = _pageIndex * size;
    final end = (start + size).clamp(0, widget.rows.length);
    return widget.rows.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final radius = context.appRadius;
    final typography = context.appTypography;

    if (widget.rows.isEmpty) {
      return AppEmptyState(
        title: widget.emptyMessage,
        icon: Icons.table_rows_outlined,
      );
    }

    final visibleRows = _visibleRows;
    final pageSize = widget.pageSize;
    final showPagination =
        pageSize != null && widget.rows.length > pageSize;

    Widget buildTableBody({
      required bool bounded,
    }) {
      final rowList = ListView.separated(
        shrinkWrap: !bounded,
        physics: bounded ? null : const NeverScrollableScrollPhysics(),
        itemCount: visibleRows.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: colors.divider, indent: spacing.md),
        itemBuilder: (context, index) {
          final row = visibleRows[index];
          final content = Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: Row(
              children: [
                for (final column in widget.columns)
                  Expanded(
                    flex: column.flex,
                    child: Align(
                      alignment: column.alignment,
                      child: column.cellBuilder(context, row),
                    ),
                  ),
              ],
            ),
          );

          final onTap = widget.onRowTap;
          if (onTap == null) return content;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(row),
              child: content,
            ),
          );
        },
      );

      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius.mdBorder,
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius.md),
                ),
              ),
              child: Row(
                children: [
                  for (final column in widget.columns)
                    Expanded(
                      flex: column.flex,
                      child: Align(
                        alignment: column.alignment,
                        child: Text(
                          column.label,
                          style: typography.labelLarge.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            if (bounded) Expanded(child: rowList) else rowList,
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite;
        final table = buildTableBody(bounded: bounded);

        if (!showPagination) {
          return bounded ? table : table;
        }

        final pagination = AppPaginationBar(
          pageIndex: _pageIndex,
          pageCount: _pageCount,
          totalItems: widget.rows.length,
          pageSize: pageSize,
          onPrevious: _pageIndex > 0
              ? () => setState(() => _pageIndex -= 1)
              : null,
          onNext: _pageIndex < _pageCount - 1
              ? () => setState(() => _pageIndex += 1)
              : null,
        );

        if (bounded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: table),
              pagination,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            table,
            pagination,
          ],
        );
      },
    );
  }
}
