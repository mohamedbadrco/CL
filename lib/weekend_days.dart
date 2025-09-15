import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:convert'; // For jsonEncode, jsonDecode
import 'dart:async'; // For Future.delayed

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For DateFormat
import '../database_helper.dart'; // For Event class (if needed in other methods)

final WEEKEND_DATA = {
  'Saturday & Sunday': {
    'weekendDays': [0, 6],
    'countries': [
      {'code': 'al', 'name': 'Albania'},
      {'code': 'ad', 'name': 'Andorra'},
      {'code': 'ao', 'name': 'Angola'},
      {'code': 'ar', 'name': 'Argentina'},
      {'code': 'am', 'name': 'Armenia'},
      {'code': 'au', 'name': 'Australia'},
      {'code': 'at', 'name': 'Austria'},
      {'code': 'az', 'name': 'Azerbaijan'},
      {'code': 'by', 'name': 'Belarus'},
      {'code': 'be', 'name': 'Belgium'},
      {'code': 'bj', 'name': 'Benin'},
      {'code': 'bt', 'name': 'Bhutan'},
      {'code': 'bo', 'name': 'Bolivia'},
      {'code': 'ba', 'name': 'Bosnia and Herzegovina'},
      {'code': 'br', 'name': 'Brazil'},
      {'code': 'bg', 'name': 'Bulgaria'},
      {'code': 'bf', 'name': 'Burkina Faso'},
      {'code': 'bi', 'name': 'Burundi'},
      {'code': 'kh', 'name': 'Cambodia'},
      {'code': 'cm', 'name': 'Cameroon'},
      {'code': 'ca', 'name': 'Canada'},
      {'code': 'cl', 'name': 'Chile'},
      {'code': 'cn', 'name': 'China'},
      {'code': 'co', 'name': 'Colombia'},
      {'code': 'cd', 'name': 'Congo, DR'},
      {'code': 'cr', 'name': 'Costa Rica'},
      {'code': 'hr', 'name': 'Croatia'},
      {'code': 'cy', 'name': 'Cyprus'},
      {'code': 'cz', 'name': 'Czech Republic'},
      {'code': 'dk', 'name': 'Denmark'},
      {'code': 'do', 'name': 'Dominican Republic'},
      {'code': 'ec', 'name': 'Ecuador'},
      {'code': 'sv', 'name': 'El Salvador'},
      {'code': 'er', 'name': 'Eritrea'},
      {'code': 'ee', 'name': 'Estonia'},
      {'code': 'et', 'name': 'Ethiopia'},
      {'code': 'fj', 'name': 'Fiji'},
      {'code': 'fi', 'name': 'Finland'},
      {'code': 'fr', 'name': 'France'},
      {'code': 'ga', 'name': 'Gabon'},
      {'code': 'gm', 'name': 'Gambia'},
      {'code': 'ge', 'name': 'Georgia'},
      {'code': 'de', 'name': 'Germany'},
      {'code': 'gh', 'name': 'Ghana'},
      {'code': 'gr', 'name': 'Greece'},
      {'code': 'gt', 'name': 'Guatemala'},
      {'code': 'gn', 'name': 'Guinea'},
      {'code': 'ht', 'name': 'Haiti'},
      {'code': 'hn', 'name': 'Honduras'},
      {'code': 'hu', 'name': 'Hungary'},
      {'code': 'is', 'name': 'Iceland'},
      {'code': 'id', 'name': 'Indonesia'},
      {'code': 'ie', 'name': 'Ireland'},
      {'code': 'it', 'name': 'Italy'},
      {'code': 'ci', 'name': 'Ivory Coast'},
      {'code': 'jm', 'name': 'Jamaica'},
      {'code': 'jp', 'name': 'Japan'},
      {'code': 'kz', 'name': 'Kazakhstan'},
      {'code': 'ke', 'name': 'Kenya'},
      {'code': 'kg', 'name': 'Kyrgyzstan'},
      {'code': 'la', 'name': 'Laos'},
      {'code': 'lv', 'name': 'Latvia'},
      {'code': 'lb', 'name': 'Lebanon'},
      {'code': 'ls', 'name': 'Lesotho'},
      {'code': 'lr', 'name': 'Liberia'},
      {'code': 'li', 'name': 'Liechtenstein'},
      {'code': 'lt', 'name': 'Lithuania'},
      {'code': 'lu', 'name': 'Luxembourg'},
      {'code': 'mg', 'name': 'Madagascar'},
      {'code': 'mw', 'name': 'Malawi'},
      {'code': 'my', 'name': 'Malaysia'},
      {'code': 'ml', 'name': 'Mali'},
      {'code': 'mt', 'name': 'Malta'},
      {'code': 'mx', 'name': 'Mexico'},
      {'code': 'md', 'name': 'Moldova'},
      {'code': 'mc', 'name': 'Monaco'},
      {'code': 'mn', 'name': 'Mongolia'},
      {'code': 'me', 'name': 'Montenegro'},
      {'code': 'ma', 'name': 'Morocco'},
      {'code': 'mz', 'name': 'Mozambique'},
      {'code': 'mm', 'name': 'Myanmar'},
      {'code': 'nl', 'name': 'Netherlands'},
      {'code': 'nz', 'name': 'New Zealand'},
      {'code': 'ni', 'name': 'Nicaragua'},
      {'code': 'ne', 'name': 'Niger'},
      {'code': 'ng', 'name': 'Nigeria'},
      {'code': 'kp', 'name': 'North Korea'},
      {'code': 'no', 'name': 'Norway'},
      {'code': 'pk', 'name': 'Pakistan'},
      {'code': 'pa', 'name': 'Panama'},
      {'code': 'pg', 'name': 'Papua New Guinea'},
      {'code': 'py', 'name': 'Paraguay'},
      {'code': 'pe', 'name': 'Peru'},
      {'code': 'pl', 'name': 'Poland'},
      {'code': 'pt', 'name': 'Portugal'},
      {'code': 'ro', 'name': 'Romania'},
      {'code': 'ru', 'name': 'Russia'},
      {'code': 'rw', 'name': 'Rwanda'},
      {'code': 'sn', 'name': 'Senegal'},
      {'code': 'rs', 'name': 'Serbia'},
      {'code': 'sl', 'name': 'Sierra Leone'},
      {'code': 'sg', 'name': 'Singapore'},
      {'code': 'sk', 'name': 'Slovakia'},
      {'code': 'si', 'name': 'Slovenia'},
      {'code': 'so', 'name': 'Somalia'},
      {'code': 'za', 'name': 'South Africa'},
      {'code': 'kr', 'name': 'South Korea'},
      {'code': 'es', 'name': 'Spain'},
      {'code': 'lk', 'name': 'Sri Lanka'},
      {'code': 'sd', 'name': 'Sudan'},
      {'code': 'se', 'name': 'Sweden'},
      {'code': 'ch', 'name': 'Switzerland'},
      {'code': 'tz', 'name': 'Tanzania'},
      {'code': 'th', 'name': 'Thailand'},
      {'code': 'tg', 'name': 'Togo'},
      {'code': 'tt', 'name': 'Trinidad and Tobago'},
      {'code': 'tn', 'name': 'Tunisia'},
      {'code': 'tr', 'name': 'Turkey'},
      {'code': 'ae', 'name': 'UAE'},
      {'code': 'ug', 'name': 'Uganda'},
      {'code': 'ua', 'name': 'Ukraine'},
      {'code': 'gb', 'name': 'United Kingdom'},
      {'code': 'us', 'name': 'United States'},
      {'code': 'uy', 'name': 'Uruguay'},
      {'code': 've', 'name': 'Venezuela'},
      {'code': 'vn', 'name': 'Vietnam'},
      {'code': 'zm', 'name': 'Zambia'},
      {'code': 'zw', 'name': 'Zimbabwe'},
    ],
  },
  'Friday & Saturday': {
    'weekendDays': [5, 6],
    'countries': [
      {'code': 'dz', 'name': 'Algeria'},
      {'code': 'bh', 'name': 'Bahrain'},
      {'code': 'bd', 'name': 'Bangladesh'},
      {'code': 'eg', 'name': 'Egypt'},
      {'code': 'iq', 'name': 'Iraq'},
      {'code': 'il', 'name': 'Israel'},
      {'code': 'jo', 'name': 'Jordan'},
      {'code': 'kw', 'name': 'Kuwait'},
      {'code': 'ly', 'name': 'Libya'},
      {'code': 'mv', 'name': 'Maldives'},
      {'code': 'mr', 'name': 'Mauritania'},
      {'code': 'om', 'name': 'Oman'},
      {'code': 'qa', 'name': 'Qatar'},
      {'code': 'sa', 'name': 'Saudi Arabia'},
      {'code': 'sy', 'name': 'Syria'},
      {'code': 'ye', 'name': 'Yemen'},
    ],
  },
  'Friday & Sunday': {
    'weekendDays': [5, 0],
    'countries': [
      {'code': 'bn', 'name': 'Brunei'},
    ],
  },
  'Thursday & Friday': {
    'weekendDays': [4, 5],
    'countries': [
      {'code': 'af', 'name': 'Afghanistan'},
    ],
  },
  'Sunday Only': {
    'weekendDays': [0],
    'countries': [
      {'code': 'ph', 'name': 'Philippines'},
      {'code': 'in', 'name': 'India'},
    ],
  },
  'Friday Only': {
    'weekendDays': [5],
    'countries': [
      {'code': 'dj', 'name': 'Djibouti'},
      {'code': 'ir', 'name': 'Iran'},
    ],
  },
  'Saturday Only': {
    'weekendDays': [6],
    'countries': [
      {'code': 'np', 'name': 'Nepal'},
    ],
  },
};

// If you want the countries sorted by name for each group, you can do this after initialization:

// Call sortWeekendCountries() in your main or initialization code if needed.

/// Returns the country code for the current location using the timezone package.
/// You must call tzdata.initializeTimeZones() before using this function.
String? getCountryCodeForCurrentLocation() {
  final location = tz.getLocation(tz.local.name);
  final String timeZoneName = location.name.toLowerCase();
  // print("++===================${timeZoneName}");

  // Simple mapping from timezone name to country code (expand as needed)
  // Example: "Europe/London" -> "gb"
  final Map<String, String> tzToCountryCode = {
    'europe/london': 'gb',
    'america/new_york': 'us',
    'asia/tokyo': 'jp',
    'europe/paris': 'fr',
    'asia/dubai': 'ae',
    'asia/muscat': 'om', // Oman: Friday-Saturday weekends
    // Add more mappings as needed
  };

  return tzToCountryCode[timeZoneName];
}

/// Returns the weekend days for a given country code using WEEKEND_DATA.
/// Returns a list of integers representing weekend days (0=Sunday, 6=Saturday).
List<int>? getWeekendDaysForCountry(String countryCode) {
  for (final entry in WEEKEND_DATA.entries) {
    final countries = entry.value['countries'] as List<dynamic>;
    for (final country in countries) {
      if (country['code'] == countryCode) {
        return List<int>.from((entry.value['weekendDays'] as List).cast<int>());
      }
    }
  }
  return null;
}

/// Returns the weekend days for the current location based on timezone.
/// Returns null if the country code or weekend days cannot be determined.
Future<List<int>?> getWeekendDaysForCurrentLocation() async {
  String? code = null;

  final locationurl = Uri.parse("http://ip-api.com/json/");
  final locationheaders = {'Content-Type': 'application/json'};
  final location_response = await http
      .post(locationurl, headers: locationheaders, body: "{}")
      .timeout(const Duration(seconds: 20)); // Increased timeout slightly
  if (location_response.statusCode == 200) {
    final location_responseData = jsonDecode(location_response.body);
    code = location_responseData['countryCode'].toString().toLowerCase();
  } else {
    print(
      "location Service: Summary API call failed. Status: ${location_response.statusCode}, Body: ${location_response.body}",
    );
    code = null;
  }

  if (code == null) {
    // If the specific timezone couldn't be mapped to a country code,
    // let's default to 'om' (Oman) as it's configured for Fri/Sat weekends.
    // You can change 'om' to another relevant country code from your WEEKEND_DATA
    // if a different default is more appropriate for your primary use case.
    print(
      "Warning: Could not determine country code from local timezone. Defaulting to 'om' to get Friday/Saturday weekends.",
    );
    code = 'om';
  }
  // The print statement you added was helpful, let's refine it slightly for clarity
  print("Using country code '$code' to determine weekend days.");
  final weekendDaysList = getWeekendDaysForCountry(
    code!,
  ); // code is now guaranteed non-null
  print("Determined weekend days: $weekendDaysList for country code '$code'.");
  return weekendDaysList;
}
