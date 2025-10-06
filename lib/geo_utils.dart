import 'dart:io';
import 'package:exif/exif.dart';
import 'country_bounds.dart';

class GeoUtils {
  static Future<String?> getCountryForImage(File imageFile, Map<String, String?> cache) async {
    final filePath = imageFile.path;

    // Проверяем кэш
    if (cache.containsKey(filePath)) {
      return cache[filePath];
    }

    // Получаем GPS координаты
    final gps = await _getExifGPS(imageFile);
    if (gps == null || gps.$1 == null || gps.$2 == null) {
      cache[filePath] = null;
      return null;
    }

    // Определяем страну по оффлайн базе
    final country = CountryBounds.getCountryCode(gps.$1!, gps.$2!);
    cache[filePath] = country;
    return country;
  }

  static Future<(double?, double?)?> _getExifGPS(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      // Извлекаем GPS координаты
      final gpsLat = data['GPS GPSLatitude'];
      final gpsLatRef = data['GPS GPSLatitudeRef']?.toString();
      final gpsLon = data['GPS GPSLongitude'];
      final gpsLonRef = data['GPS GPSLongitudeRef']?.toString();

      if (gpsLat == null || gpsLon == null) {
        return null;
      }

      // Конвертируем EXIF GPS формат в decimal degrees
      double? latitude = _convertGPSToDecimal(gpsLat, gpsLatRef);
      double? longitude = _convertGPSToDecimal(gpsLon, gpsLonRef);

      if (latitude == null || longitude == null) {
        return null;
      }

      return (latitude, longitude);
    } catch (e) {
      return null;
    }
  }

  static double? _convertGPSToDecimal(dynamic gpsValue, String? ref) {
    try {
      String coordStr = gpsValue.toString();
      coordStr = coordStr.replaceAll('[', '').replaceAll(']', '');

      final parts = coordStr.split(',').map((e) => e.trim()).toList();
      if (parts.isEmpty) return null;

      double degrees = _parseFraction(parts[0]) ?? 0.0;
      double minutes = parts.length > 1 ? _parseFraction(parts[1]) ?? 0.0 : 0.0;
      double seconds = parts.length > 2 ? _parseFraction(parts[2]) ?? 0.0 : 0.0;

      double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);

      if (ref == 'S' || ref == 'W') {
        decimal = -decimal;
      }

      return decimal;
    } catch (e) {
      return null;
    }
  }

  static double? _parseFraction(String value) {
    try {
      value = value.trim();
      if (value.contains('/')) {
        final fraction = value.split('/');
        if (fraction.length == 2) {
          final numerator = double.tryParse(fraction[0]);
          final denominator = double.tryParse(fraction[1]);
          if (numerator != null && denominator != null && denominator != 0) {
            return numerator / denominator;
          }
        }
      }
      return double.tryParse(value);
    } catch (e) {
      return null;
    }
  }

  static String getFlagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';

    // Конвертируем ISO код страны в эмодзи флага
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;

    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
