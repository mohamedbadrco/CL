import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // For Event type

class WeekPageContent extends StatelessWidget {
  final DateTime weekStart;
  final DateTime today;
  final Map<DateTime, List<Event>> events;
  final double hourHeight;
  final int minHour;
  final int maxHour;
  final double timeLabelWidth;
  final Function(DateTime) onShowDayEvents;
  final VoidCallback onGoToPreviousWeek;
  final VoidCallback onGoToNextWeek;

  const WeekPageContent({
    super.key,
    required this.weekStart,
    required this.today,
    required this.events,
    required this.hourHeight,
    required this.minHour,
    required this.maxHour,
    required this.timeLabelWidth,
    required this.onShowDayEvents,
    required this.onGoToPreviousWeek,
    required this.onGoToNextWeek,
  });

  Widget _buildTimeLabelStack(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabelColor = theme.colorScheme.onSurface;
    List<Widget> timeLabels = [];

    for (int hour = minHour; hour <= maxHour; hour++) {
      timeLabels.add(
        Positioned(
          top: (hour - minHour) * hourHeight,
          left: 0,
          width: timeLabelWidth,
          height: hourHeight,
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
    List<Event> dayEventsList,
    double columnWidth,
  ) {
    final theme = Theme.of(context);
    List<Widget> stackChildren = [];

    for (int hour = minHour; hour <= maxHour; hour++) {
      stackChildren.add(
        Positioned(
          top: (hour - minHour) * hourHeight,
          left: 0,
          width: columnWidth,
          child: Divider(height: 1, thickness: 0.5, color: theme.dividerColor),
        ),
      );
    }

    for (var event in dayEventsList) {
      final startMinutes =
          event.startTimeAsTimeOfDay.hour * 60 +
          event.startTimeAsTimeOfDay.minute;
      final endMinutes =
          event.endTimeAsTimeOfDay.hour * 60 + event.endTimeAsTimeOfDay.minute;
      final minHourMinutes = minHour * 60;

      final topPosition =
          ((startMinutes - minHourMinutes) / 60.0) * hourHeight;
      final eventDurationInMinutes = endMinutes - startMinutes;
      double eventHeight = (eventDurationInMinutes / 60.0) * hourHeight;

      if (eventHeight < hourHeight / 3) {
        eventHeight = hourHeight / 3;
      }
      if (topPosition < 0) continue;
      if (topPosition + eventHeight > (maxHour - minHour + 1) * hourHeight) {
        eventHeight = ((maxHour - minHour + 1) * hourHeight) - topPosition;
      }
      if (eventHeight <= 0) continue;

      stackChildren.add(
        Positioned(
          top: topPosition,
          left: 2.0,
          width: columnWidth - 4.0,
          height: eventHeight,
          child: GestureDetector(
            onTap: () => onShowDayEvents(day),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    final weekDaysSymbols =
        DateFormat.EEEE().dateSymbols.STANDALONESHORTWEEKDAYS;
    List<DateTime> weekDates = List.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );
    final totalScrollableHeight = (maxHour - minHour + 1) * hourHeight;

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
                onPressed: onGoToPreviousWeek,
              ),
              Expanded(
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
                onPressed: onGoToNextWeek,
              ),
            ],
          ),
        ),
        Row(
          children: [
            SizedBox(width: timeLabelWidth),
            ...weekDates.map((date) {
              bool isTodayDate =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        weekDaysSymbols[date.weekday % 7].toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground.withOpacity(0.8)
                              : (isTodayDate
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.8,
                                      )),
                        ),
                      ),
                      Text(
                        DateFormat.d().format(date),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isTodayDate
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: theme.brightness == Brightness.dark
                              ? theme.colorScheme.onBackground
                              : (isTodayDate
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
                    width: timeLabelWidth,
                    height: totalScrollableHeight,
                    child: _buildTimeLabelStack(context),
                  ),
                  ...weekDates.map((date) {
                    final dayKey = DateTime(date.year, date.month, date.day);
                    final daySpecificEvents = events[dayKey] ?? [];
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
                                        DateTime.sunday
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
}
