import 'dart:convert'; // For jsonEncode, jsonDecode
import 'dart:async'; // For Future.delayed

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For DateFormat
import '../database_helper.dart'; // For Event class (if needed in other methods)
import './api-keys.dart'; // Assuming your API key is here

class GeminiService {
  final String? _apiKey = google_ai; // Loaded from api-keys.dart

  // Helper to check for basic URL validity
  bool _isValidUrl(String? urlString) {
    if (urlString == null || urlString.isEmpty) return false;
    try {
      final uri = Uri.parse(urlString);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<String> getSummaryForDayEvents(
    DateTime dateForEvents,
    List<Event> dailyEvents,
  ) async {
    print("--- Gemini Service: getSummaryForDayEvents ---  ");
    if (_apiKey == null || _apiKey!.isEmpty) {
      const String errorMessage = "Error: API Key is not set or is empty.";
      print("GeminiService: $errorMessage");
      return errorMessage;
    }
    print("GeminiService: API Key loaded.");
    print("Requesting summary for: ${DateFormat.yMMMd().format(dateForEvents)}");

    if (dailyEvents.isEmpty) {
      return Future.delayed(
        const Duration(milliseconds: 100),
        () => "No events scheduled for this day, so no summary can be generated.",
      );
    }

    String eventDetails = "";
    for (var event in dailyEvents) {
      final startTimeStr = DateFormat.jm().format(event.startTimeAsDateTime);
      final endTimeStr = DateFormat.jm().format(event.endTimeAsDateTime);
      eventDetails += "- Event: ${event.title} ($startTimeStr - $endTimeStr)";
      if (event.description.isNotEmpty) {
        eventDetails += ", Description: ${event.description}";
      }
      eventDetails += "\n";
    }

    String promptContent =
        "Please provide a concise summary for the following events scheduled on ${DateFormat.yMMMd().format(dateForEvents)}:\n\n" +
        eventDetails +
        "Highlight the busiest parts of the day or any notable sequences of events. Focus on a human-readable narrative.";

    print("Formatted Prompt for Summary:\n$promptContent");

    final geminiApiUrl = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey",
    );
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": promptContent},
          ],
        },
      ],
    });

    try {
      print("GeminiService: Sending summary request to API...");
      final response = await http
          .post(geminiApiUrl, headers: headers, body: body)
          .timeout(const Duration(seconds: 20)); // Increased timeout slightly
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String summary =
            responseData['candidates'][0]['content']['parts'][0]['text'] ??
            "Error: Could not parse summary from API response.";
        print("GeminiService: Summary API call successful.");
        return summary;
      } else {
        print("GeminiService: Summary API call failed. Status: ${response.statusCode}, Body: ${response.body}");
        return "Error: Failed to get summary from AI (Status: ${response.statusCode}).";
      }
    } catch (e) {
      print("GeminiService: Error fetching summary - $e");
      return "Error: Could not connect to AI service or an unexpected error occurred while fetching summary.";
    } finally {
      print("--- End Gemini Service: getSummaryForDayEvents ---");
    }
  }

  Future<String?> getMapsUrlForPlaceName(String placeName) async {
    print("--- Gemini Service: getMapsUrlForPlaceName ---  ");
    if (_apiKey == null || _apiKey!.isEmpty) {
      print("GeminiService: Error: API Key is not set or is empty.");
      return null; // Return null as we expect a nullable string
    }
    print("GeminiService: API Key loaded.");
    print("Requesting Google Maps URL for: $placeName");

    if (placeName.trim().isEmpty) {
      print("GeminiService: Place name is empty. Cannot fetch URL.");
      return null;
    }

    String promptContent = 
        'Please provide a direct Google Maps URL for the following location: "$placeName". '
        'The URL should be suitable for opening directly in a web browser or Google Maps application. '
        'If you can find a specific Google Maps URL, return *only* the URL itself and nothing else. '
        'If you cannot find a specific Google Maps URL, or if the request is too ambiguous, return the exact string \'NOT_FOUND\'.';

    print("Formatted Prompt for Maps URL:\n$promptContent");

    final geminiApiUrl = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey",
    );
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "contents": [
        {
          "parts": [{"text": promptContent}],
        },
      ],
      "generationConfig": { // Optional: control output randomness
        "temperature": 0.2, // Lower temperature for more deterministic/factual output
        "topK": 1,
      }
    });

    try {
      print("GeminiService: Sending Maps URL request to API...");
      final response = await http
          .post(geminiApiUrl, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String? potentialUrl =
            responseData['candidates'][0]['content']['parts'][0]['text']?.trim();
        
        print("GeminiService: Maps URL API call successful. Raw response text: '$potentialUrl'");

        if (potentialUrl == "NOT_FOUND") {
          print("GeminiService: API indicated NOT_FOUND for the place name.");
          return null;
        }
        
        if (_isValidUrl(potentialUrl)) {
           // Further check if it looks like a maps URL (optional but good)
          if (potentialUrl!.toLowerCase().contains("maps.google.com") || 
              potentialUrl.toLowerCase().contains("goo.gl/maps") ||
              potentialUrl.toLowerCase().contains("google.com/maps")) {
            print("GeminiService: Valid Google Maps URL found: $potentialUrl");
            return potentialUrl;
          } else {
            print("GeminiService: URL found but does not appear to be a Google Maps URL: $potentialUrl. Treating as not found.");
            return null; // Or handle as a generic URL if that's acceptable
          }
        } else {
          print("GeminiService: Response was not 'NOT_FOUND' but is not a valid URL: '$potentialUrl'");
          return null;
        }
      } else {
        print("GeminiService: Maps URL API call failed. Status: ${response.statusCode}, Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("GeminiService: Error fetching Maps URL - $e");
      return null;
    } finally {
      print("--- End Gemini Service: getMapsUrlForPlaceName ---");
    }
  }

  // Old method - can be kept if used, or removed.
  Future<void> sendSpecificEventDetailsToGemini(
    DateTime eventDate,
    Event event,
  ) async {
    print("--- Gemini Service: sendSpecificEventDetailsToGemini --- (Simulated)");
    String promptContent =
        "Details for a specific event on ${DateFormat.yMMMd().format(eventDate)}:\n";
    final startTimeStr = DateFormat.jm().format(event.startTimeAsDateTime);
    final endTimeStr = DateFormat.jm().format(event.endTimeAsDateTime);
    promptContent += "Event: ${event.title}\n";
    promptContent += "Time: $startTimeStr - $endTimeStr\n";
    if (event.description.isNotEmpty) {
      promptContent += "Description: ${event.description}\n";
    }
    print("Formatted Payload for specific event:\n$promptContent");
    print("--- End Gemini Service: sendSpecificEventDetailsToGemini ---");
  }
}
