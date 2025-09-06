import 'dart:convert'; // For jsonEncode, if you decide to send JSON
import 'dart:async'; // For Future.delayed
// import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// You might need to add the http package to your pubspec.yaml:
// dependencies:
//   http: ^1.2.0 (or latest)
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart'; // For DateFormat
import '../database_helper.dart';
import './api-keys.dart';
// For the Event class

class GeminiService {
  // API Key loaded from GEM_AI_API_KEY environment variable.
  // final String? _apiKey = Platform.environment['GEM_AI_API_KEY'];

  final String? _apiKey = google_ai;

  /// Fetches an AI-generated summary for all events on a specific date.
  ///
  /// [dateForEvents]: The date for which the summary is requested.
  /// [dailyEvents]: A list of all events occurring on that date.
  /// Returns a Future<String> containing the AI summary.
  Future<String> getSummaryForDayEvents(
    DateTime dateForEvents,
    List<Event> dailyEvents,
  ) async {
    print("--- Gemini Service: getSummaryForDayEvents ---  ");

    // final String? _apiKey = "AIzaSyAm7g147WPxJ4-Eyk7IGv288zWFYODCNwM";
    print("||||||||||||||||||||||||||| $_apiKey");

    if (_apiKey == null || _apiKey!.isEmpty) {
      const String errorMessage =
          "Error: GEM_AI_API_KEY environment variable is not set or is empty.";
      print("GeminiService: $errorMessage");
      return errorMessage;
    }
    print(
      "GeminiService: API Key status: Successfully loaded from GEM_AI_API_KEY environment variable.",
    );

    print(
      "Requesting summary for: ${DateFormat.yMMMd().format(dateForEvents)}",
    );

    if (dailyEvents.isEmpty) {
      return Future.delayed(
        const Duration(milliseconds: 100),
        () =>
            "No events scheduled for this day, so no summary can be generated.",
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
        eventDetails + // eventDetails already ends with
        // if not empty and contains the list
        "Highlight the busiest parts of the day or any notable sequences of events and provide summary of the weather on ${DateFormat.yMMMd().format(dateForEvents)}  ";

    print("Formatted Prompt for Summary:\n$promptContent");

    // 2. Simulate API call with a delay
    // In a real application, you would make an HTTP request here.
    final geminiApiUrl = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey",
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
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      print("GeminiService: Sending request to API...");
      final response = await http
          .post(geminiApiUrl, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming the summary is in responseData.candidates[0].content.parts[0].text
        // This path might vary based on the actual Gemini API response structure.
        String summary =
            responseData['candidates'][0]['content']['parts'][0]['text'] ??
            "Error: Could not parse summary from API response.";
        print("GeminiService: API call successful. Summary received.");
        return summary;
      } else {
        print(
          "GeminiService: API call failed. Status: ${response.statusCode}, Body: ${response.body}",
        );
        return "Error: Failed to get summary from AI (Status: ${response.statusCode}).";
      }
    } catch (e) {
      print("GeminiService: Error fetching summary - $e");
      return "Error: Could not connect to AI service or an unexpected error occurred.";
    } finally {
      print("--- End Gemini Service: getSummaryForDayEvents ---");
    }
  }

  // Keep the old method for now if it's used elsewhere, or remove if not needed.
  // For instance, if tapping a specific event in DayEventsScreen still needs to send event details.
  Future<void> sendSpecificEventDetailsToGemini(
    DateTime eventDate,
    Event event,
  ) async {
    print("--- Gemini Service: sendSpecificEventDetailsToGemini ---");

    // Consider adding API key check here as well if this method were to make a real API call.
    // if (_apiKey == null || _apiKey!.isEmpty) {
    //   print("GeminiService: GEM_AI_API_KEY not set. Cannot send specific event details.");
    //   return;
    // }

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
    // Actual API call simulation would go here too
    print("Simulated call for specific event details.");
    print("--- End Gemini Service: sendSpecificEventDetailsToGemini ---");
  }
}
