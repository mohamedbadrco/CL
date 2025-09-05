// ignore_for_file: non_constant_identifier_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:google_fonts/google_fonts.dart'; // Added for Google Fonts
import './add_event_page.dart'; // Import the new AddEventPage
import './event_details_page.dart'; // Import the EventDetailsPage
import './database_helper.dart'; // Import DatabaseHelper
import './api/gemini_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
 // Import GeminiService

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
              DateFormat('h a')
                  .format(DateTime(date.year, date.month, date.day, hour)),
              style: GoogleFonts.openSans(textStyle: TextStyle(fontSize: 12, color: timeLabelColor, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );
    }
    double totalHeight = totalHours * hourHeight;
    return SizedBox(height: totalHeight, child: Stack(children: timeSlots));
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
              await geminiService.sendSpecificEventDetailsToGemini(event.date, event);
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
                        fontWeight: FontWeight.bold)),
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
        height: totalStackHeight, child: Stack(children: eventWidgets));
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(DateFormat.yMMMd().format(widget.date)), // Theme will apply inter
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

void main()  {
  // await dotenv.load(fileName: ".env"); // Specify the path to your .env file
  runApp(const CalendarApp());
}

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

  const Color primarySeedColor = Color(0xFF30D158);
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
    final lightColorScheme = ColorScheme(
      onBackground: const Color(0xFF1c1c1e),
      onSurface: const Color(0xFF1c1c1e),
      background: const Color(0xFFebebf0),
      surface: const Color(0xFFebebf0),
      onPrimary: const Color(0xFF30D158),
      primary: const Color(0xFF1c1c1e),
      secondary:  const Color.fromRGBO(0, 137, 50, 1),
      onSecondary: const Color(0xFFebebf0),
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme(
      // seedColor: const Color(0xFF30D158),
      brightness: Brightness.dark,
      background: const Color(0xFF1c1c1e),
      surface: const Color(0xFF1c1c1e),
      onBackground: const Color(0xFFebebf0),
      onSurface: const Color(0xFFebebf0),
      onPrimary: const Color(0xFF30D158),
      primary: const Color.fromRGBO(99, 99, 102, 1),
      secondary:  const Color(0xFF30D158),
      onSecondary: const Color(0xFF1c1c1e),
      error: const Color(0xFFff4345),
      onError: const Color(0xFFebebf0),
    );

    return MaterialApp(
      title: 'Scrollable Calendar',
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily, // Default calendar font: inter
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: lightColorScheme.background,
          foregroundColor: lightColorScheme.onSurface,
          titleTextStyle: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: lightColorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: lightColorScheme.onSurface, fontWeight: FontWeight.bold)),
          titleMedium: GoogleFonts.inter(
              textStyle: TextStyle(color: lightColorScheme.onSurface)),
          titleSmall: GoogleFonts.inter(
              textStyle: TextStyle(color: lightColorScheme.onSurface)),
          labelLarge: GoogleFonts.inter(
              textStyle: TextStyle(color: lightColorScheme.primary)),
          bodyMedium: GoogleFonts.inter( // Inter for AI Summary
              textStyle: TextStyle(color: lightColorScheme.onSurface, fontSize: 14)),
          bodySmall: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: lightColorScheme.onSurface)), 
          labelSmall: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: lightColorScheme.onSurface)), 
        ),
        iconTheme: IconThemeData(color: lightColorScheme.primary),
        dividerColor: lightColorScheme.outlineVariant,
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily, // Default calendar font for dark theme: inter
        scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          titleTextStyle: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: darkColorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        textTheme: TextTheme(
          titleLarge: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: darkColorScheme.onSurface, fontWeight: FontWeight.bold)),
          titleMedium: GoogleFonts.inter(
              textStyle: TextStyle(color: darkColorScheme.onSurface)),
          titleSmall: GoogleFonts.inter(
              textStyle: TextStyle(color: darkColorScheme.onSurface)),
          labelLarge: GoogleFonts.inter(
              textStyle: TextStyle(color: darkColorScheme.primary)),
          bodyMedium: GoogleFonts.inter( // Inter for AI Summary
              textStyle: TextStyle(
                  color: darkColorScheme.onSurface.withOpacity(0.87), fontSize: 14)),
          bodySmall: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: darkColorScheme.onSurface)), 
          labelSmall: GoogleFonts.inter(
              textStyle: TextStyle(
                  color: darkColorScheme.onSurface)), 
        ),
        iconTheme: IconThemeData(color: darkColorScheme.primary),
        dividerColor: darkColorScheme.outlineVariant,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
        ),
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
  final GeminiService _geminiService = GeminiService();

  String? _aiDaySummary;
  bool _isFetchingAiSummary = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today;
    _focusedWeekStart = _today.subtract(Duration(days: _today.weekday % 7));
    _focusedMonth = DateTime(_today.year, _today.month);

    _monthPageController =
        PageController(initialPage: _calculateMonthPageIndex(_focusedMonth));
    _weekPageController =
        PageController(initialPage: _calculateWeekPageIndex(_focusedWeekStart));
    _loadEventsFromDb().then((_) {
      if (_selectedDate != null) {
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
    setState(() {
      _isFetchingAiSummary = true;
      _aiDaySummary = null; 
    });

    final dayKey = DateTime(date.year, date.month, date.day);
    final eventsForDate = _events[dayKey] ?? [];

    try {
      final summary = await _geminiService.getSummaryForDayEvents(date, eventsForDate);
      if (mounted) {
        setState(() {
          _aiDaySummary = summary;
          _isFetchingAiSummary = false;
        });
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
    await dbHelper.resetDatabase();
    await _loadEventsFromDb();
    if (_selectedDate != null) {
      _fetchAiDaySummary(_selectedDate!); 
    } else {
       if (mounted) {
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
    DateTime todayWeekStart =
        _today.subtract(Duration(days: _today.weekday % 7));
    return _initialPageIndex +
        (weekStart.difference(todayWeekStart).inDays ~/ 7);
  }

  DateTime _getDateFromWeekPageIndex(int pageIndex) {
    final weekOffset = pageIndex - _initialPageIndex;
    DateTime todayWeekStart =
        _today.subtract(Duration(days: _today.weekday % 7));
    return todayWeekStart.add(Duration(days: weekOffset * 7));
  }

  void _goToPreviousMonth() {
    if (_monthPageController.hasClients) {
      _monthPageController.previousPage(
          duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToNextMonth() {
    if (_monthPageController.hasClients) {
      _monthPageController.nextPage(
          duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToPreviousWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.previousPage(
          duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _goToNextWeek() {
    if (_weekPageController.hasClients) {
      _weekPageController.nextPage(
          duration: _pageScrollDuration, curve: _pageScrollCurve);
    }
  }

  void _toggleView() {
    setState(() {
      final DateTime actualNow = DateTime.now();
      _today = DateTime(actualNow.year, actualNow.month, actualNow.day);
      _isWeekView = !_isWeekView;

      if (_isWeekView) {
        DateTime weekViewAnchorDate = _selectedDate ?? _today;
        _focusedWeekStart = weekViewAnchorDate
            .subtract(Duration(days: weekViewAnchorDate.weekday % 7));
        _weekPageController.dispose(); 
        _weekPageController = PageController(
            initialPage: _calculateWeekPageIndex(_focusedWeekStart));
      } else {
        _focusedMonth = DateTime(_selectedDate?.year ?? _today.year,
            _selectedDate?.month ?? _today.month);
        int targetMonthPageIndex = _calculateMonthPageIndex(_focusedMonth);
         _monthPageController.dispose(); 
        _monthPageController =
            PageController(initialPage: targetMonthPageIndex);

        if (_selectedDate != null &&
            (_selectedDate!.year != _focusedMonth.year ||
                _selectedDate!.month != _focusedMonth.month)) {
          DateTime newSelectedCandidate =
              DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDate!.day);
          if (newSelectedCandidate.month != _focusedMonth.month) {
            newSelectedCandidate =
                DateTime(_focusedMonth.year, _focusedMonth.month, 1);
          }
          _selectedDate = newSelectedCandidate;
        } else if (_selectedDate == null) {
           DateTime newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, _today.day);
            if (newSelectedCandidate.month != _focusedMonth.month) {
            newSelectedCandidate =
                DateTime(_focusedMonth.year, _focusedMonth.month, 1);
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
            _monthPageController.jumpToPage(targetMonthPageIndex);
            }
          }
        });
      }
    });
  }

  void _addEvent(DateTime initialDate) async {
    final bool? eventWasAdded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEventPage(date: initialDate),
      ),
    );

    if (eventWasAdded == true) {
      await _loadEventsFromDb();
      if (_selectedDate != null && 
          _selectedDate!.year == initialDate.year &&
          _selectedDate!.month == initialDate.month &&
          _selectedDate!.day == initialDate.day) {
        _fetchAiDaySummary(_selectedDate!);
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

  Widget _buildSelectedDayEventSummary(BuildContext context, DateTime monthToDisplay) {
    final theme = Theme.of(context);

    if (_selectedDate == null || 
        _selectedDate!.month != monthToDisplay.month || 
        _selectedDate!.year != monthToDisplay.year) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              _selectedDate == null ? "Select a day to see its AI summary." : "AI Summary will appear here.",
              style: theme.textTheme.bodyMedium, // Will use Inter from theme
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
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // inter from theme
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
                  tooltip: "View Day Details",
                  onPressed: () => _showDayEventsTimeSlotsPage(_selectedDate!),
                )
              ],
            ),
          ),
          Expanded(
            child: _isFetchingAiSummary
                ? const Center(child: CircularProgressIndicator())
                : _aiDaySummary != null && _aiDaySummary!.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          _aiDaySummary!,
                           style: theme.textTheme.bodyMedium, // Will use Inter from theme
                        ),
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No summary available for this day, or an error occurred.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium, // Will use Inter from theme
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
    final prevNextMonthTextColor =
        theme.colorScheme.onSurface.withOpacity(0.38);

    final firstDayOfMonth =
        DateTime(monthToDisplay.year, monthToDisplay.month, 1);
    final daysInMonth =
        DateTime(monthToDisplay.year, monthToDisplay.month + 1, 0).day;
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
                  top: BorderSide(color: Colors.transparent, width: 0.5),
                  right: BorderSide(color: Colors.transparent, width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: boxSize * 0.35, color: prevNextMonthTextColor), // inter from theme
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
      final isTodayDate = date.year == _today.year &&
          date.month == _today.month &&
          date.day == _today.day;
      final dayKey = DateTime(date.year, date.month, date.day);
      final hasEvent =
          _events.containsKey(dayKey) && _events[dayKey]!.isNotEmpty;

      Color numberColor;
      FontWeight numberFontWeight = FontWeight.normal;
      BoxDecoration cellDecoration = BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.transparent, width: 0.5),
          right: BorderSide(color: Colors.transparent, width: 0.5),
        ),
      );

      TextStyle? dayTextStyle;

      if (isSelected) {
        cellDecoration = cellDecoration.copyWith(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        );
        numberColor = theme.colorScheme.onPrimaryContainer;
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: numberColor );
      } else if (isTodayDate) {
        numberColor = theme.colorScheme.primary;
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: Color.fromRGBO(0, 137,50, 1) );
      } else {
        numberColor = theme.colorScheme.onSurface;
        dayTextStyle = theme.textTheme.bodySmall?.copyWith(color: numberColor );
      }

      if (isTodayDate && isSelected) {
         numberColor = theme.colorScheme.onPrimaryContainer;
         dayTextStyle = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: numberColor );
      }

      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth; // Recalculate boxSize here as it might not be in scope for dayTextStyle
            // Apply dynamic font size to the existing text style
            TextStyle? finalDayTextStyle = dayTextStyle?.copyWith(fontSize: boxSize * 0.4);

            return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _fetchAiDaySummary(date); 
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
                        style: finalDayTextStyle, // inter from theme, with dynamic size
                      ),
                      if (hasEvent)
                        Positioned(
                          right: boxSize * 0.1,
                          bottom: boxSize * 0.1,
                          child: Icon(Icons.circle,
                              size: boxSize * 0.15,
                              color: theme.colorScheme.secondary),
                        ),
                    ],
                  ),
                ));
          },
        ),
      );
    }

    int nextDaysRequired = (weekdayOffset + daysInMonth <= 35) ? 35 - (weekdayOffset + daysInMonth) : 42 - (weekdayOffset + daysInMonth);
    
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
                  top: BorderSide(color: Colors.transparent, width: 0.5),
                  right: BorderSide(color: Colors.transparent,width: 0.5),
                ),
              ),
              child: Center(
                child: Text(
                  i.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: boxSize * 0.35, color: prevNextMonthTextColor), // inter from theme
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
         _buildSelectedDayEventSummary(context, monthToDisplay),
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
            padding: const EdgeInsets.only(right: 4.0),
            alignment: Alignment.centerRight,
            child: Text(
              DateFormat('HH:mm').format(DateTime(2000, 1, 1, hour)),
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: timeLabelColor), // inter from theme
            ),
          ),
        ),
      );
    }
    return Stack(children: timeLabels);
  }

  Widget _buildSingleDayScheduleStack(
      BuildContext context, DateTime day, List<Event> events, double columnWidth) {
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
            color: theme.dividerColor,
          ),
        ),
      );
    }

    for (var event in events) {
      final startMinutes =
          event.startTimeAsTimeOfDay.hour * 60 + event.startTimeAsTimeOfDay.minute;
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
        eventHeight =
            ((_maxHour - _minHour + 1) * _hourHeight) - topPosition;
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
                style: theme.textTheme.labelSmall?.copyWith( // inter from theme
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
    List<DateTime> weekDates =
        List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final totalScrollableHeight = (_maxHour - _minHour + 1) * _hourHeight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousWeek),
              Text(
                "${DateFormat.MMMd().format(weekDates.first)} - ${DateFormat.MMMd().format(weekDates.last)}",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // inter from theme
              ),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextWeek),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(width: _timeLabelWidth),
            ...weekDates.map((date) {
              bool isToday = date.year == _today.year &&
                  date.month == _today.month &&
                  date.day == _today.day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Text(
                    weekDays[date.weekday % 7].toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith( // inter from theme
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
                    daySpecificEvents.sort((a, b) =>
                        (a.startTimeAsTimeOfDay.hour * 60 +
                                a.startTimeAsTimeOfDay.minute)
                            .compareTo(b.startTimeAsTimeOfDay.hour * 60 +
                                b.startTimeAsTimeOfDay.minute));

                    return Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: totalScrollableHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    color: borderColor,
                                    width: 0.5),
                                right: date == weekDates.last
                                    ? BorderSide(
                                        color: borderColor,
                                        width: 0.5)
                                    : BorderSide.none,
                              ),
                            ),
                            child: _buildSingleDayScheduleStack(context, date,
                                daySpecificEvents, constraints.maxWidth),
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
    final weekDayNames =
        DateFormat.EEEE().dateSymbols.STANDALONENARROWWEEKDAYS;
    final weekNameDisplay = DateFormat.yMMMM().format(_focusedMonth);
    final monthNameDisplay = DateFormat.yMMMM().format(_focusedMonth);



    return Scaffold(
      appBar: AppBar(
        title: Text(_isWeekView 
            ? weekNameDisplay
            : monthNameDisplay), // inter from theme (via appBarTheme.titleTextStyle)
        // centerTitle: true,
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
            icon: Icon(_isWeekView
                ? Icons.calendar_month_outlined
                : Icons.view_week_outlined),
            onPressed: _toggleView,
            tooltip:
                _isWeekView ? 'Switch to Month View' : 'Switch to Week View',
          ),
        ],
      ),
      body: Column( 
        children: [
          if (!_isWeekView) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    monthNameDisplay,
                    style: theme.textTheme.titleLarge, // inter from theme
                  ),
                  Row( 
                    children: [
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
                              style: theme.textTheme.labelSmall?.copyWith( // inter from theme
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
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
                          _focusedWeekStart =
                              _getDateFromWeekPageIndex(pageIndex);
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
                          final newFocusedMonth =
                              _getDateFromMonthPageIndex(pageIndex);
                          _focusedMonth = newFocusedMonth;
                           bool shouldUpdateSummary = false;
                           if (_selectedDate != null && 
                               (_selectedDate!.month != _focusedMonth.month || _selectedDate!.year != _focusedMonth.year)) {
                            DateTime newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, _selectedDate!.day);
                            if (newSelectedCandidate.month != _focusedMonth.month) {
                                newSelectedCandidate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
                            }
                            _selectedDate = newSelectedCandidate; 
                            shouldUpdateSummary = true;
                          } else if (_selectedDate == null && _focusedMonth !=null) {
                            DateTime actualNow = DateTime.now();
                             _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 
                                (_focusedMonth.year == actualNow.year && _focusedMonth.month == actualNow.month) ? actualNow.day : 1);
                             if(_selectedDate!.month != _focusedMonth.month) { 
                                _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month,1);
                             }
                            shouldUpdateSummary = true;
                          }

                          if (shouldUpdateSummary && _selectedDate != null) {
                            _fetchAiDaySummary(_selectedDate!);
                          } else if (_selectedDate == null) {
                             _aiDaySummary = "Select a day to see its AI summary.";
                             _isFetchingAiSummary = false;
                          }
                        });
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
