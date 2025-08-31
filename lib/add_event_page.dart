
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // Event class is in database_helper.dart

class AddEventPage extends StatefulWidget {
  final DateTime date;

  const AddEventPage({super.key, required this.date});

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

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    // Adjust default end time if start time is late in the day
    if (_startTime.hour == 23) {
      _endTime = const TimeOfDay(hour: 23, minute: 59);
    } else {
      _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
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
    );
    if (pickedTime != null) {
      setState(() {
        _startTime = pickedTime;
        // Adjust end time if it's before or same as new start time
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
    );
    if (pickedTime != null) {
      setState(() {
        _endTime = pickedTime;
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if ((_endTime.hour * 60 + _endTime.minute) <= (_startTime.hour * 60 + _startTime.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }

      final newEvent = Event(
        title: _title,
        date: _selectedDate, // Use the selected date
        startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        location: _location,
        description: _notes,
      );
      Navigator.of(context).pop(newEvent);
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
        title: const Text('Create Event'),
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
                onTap: _pickDate, // Allow tapping to change date
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
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'Add location',
                  icon: Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary.withOpacity(0.8)),
                  border: InputBorder.none, // Simpler look for optional fields
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.colorScheme.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12.0),
                ),
                onSaved: (value) => _location = value ?? '',
                style: TextStyle(color: theme.colorScheme.onSurface),
                 textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add notes',
                  icon: Icon(Icons.notes_outlined, color: theme.colorScheme.secondary.withOpacity(0.8)),
                  border: InputBorder.none, // Simpler look
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
   





