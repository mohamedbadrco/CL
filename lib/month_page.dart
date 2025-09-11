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
                    color: theme.dividerColor.withOpacity(0), // No right border for visual grid
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
      final int eventCount = events[dayKey]?.length ?? 0;

      dayWidgets.add(
        LayoutBuilder(
          builder: (context, constraints) {
            final boxSize = constraints.maxWidth;
            
            Color? cellBackgroundColor;
            Color dayTextColor;
            FontWeight dayTextWeight = FontWeight.normal;
            bool makeTextCircular = false;

            TextStyle baseDayNumberTextStyle = theme.textTheme.bodySmall!.copyWith(
                fontSize: boxSize * 0.4,
            );

            if (isSelected) {
              cellBackgroundColor = const Color.fromARGB(255, 30, 110, 244); // slected_blu
              dayTextColor = Colors.white;
              dayTextWeight = FontWeight.w800;
              // If you want the blue selected cell to still have a circular highlight for the number:
              // makeTextCircular = true; 
              // However, the request was about consistent *background color* for the cell.
            } else { // Not selected
              if (eventCount > 1) {
                cellBackgroundColor = const Color.fromRGBO(0, 137, 50, 1); // level2_green
                dayTextColor = Colors.white;
                dayTextWeight = FontWeight.w800;
              } else if (eventCount == 1) {
                cellBackgroundColor = const Color.fromARGB(255, 74, 217, 104); // level1_green
                dayTextColor = theme.colorScheme.primary; // Dark text for light green
                dayTextWeight = FontWeight.w800;
              } else if (isTodayDate) {
                dayTextColor = const Color.fromRGBO(0, 137, 50, 1); // Today's distinct color for text
                dayTextWeight = FontWeight.w800;
                // Optionally, make today's number circular if no events and not selected
                // makeTextCircular = true; 
              } else {
                dayTextColor = theme.colorScheme.onSurface; // Default text color
              }
            }

            Widget dayContent = Text(
              day.toString(),
              style: baseDayNumberTextStyle.copyWith(
                color: dayTextColor,
                fontWeight: dayTextWeight,
              ),
            );

            if (makeTextCircular) { // Apply if decided to keep number in a circle for selected/today
                 dayContent = Container(
                    padding: EdgeInsets.all(boxSize * 0.08), // Smaller padding for text in circle
                    decoration: BoxDecoration(
                    color: isSelected ? const Color.fromARGB(255, 30, 110, 244) : (isTodayDate && !isSelected && eventCount == 0 ? Colors.transparent : null), // Blue for selected, or other for today if specified
                    shape: BoxShape.circle,
                    border: isTodayDate && !isSelected && eventCount == 0 ? Border.all(color: const Color.fromRGBO(0, 137, 50, 1), width: 1.5) : null, // Border for today circle
                    ),
                    child: Text(
                        day.toString(),
                        style: baseDayNumberTextStyle.copyWith(
                            color: (isSelected) ? Colors.white : (isTodayDate && !isSelected && eventCount == 0 ? const Color.fromRGBO(0, 137, 50, 1) : dayTextColor),
                            fontWeight: (isSelected || (isTodayDate && !isSelected && eventCount == 0)) ? FontWeight.w800 : dayTextWeight,
                        ),
                    ),
                );
                // If making text circular, the cellBackgroundColor for selected might need to be null/transparent
                // if the circle itself provides the blue. This part needs careful thought if mixing cell bg and inner circle.
                // For now, the main logic for cellBackgroundColor stands, and makeTextCircular is an addon if uncommented.
            }
            
            // The main logic from the user request is that the CELL background should be consistent when selected.
            // So, if isSelected, cellBackgroundColor is already blue. 
            // The `makeTextCircular` above would put a circle *inside* this blue cell, which might be redundant
            // or desired depending on exact visual goal. For now, it's off.

            BoxDecoration cellDecoration = BoxDecoration(
              color: cellBackgroundColor, // Blue if selected, green if events & not selected, or null
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withOpacity(0.2),
                  width: 0.5,
                ),
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0), // No right border
                  width: 0.5,
                ),
              ),
            );

            return GestureDetector(
              onTap: () => onDateSelected(date),
              onDoubleTap: () => onDateDoubleTap(date),
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: cellDecoration,
                child: Center(
                  child: dayContent, // This is now just the styled Text widget
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
                    color: theme.dividerColor.withOpacity(0), // No right border
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
