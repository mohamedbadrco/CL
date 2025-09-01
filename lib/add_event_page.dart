
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // Event class is in database_helper.dart

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
  TimeOfDay _endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  String _location = '';
  String _notes = '';

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
    } else {
      // Default time setup for new event
      if (_startTime.hour == 23) {
        _endTime = const TimeOfDay(hour: 23, minute: 59);
      } else {
        _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
      }
    }
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
        if ((_endTime.hour * 60 + _endTime.minute) <= (_startTime.hour * 60 + _startTime.minute)) {
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
      if ((pickedTime.hour * 60 + pickedTime.minute) > (_startTime.hour * 60 + _startTime.minute)) {
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

  void _saveEvent() async { // Made async for database operations
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if ((_endTime.hour * 60 + _endTime.minute) <= (_startTime.hour * 60 + _startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      final eventData = Event(
        id: _isEditing ? widget.eventToEdit!.id : null, // Preserve ID if editing
        title: _title,
        date: _selectedDate,
        startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        location: _location,
        description: _notes,
      );

      // Save to database
      final dbHelper = DatabaseHelper.instance;
      int savedId;
      if (_isEditing) {
        savedId = await dbHelper.updateEvent(eventData);
      } else {
        savedId = await dbHelper.insertEvent(eventData);
      }
      
      // If inserting, the id in eventData is null, so we create a new Event object with the returned id.
      // If updating, savedId is the count of rows affected, ideally 1. We can return the eventData itself as it has the correct id.
      final savedEvent = _isEditing ? eventData : Event(
        id: savedId, // use the actual ID from DB if it was an insert
        title: eventData.title,
        date: eventData.date,
        startTime: eventData.startTime,
        endTime: eventData.endTime,
        location: eventData.location,
        description: eventData.description,
      );

      if (mounted) {
        Navigator.of(context).pop(savedEvent); // Pop with the saved/updated event
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
      floatingLabelStyle: TextStyle(color: theme.colorScheme.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'), // Dynamic title
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: Text(
              'Save',
              style: TextStyle(
                color: theme.colorScheme.primary,
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
                initialValue: _title, // Set initial value
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
                leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary.withOpacity(0.8)),
                title: Text(
                  DateFormat.yMMMMd().format(_selectedDate),
                  style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                ),
                trailing: Icon(Icons.edit_calendar_outlined, color: theme.colorScheme.primary),
                onTap: _pickDate,
                tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: theme.colorScheme.primary.withOpacity(0.8)),
                      title: Text(
                        'Starts: ${_startTime.format(context)}',
                        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                      onTap: _pickStartTime,
                      tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.access_time_filled, color: theme.colorScheme.primary.withOpacity(0.8)),
                      title: Text(
                        'Ends: ${_endTime.format(context)}',
                         style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                      onTap: _pickEndTime,
                      tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor.withOpacity(0.5)),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _location, // Set initial value
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'Add location',
                  icon: Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary.withOpacity(0.8)),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12.0),
                ),
                onSaved: (value) => _location = value ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _notes, // Set initial value
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add notes',
                  icon: Icon(Icons.notes_outlined, color: theme.colorScheme.secondary.withOpacity(0.8)),
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12.0),
                ),
                onSaved: (value) => _notes = value ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
