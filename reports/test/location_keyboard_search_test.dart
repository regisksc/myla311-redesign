import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as gc;
import 'package:reports/features/report/presentation/location_map.dart';

void main() {
  testWidgets(
    'keyboard Search selects the address immediately without duplicate lookup',
    (tester) async {
      final original = gc.GeocodingPlatformFactory.instance;
      final lookup = _Lookup();
      gc.GeocodingPlatformFactory.instance = _LookupFactory(lookup);
      if (original != null) {
        addTearDown(() => gc.GeocodingPlatformFactory.instance = original);
      }
      final selected = <({double latitude, double longitude})>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationMap(
              position: null,
              enabled: true,
              onSelected: selected.add,
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('report-address')),
        '200 N Spring St',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(lookup.requests, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(lookup.requests, ['200 N Spring St, Los Angeles, CA']);
      expect(find.text('Searching…'), findsOneWidget);
      expect(selected, isEmpty);
      lookup.pending.complete([
        gc.Location(latitude: 34.053722, longitude: -118.242810),
      ]);
      await tester.pumpAndSettle();
      expect(selected, [(latitude: 34.053722, longitude: -118.242810)]);
      expect(find.text('Searching…'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(lookup.requests, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}

class _Lookup extends gc.Geocoding {
  _Lookup() : super.implementation(const gc.GeocodingCreationParams());
  final requests = <String>[];
  final pending = Completer<List<gc.Location>>();
  @override
  Future<List<gc.Location>> locationFromAddress(
    String address, {
    Locale? locale,
  }) {
    requests.add(address);
    return pending.future;
  }
}

class _LookupFactory extends gc.GeocodingPlatformFactory {
  _LookupFactory(this.lookup);
  final _Lookup lookup;
  @override
  gc.Geocoding createGeocoding(gc.GeocodingCreationParams params) => lookup;
}
