import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/widgets/app_data_table.dart';
import 'package:restaurix/core/widgets/app_pagination_bar.dart';

void main() {
  testWidgets('AppDataTable paginates large datasets', (tester) async {
    final rows = List.generate(120, (index) => 'Row $index');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            width: 600,
            child: AppDataTable<String>(
              pageSize: 50,
              columns: [
                AppDataColumn(
                  label: 'Name',
                  cellBuilder: (_, row) => Text(row),
                ),
              ],
              rows: rows,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Row 0'), findsOneWidget);
    expect(find.text('Row 50'), findsNothing);
    expect(find.text('Page 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Row 50'), findsOneWidget);
    expect(find.text('Row 0'), findsNothing);
    expect(find.text('Page 2 of 3'), findsOneWidget);
  });

  testWidgets('AppPaginationBar hides when not needed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPaginationBar(
            pageIndex: 0,
            pageCount: 1,
            totalItems: 10,
            pageSize: 50,
            onPrevious: null,
            onNext: null,
          ),
        ),
      ),
    );

    expect(find.text('Previous'), findsNothing);
    expect(find.text('Next'), findsNothing);
  });
}
