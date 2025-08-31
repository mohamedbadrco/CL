
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './main.dart'; // Assuming Event class is in main.dart

class EventDetailsPage extends StatelessWidget {
  final Event event;

  const EventDetailsPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm(); // e.g., 5:08 PM
    final dateFormat = DateFormat.yMMMMd(); // e.g., September 10, 2023

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildDetailItem(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: dateFormat.format(event.date),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_outlined,
                    label: 'Start Time',
                    value: timeFormat.format(DateTime(event.date.year, event.date.month, event.date.day, event.startTime.hour, event.startTime.minute)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_filled_outlined,
                    label: 'End Time',
                    value: timeFormat.format(DateTime(event.date.year, event.date.month, event.date.day, event.endTime.hour, event.endTime.minute)),
                  ),
                ),
              ],
            ),
            if (event.location.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: event.location,
              ),
            ],
            if (event.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: event.notes,
                isMultiline: true,
              ),
            ],
            // You can add more details or actions like Edit/Delete buttons here
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, {required IconData icon, required String label, required String value, bool isMultiline = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28.0), // Align with text after icon
          child: Text(
            value,
            style: isMultiline 
                ? theme.textTheme.bodyLarge?.copyWith(height: 1.4) 
                : theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
