import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format/money_format.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/dashboard.dart';
import '../../../../domain/models/sales_analytics.dart';
import '../../../settings/providers/currency_providers.dart';

class DashboardChartsSection extends ConsumerWidget {
  const DashboardChartsSection({
    super.key,
    required this.charts,
  });

  final DashboardChartsData charts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.appSpacing;
    final formatCompact = ref.watch(compactMoneyFormatProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 900;
        final chartWidth = twoColumn
            ? (constraints.maxWidth - spacing.lg) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing.lg,
          runSpacing: spacing.lg,
          children: [
            SizedBox(
              width: chartWidth,
              child: _ChartCard(
                title: 'Sales trend',
                subtitle: 'Net revenue — last 30 days',
                child: _SalesTrendChart(
                  points: charts.salesTrend,
                  formatCompact: formatCompact,
                ),
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: _ChartCard(
                title: 'Orders trend',
                subtitle: 'Order count — last 30 days',
                child: _OrdersTrendChart(points: charts.ordersTrend),
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: _ChartCard(
                title: 'Payment distribution',
                subtitle: 'Revenue by payment method — last 30 days',
                child: _PaymentPieChart(rows: charts.paymentDistribution),
              ),
            ),
            SizedBox(
              width: chartWidth,
              child: _ChartCard(
                title: 'Top products',
                subtitle: 'Best sellers — last 30 days',
                child: _TopProductsBarChart(products: charts.topProducts),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final typography = context.appTypography;
    final colors = context.appColors;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: typography.titleMedium),
            SizedBox(height: spacing.xs),
            Text(
              subtitle,
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.md),
            SizedBox(height: 240, child: child),
          ],
        ),
      ),
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({
    required this.points,
    required this.formatCompact,
  });

  final List<DashboardTrendPoint> points;
  final MoneyFormatter formatCompact;

  @override
  Widget build(BuildContext context) {
    if (!points.any((point) => point.sales > 0)) {
      return _EmptyChart(message: 'No sales in the last 30 days');
    }

    final colors = context.appColors;
    final maxY = points
        .map((point) => point.sales)
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, _) => Text(
                formatCompact(value),
                style: context.appTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                if (index % 5 != 0 && index != points.length - 1) {
                  return const SizedBox.shrink();
                }
                final day = points[index].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${day.month}/${day.day}',
                    style: context.appTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].sales),
            ],
            isCurved: true,
            color: colors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTrendChart extends StatelessWidget {
  const _OrdersTrendChart({required this.points});

  final List<DashboardTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (!points.any((point) => point.orders > 0)) {
      return _EmptyChart(message: 'No orders in the last 30 days');
    }

    final colors = context.appColors;
    final maxY = points
        .map((point) => point.orders.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: context.appTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) return const SizedBox.shrink();
                if (index % 5 != 0 && index != points.length - 1) {
                  return const SizedBox.shrink();
                }
                final day = points[index].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${day.month}/${day.day}',
                    style: context.appTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].orders.toDouble()),
            ],
            isCurved: true,
            color: colors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _PaymentPieChart extends StatelessWidget {
  const _PaymentPieChart({required this.rows});

  final List<PaymentMethodSalesRow> rows;

  @override
  Widget build(BuildContext context) {
    final activeRows = rows.where((row) => row.netRevenue > 0).toList();
    if (activeRows.isEmpty) {
      return _EmptyChart(message: 'No payment data yet');
    }

    final palette = _chartPalette(context);
    final total = activeRows.fold<double>(0, (sum, row) => sum + row.netRevenue);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < activeRows.length; i++)
                  PieChartSectionData(
                    value: activeRows[i].netRevenue,
                    color: palette[i % palette.length],
                    title: '',
                    radius: 72,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < activeRows.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: context.appSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: context.appSpacing.xs),
                      Expanded(
                        child: Text(
                          '${activeRows[i].label} '
                          '${((activeRows[i].netRevenue / total) * 100).toStringAsFixed(0)}%',
                          style: context.appTypography.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopProductsBarChart extends StatelessWidget {
  const _TopProductsBarChart({required this.products});

  final List<ProductSalesRow> products;

  @override
  Widget build(BuildContext context) {
    final activeProducts =
        products.where((product) => product.quantitySold > 0).toList();
    if (activeProducts.isEmpty) {
      return _EmptyChart(message: 'No product sales yet');
    }

    final colors = context.appColors;
    final maxY = activeProducts
        .map((product) => product.quantitySold.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: context.appTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= activeProducts.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _shortLabel(activeProducts[index].name),
                    style: context.appTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < activeProducts.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: activeProducts[i].quantitySold.toDouble(),
                  color: colors.primary,
                  width: 20,
                  borderRadius: context.appRadius.smBorder,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: context.appTypography.bodyMedium.copyWith(
          color: context.appColors.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

List<Color> _chartPalette(BuildContext context) {
  final colors = context.appColors;
  return [
    colors.primary,
    colors.secondary,
    colors.success,
    colors.warning,
    colors.primaryContainer,
  ];
}

String _shortLabel(String value) {
  if (value.length <= 10) return value;
  return '${value.substring(0, 9)}…';
}
