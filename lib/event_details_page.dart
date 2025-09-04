// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // Event class is in database_helper.dart
import './add_event_page.dart'; // Import AddEventPage
import 'dart:io'; // For basename
import 'package:open_filex/open_filex.dart'; // Import for opening files

class EventDetailsPage extends StatefulWidget {
  final Event event;
  final Function(Event? event)? onEventChanged; // Callback for edit/delete

  const EventDetailsPage({super.key, required this.event, this.onEventChanged});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late Event _currentEvent;
  List<EventAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    if (_currentEvent.id != null) {
      final attachments = await DatabaseHelper.instance.getAttachmentsForEvent(_currentEvent.id!);
      if (mounted) {
        setState(() {
          _attachments = attachments;
        });
      }
    }
  }

  Future<void> _deleteEvent(BuildContext context) async {
    if (_currentEvent.id != null) {
      await DatabaseHelper.instance.deleteEvent(_currentEvent.id!);
      widget.onEventChanged?.call(null); // Pass null to indicate deletion
      if (mounted) {
        Navigator.of(context).pop(); // Pop EventDetailsPage
      }
    }
  }

  Future<void> _editEvent(BuildContext context) async {
    if (!mounted) return;
    // AddEventPage will pop with the updated Event object
    final updatedEvent = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (context) => AddEventPage(
          date: _currentEvent.date,
          eventToEdit: _currentEvent,
        ),
      ),
    );

    if (updatedEvent != null && mounted) { // If AddEventPage returned an event (i.e., was saved)
      widget.onEventChanged?.call(updatedEvent); // Notify listener to refresh data in the background
      setState(() {
        _currentEvent = updatedEvent; // Update the UI of this page with new event details
      });
      await _loadAttachments(); // Refresh attachments list
    }
  }

  Future<void> _openAttachmentFile(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.yMMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentEvent.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Event',
            onPressed: () => _editEvent(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Event',
            onPressed: () {
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
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Close dialog
                          _deleteEvent(context); // Will call onEventChanged and pop EventDetailsPage
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
              value: dateFormat.format(_currentEvent.date),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_outlined,
                    label: 'Start Time',
                    value: timeFormat.format(DateTime(_currentEvent.date.year, _currentEvent.date.month, _currentEvent.date.day, _currentEvent.startTimeAsTimeOfDay.hour, _currentEvent.startTimeAsTimeOfDay.minute)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_filled_outlined,
                    label: 'End Time',
                    value: timeFormat.format(DateTime(_currentEvent.date.year, _currentEvent.date.month, _currentEvent.date.day, _currentEvent.endTimeAsTimeOfDay.hour, _currentEvent.endTimeAsTimeOfDay.minute)),
                  ),
                ),
              ],
            ),
            if (_currentEvent.location.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: _currentEvent.location,
              ),
            ],
            if (_currentEvent.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailItem(
                context,
                icon: Icons.notes_outlined,
                label: 'Notes',
                value: _currentEvent.description,
                isMultiline: true,
              ),
            ],
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 24), // Increased spacing before attachments section
              Text(
                'Attachments',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _attachments.map((attachment) {
                  String fileName = attachment.filePath.split(Platform.pathSeparator).last;
                  return InkWell(
                    onTap: () => _openAttachmentFile(attachment.filePath),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: theme.textTheme.bodyLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
                color: theme.colorScheme.onSurface,
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
