import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
// Assuming you have an Event class/map like
class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final String notes;

  // Add other fields as needed

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
  });

  // Helper to calculate duration in minutes
  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }
}

class DayScheduleView extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final double hourHeight; // Height of each hour slot in the timeline
  final TimeOfDay TaminTime; //e.g. TimeOfDay(hour: 0, minute: 0);
  final TimeOfDay TamaxTime; //e.g., TimeOfDay(hour: 23, minute: 59)

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0, // e.g., 60 pixels per hour
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
  });

  @override
  Widget build(BuildContext context) {
    // Filter events for the current day and sort them by start time
    // This step might be redundant if `events` are already filtered and sorted
    final todayEvents = events.where((event) {
      // Assuming your events are for a specific date,
      // or you might need to adjust this logic if events span multiple days
      return true; // Add date checking if necessary
    }).toList()
      ..sort((a, b) =>
      (a.startTime.hour * 60 + a.startTime.minute) -
          (b.startTime.hour * 60 + b.startTime.minute));

    return SingleChildScrollView(
      child: Stack(
        children: [
          _buildTimeSlots(context),
          _buildEvents(context, todayEvents),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context) {
    List<Widget> timeSlots = [];
    final int totalHours = TamaxTime.hour - TaminTime.hour + 1;


    for (int i = 0; i < totalHours; i++) {
      final hour = TaminTime.hour + i;
      timeSlots.add(
        Positioned(
          top: i * hourHeight,
          left: 50, // For time labels
          right: 0,
          child: Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
                // Optional: bottom border for the last slot
                bottom: (i == totalHours - 1)
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      );
      timeSlots.add(
        Positioned(
          top: i * hourHeight - (hourHeight / 4), // Adjust for centering
          left: 0,
          child: Container(
            width: 45, // Width of the time label area
            height: hourHeight,
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat('h a').format(
                  DateTime(date.year, date.month, date.day, hour)),
              // Display hour
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }
    // Calculate total height for the Stack based on time slots
    double totalHeight = totalHours * hourHeight;


    return SizedBox(
      height: totalHeight,
      child: Stack(children: timeSlots),
    );
  }


  Widget _buildEvents(BuildContext context, List<Event> dayEvents) {
    List<Widget> eventWidgets = [];

    for (var event in dayEvents) {
      final double topOffset = _calculateTopOffset(event.startTime);
      final double eventHeight = _calculateEventHeight(event.durationInMinutes);

      eventWidgets.add(
        Positioned(
          top: topOffset,
          left: 50, // Align with the right of the time labels
          right: 10, // Some padding from the right edge
          child: Container(
            height: eventHeight,
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 2),
            // Spacing between events
            decoration: BoxDecoration(
              color: Theme
                  .of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme
                  .of(context)
                  .colorScheme
                  .primary),
            ),
            child: Text(
              event.title,
              style: TextStyle(
                  color: Theme
                      .of(context)
                      .brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    // Calculate total height for the Stack based on time slots
    double totalStackHeight = (TamaxTime.hour - TaminTime.hour + 1) *
        hourHeight;

    return SizedBox(
      height: totalStackHeight, // Ensure Stack has enough height
      child: Stack(children: eventWidgets),
    );
  }

  double _calculateTopOffset(TimeOfDay startTime) {
    // Calculate minutes from the start of the display range (e.g., TaminTime)
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final TaminMinutes = TaminTime.hour * 60 + TaminTime.minute;
    final minutesFromDisplayStart = startMinutes - TaminMinutes;
    return (minutesFromDisplayStart / 60.0) * hourHeight;
  }

  double _calculateEventHeight(int durationInMinutes) {
    return (durationInMinutes / 60.0) * hourHeight;
  }
}
