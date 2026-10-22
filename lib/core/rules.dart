/// Business rules from the SRS, in one place so they are never magic numbers.
class Rules {
  Rules._();

  /// FR-BOR-02
  static const maxActiveLoans = 3;

  /// FR-BOR-06
  static const loanPeriod = Duration(days: 7);

  /// FR-BOR-07
  static const collectionWindow = Duration(hours: 48);

  /// FR-BOR-11
  static const renewalPeriod = Duration(days: 7);
  static const maxRenewals = 1;

  /// FR-NOT-01: "due within 24 hours"
  static const dueSoonWindow = Duration(hours: 24);

  /// FR-SSA-04
  static const weakTopicThreshold = 60;

  /// FR-SSA-01
  static const quizLengths = [5, 10, 20];

  /// FR-SSA-08
  static const maxRecommendations = 5;

  /// FR-AUTH-07
  static const sessionTimeout = Duration(minutes: 30);
  static const shortSessionTimeout = Duration(minutes: 5);

  /// FR-RES-09, FR-SRCH-06
  static const recentItems = 5;

  /// Revision plan horizon and default session length (FR-SSA-09).
  static const planHorizonDays = 21;
  static const planSessionMinutes = 60;

  /// Collection code length (FR-BOR-06).
  static const collectionCodeLength = 6;
}
