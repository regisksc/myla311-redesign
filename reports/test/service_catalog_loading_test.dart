import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reports/features/services/service_catalog_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'resident searches while catalog loads and sees matching services',
    (tester) async {
      const savedReport =
          '{"description":"Saved Report","state":"submitted",'
          '"serviceRequestNumber":"C-04955177"}';
      SharedPreferences.setMockInitialValues({
        'reports_v2': [savedReport],
      });
      final read = Completer<List<Map<String, dynamic>>>();
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceCatalogPage(
            onIllegalDumping: () {},
            loadCatalog: () => read.future,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'dumping');
      await tester.pump();
      expect(find.text('Loading services…'), findsOneWidget);
      expect(find.text('No services found'), findsNothing);
      read.complete([
        {
          'name': 'Illegal Dumping Item Pickup',
          'group': 'Public Rights of Way',
        },
        {'name': 'Graffiti Removal', 'group': 'Public Rights of Way'},
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Loading services…'), findsNothing);
      expect(find.widgetWithText(TextField, 'dumping'), findsOneWidget);
      expect(find.text('Illegal Dumping Item Pickup'), findsOneWidget);
      expect(find.text('Graffiti Removal'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getStringList('reports_v2'),
        [savedReport],
      );
    },
  );
}
