enum Role {
  student('Student'),
  librarian('Librarian'),
  institutionAdmin('Institution administrator'),
  platformAdmin('Platform administrator');

  const Role(this.label);
  final String label;

  bool get isStaff => this != Role.student;
}

/// FR-RES-02
enum PaperType {
  final_('final', 'Final examination'),
  mid('mid', 'Mid-semester test'),
  supp('supp', 'Supplementary'),
  assignment('assignment', 'Assignment'),
  notes('notes', 'Notes');

  const PaperType(this.key, this.label);
  final String key;
  final String label;

  static PaperType fromKey(String key) =>
      values.firstWhere((t) => t.key == key);
}

enum CopyStatus {
  available('Available'),
  reserved('Reserved'),
  onLoan('On loan');

  const CopyStatus(this.label);
  final String label;
}

/// Loan states from SRS 3.5.
enum LoanStatus {
  requested('Requested'),
  approved('Approved'),
  collected('Collected'),
  overdue('Overdue'),
  returned('Returned'),
  rejected('Rejected'),
  cancelled('Cancelled'),
  expired('Expired');

  const LoanStatus(this.label);
  final String label;

  /// FR-BOR-02: these count toward the active-loan limit.
  bool get isActive =>
      this == requested ||
      this == approved ||
      this == collected ||
      this == overdue;
}

enum QuestionType {
  multipleChoice('Multiple choice'),
  trueFalse('True/false'),
  shortAnswer('Short answer');

  const QuestionType(this.label);
  final String label;
}

enum CardRating { easy, good, hard }

enum NotificationCategory {
  loan('Loans'),
  newResource('New papers'),
  study('Study reminders'),
  request('Borrowing requests'),
  system('System');

  const NotificationCategory(this.label);
  final String label;
}

enum UsageEventType { search, unmetSearch, view, loan, quiz }

T enumByName<T extends Enum>(List<T> values, String name) =>
    values.firstWhere((v) => v.name == name);
