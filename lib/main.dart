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
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255), // even lighter green
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary:  const Color(0xFFF2FFF5),
          secondary: const Color.fromARGB(255, 255, 255, 255),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor:  Color.fromARGB(255, 251, 251, 251), // lighter green for app bar
          foregroundColor: Colors.black,
        ),
      ),
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
  final DateTime _today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isWeekView = false;
  DateTime _focusedWeekStart = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day - (DateTime.now().weekday % 7),
  );

  @override
  void initState() {
    super.initState();
    if (_focusedMonth.year == _today.year && _focusedMonth.month == _today.month) {
      _selectedDate = _today;
    }
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      if (_focusedMonth.year == _today.year && _focusedMonth.month == _today.month) {
        _selectedDate = _today;
      } else {
        _selectedDate = null;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      if (_focusedMonth.year == _today.year && _focusedMonth.month == _today.month) {
        _selectedDate = _today;
      } else {
        _selectedDate = null;
      }
    });
  }

  void _goToPreviousWeek() {
    setState(() {
      _focusedWeekStart = _focusedWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7));
    });
  }

  void _toggleView() {
    setState(() {
      _isWeekView = !_isWeekView;
      if (_isWeekView) {
        _focusedWeekStart = _selectedDate != null
            ? _selectedDate!.subtract(Duration(days: _selectedDate!.weekday % 7))
            : _today.subtract(Duration(days: _today.weekday % 7));
      }
    });
  }

  void _addEvent(DateTime date) async {
    String title = '';
    String duration = '';
    String location = '';
    String notes = '';
    String contacts = '';
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

    // Previous month's days to fill the grid
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final prevMonthDays = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
    for (int i = 0; i < weekdayOffset; i++) {
      final day = prevMonthDays - weekdayOffset + i + 1;
      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            return Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.15),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: boxSize * 0.4,
                    color: Theme.of(context).disabledColor.withOpacity(0.4),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final hasEvent = _events.containsKey(DateTime(date.year, date.month, date.day));

      Color? numberColor;
      if (date.year == _today.year &&
          date.month == _today.month &&
          date.day == _today.day) {
        numberColor = Colors.blue;
      } else if (isSelected) {
        numberColor = Colors.blue;
      }

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
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 0.5,
                    ),
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: boxSize * 0.4,
                          color: numberColor,
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
              ));
          },
        ),
      );
    }

    // Next month's days to fill the grid
    int totalBoxes = dayWidgets.length;
    int nextDays = (totalBoxes % 7 == 0) ? 0 : (7 - totalBoxes % 7);
    for (int i = 1; i <= nextDays; i++) {
      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            return Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.15),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: boxSize * 0.4,
                    color: Theme.of(context).disabledColor.withOpacity(0.4),
                  ),
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

  Widget _buildWeekView(BuildContext context) {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<DateTime> weekDates = List.generate(7, (i) => _focusedWeekStart.add(Duration(days: i)));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _goToPreviousWeek,
            ),
            Text(
              "${weekDates.first.day}/${weekDates.first.month} - ${weekDates.last.day}/${weekDates.last.month}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _goToNextWeek,
            ),
          ],
        ),
        Row(
          children: weekDates.map((date) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  color: date.year == _today.year &&
                          date.month == _today.month &&
                          date.day == _today.day
                      ? Colors.blue.withOpacity(0.1)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      weekDays[date.weekday % 7],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "${date.day}/${date.month}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: date.year == _today.year &&
                                date.month == _today.month &&
                                date.day == _today.day
                            ? Colors.blue
                            : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: "Add Event",
                      onPressed: () => _addEvent(date),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weekDates.map((date) {
              final events = _events[DateTime(date.year, date.month, date.day)] ?? [];
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.2), // thin column border
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListView(
                    children: events.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "No events",
                                style: TextStyle(
                                  color: Theme.of(context).disabledColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ]
                        : events
                            .map((event) => Card(
                                  margin: const EdgeInsets.all(8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(event),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
        title: Text(_isWeekView ? 'Week View' : 'Month View'),
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
          IconButton(
            icon: Icon(_isWeekView ? Icons.calendar_month : Icons.view_week),
            onPressed: _toggleView,
            tooltip: _isWeekView ? 'Month View' : 'Week View',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (!_isWeekView)
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
          if (!_isWeekView)
            const SizedBox(height: 16),
          if (!_isWeekView)
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
          if (!_isWeekView)
            const SizedBox(height: 8),
          Expanded(
            child: !_isWeekView
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildResponsiveDaysGrid(context),
                    ),
                  )
                : _buildWeekView(context),
          ),
          const SizedBox(height: 16),
          if (_selectedDate != null && !_isWeekView)
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
                            const Icon(Icons.event, size: 18, color: Color.fromARGB(255, 255, 255, 255)),
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
