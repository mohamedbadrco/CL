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
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String location = '';
    String notes = '';
    String contacts = '';
    String attachment = '';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.scaffoldBackgroundColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final buttonColor = isDark ? Colors.greenAccent.shade700 : Colors.green.shade400;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: bgColor,
              title: Text('Add Event', style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: textColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Start Time:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: theme.copyWith(
                                    colorScheme: theme.colorScheme.copyWith(
                                      primary: buttonColor,
                                      onPrimary: Colors.white,
                                      surface: bgColor,
                                      onSurface: textColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                startTime = picked;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                        if (startTime != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              startTime!.format(context),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('End Time:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? (startTime ?? TimeOfDay.now()),
                              builder: (context, child) {
                                return Theme(
                                  data: theme.copyWith(
                                    colorScheme: theme.colorScheme.copyWith(
                                      primary: buttonColor,
                                      onPrimary: Colors.white,
                                      surface: bgColor,
                                      onSurface: textColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                endTime = picked;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                        if (endTime != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              endTime!.format(context),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: TextStyle(color: textColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) => location = value,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: TextStyle(color: textColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) => notes = value,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Attachment (URL or name)',
                        labelStyle: TextStyle(color: textColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) => attachment = value,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Contacts',
                        labelStyle: TextStyle(color: textColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: buttonColor),
                        ),
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) => contacts = value,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: buttonColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'title': title,
                      'startHour': startTime?.hour,
                      'startMinute': startTime?.minute,
                      'endHour': endTime?.hour,
                      'endMinute': endTime?.minute,
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
            "Title: ${result['title']}\nStart: ${(result['startHour'] as int?)?.toString().padLeft(2, '0') ?? '--'}:${(result['startMinute'] as int?)?.toString().padLeft(2, '0') ?? '--'}\nEnd: ${(result['endHour'] as int?)?.toString().padLeft(2, '0') ?? '--'}:${(result['endMinute'] as int?)?.toString().padLeft(2, '0') ?? '--'}\nLocation: ${result['location']}\nNotes: ${result['notes']}\nAttachment: ${result['attachment']}\nContacts: ${result['contacts']}";
        _events.putIfAbsent(key, () => []).add(eventDetails);
        _selectedDate = key;
      });
    }
  }



  void _showDayEventsTimeSlotsPage(DateTime date) async {
    final events = _events[DateTime(date.year, date.month, date.day)] ?? [];
    if (events.isEmpty) return;

    // Parse events into a list of maps with title, start/end hour/minute
    List<Map<String, dynamic>> parsedEvents = [];
    for (var event in events) {
      final lines = event.split('\n');
      String title = '';
      int startHour = 0;
      int startMinute = 0;
      int endHour = 0;
      int endMinute = 0;
      for (var line in lines) {
        if (line.startsWith('Title:')) {
          title = line.replaceFirst('Title: ', '');
        } else if (line.startsWith('Start:')) {
          final time = line.replaceFirst('Start: ', '');
          final parts = time.split(':');
          if (parts.length == 2) {
            startHour = int.tryParse(parts[0]) ?? 0;
            startMinute = int.tryParse(parts[1]) ?? 0;
          }
        } else if (line.startsWith('End:')) {
          final time = line.replaceFirst('End: ', '');
          final parts = time.split(':');
          if (parts.length == 2) {
            endHour = int.tryParse(parts[0]) ?? 0;
            endMinute = int.tryParse(parts[1]) ?? 0;
          }
        }
      }
      parsedEvents.add({
        'title': title,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final accentColor = isDark ? Colors.blue.shade400 : Colors.blue.shade200;
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
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final hourHeight = 60.0;
              return Stack(
                children: [
                  ListView.builder(
                    controller: scrollController,
                    itemCount: 24,
                    itemBuilder: (context, index) {
                      final hour = index;
                      final displayHour = hour == 0
                          ? '12 AM'
                          : hour < 12
                              ? '$hour AM'
                              : hour == 12
                                  ? '12 PM'
                                  : '${hour - 12} PM';
                      return Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 0.5),
                          ),
                          color: bgColor,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                displayHour,
                                style: TextStyle(fontSize: 15, color: textColor),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: hourHeight,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      );
                    },
                  ),
                  ...parsedEvents.map((event) {
                    int startTotalMinutes = (event['startHour'] as int) * 60 + (event['startMinute'] as int);
                    int endTotalMinutes = (event['endHour'] as int) * 60 + (event['endMinute'] as int);
                    if (endTotalMinutes <= startTotalMinutes) endTotalMinutes += 24 * 60;
                    double top = startTotalMinutes * hourHeight / 60.0;
                    double height = (endTotalMinutes - startTotalMinutes) * hourHeight / 60.0;

                    return Positioned(
                      top: top,
                      left: 69, // 60 for time + 1 for divider + 8 padding
                      right: 16,
                      height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'].isEmpty ? '(No title)' : event['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${_formatHourMinute(event['startHour'], event['startMinute'])} – ${_formatHourMinute(event['endHour'], event['endMinute'])}",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ));
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

String _formatHourMinute(int hour, int minute) {
  final h = hour % 24;
  final m = minute.toString().padLeft(2, '0');
  final ampm = h < 12 ? 'am' : 'pm';
  final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$displayHour:$m$ampm';
}
