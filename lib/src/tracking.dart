class TimeTracking {
  final DateTime _startTime;
  final String _tag;

  TimeTracking(this._tag) : _startTime = DateTime.now();

  Duration elapsed() => DateTime.now().difference(_startTime);

  String elapsedString() => '[$_tag] ${elapsed().inMicroseconds} microseconds';
}

final appStartTracking = TimeTracking('app');
