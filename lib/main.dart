// ignore_for_file: non_constant_identifier_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import './add_event_page.dart'; // Import the new AddEventPage
import './event_details_page.dart'; // Import the EventDetailsPage
import './database_helper.dart'; // Import DatabaseHelper

// Event class is now imported from database_helper.dart

// DayScheduleView class from new.dart
class DayScheduleView extends StatelessWidget {
  final DateTime date;
  final List<Event> events; // Uses Event from database_helper.dart
  final double hourHeight; // Height of each hour slot in the timeline
  final TimeOfDay TaminTime; //e.g. TimeOfDay(hour: 0, minute: 0);
  final TimeOfDay TamaxTime; //e.g., TimeOfDay(hour: 23, minute: 59)
  final VoidCallback? onEventChanged; // Changed from onEventDeleted

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0, // e.g., 60 pixels per hour
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
    this.onEventChanged, // Changed from onEventDeleted
  });

  @override
  Widget build(BuildContext context) {
    // Events are already sorted and filtered by the caller if needed,
    // but if not, ensure sorting by start time.
    final todayEvents = List<Event>.from(events) // Create a mutable copy
      ..sort((a, b) =>
      (a.startTimeAsTimeOfDay.hour * 60 + a.startTimeAsTimeOfDay.minute) -
          (b.startTimeAsTimeOfDay.hour * 60 + b.startTimeAsTimeOfDay.minute));

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
    final slotBorderColor = theme.colorScheme.outlineVariant.withOpacity(0.5);
    final timeLabelColor = theme.colorScheme.onSurface.withOpacity(0.6);

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
    final eventBgColor = theme.colorScheme.secondaryContainer;
    final eventTextColor = theme.colorScheme.onSecondaryContainer;

    for (var event in dayEvents) { // event is now from database_helper.dart
      final double topOffset = _calculateTopOffset(event.startTimeAsTimeOfDay);
      final double eventHeight = _calculateEventHeight(event.durationInMinutes);

      eventWidgets.add(
        Positioned(
          top: topOffset,
          left: 55, // Shifted right a bit
          right: 10,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event, onEventChanged: (Event? updatedEvent) {
                    // This onEventChanged is called by EventDetailsPage AFTER DB operations.
                    // It should trigger a reload in CalendarScreen.
                    onEventChanged?.call();
                    // EventDetailsPage will pop itself.
                  }),
                ),
              );
              // Data re-fetch is handled by the onEventChanged callback chain
            },
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
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.teal;
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Scrollable Calendar',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: lightColorScheme.background,
          foregroundColor: lightColorScheme.onSurface,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(color: lightColorScheme.onSurface, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: lightColorScheme.primary),
        ),
        iconTheme: IconThemeData(color: lightColorScheme.primary),
        dividerColor: lightColorScheme.outlineVariant,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: darkColorScheme.onSurface,
        ),
         textTheme: TextTheme(
          titleLarge: TextStyle(color: darkColorScheme.onSurface, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(color: darkColorScheme.primary),
        ),
        iconTheme: IconThemeData(color: darkColorScheme.primary),
        dividerColor: darkColorScheme.outlineVariant,
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
  static const int _initialPageIndex = 10000;
  static const Duration _pageScrollDuration = Duration(milliseconds: 300);
  static const Curve _pageScrollCurve = Curves.easeInOut;

  late PageController _monthPageController;
  late PageController _weekPageController;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  Map<DateTime, List<Event>> _events = {};
  DateTime _today = DateTime(
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

  final double _hourHeight = 60.0;
  final int _minHour = 0;
  final int _maxHour = 23;
  final double _timeLabelWidth = 50.0;

  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    _focusedMonth = DateTime(_today.year, _today.month);

    _monthPageController = PageController(initialPage: _calculateMonthPageIndex(_focusedMonth));
    _weekPageController = PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
    _loadEventsFromDb();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  Future<void> _loadEventsFromDb() async {
    final allEvents = await dbHelper.getAllEvents();
    final Map<DateTime, List<Event>> newEventsMap = {};
    for (var event in allEvents) {
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      newEventsMap.putIfAbsent(key, () => []).add(event);
    }
    if (mounted) {
      setState(() {
        _events = newEventsMap;
      });
    }
  }

  Future<void> _resetDatabase() async {
    await dbHelper.resetDatabase();
    // No need to clear _events locally, _loadEventsFromDb will overwrite it.
    await _loadEventsFromDb(); // Await the loading after reset.
  }

  int _calculateMonthPageIndex(DateTime month) {
    final referenceMonth = DateTime(_today.year, _today.month);
    return _initialPageIndex + (month.year - referenceMonth.year) * 12 + (month.month - referenceMonth.month);
  }

  DateTime _getDateFromMonthPageIndex(int pageIndex) {
    final monthOffset = pageIndex - _initialPageIndex;
    final referenceMonth = DateTime(_today.year, _today.month);
    return DateTime(referenceMonth.year, referenceMonth.month + monthOffset, 1);
  }

  int _calculateWeekPageIndex(DateTime weekStart) {
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return _initialPageIndex + (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

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
      final DateTime actualNow = DateTime.now();
      _today = DateTime(actualNow.year, actualNow.month, actualNow.day);
      _isWeekView = !_isWeekView;

      if (_isWeekView) {
        DateTime weekViewAnchorDate = _selectedDate ?? _today;
        _focusedWeekStart = weekViewAnchorDate.subtract(Duration(days: weekViewAnchorDate.weekday % 7));
        _weekPageController.dispose();
        _weekPageController = PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
      } else {
        _focusedMonth = DateTime(_selectedDate?.year ?? _today.year, _selectedDate?.month ?? _today.month);
        int targetMonthPageIndex = _calculateMonthPageIndex(_focusedMonth);
        _monthPageController.dispose();
        _monthPageController = PageController(initialPage: targetMonthPageIndex);

        if (_selectedDate != null &&
            (_selectedDate!.year != _focusedMonth.year || _selectedDate!.month != _focusedMonth.month)) {
          DateTime newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, _today.day);
          if (newSelectedCandidate.month != _focusedMonth.month) {
              newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
          }
          _selectedDate = newSelectedCandidate;
        } else if (_selectedDate == null) {
            DateTime newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, _today.day);
            if (newSelectedCandidate.month != _focusedMonth.month) {
                newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
            }
            _selectedDate = newSelectedCandidate;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _monthPageController.hasClients) {
            final currentPage = _monthPageController.page?.round();
            if (currentPage != targetMonthPageIndex) {
                 _monthPageController.jumpToPage(targetMonthPageIndex);
            }
          }
        });
      }
      _loadEventsFromDb(); 
    });
  }

  void _addEvent(DateTime initialDate) async {
    // AddEventPage will pop with `true` if an event was added.
    // It is responsible for saving the event to the database.
    final bool? eventWasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEventPage(date: initialDate),
      ),
    );

    if (eventWasAdded == true) {
      await _loadEventsFromDb(); // Refresh data from the database
    }
  }

  void _showDayEventsTimeSlotsPage(DateTime date) async {
    final dayKey = DateTime(date.year, date.month, date.day);
    final dayEvents = List<Event>.from(_events[dayKey] ?? []);

    if (!mounted) return;

    // EventDetailsPage (pushed from DayScheduleView) will call _loadEventsFromDb
    // via its onEventChanged callback and then pop itself.
    // So, no need to await a result or call _loadEventsFromDb after this push.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              DateFormat.yMMMd().format(date),
            ),
          ),
          body: DayScheduleView(
            date: date,
            events: dayEvents,
            hourHeight: _hourHeight,
            TaminTime: TimeOfDay(hour: _minHour, minute: 0),
            TamaxTime: TimeOfDay(hour: _maxHour, minute: 59),
            onEventChanged: _loadEventsFromDb, // Pass _loadEventsFromDb directly
          ),
        ),
      ),
    );
    // REMOVED: await _loadEventsFromDb(); 
    // This was redundant as EventDetailsPage/AddEventPage triggers the reload.
  }

  Widget _buildMonthPageWidget(BuildContext context, DateTime monthToDisplay) {
    final theme = Theme.of(context);
    final prevNextMonthTextColor = theme.colorScheme.onSurface.withOpacity(0.38);

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
                border: Border(
                  top: BorderSide(color: Colors.transparent, width: 0.5, ),
                  right: BorderSide(color: Colors.transparent, width: 0.5, ),
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
      final isTodayDate = date.year == _today.year && date.month == _today.month && date.day == _today.day;
      final dayKey = DateTime(date.year, date.month, date.day);
      final hasEvent = _events.containsKey(dayKey) && _events[dayKey]!.isNotEmpty;

      Color numberColor;
      FontWeight numberFontWeight = FontWeight.normal;
      BoxDecoration cellDecoration = BoxDecoration(
         border: Border(
           top: BorderSide(color: Colors.transparent, width: 0.5, ),
           right: BorderSide(color: Colors.transparent, width: 0.5, ),
         ),
      );

      if (isSelected) {
        cellDecoration = cellDecoration.copyWith(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        );
        numberColor = theme.colorScheme.onPrimaryContainer;
        numberFontWeight = FontWeight.bold;
      } else if (isTodayDate) {
        numberColor = theme.colorScheme.primary;
        numberFontWeight = FontWeight.bold;
      } else {
        numberColor = theme.colorScheme.onSurface;
      }

      if (isTodayDate && isSelected) {
          numberColor = theme.colorScheme.onPrimaryContainer;
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
                decoration: cellDecoration,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        fontWeight: numberFontWeight,
                        fontSize: boxSize * 0.4,
                        color: numberColor,
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
                 border: Border(
                    top: BorderSide(color: Colors.transparent, width: 0.5, ),
                    right: BorderSide(color: Colors.transparent, width: 0.5, ),
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

  Widget _buildTimeLabelStack(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabelColor = theme.colorScheme.onSurface.withOpacity(0.6);
    List<Widget> timeLabels = [];

    for (int hour = _minHour; hour <= _maxHour; hour++) {
      timeLabels.add(
        Positioned(
          top: (hour - _minHour) * _hourHeight,
          left: 0,
          width: _timeLabelWidth,
          height: _hourHeight,
          child: Container(
            padding: const EdgeInsets.only(right: 4.0),
            alignment: Alignment.centerRight,
            child: Text(
              DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour)),
              style: TextStyle(
                fontSize: 10,
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
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
      );
    }

    for (var event in events) { 
      final startMinutes = event.startTimeAsTimeOfDay.hour * 60 + event.startTimeAsTimeOfDay.minute;
      final endMinutes = event.endTimeAsTimeOfDay.hour * 60 + event.endTimeAsTimeOfDay.minute;
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
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event, onEventChanged: (Event? updatedEvent) {
                     // This callback is _loadEventsFromDb from CalendarScreen
                     _loadEventsFromDb(); 
                     // EventDetailsPage will pop itself after calling this.
                  }), 
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4.0),
              margin: const EdgeInsets.only(bottom: 1.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                event.title,
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: eventHeight > 25 ? 2 : 1,
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: stackChildren);
  }

  Widget _buildWeekPageWidget(BuildContext context, DateTime weekStart) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    final weekDays = DateFormat.EEEE().dateSymbols.STANDALONESHORTWEEKDAYS;
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: _goToNextWeek),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(width: _timeLabelWidth),
            ...weekDates.map((date) {
              bool isToday = date.year == _today.year && date.month == _today.month && date.day == _today.day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    weekDays[date.weekday % 7].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
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
                    final dayKey = DateTime(date.year, date.month, date.day);
                    final daySpecificEvents = _events[dayKey] ?? [];
                     daySpecificEvents.sort((a, b) => (a.startTimeAsTimeOfDay.hour * 60 + a.startTimeAsTimeOfDay.minute)
                        .compareTo(b.startTimeAsTimeOfDay.hour * 60 + b.startTimeAsTimeOfDay.minute));

                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: totalScrollableHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: borderColor.withOpacity(0.5), width: 0.5),
                                right: date == weekDates.last ? BorderSide(color: borderColor.withOpacity(0.5), width: 0.5) : BorderSide.none,
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
    final weekDayNames = DateFormat.EEEE().dateSymbols.STANDALONENARROWWEEKDAYS;
    final monthNameDisplay = DateFormat.yMMMM().format(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isWeekView ? '${DateFormat.MMMM().format(_focusedWeekStart)} - ${DateFormat.MMMM().format(_focusedWeekStart.add(const Duration(days:6)))}' : monthNameDisplay),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDatabase,
            tooltip: 'Reset Database & Refresh Events',
          ),
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(_isWeekView ? Icons.calendar_month_outlined : Icons.view_week_outlined),
            onPressed: _toggleView,
            tooltip: _isWeekView ? 'Switch to Month View' : 'Switch to Week View',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isWeekView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Spacer(), 
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _goToPreviousMonth,
                  ),
                   Text( 
                    monthNameDisplay,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _goToNextMonth,
                  ),
                   const Spacer(), 
                ],
              ),
            ),
          if (!_isWeekView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: weekDayNames
                    .map((name) => Expanded(
                          child: Center(
                            child: Text(
                              name.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary.withOpacity(0.8),
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
                          final newFocusedMonth = _getDateFromMonthPageIndex(pageIndex);
                          _focusedMonth = newFocusedMonth;
                        });
                      },
                      itemBuilder: (context, pageIndex) {
                        final month = _getDateFromMonthPageIndex(pageIndex);
                        return _buildMonthPageWidget(context, month);
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addEvent(_selectedDate ?? _today);
        },
        tooltip: 'Add Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}
