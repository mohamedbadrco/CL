// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import './database_helper.dart'; // Event class is in database_helper.dart
import './add_event_page.dart'; // Import AddEventPage
import './notification_service.dart'; // Import for cancelEventNotification
import 'dart:io'; // For basename
import 'package:open_filex/open_filex.dart'; // Import for opening files
import './api/gemini_service.dart'; // Import GeminiService

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
  final GeminiService _geminiService = GeminiService(); // Instance of GeminiService
  bool _isFetchingGeoUrl = false;
  String? _fetchedGeoUrl;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    if (_currentEvent.id != null) {
      final attachments = await DatabaseHelper.instance.getAttachmentsForEvent(
        _currentEvent.id!,
      );
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
      await cancelEventNotification(_currentEvent.id!);
      widget.onEventChanged?.call(null); 
      if (mounted) {
        Navigator.of(context).pop(); 
      }
    }
  }

  Future<void> _editEvent(BuildContext context) async {
    if (!mounted) return;
    final updatedEvent = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (context) =>
            AddEventPage(date: _currentEvent.date, eventToEdit: _currentEvent),
      ),
    );

    if (updatedEvent != null && mounted) {
      widget.onEventChanged?.call(updatedEvent);
      setState(() {
        _currentEvent = updatedEvent;
        _fetchedGeoUrl = null; // Reset fetched URL if event is edited
        _isFetchingGeoUrl = false;
      });
      await _loadAttachments();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  Future<void> _fetchGeoUrlForLocation(String locationName) async {
    if (locationName.trim().isEmpty) return;
    setState(() {
      _isFetchingGeoUrl = true;
      _fetchedGeoUrl = null;
    });
    try {
      // This is where you would call your GeminiService method
      // String? url = await _geminiService.getMapsUrlForPlaceName(locationName);
      // For now, we'll simulate a delay and a response for UI testing:
      await Future.delayed(const Duration(seconds: 2)); 
      String? url = "https://maps.google.com/?q=${Uri.encodeComponent(locationName)}"; // Simulated basic link
      // To simulate a failure or no link found:
      // String? url = null; 
      // String? url = "not_a_valid_link";

      if (url != null && _isValidUrl(url)) {
        setState(() {
          _fetchedGeoUrl = url;
        });
      } else {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find a valid Maps URL for this location.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching location URL: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingGeoUrl = false;
        });
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
                    content: const Text(
                      'Are you sure you want to delete this event? This action cannot be undone.',
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(dialogContext).colorScheme.error,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _deleteEvent(context);
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
                    value: timeFormat.format(
                      DateTime(
                        _currentEvent.date.year,
                        _currentEvent.date.month,
                        _currentEvent.date.day,
                        _currentEvent.startTimeAsTimeOfDay.hour,
                        _currentEvent.startTimeAsTimeOfDay.minute,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    context,
                    icon: Icons.access_time_filled_outlined,
                    label: 'End Time',
                    value: timeFormat.format(
                      DateTime(
                        _currentEvent.date.year,
                        _currentEvent.date.month,
                        _currentEvent.date.day,
                        _currentEvent.endTimeAsTimeOfDay.hour,
                        _currentEvent.endTimeAsTimeOfDay.minute,
                      ),
                    ),
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
                  isLocationField: true // Indicate this is the location field
                  ),
            ],
            if (_fetchedGeoUrl != null) ...[
              const SizedBox(height: 8),
               Padding(
                 padding: const EdgeInsets.only(left: 28.0), // Align with other values
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Suggested Map Link:", style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     InkWell(
                       onTap: () => _launchUrl(_fetchedGeoUrl!),
                       child: Text(
                         _fetchedGeoUrl!,
                         style: theme.textTheme.bodyLarge?.copyWith(
                           color: Colors.blue,
                           decoration: TextDecoration.underline,
                           decorationColor: Colors.blue,
                         ),
                       ),
                     ),
                   ],
                 ),
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
              const SizedBox(height: 24),
              Text(
                'Attachments',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                          Icon(
                            Icons.attach_file,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
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

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
    bool isLocationField = false, // New parameter
  }) {
    final theme = Theme.of(context);
    final bool isActualUrl = _isValidUrl(value);

    Widget valueWidget;
    if (isLocationField && isActualUrl) {
      valueWidget = InkWell(
        onTap: () => _launchUrl(value),
        child: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.blue, 
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue,
          ),
        ),
      );
    } else if (isLocationField && !isActualUrl) {
      valueWidget = Row(
        children: [
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
          if (_isFetchingGeoUrl) 
            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0))
          else
            IconButton(
              icon: const Icon(Icons.travel_explore_outlined, size: 22),
              tooltip: 'Find on map',
              onPressed: () => _fetchGeoUrlForLocation(value),
            ),
        ],
      );
    } else {
      valueWidget = Text(
        value,
        style: isMultiline
            ? theme.textTheme.bodyLarge?.copyWith(height: 1.4)
            : theme.textTheme.bodyLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onPrimary),
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
          padding: const EdgeInsets.only(left: 28.0),
          child: valueWidget,
        ),
      ],
    );
  }
}
