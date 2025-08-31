
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // Event class is in database_helper.dart

class EventDetailsPage extends StatelessWidget {
  final Event event;
  final VoidCallback? onDelete;

  const EventDetailsPage({super.key, required this.event, this.onDelete});

  Future<void> _deleteEvent(BuildContext context) async {
    if (event.id != null) {
      await DatabaseHelper.instance.deleteEvent(event.id!);
      onDelete?.call();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final timeFormat = DateFormat.jm(); // e.g., 5:08 PM
    final dateFormat = DateFormat.yMMMMd(); // e.g., September 10, 2023

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Event',
            onPressed: () {
              // Show confirmation dialog before deleting
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete Event?'),
                    content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close the dialog
                          _deleteEvent(context); // Pass the parent context
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
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
                    value: timeFormat.format(DateTime(event.date.year, event.date.month, event.date.day, event.startTimeAsTimeOfDay.hour, event.startTimeAsTimeOfDay.minute)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_filled_outlined,
                    label: 'End Time',
                    value: timeFormat.format(DateTime(event.date.year, event.date.month, event.date.day, event.endTimeAsTimeOfDay.hour, event.endTimeAsTimeOfDay.minute)),
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
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: event.description,
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
