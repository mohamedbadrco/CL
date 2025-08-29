import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for DateFormat

void main() {
  runApp(const CalendarApp());
}

// Event class from new.dart
class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final String notes;
  // final String contacts; // Assuming these were intended fields
  // final String attachment;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
    // required this.contacts,
    // required this.attachment,
  });

  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }
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
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255), 
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary:  const Color(0xFFF2FFF5),
          secondary: const Color.fromARGB(255, 255, 255, 255),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor:  Color.fromARGB(255, 251, 251, 251), 
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
  // Updated to store List<Event>
  final Map<DateTime, List<Event>> _events = {}; 
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
    // String contacts = ''; // Not used in Event class as defined in new.dart
    // String attachment = ''; // Not used in Event class as defined in new.dart

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
                    if (title.trim().isNotEmpty && startTime != null && endTime != null) {
                       Navigator.pop(context, {
                        'title': title,
                        'startTime': startTime,
                        'endTime': endTime,
                        'location': location,
                        'notes': notes,
                      });
                    } else {
                      // Optionally show an error or prevent closing if fields are missing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Title, Start Time, and End Time are required.')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        final key = DateTime(date.year, date.month, date.day);
        final newEvent = Event(
          title: result['title'] as String,
          startTime: result['startTime'] as TimeOfDay,
          endTime: result['endTime'] as TimeOfDay,
          location: result['location'] as String,
          notes: result['notes'] as String,
        );
        _events.putIfAbsent(key, () => []).add(newEvent);
        _selectedDate = key;
      });
    }
  }

  void _showDayEventsTimeSlotsPage(DateTime date) async {
    final dayEvents = _events[DateTime(date.year, date.month, date.day)] ?? [];
    // if (dayEvents.isEmpty) return; // DayScheduleView can handle empty events

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final appBarColor = isDark ? theme.appBarTheme.backgroundColor ?? Colors.black : const Color.fromARGB(255, 251, 251, 251);


    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: appBarColor, 
            foregroundColor: textColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              DateFormat('MMMM d, yyyy').format(date),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          body: DayScheduleView(
            date: date,
            events: dayEvents,
            // Optionally customize hourHeight, TaminTime, TamaxTime
            // hourHeight: 60.0, 
            // TaminTime: const TimeOfDay(hour: 0, minute: 0),
            // TamaxTime: const TimeOfDay(hour: 23, minute: 59), 
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

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final hasEvent = _events.containsKey(DateTime(date.year, date.month, date.day)) && 
                       (_events[DateTime(date.year, date.month, date.day)]?.isNotEmpty ?? false);

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
                // Always navigate, DayScheduleView will show "No events" if empty
                _showDayEventsTimeSlotsPage(date);
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
              // Format as "Month Day - Month Day" or "Month Day - Day" if same month
              "${DateFormat('MMM d').format(weekDates.first)} - ${weekDates.first.month == weekDates.last.month ? DateFormat('d').format(weekDates.last) : DateFormat('MMM d').format(weekDates.last)}, ${weekDates.first.year}",
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
            final isToday = date.year == _today.year && date.month == _today.month && date.day == _today.day;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _showDayEventsTimeSlotsPage(date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    color: isToday ? Colors.blue.withOpacity(0.1) : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekDays[date.weekday % 7],
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isToday ? Colors.blue : null),
                      ),
                      Text(
                        "${date.day}", // Just the day number
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isToday ? Colors.blue : null,
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
              ),
            );
          }).toList(),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: weekDates.map((date) {
              final dayEvents = _events[DateTime(date.year, date.month, date.day)] ?? [];
              // For week view, we might want a summarised view or clickable areas that lead to DayScheduleView
              // For simplicity here, showing a count or small indicators.
              // Tapping the date header already navigates to DayScheduleView.
              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 0.5,
                      ),
                       left: date.weekday % 7 == 0 ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
                    ),
                  ),
                  child: ListView(
                    children: dayEvents.isEmpty
                        ? [
                            if (date.day == _today.day && date.month == _today.month && date.year == _today.year)
                             Container(height: 5, color: Colors.blue) // Current time indicator placeholder
                          ]
                        : dayEvents.map((event) => Tooltip(
                              message: "${event.title} (${DateFormat.jm().format(DateTime(date.year,date.month,date.day,event.startTime.hour,event.startTime.minute))})",
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
    final monthName = DateFormat('MMMM').format(_focusedMonth); // Using DateFormat for month name

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

// DayScheduleView class from new.dart
class DayScheduleView extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final double hourHeight; 
  final TimeOfDay TaminTime; 
  final TimeOfDay TamaxTime; 

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0, 
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
  });

  @override
  Widget build(BuildContext context) {
    final todayEvents = events.where((event) {
      return true; 
    }).toList()
      ..sort((a, b) =>
      (a.startTime.hour * 60 + a.startTime.minute) -
          (b.startTime.hour * 60 + b.startTime.minute));

    return SingleChildScrollView(
      child: Stack(
        children: [
          _buildTimeSlots(context),
          _buildEvents(context, todayEvents),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context) {
    List<Widget> timeSlots = [];
    final int totalHours = TamaxTime.hour - TaminTime.hour + 1;

    for (int i = 0; i < totalHours; i++) {
      final hour = TaminTime.hour + i;
      timeSlots.add(
        Positioned(
          top: i * hourHeight,
          left: 50, 
          right: 0,
          child: Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: (i == totalHours - 1)
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      );
      timeSlots.add(
        Positioned(
          top: i * hourHeight - (hourHeight / 4), 
          left: 0,
          child: Container(
            width: 45, 
            height: hourHeight,
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat('h a').format(
                  DateTime(date.year, date.month, date.day, hour)),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }
    double totalHeight = totalHours * hourHeight;

    return SizedBox(
      height: totalHeight,
      child: Stack(children: timeSlots),
    );
  }

  Widget _buildEvents(BuildContext context, List<Event> dayEvents) {
    List<Widget> eventWidgets = [];

    if (dayEvents.isEmpty) {
      return Positioned(
        top: (TamaxTime.hour - TaminTime.hour +1) * hourHeight / 2 - 30, // Center vertically
        left: 50,
        right: 10,
        child: Center(
          child: Text(
            "No events scheduled for this day.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ),
      );
    }

    for (var event in dayEvents) {
      final double topOffset = _calculateTopOffset(event.startTime);
      final double eventHeight = _calculateEventHeight(event.durationInMinutes);

      eventWidgets.add(
        Positioned(
          top: topOffset,
          left: 55, // Align with the right of the time labels + some padding
          right: 10, 
          child: Container(
            height: eventHeight,
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(bottom: 1), // Minimal spacing
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Text(
              event.title,
              style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }
    double totalStackHeight = (TamaxTime.hour - TaminTime.hour + 1) * hourHeight;

    return SizedBox(
      height: totalStackHeight, 
      child: Stack(children: eventWidgets),
    );
  }

  double _calculateTopOffset(TimeOfDay startTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final TaminMinutes = TaminTime.hour * 60 + TaminTime.minute;
    final minutesFromDisplayStart = startMinutes - TaminMinutes;
    return (minutesFromDisplayStart / 60.0) * hourHeight;
  }

  double _calculateEventHeight(int durationInMinutes) {
    // Ensure minimum height for very short events to be visible
    final calculatedHeight = (durationInMinutes / 60.0) * hourHeight;
    return calculatedHeight < 15.0 ? 15.0 : calculatedHeight; // Min height of 15px
  }
}
