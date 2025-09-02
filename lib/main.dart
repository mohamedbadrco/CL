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
  final VoidCallback? onEventDeleted;
  final void Function(Event updatedEvent)? onEventEdited; // Added for edits

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0, // e.g., 60 pixels per hour
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
    this.onEventDeleted,
    this.onEventEdited, // Added to constructor
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                    event: event, 
                    onEventChanged: (Event? changedEvent) { 
                      if (changedEvent == null) { // Event was deleted
                        onEventDeleted?.call();
                      } else { // Event was edited
                        onEventEdited?.call(changedEvent);
                      }
                    }
                  ),
                ),
              );
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

/// A screen that displays a calendar with month and week views.
///
/// Allows users to navigate between months/weeks, select dates,
/// view events, and add new events.
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

/// State for the [CalendarScreen].
///
/// Manages the current view (month or week), selected dates,
/// event data, and navigation between different time periods.
class _CalendarScreenState extends State<CalendarScreen> {
  static const int _initialPageIndex = 10000;
  static const Duration _pageScrollDuration = Duration(milliseconds: 300);
  static const Curve _pageScrollCurve = Curves.easeInOut;

  late PageController _monthPageController;
  late PageController _weekPageController;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  // _events map now holds Event objects from database_helper.dart
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

  final dbHelper = DatabaseHelper.instance; // Instance of DatabaseHelper

  @override
  void initState() {
    super.initState();
    _selectedDate = _today; // Select today by default
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    _focusedMonth = DateTime(_today.year, _today.month);

    _monthPageController = PageController(initialPage: _calculateMonthPageIndex(_focusedMonth));
    _weekPageController = PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
    _loadEventsFromDb(); // Load all events from DB
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  /// Loads all events from the database and updates the state.
  Future<void> _loadEventsFromDb() async {
    final allEvents = await dbHelper.getAllEvents();
    final Map<DateTime, List<Event>> newEventsMap = {};
    for (var event in allEvents) {
      // Normalize date to DateTime(year, month, day) for map key
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      newEventsMap.putIfAbsent(key, () => []).add(event);
    }
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _events = newEventsMap;
      });
    }
  }

  /// Loads events for a specific [date] from the database and updates the state.
  Future<void> _loadEventsForDate(DateTime date) async {
    final key = DateTime(date.year, date.month, date.day);
    final dayEvents = await dbHelper.getEventsForDate(key);
     if (mounted) {
      setState(() {
        _events[key] = dayEvents;
      });
    }
  }

  /// Resets the database and reloads all events.
  Future<void> _resetDatabase() async {
    await dbHelper.resetDatabase();
    if (mounted) {
      setState(() {
        _events.clear();
      });
    }
    _loadEventsFromDb();
  }

  /// Calculates the page index for the month view based on the given [month].
  int _calculateMonthPageIndex(DateTime month) {
    // Calculate the difference in months from a fixed reference, e.g., _today's month
    // This reference (_today) should be consistent with how _getDateFromMonthPageIndex is calculated
    final referenceMonth = DateTime(_today.year, _today.month);
    return _initialPageIndex + (month.year - referenceMonth.year) * 12 + (month.month - referenceMonth.month);
  }

  /// Gets the date from the month page index.
  DateTime _getDateFromMonthPageIndex(int pageIndex) {
    final monthOffset = pageIndex - _initialPageIndex;
    // Use the same reference month logic
    final referenceMonth = DateTime(_today.year, _today.month);
    return DateTime(referenceMonth.year, referenceMonth.month + monthOffset, 1);
  }

  /// Calculates the page index for the week view based on the [weekStart] date.
  int _calculateWeekPageIndex(DateTime weekStart) {
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return _initialPageIndex + (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  /// Gets the date from the week page index.
  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

  /// Navigates to the previous month in the month view.
  void _goToPreviousMonth() {
    if (_monthPageController.hasClients) {
        _monthPageController.previousPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  /// Navigates to the next month in the month view.
  void _goToNextMonth() {
    if (_monthPageController.hasClients) {
        _monthPageController.nextPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  /// Navigates to the previous week in the week view.
  void _goToPreviousWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.previousPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  /// Navigates to the next week in the week view.
  void _goToNextWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.nextPage(duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  /// Toggles between month and week view.
  ///
  /// Resets the [_today] date to the current day and updates
  /// page controllers and focused dates accordingly.
  void _toggleView() {
    setState(() {
      final DateTime actualNow = DateTime.now();
      _today = DateTime(actualNow.year, actualNow.month, actualNow.day);

      _isWeekView = !_isWeekView;

      if (_isWeekView) {
        // Switching to Week View
        DateTime weekViewAnchorDate = _selectedDate ?? _today;
        _focusedWeekStart = weekViewAnchorDate.subtract(Duration(days: weekViewAnchorDate.weekday % 7));
        
        _weekPageController.dispose();
        _weekPageController = PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
        
      } else {
        // Switching to Month View
        _focusedMonth = DateTime(_today.year, _today.month); 
        int targetMonthPageIndex = _calculateMonthPageIndex(_focusedMonth);

        _monthPageController.dispose(); 
        _monthPageController = PageController(initialPage: targetMonthPageIndex);

        // Ensure _selectedDate is valid for the new _focusedMonth
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
        
        // Add post frame callback to ensure jumpToPage
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _monthPageController.hasClients) {
            // Check if the current page is already the target page to avoid unnecessary jumps
            // PageController.page can be null initially or a double.
            final currentPage = _monthPageController.page?.round();
            if (currentPage != targetMonthPageIndex) {
                 _monthPageController.jumpToPage(targetMonthPageIndex);
            }
          }
        });
      }
    });
  }

  /// Adds a new event for the given [initialDate].
  ///
  /// Opens the [AddEventPage] and reloads events for the date
  /// if a new event is added.
  void _addEvent(DateTime initialDate) async {
    // AddEventPage should return the new Event object (from database_helper.dart)
    final newEventFromPage = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        // Pass a callback to AddEventPage if it needs to inform about save
        builder: (context) => AddEventPage(date: initialDate),
      ),
    );

    if (newEventFromPage != null) {
      await dbHelper.insertEvent(newEventFromPage);
      // Reload events for the specific date to reflect the new event
      _loadEventsForDate(newEventFromPage.date);
      // Optionally, if _selectedDate should change to the new event's date:
      if (mounted) {
        setState(() {
          _selectedDate = DateTime(newEventFromPage.date.year, newEventFromPage.date.month, newEventFromPage.date.day);
        });
      }
    }
  }

  /// Shows a page with a time slot view for the given [date].
  ///
  /// Fetches events for the date from the database and displays them
  /// in a [DayScheduleView].
  void _showDayEventsTimeSlotsPage(DateTime date) async {
    // Fetch events for the date directly from the database
    // This ensures the DayScheduleView gets the most current data when it's (re)built.
    final dayKey = DateTime(date.year, date.month, date.day);
    final dayEvents = await dbHelper.getEventsForDate(dayKey);

    if (!mounted) return; // Check if the _CalendarScreenState widget is still in the tree

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext pageContext) => Scaffold( // Use a different context name for clarity
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(pageContext).pop(),
            ),
            title: Text(
              DateFormat.yMMMd().format(date),
            ),
          ),
          body: DayScheduleView(
            date: date, 
            events: dayEvents, // Pass the freshly fetched events
            hourHeight: _hourHeight,
            TaminTime: TimeOfDay(hour: _minHour, minute: 0),
            TamaxTime: TimeOfDay(hour: _maxHour, minute: 59),
            onEventDeleted: () async {
              // 1. Update the central event store for the current day
              await _loadEventsForDate(date);
              
              // 2. Refresh the DayScheduleView page
              if (mounted) { // Check mounted status of _CalendarScreenState
                Navigator.of(pageContext).pop(); // Pop the current DayScheduleView
                _showDayEventsTimeSlotsPage(date);    // Push a new one for the same date
              }
            },
            onEventEdited: (Event editedEvent) async {
              final originalDateKey = DateTime(date.year, date.month, date.day);
              final editedEventDateKey = DateTime(editedEvent.date.year, editedEvent.date.month, editedEvent.date.day);

              // 1. Update central event store for the edited event's (potentially new) date
              await _loadEventsForDate(editedEvent.date);

              // 2. If event's date changed, update central store for the original date too
              if (originalDateKey != editedEventDateKey) {
                await _loadEventsForDate(date);
              }
              
              // 3. Refresh the DayScheduleView page for its original date
              if (mounted) { // Check mounted status of _CalendarScreenState
                Navigator.of(pageContext).pop(); // Pop the current DayScheduleView
                _showDayEventsTimeSlotsPage(date); // Push a new DayScheduleView for the original date
              }
            },
          ),
        ),
      ),
    );
  }

  /// Builds the widget for a single month page in the month view.
  ///
  /// Displays the days of the [monthToDisplay], highlighting the selected date,
  /// today's date, and days with events.
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
      // Use the _events map which is populated from the DB
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

  /// Builds the stack of time labels for the week view.
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

  /// Builds the schedule view for a single day within the week view.
  ///
  /// Displays events for the given [day] within a column of [columnWidth].
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

    for (var event in events) { // event is from database_helper.dart
      final startMinutes = event.startTimeAsTimeOfDay.hour * 60 + event.startTimeAsTimeOfDay.minute;
      final endMinutes = event.endTimeAsTimeOfDay.hour * 60 + event.endTimeAsTimeOfDay.minute;
      final minHourMinutes = _minHour * 60;

      final topPosition = ((startMinutes - minHourMinutes) / 60.0) * _hourHeight;
      final eventDurationInMinutes = endMinutes - startMinutes; // durationInMinutes is a getter in DB Event
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                    event: event, 
                    onEventChanged: (Event? changedEvent) { 
                      if (changedEvent == null) { // Event deleted
                         // This is week view, onEventDeleted on DayScheduleView is not wired up here.
                         // We need to call _loadEventsForDate for the 'day' of this schedule stack.
                        _loadEventsForDate(day);
                      } else { // Event edited
                        // Similarly, call _loadEventsForDate for the original day and the new day.
                        _loadEventsForDate(changedEvent.date);
                        if (DateTime(changedEvent.date.year, changedEvent.date.month, changedEvent.date.day) != 
                            DateTime(day.year, day.month, day.day)) {
                           _loadEventsForDate(day);
                        }
                      }
                    }
                  ),
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

  /// Builds the widget for a single week page in the week view.
  ///
  /// Displays the days of the [weekStart] date, with time labels and events.
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
                    // Use the _events map which is populated from the DB
                    final daySpecificEvents = _events[dayKey] ?? [];
                    // Ensure sorting if not already sorted (DB query might sort, but good to be sure)
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
        title: Text(_isWeekView ? 'Week View' : 'Month View'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDatabase,
            tooltip: 'Reset Database',
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
                  Text(
                    monthNameDisplay,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    onPressed: _goToPreviousMonth,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    onPressed: _goToNextMonth,
                  ),
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
                           // Optionally, load events if not already loaded for the new view
                           // For week view, _buildWeekPageWidget handles fetching/filtering from _events
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
                           if (newFocusedMonth.year == _today.year && newFocusedMonth.month == _today.month) {
                            if (_selectedDate == null || _selectedDate!.month != newFocusedMonth.month || _selectedDate!.year != newFocusedMonth.year) {
                                _selectedDate = _today;
                            }
                          } else {
                             if(_selectedDate != null && (_selectedDate!.month != newFocusedMonth.month || _selectedDate!.year != newFocusedMonth.year) ){
                               _selectedDate = null;
                             }
                          }
                          // Events are loaded globally in initState and updated on add/edit/delete
                          // No need to reload all events on month change unless your logic requires it
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
