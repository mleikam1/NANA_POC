import 'package:geocoding/geocoding.dart';

class LocationLabelHelper {
  LocationLabelHelper._();

  static final RegExp _coordinateLikeRegExp = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
  );

  static bool isCoordinateLikeLabel(String label) {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      return false;
    }

    if (_coordinateLikeRegExp.hasMatch(normalized)) {
      return true;
    }

    if (normalized.startsWith('Current location (') && normalized.endsWith(')')) {
      final inner = normalized.substring(
        'Current location ('.length,
        normalized.length - 1,
      );
      return _coordinateLikeRegExp.hasMatch(inner);
    }

    return false;
  }

  static String fallbackLatLngLabel(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  static String bestLabelFromProfile({
    required String locationLabel,
    required double? latitude,
    required double? longitude,
  }) {
    final trimmed = locationLabel.trim();
    if (trimmed.isNotEmpty && !isCoordinateLikeLabel(trimmed)) {
      return trimmed;
    }

    if (trimmed.isNotEmpty && (latitude == null || longitude == null)) {
      return trimmed;
    }

    return '';
  }

  static Future<String> reverseGeocodeLocationLabel({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return fallbackLatLngLabel(latitude, longitude);
      }

      final label = _formatPlacemarkLabel(placemarks.first);
      if (label.isEmpty) {
        return fallbackLatLngLabel(latitude, longitude);
      }
      return label;
    } catch (_) {
      return fallbackLatLngLabel(latitude, longitude);
    }
  }

  static String _formatPlacemarkLabel(Placemark placemark) {
    final locality = _pickFirstNonEmpty(<String?>[
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.subLocality,
      placemark.administrativeArea,
    ]);

    final countryCode = (placemark.isoCountryCode ?? '').toUpperCase();
    if (countryCode == 'US') {
      final usCity = _pickFirstNonEmpty(<String?>[
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.subLocality,
      ]);
      final usState = _pickFirstNonEmpty(<String?>[
        placemark.administrativeArea,
        placemark.country,
      ]);
      return _joinCityAndArea(usCity, usState);
    }

    final nonUsRegion = _pickFirstNonEmpty(<String?>[
      placemark.administrativeArea,
      placemark.country,
    ]);

    return _joinCityAndArea(locality, nonUsRegion);
  }

  static String _pickFirstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  static String _joinCityAndArea(String city, String area) {
    if (city.isNotEmpty && area.isNotEmpty) {
      if (city.toLowerCase() == area.toLowerCase()) {
        return city;
      }
      return '$city, $area';
    }
    if (city.isNotEmpty) {
      return city;
    }
    if (area.isNotEmpty) {
      return area;
    }
    return '';
  }
}
