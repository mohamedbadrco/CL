import 'package:flutter/material.dart';

void main() {
  runApp(const CalendarApp());
}

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scrollable Calendar',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: CalendarScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const CalendarScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  final Map<DateTime, List<String>> _events = {};

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      _selectedDate = null;
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      _selectedDate = null;
    });
  }

  void _addEvent(DateTime date) async {
    String title = '';
    String duration = '';
    String location = '';
    String notes = '';
    String contacts = '';
    // For attachment, just a text field for demo (file picker needs more setup)
    String attachment = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) => title = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Duration'),
                  onChanged: (value) => duration = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Location'),
                  onChanged: (value) => location = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Notes'),
                  onChanged: (value) => notes = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Attachment (URL or name)'),
                  onChanged: (value) => attachment = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Contacts'),
                  onChanged: (value) => contacts = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': title,
                  'duration': duration,
                  'location': location,
                  'notes': notes,
                  'attachment': attachment,
                  'contacts': contacts,
                });
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result['title']!.trim().isNotEmpty) {
      setState(() {
        final key = DateTime(date.year, date.month, date.day);
        final eventDetails =
            "Title: ${result['title']}\nDuration: ${result['duration']}\nLocation: ${result['location']}\nNotes: ${result['notes']}\nAttachment: ${result['attachment']}\nContacts: ${result['contacts']}";
        _events.putIfAbsent(key, () => []).add(eventDetails);
        _selectedDate = key;
      });
    }
  }

  Widget _buildResponsiveDaysGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final weekdayOffset = firstDayOfMonth.weekday % 7;
    List<Widget> dayWidgets = [];

    for (int i = 0; i < weekdayOffset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final hasEvent = _events.containsKey(DateTime(date.year, date.month, date.day));
      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              onDoubleTap: () {
                _addEvent(date);
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.2) : null,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7), // Border color close to background
                    width: 0.25, // Even thinner border
                  ),
                ),
                // Removed margin
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: boxSize * 0.4,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                    ),
                    if (hasEvent)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(Icons.event, size: boxSize * 0.18, color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selectedEvents = _selectedDate != null
        ? _events[DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day)] ?? []
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrollable Calendar'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPreviousMonth,
              ),
              Text(
                "${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goToNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays
                  .map((name) => Expanded(
                        child: Center(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildResponsiveDaysGrid(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selected date: ${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ...selectedEvents.map((event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.event, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 4),
                            Expanded(child: Text(event)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
