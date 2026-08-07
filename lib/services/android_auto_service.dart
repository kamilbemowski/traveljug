import 'package:flutter/foundation.dart';
import 'package:flutter_carplay/flutter_carplay.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/timeline_day.dart';

/// Builds Android Auto templates from timeline data and pushes them
/// to the car head unit via flutter_carplay.
class AndroidAutoService {
  AndroidAutoService._();

  /// Builds a list of today's attractions for Android Auto.
  static Future<void> showTodayPlan(TimelineDay today) async {
    final items = <AAListItem>[];

    for (final slot in today.slots) {
      final a = slot.attraction;
      final prefix = slot.isMustHave ? '★ ' : ''; // ★
      final title = '$prefix${a.name}';
      final travelText =
          slot.travelFromPrevMin != null ? ' ← ${slot.travelFromPrevMin} min' : '';
      final subtitle = '${slot.startTime}$travelText · ${a.category}';

      // Navigate action — only if coordinates are available.
      void Function(Function() complete, AAListItem self)? onPress;
      if (a.latitude != null && a.longitude != null) {
        final lat = a.latitude!;
        final lon = a.longitude!;
        onPress = (complete, self) {
          _openInMaps(lat, lon);
          complete();
        };
      }

      items.add(AAListItem(
        title: title,
        subtitle: subtitle,
        onPress: onPress,
      ));
    }

    await FlutterAndroidAuto.setRootTemplate(
      template: AAListTemplate(
        title: 'Today\'s Plan',
        sections: [
          AAListSection(items: items),
        ],
      ),
    );
  }

  /// Shows a message when there are no attractions planned for today.
  static Future<void> showNoAttractionsMessage(String tripName) async {
    await FlutterAndroidAuto.setRootTemplate(
      template: AAMessageTemplate(
        title: tripName,
        message: 'No attractions planned for today. Open the app to add some.',
      ),
    );
  }

  /// Shows a message when there are no trips at all.
  static Future<void> showNoTripsMessage() async {
    await FlutterAndroidAuto.setRootTemplate(
      template: AAMessageTemplate(
        title: 'TravelJug',
        message: 'No trips yet. Create one in the app.',
      ),
    );
  }

  /// Shows a message when the selected trip has no dates.
  static Future<void> showNoDatesMessage(String tripName) async {
    await FlutterAndroidAuto.setRootTemplate(
      template: AAMessageTemplate(
        title: tripName,
        message: 'Add trip dates in the app to see your plan.',
      ),
    );
  }

  /// Opens Google Maps with coordinates for navigation.
  static Future<void> _openInMaps(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lon');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('AndroidAuto: failed to open maps: $e');
    }
  }

}
