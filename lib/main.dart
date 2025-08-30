// ignore_for_file: non_constant_identifier_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import './add_event_page.dart'; // Import the new AddEventPage

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
  static const int _initialPageIndex = 10000; // For "infinite" scrolling
  static const Duration _pageScrollDuration = Duration(milliseconds: 300);
  static const Curve _pageScrollCurve = Curves.easeInOut;

  late PageController _monthPageController;
  late PageController _weekPageController;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
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

  final double _hourHeight = 50.0;
  final int _minHour = 0;
  final int _maxHour = 23;
  final double _timeLabelWidth = 50.0;

  @override
  void initState() {
    super.initState();
    if (_focusedMonth.year == _today.year && _focusedMonth.month == _today.month) {
      _selectedDate = _today;
    }
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));

    _monthPageController = PageController(initialPage: _calculateMonthPageIndex(_focusedMonth));
    _weekPageController = PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  // --- PageView Indexing Helper Methods ---
  int _calculateMonthPageIndex(DateTime month) {
    // Calculates a page index based on the difference from a reference start (e.g., _today)
    // This allows for a large number of pages before and after the initial month.
    return _initialPageIndex + (month.year - _today.year) * 12 + (month.month - _today.month);
  }

  DateTime _getDateFromMonthPageIndex(int pageIndex) {
    final monthOffset = pageIndex - _initialPageIndex;
    return DateTime(_today.year, _today.month + monthOffset, 1);
  }

  int _calculateWeekPageIndex(DateTime weekStart) {
    // Calculates page index based on week difference from _today's week start
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return _initialPageIndex + (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

  // --- Navigation Methods ---
  void _goToPreviousMonth() {
    if (_monthPageController.hasClients) {
        _monthPageController.previousPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToNextMonth() {
    if (_monthPageController.hasClients) {
        _monthPageController.nextPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToPreviousWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.previousPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToNextWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.nextPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _toggleView() {
    setState(() {
      _isWeekView = !_isWeekView;
      if (_isWeekView) {
        // When switching to week view, focus on the week of the currently selected date or today
        _focusedWeekStart = _selectedDate != null
            ? _selectedDate!.subtract(Duration(days: _selectedDate!.weekday % 7))
            : _today.subtract(Duration(days: _today.weekday % 7));
        if (_weekPageController.hasClients) {
            _weekPageController.jumpToPage(_calculateWeekPageIndex(_focusedWeekStart));
        }
      } else {
        // When switching to month view, focus on the month of the currently selected date or today
        _focusedMonth = _selectedDate != null
            ? DateTime(_selectedDate!.year, _selectedDate!.month)
            : DateTime(_today.year, _today.month);
        if (_monthPageController.hasClients) {
            _monthPageController.jumpToPage(_calculateMonthPageIndex(_focusedMonth));
        }
      }
    });
  }

  void _addEvent(DateTime date) async {
    final result = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (context) => AddEventPage(date: date),
      ),
    );

    if (result != null) {
      setState(() {
        final key = DateTime(date.year, date.month, date.day);
        _events.putIfAbsent(key, () => []).add(result);
        _selectedDate = key;
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
          ),
        ),
      ),
    );
  }

  Widget _buildMonthPageWidget(BuildContext context, DateTime monthToDisplay) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gridBorderColor = isDark ? Colors.grey.shade700.withOpacity(0.0) : Colors.grey.withOpacity(0.0);
    final prevNextMonthTextColor = theme.disabledColor.withOpacity(0.5);
    final todayIndicatorColor = isDark ? Colors.teal.shade300 : Colors.teal.shade600;
    final selectedDayBgColor = todayIndicatorColor.withOpacity(0.2);

    final firstDayOfMonth = DateTime(monthToDisplay.year, monthToDisplay.month, 1);
    final daysInMonth = DateTime(monthToDisplay.year, monthToDisplay.month + 1, 0).day;
    final weekdayOffset = firstDayOfMonth.weekday % 7;
    List<Widget> dayWidgets = [];

    final prevMonth = DateTime(monthToDisplay.year, monthToDisplay.month - 1);
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
      final date = DateTime(monthToDisplay.year, monthToDisplay.month, day);
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
                  // Update _focusedMonth as well if the selected date changes the month context
                  // This is primarily handled by PageView's onPageChanged now
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
      physics: const NeverScrollableScrollPhysics(), // Important for PageView
      children: dayWidgets,
    );
  }

  Widget _buildTimeLabelStack(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabelColor = theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600;
    List<Widget> timeLabels = [];

    for (int hour = _minHour; hour <= _maxHour; hour++) {
      timeLabels.add(
        Positioned(
          top: (hour - _minHour) * _hourHeight,
          left: 0,
          width: _timeLabelWidth,
          height: _hourHeight,
          child: Container(
            alignment: Alignment.topRight,
            child: Text(
              DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour)),
              style: TextStyle(
                fontSize: 12,
                color: timeLabelColor,
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: timeLabels);
  }

  Widget _buildSingleDayScheduleStack(BuildContext context, DateTime day, List<Event> events, double columnWidth) {
    final theme = Theme.of(context);
    List<Widget> stackChildren = [];

    for (int hour = _minHour; hour <= _maxHour; hour++) {
      stackChildren.add(
        Positioned(
          top: (hour - _minHour) * _hourHeight,
          left: 0,
          width: columnWidth,
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
      );
    }

    for (var event in events) {
      final startMinutes = event.startTime.hour * 60 + event.startTime.minute;
      final endMinutes = event.endTime.hour * 60 + event.endTime.minute;
      final minHourMinutes = _minHour * 60;

      final topPosition = ((startMinutes - minHourMinutes) / 60.0) * _hourHeight;
      final eventDurationInMinutes = endMinutes - startMinutes;
      double eventHeight = (eventDurationInMinutes / 60.0) * _hourHeight;

      if (eventHeight < _hourHeight / 3) {
          eventHeight = _hourHeight / 3;
      }
      if (topPosition < 0) continue;
      if (topPosition + eventHeight > (_maxHour - _minHour + 1) * _hourHeight) {
          eventHeight = ((_maxHour - _minHour + 1) * _hourHeight) - topPosition;
      }
      if (eventHeight <=0) continue;

      stackChildren.add(
        Positioned(
          top: topPosition,
          left: 2.0,
          width: columnWidth - 4.0,
          height: eventHeight,
          child: Container(
            padding: const EdgeInsets.all(4.0),
            margin: const EdgeInsets.only(bottom: 1.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              event.title,
              style: TextStyle(
                color: theme.colorScheme.onSecondary.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: eventHeight > 25 ? 2 : 1,
            ),
          ),
        ),
      );
    }
    return Stack(children: stackChildren);
  }

  Widget _buildWeekPageWidget(BuildContext context, DateTime weekStart) {
    final theme = Theme.of(context);
    final weekDayHeaderColor = theme.colorScheme.primary;
    final borderColor = theme.dividerColor;

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    List<DateTime> weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final totalScrollableHeight = (_maxHour - _minHour + 1) * _hourHeight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: _goToPreviousWeek),
              Text(
                "${DateFormat.MMMd().format(weekDates.first)} - ${DateFormat.MMMd().format(weekDates.last)}",
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _goToNextWeek),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(width: _timeLabelWidth),
            ...weekDates.map((date) {
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    weekDays[date.weekday % 7].substring(0,3).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: weekDayHeaderColor.withOpacity(0.8),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        Expanded(
          child: SingleChildScrollView( // Important for the content within the PageView page
            child: SizedBox(
              height: totalScrollableHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _timeLabelWidth,
                    height: totalScrollableHeight,
                    child: _buildTimeLabelStack(context),
                  ),
                  ...weekDates.map((date) {
                    final daySpecificEvents = _events[DateTime(date.year, date.month, date.day)] ?? [];
                    daySpecificEvents.sort((a, b) => (a.startTime.hour * 60 + a.startTime.minute)
                        .compareTo(b.startTime.hour * 60 + b.startTime.minute));

                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: totalScrollableHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: borderColor, width: 0.5),
                                right: date == weekDates.last ? BorderSide(color: borderColor, width: 0.5) : BorderSide.none,
                              ),
                            ),
                            child: _buildSingleDayScheduleStack(context, date, daySpecificEvents, constraints.maxWidth),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final accentColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // This monthName is now only for the header in month view, which is outside the PageView
    final monthNameDisplay = DateFormat.MMMM().format(_focusedMonth);
    final yearDisplay = _focusedMonth.year.toString();


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
          if (!_isWeekView) // Month View Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthNameDisplay, // Use dynamically calculated name based on _focusedMonth
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: accentColor,
                          fontSize: 26,
                        ),
                      ),
                      Text(
                        yearDisplay, // Use dynamically calculated year
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
          if (!_isWeekView) // Weekday Headers for Month View
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
              child: _isWeekView
                  ? PageView.builder(
                      controller: _weekPageController,
                      onPageChanged: (pageIndex) {
                        setState(() {
                          _focusedWeekStart = _getDateFromWeekPageIndex(pageIndex);
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        final weekStart = _getDateFromWeekPageIndex(pageIndex);
                        return _buildWeekPageWidget(context, weekStart);
                      },
                    )
                  : PageView.builder(
                      controller: _monthPageController,
                      onPageChanged: (pageIndex) {
                        setState(() {
                          _focusedMonth = _getDateFromMonthPageIndex(pageIndex);
                           if (_focusedMonth.year == _today.year && _focusedMonth.month == _today.month) {
                            _selectedDate = _today;
                          } else {
                            // Keep _selectedDate if it's in the new _focusedMonth, otherwise clear it or set to first day.
                            // For simplicity, clearing it if month changes:
                             if(_selectedDate != null && (_selectedDate!.month != _focusedMonth.month || _selectedDate!.year != _focusedMonth.year) ){
                               _selectedDate = null;
                             }
                          }
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        final month = _getDateFromMonthPageIndex(pageIndex);
                        // The SingleChildScrollView is removed here, as PageView handles scrolling.
                        // _buildMonthPageWidget returns the GridView directly.
                        return _buildMonthPageWidget(context, month);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

