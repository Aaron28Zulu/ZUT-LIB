/// The demo clock (FR-DEMO-03). Every due-date, expiry and reminder rule reads
/// [Clock.now]; the platform administrator can move it forward from demo controls.
///
/// This is the only file allowed to call `DateTime.now()`.
class Clock {
  Clock._();

  static Duration _offset = Duration.zero;

  static DateTime now() => DateTime.now().toUtc().add(_offset);

  /// Real time, for things the demo clock must not affect (session inactivity).
  static DateTime wallNow() => DateTime.now().toUtc();

  static Duration get offset => _offset;

  static bool get isShifted => _offset != Duration.zero;

  static void advance(Duration by) => _offset += by;

  static void setOffset(Duration offset) => _offset = offset;

  static void reset() => _offset = Duration.zero;
}
