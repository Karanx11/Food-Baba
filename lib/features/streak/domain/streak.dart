import '../../../core/dates.dart';

/// Milestone lengths, in days, that earn a badge.
const List<int> kStreakMilestones = [7, 30, 100];

/// A logging streak computed from the days that have food logged.
class Streak {
  const Streak({
    required this.current,
    required this.longest,
    required this.loggedToday,
    required this.atRisk,
  });

  static const Streak none = Streak(
    current: 0,
    longest: 0,
    loggedToday: false,
    atRisk: false,
  );

  /// Length of the run of consecutive logged days ending today, or ending
  /// yesterday when today has nothing yet (the streak is still alive today).
  final int current;

  /// The longest run of consecutive logged days ever.
  final int longest;

  /// Whether today already has food logged.
  final bool loggedToday;

  /// True when the streak is positive but today is not logged yet, so it will
  /// break at midnight unless the user logs something.
  final bool atRisk;

  /// The highest milestone this streak has reached, or null.
  int? get reachedMilestone {
    int? reached;
    for (final m in kStreakMilestones) {
      if (current >= m) reached = m;
    }
    return reached;
  }

  /// The next milestone to aim for, or null once the last one is passed.
  int? get nextMilestone {
    for (final m in kStreakMilestones) {
      if (current < m) return m;
    }
    return null;
  }

  /// Days remaining to [nextMilestone], or null when there is none.
  int? get daysToNextMilestone {
    final next = nextMilestone;
    return next == null ? null : next - current;
  }
}

abstract final class StreakCalculator {
  /// Builds a [Streak] from the set of day keys that have food and [today].
  ///
  /// The current streak counts consecutive days back from today. If today has
  /// nothing logged yet the run is measured from yesterday instead, and the
  /// streak is flagged [Streak.atRisk] so the UI can nudge the user before
  /// midnight.
  static Streak compute(Set<String> loggedDays, DateTime today) {
    if (loggedDays.isEmpty) return Streak.none;
    final t = dateOnly(today);
    final loggedToday = loggedDays.contains(dayKeyOf(t));

    // Anchor the current run at today if logged, else yesterday.
    final anchor = loggedToday ? t : DateTime(t.year, t.month, t.day - 1);
    var current = 0;
    if (loggedDays.contains(dayKeyOf(anchor))) {
      var day = anchor;
      while (loggedDays.contains(dayKeyOf(day))) {
        current++;
        day = DateTime(day.year, day.month, day.day - 1);
      }
    }

    return Streak(
      current: current,
      longest: _longestRun(loggedDays),
      loggedToday: loggedToday,
      atRisk: current > 0 && !loggedToday,
    );
  }

  static int _longestRun(Set<String> loggedDays) {
    final days = loggedDays.map(parseDayKey).toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (daysBetween(days[i - 1], days[i]) == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
    }
    return longest;
  }
}
