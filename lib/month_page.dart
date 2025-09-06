import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './database_helper.dart'; // For Event type

class MonthPageContent extends StatelessWidget {
  final DateTime monthToDisplay;
  final DateTime? selectedDate;
  final DateTime today;
  final Map<DateTime, List<Event>> events;
  final bool isFetchingAiSummary;
  final String? aiDaySummary;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onDateDoubleTap;
  final Function(DateTime) onShowDayEvents;

  const MonthPageContent({
    super.key,
    required this.monthToDisplay,
    required this.selectedDate,
    required this.today,
    required this.events,
    required this.isFetchingAiSummary,
    required this.aiDaySummary,
    required this.onDateSelected,
    required this.onDateDoubleTap,
    required this.onShowDayEvents,
  });

  Widget _buildSelectedDayEventSummary(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedDate == null ||
        selectedDate!.month != monthToDisplay.month ||
        selectedDate!.year != monthToDisplay.year) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              selectedDate == null
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
                    "AI Summary for ${DateFormat.yMMMd().format(selectedDate!)}",
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
                  onPressed: () => onShowDayEvents(selectedDate!),
                ),
              ],
            ),
          ),
          Expanded(
            child: isFetchingAiSummary
                ? const Center(child: CircularProgressIndicator())
                : aiDaySummary != null && aiDaySummary!.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          aiDaySummary!,
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

  @override
  Widget build(BuildContext context) {
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

    // Previous month's days
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

    // Current month's days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthToDisplay.year, monthToDisplay.month, day);
      final isSelected =
          selectedDate != null &&
          selectedDate!.year == date.year &&
          selectedDate!.month == date.month &&
          selectedDate!.day == date.day;
      final isTodayDate =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final dayKey = DateTime(date.year, date.month, date.day);
      final hasEvent =
          events.containsKey(dayKey) && events[dayKey]!.isNotEmpty;

      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;

            BoxDecoration cellOverallDecoration = BoxDecoration(
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

            Widget dayNumberWidget;
            TextStyle? dayNumberStyle;

            if (isSelected) {
              dayNumberStyle = theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: boxSize * 0.4,
              );
              dayNumberWidget = Container(
                padding: EdgeInsets.all(boxSize * 0.1), // Padding for the circle around the text
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(day.toString(), style: dayNumberStyle),
              );
            } else if (isTodayDate) {
              dayNumberStyle = theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color.fromRGBO(0, 137, 50, 1), // Today's distinct color
                fontSize: boxSize * 0.4,
              );
              dayNumberWidget = Text(day.toString(), style: dayNumberStyle);
            } else {
              dayNumberStyle = theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: boxSize * 0.4,
              );
              dayNumberWidget = Text(day.toString(), style: dayNumberStyle);
            }

            return GestureDetector(
              onTap: () => onDateSelected(date),
              onDoubleTap: () => onDateDoubleTap(date),
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: cellOverallDecoration, // This decoration is for the cell borders
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    dayNumberWidget, // This is the (potentially decorated) day number
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

    // Next month's days
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
        _buildSelectedDayEventSummary(context),
      ],
    );
  }
}
