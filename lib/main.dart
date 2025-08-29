import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// Event class from new.dart
class Event {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final String notes;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.notes = '',
  });

  int get durationInMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }
}

// DayScheduleView class from new.dart
class DayScheduleView extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final double hourHeight; // Height of each hour slot in the timeline
  final TimeOfDay TaminTime; //e.g. TimeOfDay(hour: 0, minute: 0);
  final TimeOfDay TamaxTime; //e.g., TimeOfDay(hour: 23, minute: 59)

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0, // e.g., 60 pixels per hour
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
  });

  @override
  Widget build(BuildContext context) {
    final todayEvents = events.where((event) {
      return true; // Assuming events are already filtered for the day
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final slotBorderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final timeLabelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;


    for (int i = 0; i < totalHours; i++) {
      final hour = TaminTime.hour + i;
      timeSlots.add(
        Positioned(
          top: i * hourHeight,
          left: 50, // For time labels
          right: 0,
          child: Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: slotBorderColor, width: 0.5),
                bottom: (i == totalHours - 1)
                    ? BorderSide(color: slotBorderColor, width: 0.5)
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      );
      timeSlots.add(
        Positioned(
          top: i * hourHeight - (hourHeight / 4), // Adjust for centering
          left: 0,
          child: Container(
            width: 45, // Width of the time label area
            height: hourHeight,
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat('h a').format(
                  DateTime(date.year, date.month, date.day, hour)),
              style: TextStyle(fontSize: 12, color: timeLabelColor),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final eventBgColor = isDark ? Colors.teal.shade700 : Colors.teal.shade400; // Accent color for events
    final eventTextColor = isDark ? Colors.white : Colors.white; // Text on event boxes


    for (var event in dayEvents) {
      final double topOffset = _calculateTopOffset(event.startTime);
      final double eventHeight = _calculateEventHeight(event.durationInMinutes);

      eventWidgets.add(
        Positioned(
          top: topOffset,
          left: 55, // Shifted right a bit
          right: 10, 
          child: Container(
            height: eventHeight,
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: eventBgColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.title,
              style: TextStyle(
                  color: eventTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
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
    return calculatedHeight < 20.0 ? 20.0 : calculatedHeight;
  }
}

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
        scaffoldBackgroundColor: const Color(0xFFFAFDFB), // Light mode background
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal, // Used for generating other colors if not specified
        ).copyWith(
          primary: Colors.teal.shade600, // Light mode accent
          secondary: Colors.teal.shade400,
          surface: const Color(0xFFFAFDFB), // Background for cards, dialogs
          surfaceVariant: Colors.teal.shade50, // For subtle containers like time picker buttons
          surfaceContainerHighest: Colors.teal.shade100, // Slightly more prominent containers
          onPrimary: Colors.white, // Text on primary color
          onSecondary: Colors.black,
          onSurface: const Color(0xFF202124), // Main text color
          onSurfaceVariant: Colors.teal.shade700, // Text on surfaceVariant
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFAFDFB), // Light mode app bar
          foregroundColor: const Color(0xFF202124), // Light mode app bar text/icons
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF202124)),
          bodyMedium: TextStyle(color: Color(0xFF202124)),
          titleLarge: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Color(0xFF00897B)), // For button text if needed
        ),
        iconTheme: IconThemeData(color: Colors.teal.shade600),
        dividerColor: Colors.grey.shade300,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF202124), // Dark mode background
        colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.teal,
            brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.teal.shade300, // Dark mode accent
          secondary: Colors.teal.shade200,
          surface: const Color(0xFF202124), // Background for cards, dialogs
          surfaceVariant: Colors.grey.shade800, // For subtle containers
          surfaceContainerHighest: Colors.grey.shade700, // Slightly more prominent
          onPrimary: Colors.black, // Text on primary color
          onSecondary: Colors.black,
          onSurface: const Color(0xFFE8EAED), // Main text color
          onSurfaceVariant: Colors.teal.shade200, // Text on surfaceVariant
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF202124), // Dark mode app bar
          foregroundColor: const Color(0xFFE8EAED), // Dark mode app bar text/icons
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE8EAED)),
          bodyMedium: TextStyle(color: Color(0xFFE8EAED)),
          titleLarge: TextStyle(color: Color(0xFFE8EAED), fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: Color(0xFF4DB6AC)),
        ),
        iconTheme: IconThemeData(color: Colors.teal.shade300),
        dividerColor: Colors.grey.shade700,
      ),
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
  final Map<DateTime, List<Event>> _events = {}; // Changed to List<Event>
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
    TimeOfDay? startTime; // Nullable, to be defaulted in StatefulBuilder
    TimeOfDay? endTime;   // Nullable, to be defaulted in StatefulBuilder
    String location = '';
    String notes = '';

    final currentTheme = Theme.of(context);
    final dialogBgColor = currentTheme.colorScheme.surface;
    final dialogTextColor = currentTheme.colorScheme.onSurface;
    final dialogAccentColor = currentTheme.colorScheme.primary;
    // final dialogOnAccentColor = currentTheme.colorScheme.onPrimary; // Kept for Add button

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        // Use a local variable for theme inside builder to ensure it has the context
        final dialogTheme = Theme.of(context);

        return Theme(
          data: dialogTheme, // Use the context-aware theme
          child: StatefulBuilder(
            builder: (context, setState) {
              // Default times if null
              if (startTime == null) {
                startTime = TimeOfDay.now();
                if (endTime == null) { // Only default endTime if it wasn't already set/picked
                  final now = DateTime.now();
                  final defaultEndTime = DateTime(now.year, now.month, now.day, startTime!.hour, startTime!.minute).add(const Duration(hours: 1));
                  endTime = TimeOfDay.fromDateTime(defaultEndTime);
                }
              }

              return AlertDialog(
                backgroundColor: dialogBgColor,
                title: Text('Add Event', style: TextStyle(color: dialogTextColor)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(color: dialogTextColor.withOpacity(0.7)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor, width: 2),
                          ),
                        ),
                        style: TextStyle(color: dialogTextColor),
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dialogTheme.colorScheme.surfaceVariant, // Subtle background
                                foregroundColor: dialogAccentColor, // Accent color for text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0.0), // Perfectly square
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0, // Flat appearance
                                side: BorderSide(color: dialogAccentColor.withOpacity(0.5)) // Optional: subtle border
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? TimeOfDay.now(), // Fallback just in case
                                );
                                if (picked != null) {
                                  setState(() {
                                    startTime = picked;
                                    // Optional: Adjust end time if start time changes and end time was default or is now before start time
                                    if (endTime != null && (picked.hour * 60 + picked.minute) >= (endTime!.hour * 60 + endTime!.minute)){
                                       final newEndTime = DateTime(0,0,0, picked.hour, picked.minute).add(const Duration(hours:1));
                                       endTime = TimeOfDay.fromDateTime(newEndTime);
                                    }
                                  });
                                }
                              },
                              child: Text(
                                // startTime is guaranteed to be non-null here due to defaulting logic
                                startTime!.format(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.arrow_forward, color: dialogTextColor.withOpacity(0.7)),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dialogTheme.colorScheme.surfaceVariant, // Subtle background
                                foregroundColor: dialogAccentColor, // Accent color for text
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0.0), // Perfectly square
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0, // Flat appearance
                                side: BorderSide(color: dialogAccentColor.withOpacity(0.5)) // Optional: subtle border
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: endTime ?? startTime ?? TimeOfDay.now(), // Fallback
                                );
                                if (picked != null) {
                                  setState(() {
                                    endTime = picked;
                                  });
                                }
                              },
                              child: Text(
                                // endTime is guaranteed to be non-null here due to defaulting logic
                                endTime!.format(context),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: TextStyle(color: dialogTextColor.withOpacity(0.7)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor, width: 2),
                          ),
                        ),
                        style: TextStyle(color: dialogTextColor),
                        onChanged: (value) => location = value,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          labelStyle: TextStyle(color: dialogTextColor.withOpacity(0.7)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: dialogAccentColor, width: 2),
                          ),
                        ),
                        style: TextStyle(color: dialogTextColor),
                        onChanged: (value) => notes = value,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: dialogAccentColor)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dialogAccentColor,
                      foregroundColor: dialogTheme.colorScheme.onPrimary, // Use onPrimary for text on accent button
                    ),
                    onPressed: () {
                      if (title.trim().isEmpty || startTime == null || endTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Title, start time, and end time are required.')),
                        );
                        return;
                      }
                      if ((endTime!.hour * 60 + endTime!.minute) <= (startTime!.hour * 60 + startTime!.minute)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('End time must be after start time.')),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'title': title,
                        'startHour': startTime?.hour,
                        'startMinute': startTime?.minute,
                        'endHour': endTime?.hour,
                        'endMinute': endTime?.minute,
                        'location': location,
                        'notes': notes,
                      });
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (result != null && result['title'] != null && (result['title'] as String).trim().isNotEmpty) {
      // startTime and endTime null checks are implicitly handled by the Add button's validation
        final newEvent = Event(
          title: result['title'] as String,
          startTime: TimeOfDay(hour: result['startHour'] as int, minute: result['startMinute'] as int),
          endTime: TimeOfDay(hour: result['endHour'] as int, minute: result['endMinute'] as int),
          location: result['location'] as String? ?? '',
          notes: result['notes'] as String? ?? '',
        );

        setState(() {
          final key = DateTime(date.year, date.month, date.day);
          _events.putIfAbsent(key, () => []).add(newEvent);
          _selectedDate = key; // Optionally select the date when an event is added
        });
    }
  }

  void _showDayEventsTimeSlotsPage(DateTime date) {
    final dayEvents = _events[DateTime(date.year, date.month, date.day)] ?? [];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back), 
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Schedule for ${DateFormat.yMMMd().format(date)}',
            ),
          ),
          body: DayScheduleView(
            date: date,
            events: dayEvents,
            // TaminTime: const TimeOfDay(hour: 7, minute: 0), 
            // TamaxTime: const TimeOfDay(hour: 22, minute: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveDaysGrid(BuildContext context) {
    final theme = Theme.of(context); 
    final isDark = theme.brightness == Brightness.dark;
    final gridBorderColor = isDark ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.withOpacity(0.2);
    final prevNextMonthTextColor = theme.disabledColor.withOpacity(0.5);
    final todayIndicatorColor = isDark ? Colors.teal.shade300 : Colors.teal.shade600; 
    final selectedDayBgColor = todayIndicatorColor.withOpacity(0.2);


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
                color: theme.scaffoldBackgroundColor.withOpacity(0.5), 
                border: Border(
                  top: BorderSide(color: gridBorderColor, width: 0.5,),
                  right: BorderSide(color: gridBorderColor, width: 0.5,),
                ),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: boxSize * 0.35,
                    color: prevNextMonthTextColor,
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
                       _events[DateTime(date.year, date.month, date.day)]!.isNotEmpty;

      Color? numberColor = theme.colorScheme.onSurface; 
      FontWeight numberFontWeight = FontWeight.normal;

      if (date.year == _today.year &&
          date.month == _today.month &&
          date.day == _today.day) {
        numberColor = todayIndicatorColor;
        numberFontWeight = FontWeight.bold;
      } else if (isSelected) {
        numberColor = todayIndicatorColor; 
        numberFontWeight = FontWeight.bold;
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
                _showDayEventsTimeSlotsPage(date);
              },
              onDoubleTap: () { 
                _addEvent(date);
              },
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  color: isSelected ? selectedDayBgColor : null,
                  border: Border(
                    top: BorderSide(color: gridBorderColor, width: 0.5,),
                    right: BorderSide(color: gridBorderColor, width: 0.5,),
                  ),
                  borderRadius: isSelected ? BorderRadius.circular(8) : null, 
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: numberFontWeight,
                          fontSize: boxSize * 0.4,
                          color: numberColor,
                        ),
                      ),
                    ),
                    if (hasEvent)
                      Positioned(
                        right: boxSize * 0.1,
                        bottom: boxSize * 0.1,
                        child: Icon(Icons.circle, size: boxSize * 0.15, color: theme.colorScheme.secondary.withOpacity(0.8)),
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
                color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                border: Border(
                  top: BorderSide(color: gridBorderColor, width: 0.5,),
                  right: BorderSide(color: gridBorderColor, width: 0.5,),
                ),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: boxSize * 0.35,
                    color: prevNextMonthTextColor,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weekDayHeaderColor = theme.colorScheme.primary; 
    final dateNumberColor = theme.colorScheme.onSurface;
    final todayDateColor = theme.colorScheme.primary; 
    final borderColor = isDark ? Colors.grey.shade700.withOpacity(0.5) : Colors.grey.withOpacity(0.2);


    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<DateTime> weekDates = List.generate(7, (i) => _focusedWeekStart.add(Duration(days: i)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left), 
                onPressed: _goToPreviousWeek,
              ),
              Text(
                "${DateFormat.MMMd().format(weekDates.first)} - ${DateFormat.MMMd().format(weekDates.last)}",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right), 
                onPressed: _goToNextWeek,
              ),
            ],
          ),
        ),
        Row(
          children: weekDates.map((date) {
            final isToday = date.year == _today.year &&
                            date.month == _today.month &&
                            date.day == _today.day;
            return Expanded(
              child: InkWell(
                onTap: () => _showDayEventsTimeSlotsPage(date), 
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: borderColor, width: 0.5,),
                      left: date == weekDates.first ? BorderSide(color: borderColor, width: 0.5,) : BorderSide.none,
                    ),
                    color: isToday ? theme.colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        weekDays[date.weekday % 7].substring(0,3).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: isToday ? todayDateColor : weekDayHeaderColor.withOpacity(0.8)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${date.day}",
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 18,
                          color: isToday ? todayDateColor : dateNumberColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 24, 
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.add_circle_outline, size: 18, color: theme.iconTheme.color?.withOpacity(0.7)),
                          tooltip: "Add Event to ${DateFormat.MMMd().format(date)}",
                          onPressed: () => _addEvent(date),
                        ),
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
              final daySpecificEvents = _events[DateTime(date.year, date.month, date.day)] ?? [];
              daySpecificEvents.sort((a,b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(b.startTime.hour * 60 + b.startTime.minute));

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: borderColor,width: 0.5,),
                      left: date == weekDates.first ? BorderSide(color: borderColor, width: 0.5,) : BorderSide.none,
                      top: BorderSide(color: borderColor, width: 0.5,)
                    ),
                  ),
                  child: ListView(
                    children: daySpecificEvents.isEmpty
                        ? [
                            if (date.day == weekDates.first.day) 
                              Padding(
                                padding: const EdgeInsets.all(8.0).copyWith(top:16),
                                child: Center(
                                  child: Text(
                                    "No events",
                                    style: TextStyle(
                                      color: theme.disabledColor,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ]
                        : daySpecificEvents
                            .map((event) => Card(
                                  elevation: 1.0,
                                  color: theme.colorScheme.primary.withOpacity(isDark ? 0.3: 0.15),
                                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         Text(
                                           event.title, 
                                           style: TextStyle(
                                             fontWeight: FontWeight.bold, 
                                             fontSize: 11,
                                             color: theme.colorScheme.onSurface
                                           ),
                                           maxLines: 1,
                                           overflow: TextOverflow.ellipsis,
                                          ),
                                         Text(
                                           '${event.startTime.format(context)} - ${event.endTime.format(context)}',
                                           style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                          ),
                                         if (event.location.isNotEmpty) 
                                           Text(
                                             'Loc: ${event.location}', 
                                             style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                                             maxLines: 1,
                                             overflow: TextOverflow.ellipsis,
                                            ),
                                       ],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = theme.scaffoldBackgroundColor;
    final accentColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;


    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_focusedMonth.month - 1];

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
      backgroundColor: bgColor, 
      body: Column(
        children: [
          if (!_isWeekView) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: accentColor, 
                          fontSize: 26,
                        ),
                      ),
                      Text(
                        _focusedMonth.year.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textColor.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, size: 28), 
                        onPressed: _goToPreviousMonth,
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, size: 28), 
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_isWeekView) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays
                    .map((name) => Expanded(
                          child: Center(
                            child: Text(
                              name.substring(0,3).toUpperCase(), 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: accentColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: !_isWeekView
                  ? SingleChildScrollView( 
                      child: _buildResponsiveDaysGrid(context),
                    )
                  : _buildWeekView(context), 
            ),
          ),
          const SizedBox(height: 8), 
        ],
      ),
    );
  }
}
