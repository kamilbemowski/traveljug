import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_places_sdk/flutter_places_sdk.dart';

import 'package:travelapp/screens/map_picker_screen.dart';
import 'package:travelapp/services/geocoding_service.dart';

/// Mock Places service that returns canned results without calling the native SDK.
class MockPlacesService extends PlacesService {
  final List<AutocompletePrediction> Function(String query)? onAutocomplete;
  final PlaceDetails? Function(String placeId)? onDetails;
  final bool isAvailableOverride;

  MockPlacesService({
    this.onAutocomplete,
    this.onDetails,
    this.isAvailableOverride = true,
  }) : super(apiKey: 'test-key');

  @override
  bool get isAvailable => isAvailableOverride;

  @override
  Future<List<AutocompletePrediction>> autocomplete(String query) async {
    if (onAutocomplete != null) return onAutocomplete!(query);
    return [];
  }

  @override
  Future<PlaceDetails?> details(String placeId) async {
    if (onDetails != null) return onDetails!(placeId);
    return null;
  }
}

Widget buildTestWidget({String? searchQuery}) {
  return MaterialApp(
    home: MapPickerScreen(searchQuery: searchQuery),
  );
}

void main() {
  setUp(() {
    setTestPlacesService(MockPlacesService());
  });

  tearDown(() {
    clearTestPlacesService();
  });

  group('Search field', () {
    testWidgets('renders search field on map screen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      expect(find.text('Search for a place...'), findsOneWidget);
    });

    testWidgets('typing <3 chars shows no predictions', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Pa');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('typing 3+ chars triggers autocomplete', (tester) async {
      setTestPlacesService(MockPlacesService(
        onAutocomplete: (query) => [
          AutocompletePrediction(
            placeId: 'paris123',
            primaryText: 'Paris',
            secondaryText: 'France',
            fullText: 'Paris, France',
          ),
        ],
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Paris'), findsWidgets);
      expect(find.text('France'), findsOneWidget);
    });

    testWidgets('tapping result fetches details and sets pin', (tester) async {
      setTestPlacesService(MockPlacesService(
        onAutocomplete: (query) => [
          AutocompletePrediction(
            placeId: 'eiffel123',
            primaryText: 'Eiffel Tower',
            secondaryText: 'Paris, France',
            fullText: 'Eiffel Tower, Paris, France',
          ),
        ],
        onDetails: (placeId) => const PlaceDetails(
          name: 'Eiffel Tower',
          latitude: 48.8584,
          longitude: 2.2945,
        ),
      ));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Eiffel');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eiffel Tower'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'Eiffel Tower');
    });

    testWidgets('auto-searches when searchQuery is passed', (tester) async {
      setTestPlacesService(MockPlacesService(
        onAutocomplete: (query) => [
          AutocompletePrediction(
            placeId: 'eiffel123',
            primaryText: 'Eiffel Tower',
            secondaryText: 'Paris, France',
            fullText: 'Eiffel Tower, Paris, France',
          ),
        ],
      ));

      await tester.pumpWidget(buildTestWidget(searchQuery: 'Eiffel Tower'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Eiffel Tower'), findsWidgets);
    });
  });

  group('Error handling', () {
    testWidgets('shows error when autocomplete returns empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'xyzxyz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No places found.'), findsOneWidget);
    });

    testWidgets('shows error when API key is missing', (tester) async {
      setTestPlacesService(MockPlacesService(isAvailableOverride: false));

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.text('Places search not available. Enter coordinates manually.'),
        findsOneWidget,
      );
    });
  });
}
