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
    TimeOfDay? selectedTime;
    String location = '';
    String notes = '';
    String contacts = '';
    String attachment = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Event'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                selectedTime = picked;
                              });
                            }
                          },
                          child: const Text('Select Time'),
                        ),
                        if (selectedTime != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              selectedTime!.format(context),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      'hour': selectedTime?.hour,
                      'minute': selectedTime?.minute,
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
      },
    );

    if (result != null && (result['title'] as String).trim().isNotEmpty) {
      setState(() {
        final key = DateTime(date.year, date.month, date.day);
        final eventDetails =
            "Title: ${result['title']}\nTime: ${(result['hour'] as int?)?.toString().padLeft(2, '0') ?? '--'}:${(result['minute'] as int?)?.toString().padLeft(2, '0') ?? '--'}\nLocation: ${result['location']}\nNotes: ${result['notes']}\nAttachment: ${result['attachment']}\nContacts: ${result['contacts']}";
        _events.putIfAbsent(key, () => []).add(eventDetails);
        _selectedDate = key;
      });
    }
  }

  void _showDayEventsPopup(DateTime date) {
    final events = _events[DateTime(date.year, date.month, date.day)] ?? [];
    if (events.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: events.map((event) {
                // Parse event details
                final lines = event.split('\n');
                String title = '';
                String time = '';
                String location = '';
                for (var line in lines) {
                  if (line.startsWith('Title:')) {
                    title = line.replaceFirst('Title: ', '');
                  } else if (line.startsWith('Time:')) {
                    time = line.replaceFirst('Time: ', '');
                  } else if (line.startsWith('Location:')) {
                    location = line.replaceFirst('Location: ', '');
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDayEventsFullScreen(DateTime date) async {
    final events = _events[DateTime(date.year, date.month, date.day)] ?? [];
    if (events.isEmpty) return;

    // Group events by hour
    Map<String, List<Map<String, String>>> eventsByHour = {};
    for (var event in events) {
      final lines = event.split('\n');
      String title = '';
      String time = '';
      String location = '';
      for (var line in lines) {
        if (line.startsWith('Title:')) {
          title = line.replaceFirst('Title: ', '');
        } else if (line.startsWith('Time:')) {
          time = line.replaceFirst('Time: ', '');
        } else if (line.startsWith('Location:')) {
          location = line.replaceFirst('Location: ', '');
        }
      }
      final hour = time.split(':').first;
      eventsByHour.putIfAbsent(hour, () => []).add({
        'title': title,
        'time': time,
        'location': location,
      });
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: eventsByHour.isEmpty
                ? const Center(child: Text('No events'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: eventsByHour.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${entry.key.padLeft(2, '0')}:00",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          ...entry.value.map((event) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      event['location'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      event['time'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Divider(),
                                  ],
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDayEventsTimeSlotsPage(DateTime date) async {
    final events = _events[DateTime(date.year, date.month, date.day)] ?? [];
    if (events.isEmpty) return;

    // Parse events into a list of maps with title, start hour, start minute, duration (default 1 hour if not specified)
    List<Map<String, dynamic>> parsedEvents = [];
    for (var event in events) {
      final lines = event.split('\n');
      String title = '';
      String time = '';
      String location = '';
      String notes = '';
      String contacts = '';
      String attachment = '';
      int hour = 0;
      int minute = 0;
      int duration = 1; // default 1 hour

      for (var line in lines) {
        if (line.startsWith('Title:')) {
          title = line.replaceFirst('Title: ', '');
        } else if (line.startsWith('Time:')) {
          time = line.replaceFirst('Time: ', '');
          final parts = time.split(':');
          if (parts.length == 2) {
            hour = int.tryParse(parts[0]) ?? 0;
            minute = int.tryParse(parts[1]) ?? 0;
          }
        } else if (line.startsWith('Location:')) {
          location = line.replaceFirst('Location: ', '');
        } else if (line.startsWith('Notes:')) {
          notes = line.replaceFirst('Notes: ', '');
        } else if (line.startsWith('Contacts:')) {
          contacts = line.replaceFirst('Contacts: ', '');
        } else if (line.startsWith('Attachment:')) {
          attachment = line.replaceFirst('Attachment: ', '');
        } else if (line.startsWith('Duration:')) {
          duration = int.tryParse(line.replaceFirst('Duration: ', '')) ?? 1;
        }
      }
      parsedEvents.add({
        'title': title,
        'hour': hour,
        'minute': minute,
        'duration': duration,
        'location': location,
        'notes': notes,
        'contacts': contacts,
        'attachment': attachment,
        'time': time,
      });
    }

    // Time slots from 11 AM to 10 AM next day (24 slots)
    List<int> timeSlots = List.generate(24, (i) => (11 + i) % 24);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF2FFF5);
    final accentColor = isDark ? Colors.greenAccent.shade700 : Colors.green.shade400;
    final textColor = isDark ? Colors.white : Colors.black;

    final ScrollController scrollController = ScrollController();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: accentColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          body: Container(
            color: bgColor,
            child: ListView.builder(
              controller: scrollController,
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final hour = timeSlots[index];
                final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                final ampm = hour < 12 ? 'AM' : 'PM';

                // Find events that start at this hour
                final slotEvents = parsedEvents.where((event) => event['hour'] == hour).toList();

                return Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: accentColor.withOpacity(0.2), width: 0.5),
                    ),
                    color: bgColor,
                  ),
                  child: Row(
                    children: [
                      // Time slot
                      Container(
                        width: 70,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$displayHour $ampm',
                          style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Vertical divider
                      Container(
                        width: 1,
                        height: 60,
                        color: accentColor.withOpacity(0.6),
                      ),
                      // Events area
                      Expanded(
                        child: Stack(
                          children: slotEvents.map((event) {
                            double top = (event['minute'] / 60.0) * 60.0;
                            double height = (event['duration'] ?? 1) * 60.0;
                            return Positioned(
                              top: top,
                              left: 8,
                              right: 8,
                              height: height,
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        backgroundColor: bgColor,
                                        title: Text(
                                          event['title'],
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                        content: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Time: ${event['time']}', style: TextStyle(fontSize: 18, color: accentColor)),
                                            if ((event['location'] as String).isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text('Location: ${event['location']}', style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            if ((event['notes'] as String).isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text('Notes: ${event['notes']}', style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            if ((event['contacts'] as String).isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text('Contacts: ${event['contacts']}', style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                            if ((event['attachment'] as String).isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text('Attachment: ${event['attachment']}', style: TextStyle(fontSize: 16, color: textColor)),
                                              ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text('Close', style: TextStyle(color: accentColor)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    event['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
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
                if (hasEvent) {
                  _showDayEventsTimeSlotsPage(date);
                }
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

    // Month name in English
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_focusedMonth.month - 1];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF2FFF5);
    final accentColor = isDark ? Colors.greenAccent.shade700 : Colors.green.shade400;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(_isWeekView ? 'Week View' : 'Month View', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: accentColor,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(_isWeekView ? Icons.calendar_month : Icons.view_week, color: accentColor),
            onPressed: _toggleView,
            tooltip: _isWeekView ? 'Month View' : 'Week View',
          ),
        ],
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (!_isWeekView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  // Month name and year on the left
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        _focusedMonth.year.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Navigation buttons on the right
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: accentColor),
                        onPressed: _goToPreviousMonth,
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: accentColor),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ],
              ),
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
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: accentColor,
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
        ],
      ),
    );
  }
}
