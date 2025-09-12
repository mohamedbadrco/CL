import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:google_fonts/google_fonts.dart'; // Added for Google Fonts
import './add_event_page.dart'; // Import the new AddEventPage
import './event_details_page.dart'; // Import the EventDetailsPage
import './database_helper.dart'; // Import DatabaseHelper - defines Event
import './api/gemini_service.dart';
import './month_page.dart'; // Import MonthPageContent
import './week_page.dart'; // Import WeekPageContent
import './notification_service.dart'; // Import NotificationService
import 'package:timezone/data/latest.dart' as tzdata;
import './weekend_days.dart'; // <-- Add this import

// import \'package:flutter_dotenv/flutter_dotenv.dart\'; // Commented out, ensure it\'s handled if needed

// Updated main function:
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // REQUIRED
  tzdata
      .initializeTimeZones(); // Initialize timezone data for weekend detection
  try {
    await initializeNotifications(); // Initialize notifications system
  } catch (e) {
    print('Error initializing notifications: $e');
    // Continue running the app even if notifications fail
  }
  runApp(const CalendarApp());
}

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
    final eventBgColor = theme.colorScheme.onPrimary;
    final eventTextColor =
        theme.colorScheme.primary; // Changed for better contrast

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
                    color: eventTextColor, // Will use theme.colorScheme.primary
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
    _loadDayEvents();
    widget.onMasterListShouldUpdate();
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
        title: Text(DateFormat('MMM d, yy').format(widget.date)),
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
    final selectedBlue = const Color.fromARGB(255, 30, 110, 244);
    final level1_green = const Color.fromARGB(255, 74, 217, 104);
    final level2_green = const Color.fromRGBO(0, 137, 50, 1);

    final lightColorScheme = ColorScheme(
      onBackground: const Color(0xFF1c1c1e),
      onSurface: const Color(0xFF1c1c1e),
      background: const Color(0xFFebebf0),
      surface: const Color(0xFFebebf0),
      onPrimary: const Color(0xFF30D158),
      primary: const Color(0xFF1c1c1e),
      secondary: const Color.fromRGBO(0, 137, 50, 1),
      onSecondary: const Color(0xFFebebf0),
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
      brightness: Brightness.light,
      primaryContainer: const Color(0xFFDCFEE2),
      onPrimaryContainer: const Color(0xFF0A3811),
      secondaryContainer: const Color(0xFFD4F5D8),
      onSecondaryContainer: const Color(0xFF00210B),
      outlineVariant: const Color(0xFF1c1c1e),
    );

    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      background: const Color(0xFF1c1c1e),
      surface: const Color(0xFF1c1c1e),
      onBackground: const Color(0xFFebebf0),
      onSurface: const Color(0xFFebebf0),
      onPrimary: const Color(0xFF30D158),
      primary: const Color(0xFFebebf0),
      secondary: const Color(0xFF30D158),
      onSecondary: const Color(0xFF1c1c1e),
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
      primaryContainer: const Color(0xFF1E4B27),
      onPrimaryContainer: const Color(0xFFBEF0C4),
      secondaryContainer: const Color(0xFF2B5C34),
      onSecondaryContainer: const Color(0xFFE0FFE7),
      outlineVariant: Colors.grey.shade700,
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
          backgroundColor: darkColorScheme.surface,
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
            textStyle: TextStyle(color: darkColorScheme.onBackground),
          ),
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
            textStyle: TextStyle(color: darkColorScheme.onSurface),
          ),
        ),
        iconTheme: IconThemeData(color: darkColorScheme.primary),
        dividerColor: darkColorScheme.outlineVariant,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkColorScheme.secondary,
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

  List<int> _weekendDays = []; // Default: Sunday (0), Saturday (6)

  @override
  void initState() {
    super.initState();
    // Initialize _today accurately at the start
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    _selectedDate = _today;
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    _focusedMonth = DateTime(_today.year, _today.month);

    _monthPageController = PageController(
      initialPage: _calculateMonthPageIndex(_focusedMonth),
    );
    _weekPageController = PageController(
      initialPage: _calculateWeekPageIndex(_focusedWeekStart),
    );

    _loadEventsFromDb().then((_) async {
      try {
        await cleanupCompletedEventNotifications();
      } catch (e) {
        print('Error cleaning up notifications: $e');
      }
      if (_selectedDate != null && mounted) {
        try {
          _fetchAiDaySummary(_selectedDate!);
        } catch (e) {
          print('Error fetching AI summary on launch: $e');
        }
      }
    });
    _loadWeekendDays();
  }

  Future<void> _loadWeekendDays() async {
    // Ensure timezone data is initialized before calling this
    // You should call tzdata.initializeTimeZones() in your main() if not already
    final weekends = getWeekendDaysForCurrentLocation();
    // Use the [0, 6] format (Sun=0, Sat=6) directly,
    // or default to it if `weekends` is null.
    print("+++++++++++++++++++++${weekends}");
    setState(() {
      _weekendDays = weekends ?? [0, 6];
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
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isFetchingAiSummary = true;
        _aiDaySummary = null;
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
    // First, cancel all pending notifications before resetting the database
    final allEvents = await dbHelper.getAllEvents();
    for (var event in allEvents) {
      if (event.id != null) {
        await cancelEventNotification(
          event.id!,
        ); // Cancel notification for each event
      }
    }

    await dbHelper.resetDatabase();
    await _loadEventsFromDb(); // Reload (empty) events
    if (mounted) {
      setState(() {
        _events.clear(); // Ensure UI reflects the cleared events
        _aiDaySummary = null;
      });
      if (_selectedDate != null) {
        _fetchAiDaySummary(
          _selectedDate!,
        ); // Attempt to fetch summary for selected day (likely empty)
      } else {
        setState(() {
          _aiDaySummary = "Database reset. Select a day to see its AI summary.";
          _isFetchingAiSummary = false;
        });
      }
    }
  }

  int _calculateMonthPageIndex(DateTime month) {
    final referenceMonth = DateTime(
      _today.year,
      _today.month,
    ); // Use consistent _today
    return _initialPageIndex +
        (month.year - referenceMonth.year) * 12 +
        (month.month - referenceMonth.month);
  }

  DateTime _getDateFromMonthPageIndex(int pageIndex) {
    final monthOffset = pageIndex - _initialPageIndex;
    final referenceMonth = DateTime(
      _today.year,
      _today.month,
    ); // Use consistent _today
    return DateTime(referenceMonth.year, referenceMonth.month + monthOffset, 1);
  }

  int _calculateWeekPageIndex(DateTime weekStart) {
    DateTime todayWeekStart = _today.subtract(
      Duration(days: _today.weekday % 7),
    ); // Use consistent _today
    return _initialPageIndex +
        (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart = _today.subtract(
      Duration(days: _today.weekday % 7),
    ); // Use consistent _today
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

  void _goToToday() {
    if (!mounted) return;
    final DateTime now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);

    setState(() {
      _today = todayDate; // Update _today to actual current day
      _selectedDate = todayDate; // Select today

      if (_isWeekView) {
        _focusedWeekStart = todayDate.subtract(
          Duration(days: todayDate.weekday % 7),
        );
        final int targetWeekPage = _calculateWeekPageIndex(_focusedWeekStart);
        if (_weekPageController.hasClients &&
            _weekPageController.page?.round() != targetWeekPage) {
          _weekPageController.jumpToPage(targetWeekPage);
        }
      } else {
        _focusedMonth = DateTime(todayDate.year, todayDate.month);
        final int targetMonthPage = _calculateMonthPageIndex(_focusedMonth);
        if (_monthPageController.hasClients &&
            _monthPageController.page?.round() != targetMonthPage) {
          _monthPageController.jumpToPage(targetMonthPage);
        }
      }
    });
    _fetchAiDaySummary(todayDate);
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
        _focusedWeekStart = _selectedDate != null
            ? _selectedDate!.subtract(
                Duration(days: _selectedDate!.weekday % 7),
              )
            : _today.subtract(Duration(days: _today.weekday % 7));

        final int targetWeekPage = _calculateWeekPageIndex(_focusedWeekStart);

        if (_weekPageController.hasClients) _weekPageController.dispose();
        _weekPageController = PageController(initialPage: targetWeekPage);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _weekPageController.hasClients &&
              _weekPageController.page?.round() != targetWeekPage) {
            _weekPageController.jumpToPage(targetWeekPage);
          }
        });
        if (_selectedDate != null) _fetchAiDaySummary(_selectedDate!);
      } else {
        _focusedMonth = DateTime(
          _selectedDate?.year ?? _today.year,
          _selectedDate?.month ?? _today.month,
        );
        final int targetMonthPage = _calculateMonthPageIndex(_focusedMonth);

        if (_monthPageController.hasClients) _monthPageController.dispose();
        _monthPageController = PageController(initialPage: targetMonthPage);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _monthPageController.hasClients &&
              _monthPageController.page?.round() != targetMonthPage) {
            _monthPageController.jumpToPage(targetMonthPage);
          }
        });
        if (_selectedDate != null) _fetchAiDaySummary(_selectedDate!);
      }
    });
  }

  void _addEvent(DateTime initialDate) async {
    final Event? newEvent = await Navigator.of(context).push<Event>(
      MaterialPageRoute(builder: (context) => AddEventPage(date: initialDate)),
    );

    if (newEvent != null && newEvent.id != null && mounted) {
      await _loadEventsFromDb();
      await scheduleEventNotification(newEvent);

      final DateTime eventDayOnly = DateTime(
        newEvent.date.year,
        newEvent.date.month,
        newEvent.date.day,
      );
      if (_selectedDate != null &&
          _selectedDate!.year == eventDayOnly.year &&
          _selectedDate!.month == eventDayOnly.month &&
          _selectedDate!.day == eventDayOnly.day) {
        _fetchAiDaySummary(_selectedDate!);
      } else if (_selectedDate == null && eventDayOnly == _today) {
        _selectedDate = _today;
        _fetchAiDaySummary(_today);
      }
    }
  }

  void _showDayEventsTimeSlotsPage(DateTime date) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DayEventsScreen(
          date: date,
          onMasterListShouldUpdate: () async {
            await _loadEventsFromDb();
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

  Future<void> _navigateToEventDetails(Event event) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsPage(
          event: event,
          onEventChanged: (Event? updatedEvent) async {
            if (mounted) {
              await _loadEventsFromDb();

              if (event.id != null) {
                await cancelEventNotification(event.id!);
              }
              if (updatedEvent != null && updatedEvent.id != null) {
                await scheduleEventNotification(updatedEvent);
              }

              final DateTime dateToRefresh = updatedEvent?.date ?? event.date;
              final DateTime dayToRefreshSummary = DateTime(
                dateToRefresh.year,
                dateToRefresh.month,
                dateToRefresh.day,
              );
              _fetchAiDaySummary(dayToRefreshSummary);

              if (_selectedDate != null &&
                  _selectedDate!.year == dayToRefreshSummary.year &&
                  _selectedDate!.month == dayToRefreshSummary.month &&
                  _selectedDate!.day == dayToRefreshSummary.day &&
                  _selectedDate != dayToRefreshSummary) {
                _fetchAiDaySummary(_selectedDate!);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBlue = const Color.fromARGB(255, 30, 110, 244);

    final intlDateSymbols = DateFormat.EEEE().dateSymbols;
    final weekDayNames = intlDateSymbols.STANDALONENARROWWEEKDAYS;

    final String appBarTitleText;
    final DateTime referenceDateForTitle = _isWeekView
        ? (_focusedWeekStart ?? _today)
        : (_focusedMonth ?? _today);

    appBarTitleText = DateFormat("MMM yy").format(referenceDateForTitle);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            top: 6.0,
            bottom: 6.0,
            right: 4.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: Text(
                DateFormat('d').format(_today),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      theme.appBarTheme.titleTextStyle?.color ??
                      theme.colorScheme.onPrimary,
                  fontSize:
                      (theme.appBarTheme.titleTextStyle?.fontSize ?? 20) * 0.95,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(appBarTitleText),
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
          if (!_isWeekView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: weekDayNames.asMap().entries.map((entry) {
                  // entry.key is the 0-6 index into STANDALONENARROWWEEKDAYS
                  // _weekendDays uses Sun=0, Mon=1, ..., Sat=6

                  // entry.key corresponds to Sun=0, Mon=1, ..., Sat=6
                  int dayValueInOurScheme = entry.key;
                  bool isHeaderWeekend = _weekendDays.contains(
                    dayValueInOurScheme,
                  );

                  return Expanded(
                    child: Center(
                      child: Text(
                        entry.value.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: isHeaderWeekend
                              ? selectedBlue
                              : (theme.brightness == Brightness.dark
                                    ? theme.colorScheme.onBackground
                                          .withOpacity(0.7)
                                    : theme.colorScheme.primary.withOpacity(
                                        0.8,
                                      )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
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
                            final newFocusedWeekStart =
                                _getDateFromWeekPageIndex(pageIndex);
                            _focusedWeekStart = newFocusedWeekStart;

                            DateTime newSelectedDateCandidate =
                                _selectedDate ?? newFocusedWeekStart;
                            if (newSelectedDateCandidate.isBefore(
                                  newFocusedWeekStart,
                                ) ||
                                newSelectedDateCandidate.isAfter(
                                  newFocusedWeekStart.add(
                                    const Duration(days: 6),
                                  ),
                                )) {
                              _selectedDate = newFocusedWeekStart;
                            } else {
                              _selectedDate = DateTime(
                                newFocusedWeekStart.year,
                                newFocusedWeekStart.month,
                                newSelectedDateCandidate.day,
                              );
                              if (_selectedDate!.month !=
                                      newFocusedWeekStart.month &&
                                  newFocusedWeekStart.day >
                                      _selectedDate!.day) {
                                _selectedDate = newFocusedWeekStart;
                              }
                            }
                            if (_selectedDate != null) {
                              _fetchAiDaySummary(_selectedDate!);
                            }
                          });
                        }
                      },
                      itemBuilder: (context, pageIndex) {
                        final weekStart = _getDateFromWeekPageIndex(pageIndex);
                        return WeekPageContent(
                          weekStart: weekStart,
                          today: _today,
                          events: _events,
                          hourHeight: _hourHeight,
                          minHour: _minHour,
                          maxHour: _maxHour,
                          timeLabelWidth: _timeLabelWidth,
                          onShowDayEvents: _showDayEventsTimeSlotsPage,
                          onEventTapped: _navigateToEventDetails,
                          onGoToPreviousWeek: _goToPreviousWeek,
                          onGoToNextWeek: _goToNextWeek,
                          weekendDays: _weekendDays, // <-- Pass weekend days
                          weekendColor: selectedBlue, // <-- Pass color
                        );
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

                            int dayToSelect = _selectedDate?.day ?? _today.day;
                            DateTime candidateDate;
                            try {
                              candidateDate = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month,
                                dayToSelect,
                              );
                            } catch (e) {
                              candidateDate = DateTime(
                                _focusedMonth.year,
                                _focusedMonth.month + 1,
                                0,
                              );
                            }

                            if (_selectedDate != candidateDate) {
                              _selectedDate = candidateDate;
                              if (_selectedDate != null) {
                                _fetchAiDaySummary(_selectedDate!);
                              }
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
                        return MonthPageContent(
                          monthToDisplay: month,
                          selectedDate: _selectedDate,
                          today: _today,
                          events: _events,
                          isFetchingAiSummary: _isFetchingAiSummary,
                          aiDaySummary: _aiDaySummary,
                          onDateSelected: (date) {
                            if (mounted) {
                              setState(() {
                                _selectedDate = date;
                              });
                              if (_selectedDate != null) {
                                _fetchAiDaySummary(_selectedDate!);
                              }
                            }
                          },
                          onDateDoubleTap: _addEvent,
                          onShowDayEvents: _showDayEventsTimeSlotsPage,
                          weekendDays: _weekendDays, // <-- Pass weekend days
                          weekendColor: selectedBlue, // <-- Pass color
                        );
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
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        backgroundColor: theme.colorScheme.outlineVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            25.0,
          ), // Adjust the radius as needed
        ),
      ),
    );
  }
}
