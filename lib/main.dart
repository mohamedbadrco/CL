import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:google_fonts/google_fonts.dart'; // Added for Google Fonts
import './add_event_page.dart'; // Import the new AddEventPage
import './event_details_page.dart'; // Import the EventDetailsPage
import './database_helper.dart'; // Import DatabaseHelper
import './api/gemini_service.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Commented out, ensure it's handled if needed

class DayScheduleView extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final double hourHeight;
  final TimeOfDay TaminTime;
  final TimeOfDay TamaxTime;
  final VoidCallback? onEventChanged;

  const DayScheduleView({
    super.key,
    required this.date,
    required this.events,
    this.hourHeight = 60.0,
    this.TaminTime = const TimeOfDay(hour: 0, minute: 0),
    this.TamaxTime = const TimeOfDay(hour: 23, minute: 59),
    this.onEventChanged,
  });

  @override
  Widget build(BuildContext context) {
    final todayEvents = List<Event>.from(events)
      ..sort(
        (a, b) =>
            (a.startTimeAsTimeOfDay.hour * 60 + a.startTimeAsTimeOfDay.minute) -
            (b.startTimeAsTimeOfDay.hour * 60 + b.startTimeAsTimeOfDay.minute),
      );

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
    final slotBorderColor = theme.colorScheme.outlineVariant;
    final timeLabelColor = theme.colorScheme.onSurface;

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
          top: i * hourHeight - (hourHeight / 4),
          left: 0,
          child: Container(
            width: 45,
            height: hourHeight,
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat(
                'h a',
              ).format(DateTime(date.year, date.month, date.day, hour)),
              style: GoogleFonts.openSans(
                textStyle: TextStyle(
                  fontSize: 10,
                  color: timeLabelColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
    final geminiService = GeminiService();

    for (var event in dayEvents) {
      final double topOffset = _calculateTopOffset(event.startTimeAsTimeOfDay);
      final double eventHeight = _calculateEventHeight(event.durationInMinutes);

      eventWidgets.add(
        Positioned(
          top: topOffset,
          left: 55,
          right: 10,
          child: GestureDetector(
            onTap: () async {
              // await geminiService.sendSpecificEventDetailsToGemini(event.date, event); // Consider if this is still needed
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                    event: event,
                    onEventChanged: (Event? updatedEvent) {
                      onEventChanged?.call();
                    },
                  ),
                ),
              );
            },
            child: Container(
              height: eventHeight,
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: eventBgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.title,
                style: GoogleFonts.inter(
                  textStyle: TextStyle(
                    color: eventTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
    }
    double totalStackHeight =
        (TamaxTime.hour - TaminTime.hour + 1) * hourHeight;
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

class DayEventsScreen extends StatefulWidget {
  final DateTime date;
  final VoidCallback onMasterListShouldUpdate;

  const DayEventsScreen({
    super.key,
    required this.date,
    required this.onMasterListShouldUpdate,
  });

  @override
  State<DayEventsScreen> createState() => _DayEventsScreenState();
}

class _DayEventsScreenState extends State<DayEventsScreen> {
  List<Event> _dayEvents = [];
  final dbHelper = DatabaseHelper.instance;
  final double _hourHeight = 60.0;
  final int _minHour = 0;
  final int _maxHour = 23;

  @override
  void initState() {
    super.initState();
    _loadDayEvents();
  }

  Future<void> _loadDayEvents() async {
    final events = await dbHelper.getEventsForDate(widget.date);
    if (mounted) {
      setState(() {
        _dayEvents = events;
      });
    }
  }

  void _handleEventChangeFromDetails() {
    _loadDayEvents(); // Reload events for this specific day
    widget
        .onMasterListShouldUpdate(); // Notify CalendarScreen to reload all events and refetch summary
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.onBackground
                : theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(DateFormat.yMMMd().format(widget.date)),
      ),
      body: DayScheduleView(
        date: widget.date,
        events: _dayEvents,
        hourHeight: _hourHeight,
        TaminTime: TimeOfDay(hour: _minHour, minute: 0),
        TamaxTime: TimeOfDay(hour: _maxHour, minute: 59),
        onEventChanged: _handleEventChangeFromDetails,
      ),
    );
  }
}

void main() {
  // await dotenv.load(fileName: ".env"); // Ensure flutter_dotenv is in pubspec if used
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
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme(
      onBackground: const Color(0xFF1c1c1e),
      onSurface: const Color(0xFF1c1c1e),
      background: const Color(0xFFebebf0),
      surface: const Color(0xFFebebf0),
      onPrimary: const Color(
        0xFF30D158,
      ), // Used for month text color in light mode title
      primary: const Color(0xFF1c1c1e),
      secondary: const Color.fromRGBO(0, 137, 50, 1),
      onSecondary: const Color(0xFFebebf0),
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
      brightness: Brightness.light,
      primaryContainer: const Color(
        0xFFDCFEE2,
      ), // Example: A light green for selected day
      onPrimaryContainer: const Color(0xFF0A3811), // Text on primaryContainer
      secondaryContainer: const Color(
        0xFFD4F5D8,
      ), // Event bg in day schedule view
      onSecondaryContainer: const Color(0xFF00210B), // Text on event bg
      outlineVariant: Colors.grey.shade300, // For borders like time slots
    );

    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      background: const Color(0xFF1c1c1e),
      surface: const Color(0xFF1c1c1e), // Used for AppBar background in dark
      onBackground: const Color(0xFFebebf0),
      onSurface: const Color(0xFFebebf0),
      onPrimary: const Color(
        0xFF30D158,
      ), // Used for month text color in dark mode title
      primary: const Color.fromRGBO(
        58,
        58,
        60,
        1,
      ), // Used for "Today" and icons
      secondary: const Color(0xFF30D158), // Event indicator dot, FAB
      onSecondary: const Color(0xFF1c1c1e), // Text on FAB
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
      primaryContainer: const Color(
        0xFF1E4B27,
      ), // Example: A dark green for selected day
      onPrimaryContainer: const Color(0xFFBEF0C4), // Text on primaryContainer
      secondaryContainer: const Color(
        0xFF2B5C34,
      ), // Event bg in day schedule view
      onSecondaryContainer: const Color(0xFFE0FFE7), // Text on event bg
      outlineVariant: Colors.grey.shade700, // For borders like time slots
    );

    return MaterialApp(
      title: 'Scrollable Calendar',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: lightColorScheme.background,
          foregroundColor: lightColorScheme.onSurface,
          titleTextStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              color: lightColorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.inter(
            textStyle: TextStyle(
              color: lightColorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          titleMedium: GoogleFonts.inter(
            textStyle: TextStyle(color: lightColorScheme.onSurface),
          ),
          titleSmall: GoogleFonts.inter(
            textStyle: TextStyle(color: lightColorScheme.onSurface),
          ),
          labelLarge: GoogleFonts.inter(
            textStyle: TextStyle(color: lightColorScheme.primary),
          ),
          bodyMedium: GoogleFonts.inter(
            textStyle: TextStyle(
              color: lightColorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          bodySmall: GoogleFonts.inter(
            textStyle: TextStyle(color: lightColorScheme.onSurface),
          ),
          labelSmall: GoogleFonts.inter(
            textStyle: TextStyle(color: lightColorScheme.onSurface),
          ),
        ),
        iconTheme: IconThemeData(color: lightColorScheme.primary),
        dividerColor: lightColorScheme.outlineVariant,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: darkColorScheme.surface, // Changed from background
          foregroundColor: darkColorScheme.onSurface,
          titleTextStyle: GoogleFonts.inter(
            textStyle: TextStyle(
              color: darkColorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.inter(
            textStyle: TextStyle(
              color: darkColorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          titleMedium: GoogleFonts.inter(
            textStyle: TextStyle(color: darkColorScheme.onSurface),
          ),
          titleSmall: GoogleFonts.inter(
            textStyle: TextStyle(color: darkColorScheme.onSurface),
          ),
          labelLarge: GoogleFonts.inter(
            // Used for weekday names in dark mode
            textStyle: TextStyle(color: darkColorScheme.onBackground),
          ), // Changed from primary
          bodyMedium: GoogleFonts.inter(
            textStyle: TextStyle(
              color: darkColorScheme.onSurface.withOpacity(0.87),
              fontSize: 14,
            ),
          ),
          bodySmall: GoogleFonts.inter(
            textStyle: TextStyle(color: darkColorScheme.onSurface),
          ),
          labelSmall: GoogleFonts.inter(
            // Used for time labels in week/day view and weekday names
            textStyle: TextStyle(color: darkColorScheme.onSurface),
          ),
        ),
        iconTheme: IconThemeData(
          color: darkColorScheme.primary,
        ), // primary for dark mode icons too
        dividerColor: darkColorScheme.outlineVariant,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkColorScheme.secondary, // Changed from primary
          foregroundColor: darkColorScheme.onSecondary,
        ),
      ),
      themeMode: _themeMode,
      home: CalendarScreen(themeMode: _themeMode, onToggleTheme: _toggleTheme),
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

  final double _hourHeight = 80.0;
  final int _minHour = 0;
  final int _maxHour = 23;
  final double _timeLabelWidth = 20.0;

  final dbHelper = DatabaseHelper.instance;
  final GeminiService _geminiService = GeminiService();

  String? _aiDaySummary;
  bool _isFetchingAiSummary = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    _focusedMonth = DateTime(_today.year, _today.month);

    _monthPageController = PageController(
      initialPage: _calculateMonthPageIndex(_focusedMonth),
    );
    _weekPageController = PageController(
      initialPage: _calculateWeekPageIndex(_focusedWeekStart),
    );

    // Load events first, then fetch summary for the initially selected date.
    _loadEventsFromDb().then((_) {
      if (_selectedDate != null && mounted) {
        _fetchAiDaySummary(_selectedDate!);
      }
    });
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

  Future<void> _fetchAiDaySummary(DateTime date) async {
    if (!mounted) return;

    final String dateString = DateFormat('yyyy-MM-dd').format(date);
    final dayKey = DateTime(date.year, date.month, date.day);
    final eventsForDate = _events[dayKey] ?? [];
    final String currentEventsHash = dbHelper.generateEventsHash(eventsForDate);

    // Try to get stored summary
    final AiSummary? storedSummary = await dbHelper.getAiSummary(dateString);

    if (storedSummary != null) {
      final DateTime lastUpdated = DateTime.parse(storedSummary.lastUpdated);
      final bool isRecentEnough =
          DateTime.now().difference(lastUpdated).inHours < 24;
      final bool eventsUnchanged =
          storedSummary.eventsHash == currentEventsHash;

      if (isRecentEnough && eventsUnchanged) {
        if (mounted) {
          setState(() {
            _aiDaySummary = storedSummary.summary;
            _isFetchingAiSummary = false;
          });
        }
        return; // Use cached summary
      }
    }

    // If no cache, or cache is stale/invalid, fetch new summary
    if (mounted) {
      setState(() {
        _isFetchingAiSummary = true;
        _aiDaySummary = null; // Clear previous summary while fetching
      });
    }

    try {
      final summary = await _geminiService.getSummaryForDayEvents(
        date,
        eventsForDate,
      );
      if (mounted) {
        setState(() {
          _aiDaySummary = summary;
          _isFetchingAiSummary = false;
        });
        // Save the new summary to DB
        final newDbSummary = AiSummary(
          date: dateString,
          summary: summary,
          lastUpdated: DateTime.now().toIso8601String(),
          eventsHash: currentEventsHash,
        );
        await dbHelper.upsertAiSummary(newDbSummary);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiDaySummary = "Error fetching summary: ${e.toString()}";
          _isFetchingAiSummary = false;
        });
      }
    }
  }

  Future<void> _resetDatabase() async {
    await dbHelper
        .resetDatabase(); // This will delete the AI summaries table too if recreated in onCreate
    await _loadEventsFromDb(); // Reload events
    if (mounted) {
      setState(() {
        _events.clear(); // Clear in-memory events
        _aiDaySummary = null; // Clear current summary
      });
      if (_selectedDate != null) {
        _fetchAiDaySummary(_selectedDate!);
      } else {
        setState(() {
          _aiDaySummary = "Database reset. Select a day to see its AI summary.";
          _isFetchingAiSummary = false;
        });
      }
    }
  }

  int _calculateMonthPageIndex(DateTime month) {
    final referenceMonth = DateTime(_today.year, _today.month);
    return _initialPageIndex +
        (month.year - referenceMonth.year) * 12 +
        (month.month - referenceMonth.month);
  }

  DateTime _getDateFromMonthPageIndex(int pageIndex) {
    final monthOffset = pageIndex - _initialPageIndex;
    final referenceMonth = DateTime(_today.year, _today.month);
    return DateTime(referenceMonth.year, referenceMonth.month + monthOffset, 1);
  }

  int _calculateWeekPageIndex(DateTime weekStart) {
    DateTime todayWeekStart = _today.subtract(
      Duration(days: _today.weekday % 7),
    );
    return _initialPageIndex +
        (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart = _today.subtract(
      Duration(days: _today.weekday % 7),
    );
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

  void _goToPreviousMonth() {
    if (_monthPageController.hasClients) {
      _monthPageController.previousPage(
        duration: _pageScrollDuration,
        curve: _pageScrollCurve,
      );
    }
  }

  void _goToNextMonth() {
    if (_monthPageController.hasClients) {
      _monthPageController.nextPage(
        duration: _pageScrollDuration,
        curve: _pageScrollCurve,
      );
    }
  }

  void _goToPreviousWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.previousPage(
        duration: _pageScrollDuration,
        curve: _pageScrollCurve,
      );
    }
  }

  void _goToNextWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.nextPage(
        duration: _pageScrollDuration,
        curve: _pageScrollCurve,
      );
    }
  }

  void _toggleView() {
    setState(() {
      final DateTime actualNow = DateTime.now();
      _today = DateTime(actualNow.year, actualNow.month, actualNow.day);
      _isWeekView = !_isWeekView;

      if (_isWeekView) {
        DateTime weekViewAnchorDate = _selectedDate ?? _today;
        _focusedWeekStart = weekViewAnchorDate.subtract(
          Duration(days: weekViewAnchorDate.weekday % 7),
        );
        // Dispose and recreate if it exists and has clients
        if (_weekPageController.hasClients) _weekPageController.dispose();
        _weekPageController = PageController(
          initialPage: _calculateWeekPageIndex(_focusedWeekStart),
        );
      } else {
        // Switching to Month View
        _focusedMonth = DateTime(
          _selectedDate?.year ?? _today.year,
          _selectedDate?.month ?? _today.month,
        );
        int targetMonthPageIndex = _calculateMonthPageIndex(_focusedMonth);

        // Dispose and recreate if it exists and has clients
        if (_monthPageController.hasClients) _monthPageController.dispose();
        _monthPageController = PageController(
          initialPage: targetMonthPageIndex,
        );

        // Adjust selectedDate if it's not in the new focusedMonth or if null
        if (_selectedDate == null ||
            _selectedDate!.month != _focusedMonth.month ||
            _selectedDate!.year != _focusedMonth.year) {
          DateTime newSelectedCandidate = DateTime(
            _focusedMonth.year,
            _focusedMonth.month,
            _selectedDate?.day ?? _today.day,
          );
          // If the day doesn't exist in the month (e.g. Feb 30), clamp to last day.
          if (newSelectedCandidate.month != _focusedMonth.month) {
            newSelectedCandidate = DateTime(
              _focusedMonth.year,
              _focusedMonth.month + 1,
              0,
            ); // Last day of focused month
          }
          _selectedDate = newSelectedCandidate;
        }

        if (_selectedDate != null) {
          _fetchAiDaySummary(_selectedDate!);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _monthPageController.hasClients) {
            final currentPage = _monthPageController.page?.round();
            if (currentPage != targetMonthPageIndex) {
              // Using jumpToPage might be too abrupt after a dispose.
              // Consider if animateToPage is better, or if initialPage handles it.
              // For now, relying on initialPage in constructor.
            }
          }
        });
      }
    });
  }

  void _addEvent(DateTime initialDate) async {
    final bool? eventWasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => AddEventPage(date: initialDate)),
    );

    if (eventWasAdded == true && mounted) {
      await _loadEventsFromDb(); // Reload all events
      // Check if the summary for the affected date needs an update
      final DateTime eventDayOnly = DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
      );
      if (_selectedDate != null &&
          _selectedDate!.year == eventDayOnly.year &&
          _selectedDate!.month == eventDayOnly.month &&
          _selectedDate!.day == eventDayOnly.day) {
        _fetchAiDaySummary(
          _selectedDate!,
        ); // Refetch summary for the selected/modified day
      } else if (_selectedDate == null && eventDayOnly == _today) {
        // If no date was selected, but an event was added for today
        _selectedDate = _today;
        _fetchAiDaySummary(_today);
      }
      // If an event was added for a non-selected day, its summary will update when that day is selected.
    }
  }

  void _showDayEventsTimeSlotsPage(DateTime date) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DayEventsScreen(
          date: date,
          onMasterListShouldUpdate: () async {
            // This callback is from DayEventsScreen
            await _loadEventsFromDb(); // Master list reloads
            // Refetch summary for the currently selected day in CalendarScreen,
            // which might be the day that was just edited.
            if (_selectedDate != null &&
                mounted &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day) {
              _fetchAiDaySummary(_selectedDate!);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayEventSummary(
    BuildContext context,
    DateTime monthToDisplay,
  ) {
    final theme = Theme.of(context);

    if (_selectedDate == null ||
        _selectedDate!.month != monthToDisplay.month ||
        _selectedDate!.year != monthToDisplay.year) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              _selectedDate == null
                  ? "Select a day to see its AI summary."
                  : "AI Summary will appear here for ${DateFormat.MMMM().format(monthToDisplay)}.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "AI Summary for ${DateFormat.yMMMd().format(_selectedDate!)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.open_in_new,
                    color: theme.brightness == Brightness.dark
                        ? theme.colorScheme.onBackground
                        : theme.colorScheme.primary,
                  ),
                  tooltip: "View Day Details",
                  onPressed: () => _showDayEventsTimeSlotsPage(_selectedDate!),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isFetchingAiSummary
                ? const Center(child: CircularProgressIndicator())
                : _aiDaySummary != null && _aiDaySummary!.isNotEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      _aiDaySummary!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No AI summary available for this day, or an error occurred.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildMonthPageWidget(BuildContext context, DateTime monthToDisplay) {
    final theme = Theme.of(context);
    final prevNextMonthTextColor = theme.colorScheme.onSurface.withOpacity(
      0.38,
    );

    final firstDayOfMonth = DateTime(
      monthToDisplay.year,
      monthToDisplay.month,
      1,
    );
    final daysInMonth = DateTime(
      monthToDisplay.year,
      monthToDisplay.month + 1,
      0,
    ).day;
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
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: theme.dividerColor.withOpacity(0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
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
      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isTodayDate =
          date.year == _today.year &&
          date.month == _today.month &&
          date.day == _today.day;
      final dayKey = DateTime(date.year, date.month, date.day);
      final hasEvent =
          _events.containsKey(dayKey) && _events[dayKey]!.isNotEmpty;

      BoxDecoration cellDecoration = BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 0.5,
          ),
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0),
            width: 0.5,
          ),
        ),
      );
      TextStyle? dayTextStyle;

      if (isSelected) {
        cellDecoration = cellDecoration.copyWith(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        );
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onPrimaryContainer,
        );
      } else if (isTodayDate) {
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
        );
      } else {
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        );
      }

      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            TextStyle? finalDayTextStyle = dayTextStyle?.copyWith(
              fontSize: boxSize * 0.4,
            );

            return GestureDetector(
              onTap: () {
                if (mounted) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _fetchAiDaySummary(date);
                }
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
                    Text(day.toString(), style: finalDayTextStyle),
                    if (hasEvent)
                      Positioned(
                        right: boxSize * 0.1,
                        bottom: boxSize * 0.1,
                        child: Icon(
                          Icons.circle,
                          size: boxSize * 0.15,
                          color: theme.colorScheme.secondary.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    int totalCells = weekdayOffset + daysInMonth;
    int nextDaysRequired = (totalCells <= 35)
        ? (35 - totalCells)
        : (42 - totalCells);

    for (int i = 1; i <= nextDaysRequired; i++) {
      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            return Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.2),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: theme.dividerColor.withOpacity(0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
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

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: dayWidgets,
        ),
        _buildSelectedDayEventSummary(
          context,
          monthToDisplay,
        ), // Pass monthToDisplay
      ],
    );
  }

  Widget _buildTimeLabelStack(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabelColor = theme.colorScheme.onSurface;
    List<Widget> timeLabels = [];

    for (int hour = _minHour; hour <= _maxHour; hour++) {
      timeLabels.add(
        Positioned(
          top: (hour - _minHour) * _hourHeight,
          left: 0,
          width: _timeLabelWidth,
          height: _hourHeight,
          child: Container(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('HH').format(DateTime(2000, 1, 1, hour)),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: timeLabelColor.withOpacity(0.7),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: timeLabels);
  }

  Widget _buildSingleDayScheduleStack(
    BuildContext context,
    DateTime day,
    List<Event> events,
    double columnWidth,
  ) {
    final theme = Theme.of(context);
    List<Widget> stackChildren = [];

    for (int hour = _minHour; hour <= _maxHour; hour++) {
      stackChildren.add(
        Positioned(
          top: (hour - _minHour) * _hourHeight,
          left: 0,
          width: columnWidth,
          child: Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
        ),
      );
    }

    for (var event in events) {
      final startMinutes =
          event.startTimeAsTimeOfDay.hour * 60 +
          event.startTimeAsTimeOfDay.minute;
      final endMinutes =
          event.endTimeAsTimeOfDay.hour * 60 + event.endTimeAsTimeOfDay.minute;
      final minHourMinutes = _minHour * 60;

      final topPosition =
          ((startMinutes - minHourMinutes) / 60.0) * _hourHeight;
      final eventDurationInMinutes = endMinutes - startMinutes;
      double eventHeight = (eventDurationInMinutes / 60.0) * _hourHeight;

      if (eventHeight < _hourHeight / 3) {
        eventHeight = _hourHeight / 3;
      }
      if (topPosition < 0) continue;
      if (topPosition + eventHeight > (_maxHour - _minHour + 1) * _hourHeight) {
        eventHeight = ((_maxHour - _minHour + 1) * _hourHeight) - topPosition;
      }
      if (eventHeight <= 0) continue;

      stackChildren.add(
        Positioned(
          top: topPosition,
          left: 2.0,
          width: columnWidth - 4.0,
          height: eventHeight,
          child: GestureDetector(
            onTap: () async {
              _showDayEventsTimeSlotsPage(day);
            },
            child: Container(
              padding: const EdgeInsets.all(4.0),
              margin: const EdgeInsets.only(bottom: 1.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                event.title,
                style: theme.textTheme.labelSmall?.copyWith(
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

    final weekDaysSymbols =
        DateFormat.EEEE().dateSymbols.STANDALONESHORTWEEKDAYS;
    List<DateTime> weekDates = List.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );
    final totalScrollableHeight = (_maxHour - _minHour + 1) * _hourHeight;

    String weekRangeText;
    if (weekDates.first.month == weekDates.last.month) {
      weekRangeText =
          "${DateFormat.MMMd().format(weekDates.first)} - ${DateFormat.d().format(weekDates.last)}, ${weekDates.last.year}";
    } else if (weekDates.first.year == weekDates.last.year) {
      weekRangeText =
          "${DateFormat.MMMd().format(weekDates.first)} - ${DateFormat.MMMd().format(weekDates.last)}, ${weekDates.last.year}";
    } else {
      weekRangeText =
          "${DateFormat.yMMMd().format(weekDates.first)} - ${DateFormat.yMMMd().format(weekDates.last)}";
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onBackground
                      : theme.iconTheme.color,
                ),
                onPressed: _goToPreviousWeek,
              ),
              Expanded(
                // Allow text to take available space and center
                child: Text(
                  weekRangeText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: theme.brightness == Brightness.dark
                      ? theme.colorScheme.onBackground
                      : theme.iconTheme.color,
                ),
                onPressed: _goToNextWeek,
              ),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(width: _timeLabelWidth),
            ...weekDates.map((date) {
              bool isToday =
                  date.year == _today.year &&
                  date.month == _today.month &&
                  date.day == _today.day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Column(
                    // Display day number and weekday name
                    children: [
                      Text(
                        weekDaysSymbols[date.weekday % 7].toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10, // Smaller font for weekday name
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground.withOpacity(0.8)
                              : (isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.8,
                                      )),
                        ),
                      ),
                      Text(
                        DateFormat.d().format(date), // Day number
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground
                              : (isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
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
                    daySpecificEvents.sort(
                      (a, b) =>
                          (a.startTimeAsTimeOfDay.hour * 60 +
                                  a.startTimeAsTimeOfDay.minute)
                              .compareTo(
                                b.startTimeAsTimeOfDay.hour * 60 +
                                    b.startTimeAsTimeOfDay.minute,
                              ),
                    );

                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: totalScrollableHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: borderColor,
                                  width: 0.5,
                                ),
                                right:
                                    date.weekday ==
                                        DateTime
                                            .sunday // Assuming Sunday is the last day shown
                                    ? BorderSide(color: borderColor, width: 0.5)
                                    : BorderSide.none,
                              ),
                            ),
                            child: _buildSingleDayScheduleStack(
                              context,
                              date,
                              daySpecificEvents,
                              constraints.maxWidth,
                            ),
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
    // For Month View App Bar title
    final monthViewAppBarTitle = _focusedMonth != null
        ? DateFormat.yMMMM().format(_focusedMonth)
        : "Calendar";
    // For Week View App Bar title (can be more dynamic if needed, e.g. showing week range)
    final weekViewAppBarTitle = _focusedWeekStart != null
        ? "Week of ${DateFormat.MMMd().format(_focusedWeekStart)}"
        : "Calendar";

    return Scaffold(
      appBar: AppBar(
        title: Text(_isWeekView ? weekViewAppBarTitle : monthViewAppBarTitle),
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
            icon: Icon(
              _isWeekView
                  ? Icons.calendar_month_outlined
                  : Icons.view_week_outlined,
            ),
            onPressed: _toggleView,
            tooltip: _isWeekView
                ? 'Switch to Month View'
                : 'Switch to Week View',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isWeekView && _focusedMonth != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: DateFormat.MMMM().format(_focusedMonth),
                          style: (theme.textTheme.titleLarge ?? const TextStyle())
                              .copyWith(
                                fontSize:
                                    (theme.textTheme.titleLarge?.fontSize ??
                                        20.0) *
                                    1.2,
                                color: theme
                                    .colorScheme
                                    .onPrimary, // Dynamic color based on theme
                              ),
                        ),
                        TextSpan(
                          text: ' ${DateFormat.y().format(_focusedMonth)}',
                          style:
                              (theme.textTheme.titleLarge ?? const TextStyle())
                                  .copyWith(
                                    fontSize:
                                        (theme.textTheme.titleLarge?.fontSize ??
                                            20.0) *
                                        0.9,
                                    color: theme.textTheme.titleLarge?.color,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground
                              : theme.iconTheme.color,
                        ),
                        onPressed: _goToPreviousMonth,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          size: 28,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground
                              : theme.iconTheme.color,
                        ),
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
                children: weekDayNames
                    .map(
                      (name) => Expanded(
                        child: Center(
                          child: Text(
                            name.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Made smaller
                              color: theme.brightness == Brightness.dark
                                  ? theme.colorScheme.onBackground.withOpacity(
                                      0.7,
                                    ) // Muted for dark
                                  : theme.colorScheme.primary.withOpacity(
                                      0.8,
                                    ), // Muted for light
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Expanded(
            child: Padding(
              padding: _isWeekView
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 8.0),
              child: _isWeekView
                  ? PageView.builder(
                      controller: _weekPageController,
                      onPageChanged: (pageIndex) {
                        if (mounted) {
                          setState(() {
                            _focusedWeekStart = _getDateFromWeekPageIndex(
                              pageIndex,
                            );
                            // Potentially select the first day of the week and fetch its summary
                            _selectedDate = _focusedWeekStart;
                            _fetchAiDaySummary(_selectedDate!);
                          });
                        }
                      },
                      itemBuilder: (context, pageIndex) {
                        final weekStart = _getDateFromWeekPageIndex(pageIndex);
                        return _buildWeekPageWidget(context, weekStart);
                      },
                    )
                  : PageView.builder(
                      controller: _monthPageController,
                      onPageChanged: (pageIndex) {
                        if (mounted) {
                          setState(() {
                            final newFocusedMonth = _getDateFromMonthPageIndex(
                              pageIndex,
                            );
                            _focusedMonth = newFocusedMonth;
                            bool summaryNeedsUpdate = false;

                            if (_selectedDate == null ||
                                _selectedDate!.month != _focusedMonth.month ||
                                _selectedDate!.year != _focusedMonth.year) {
                              DateTime candidateDate = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month,
                                _selectedDate?.day ??
                                    (_focusedMonth.month == _today.month &&
                                            _focusedMonth.year == _today.year
                                        ? _today.day
                                        : 1),
                              );
                              // Ensure candidate day is valid for the month
                              if (candidateDate.month != _focusedMonth.month) {
                                candidateDate = DateTime(
                                  _focusedMonth.year,
                                  _focusedMonth.month + 1,
                                  0,
                                ); // Last day of month
                              }
                              _selectedDate = candidateDate;
                              summaryNeedsUpdate = true;
                            }

                            if (summaryNeedsUpdate && _selectedDate != null) {
                              _fetchAiDaySummary(_selectedDate!);
                            } else if (_selectedDate == null) {
                              _aiDaySummary =
                                  "Select a day to see its AI summary.";
                              _isFetchingAiSummary = false;
                            }
                          });
                        }
                      },
                      itemBuilder: (context, pageIndex) {
                        final month = _getDateFromMonthPageIndex(pageIndex);
                        return _buildMonthPageWidget(context, month);
                      },
                    ),
            ),
          ),
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
