import 'package:flutter_test/flutter_test.dart';
import 'package:food_baba/core/dates.dart';
import 'package:food_baba/features/streak/domain/streak.dart';

/// Day keys for [count] consecutive days ending at [end] (inclusive).
Set<String> _run(DateTime end, int count) => {
  for (var i = 0; i < count; i++)
    dayKeyOf(DateTime(end.year, end.month, end.day - i)),
};

void main() {
  final today = DateTime(2026, 9, 22, 13); // Tuesday 1 pm

  group('current streak', () {
    test('no logged days is a zero streak', () {
      final s = StreakCalculator.compute({}, today);
      expect(s.current, 0);
      expect(s.longest, 0);
      expect(s.loggedToday, isFalse);
      expect(s.atRisk, isFalse);
    });

    test('only today counts as one', () {
      final s = StreakCalculator.compute({dayKeyOf(today)}, today);
      expect(s.current, 1);
      expect(s.loggedToday, isTrue);
      expect(s.atRisk, isFalse);
    });

    test('consecutive days ending today', () {
      final s = StreakCalculator.compute(_run(today, 3), today);
      expect(s.current, 3);
      expect(s.longest, 3);
    });

    test('yesterday but not today keeps the streak, flagged at risk', () {
      final yesterday = DateTime(2026, 9, 21);
      final s = StreakCalculator.compute(_run(yesterday, 3), today);
      expect(s.current, 3); // 21, 20, 19
      expect(s.loggedToday, isFalse);
      expect(s.atRisk, isTrue);
    });

    test('a gap before today breaks the current run', () {
      // 22 and 21 logged, 20 missing, 19 logged.
      final days = {
        dayKeyOf(DateTime(2026, 9, 22)),
        dayKeyOf(DateTime(2026, 9, 21)),
        dayKeyOf(DateTime(2026, 9, 19)),
      };
      final s = StreakCalculator.compute(days, today);
      expect(s.current, 2);
    });

    test('two days ago with nothing since is a broken streak', () {
      final s = StreakCalculator.compute({
        dayKeyOf(DateTime(2026, 9, 20)),
      }, today);
      expect(s.current, 0);
      expect(s.atRisk, isFalse);
    });
  });

  group('longest streak', () {
    test('is the best run across all history', () {
      final days = {
        ..._run(DateTime(2026, 9, 3), 3), // 1,2,3 -> run of 3
        dayKeyOf(DateTime(2026, 9, 10)), // lone day
        ..._run(today, 2), // 21,22 -> run of 2
      };
      final s = StreakCalculator.compute(days, today);
      expect(s.current, 2);
      expect(s.longest, 3);
    });

    test('never below the current run', () {
      final s = StreakCalculator.compute(_run(today, 5), today);
      expect(s.longest, 5);
    });
  });

  group('milestones', () {
    Streak at(int current) =>
        StreakCalculator.compute(_run(today, current), today);

    test('below the first milestone', () {
      final s = at(5);
      expect(s.reachedMilestone, isNull);
      expect(s.nextMilestone, 7);
      expect(s.daysToNextMilestone, 2);
    });

    test('exactly on a milestone', () {
      final s = at(7);
      expect(s.reachedMilestone, 7);
      expect(s.nextMilestone, 30);
      expect(s.daysToNextMilestone, 23);
    });

    test('past the last milestone', () {
      final s = at(100);
      expect(s.reachedMilestone, 100);
      expect(s.nextMilestone, isNull);
      expect(s.daysToNextMilestone, isNull);
    });
  });
}
