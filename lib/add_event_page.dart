import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // Added for file picking
import './database_helper.dart'; // Event class is in database_helper.dart
import 'dart:io'; // Potentially for File, though PlatformFile is often used

class AddEventPage extends StatefulWidget {
  final DateTime date;
  final Event? eventToEdit; // Added for editing

  const AddEventPage({super.key, required this.date, this.eventToEdit});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  late DateTime _selectedDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );
  String _location = '';
  String _notes = '';

  // Attachments state
  List<PlatformFile> _newlySelectedAttachments = [];
  List<EventAttachment> _existingAttachments = [];
  List<EventAttachment> _initialAttachments =
      []; // To track deletions for existing events

  bool get _isEditing => widget.eventToEdit != null; // Helper to check mode

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;

    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _title = event.title;
      _selectedDate = event.date;
      _startTime = event.startTimeAsTimeOfDay;
      _endTime = event.endTimeAsTimeOfDay;
      _location = event.location;
      _notes = event.description;
      _loadExistingAttachments(event.id!);
    } else {
      // Default time setup for new event
      if (_startTime.hour == 23) {
        _endTime = const TimeOfDay(hour: 23, minute: 59);
      } else {
        _endTime = TimeOfDay(
          hour: _startTime.hour + 1,
          minute: _startTime.minute,
        );
      }
    }
  }

  Future<void> _loadExistingAttachments(int eventId) async {
    final attachments = await DatabaseHelper.instance.getAttachmentsForEvent(
      eventId,
    );
    if (mounted) {
      setState(() {
        _existingAttachments = attachments;
        _initialAttachments = List.from(attachments); // Keep a copy for diffing
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType
            .any, // Or specific types: FileType.custom(allowedExtensions: ['jpg', 'pdf', 'doc']),
      );

      if (result != null) {
        setState(() {
          _newlySelectedAttachments.addAll(result.files);
        });
      }
    } catch (e) {
      // Handle exceptions from file picker
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
    }
  }

  void _removeNewAttachment(PlatformFile file) {
    setState(() {
      _newlySelectedAttachments.remove(file);
    });
  }

  void _removeExistingAttachment(EventAttachment attachment) {
    setState(() {
      _existingAttachments.remove(attachment);
    });
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        if ((_endTime.hour * 60 + _endTime.minute) <=
            (_startTime.hour * 60 + _startTime.minute)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour == 23 ? 23 : _startTime.hour + 1,
            minute: _startTime.hour == 23 ? 59 : _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (pickedTime != null) {
      // Validate that end time is after start time
      if ((pickedTime.hour * 60 + pickedTime.minute) >
          (_startTime.hour * 60 + _startTime.minute)) {
        setState(() {
          _endTime = pickedTime;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
      }
    }
  }

  void _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if ((_endTime.hour * 60 + _endTime.minute) <=
          (_startTime.hour * 60 + _startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      final dbHelper = DatabaseHelper.instance;
      final eventsOnSelectedDate = await dbHelper.getEventsForDate(
        _selectedDate,
      );

      final newEventStartDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final newEventEndDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      for (final existingEvent in eventsOnSelectedDate) {
        // If editing, skip checking against the event itself
        if (_isEditing && existingEvent.id == widget.eventToEdit!.id) {
          continue;
        }

        final existingEventStartDateTime = existingEvent.startTimeAsDateTime;
        final existingEventEndDateTime = existingEvent.endTimeAsDateTime;

        // Check for overlap
        if (newEventStartDateTime.isBefore(existingEventEndDateTime) &&
            newEventEndDateTime.isAfter(existingEventStartDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: This time conflicts with "${existingEvent.title}". Please choose a different time.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return; // Stop saving
        }
      }

      final eventData = Event(
        id: _isEditing ? widget.eventToEdit!.id : null,
        title: _title,
        date: _selectedDate,
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        location: _location,
        description: _notes,
      );

      int eventId;

      if (_isEditing) {
        eventId = widget.eventToEdit!.id!;
        await dbHelper.updateEvent(eventData);

        // Handle deleted attachments
        final removedDBAttachments = _initialAttachments
            .where(
              (initial) => !_existingAttachments.any(
                (current) => current.id == initial.id,
              ),
            )
            .toList();
        for (final attachment in removedDBAttachments) {
          if (attachment.id != null) {
            await dbHelper.deleteAttachment(attachment.id!);
          }
        }
      } else {
        eventId = await dbHelper.insertEvent(
          eventData,
        ); // insertEvent returns the new ID
      }

      // Save new attachments
      for (final file in _newlySelectedAttachments) {
        if (file.path != null) {
          await dbHelper.insertAttachment(eventId, file.path!);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(_isEditing ? eventData : true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.7),
      ),
      floatingLabelStyle: TextStyle(color: theme.colorScheme.primary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
    );

    // Combine existing and new attachments for display
    List<Widget> attachmentWidgets = [];

    // Display existing attachments
    for (var attachment in _existingAttachments) {
      attachmentWidgets.add(
        ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(
            attachment.filePath.split(Platform.pathSeparator).last,
            overflow: TextOverflow.ellipsis,
          ), // Show filename
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeExistingAttachment(attachment),
          ),
        ),
      );
    }
    // Display newly selected attachments
    for (var file in _newlySelectedAttachments) {
      attachmentWidgets.add(
        ListTile(
          leading: const Icon(
            Icons.attach_file_outlined,
          ), // Slightly different icon for new
          title: Text(file.name, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeNewAttachment(file),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Add title',
                  border: inputDecorationTheme.border,
                  focusedBorder: inputDecorationTheme.focusedBorder,
                  labelStyle: inputDecorationTheme.labelStyle,
                  floatingLabelStyle: inputDecorationTheme.floatingLabelStyle,
                  contentPadding: inputDecorationTheme.contentPadding,
                ),
                onSaved: (value) => _title = value ?? '',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                style: TextStyle(color: theme.colorScheme.onSurface),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.onBackground,
                ),
                title: Text(
                  DateFormat.yMMMMd().format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.edit_calendar_outlined,
                  color: theme.colorScheme.onBackground,
                ),
                onTap: _pickDate,
                tileColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(
                        Icons.access_time,
                        color: theme.colorScheme.onBackground,
                      ),
                      title: Text(
                        'Starts: ${_startTime.format(context)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      onTap: _pickStartTime,
                      tileColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      leading: Icon(
                        Icons.access_time_filled,
                        color: theme.colorScheme.onBackground,
                      ),
                      title: Text(
                        'Ends: ${_endTime.format(context)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      onTap: _pickEndTime,
                      tileColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _location,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'Add location',
                  icon: Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.secondary.withOpacity(0.8),
                  ),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12.0,
                  ),
                ),
                onSaved: (value) => _location = value ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _notes,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add notes',
                  icon: Icon(
                    Icons.notes_outlined,
                    color: theme.colorScheme.secondary.withOpacity(0.8),
                  ),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12.0,
                  ),
                ),
                onSaved: (value) => _notes = value ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text('Attachments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_link),
                label: const Text('Add Attachments'),
                onPressed: _pickFiles,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              if (attachmentWidgets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No attachments added.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...attachmentWidgets, // Display the list of attachments
            ],
          ),
        ),
      ),
    );
  }
}
