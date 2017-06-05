// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

/// A Simple Timer based on Dart's [Stopwatch].
class Timer {
    final Stopwatch watch = new Stopwatch();
    /// The first time [this] was started.
    DateTime _start;

    /// The last time [this] was stopped.
    DateTime _stop;

    int _splitTicks = 0;

    /// The end of the last [split], i.e. interval.
    Duration _last = new Duration(microseconds: 0);

    /// The constructor automatically starts the timer.
    Timer({bool start = false}) {
      if (start) watch.start();
    }

    /// The [DateTime] when [this] started/
    DateTime get startTime => _start;

    /// The [DateTime] when [this] started/
    DateTime get stopTime => _stop;

    int get frequency => watch.frequency;

    /// The total elapsed time as a [Duration] since the first call to [start],
    /// while the
    /// [Timer] is running.
    Duration get elapsed => watch.elapsed;

    int get elapsedMicroseconds => watch.elapsedMicroseconds;

    int get elapsedMilliseconds => watch.elapsedMilliseconds;

    int get elapsedTicks => watch.elapsedTicks;

    bool get isRunning => watch.isRunning;

    bool get isStopped => !watch.isRunning;

    /// Returns the current [split] in clock ticks.
    int get splitTicks {
        int now = watch.elapsedTicks;
        int time = now - _splitTicks;
        _splitTicks = now;
        return time;
    }

    /// Returns the current [split] in microseconds.
    int get splitMicroseconds => splitTicks * 1000000 ~/ watch.frequency;

    /// Returns the [Duration] between the current time and the last split.
    Duration get split => new Duration(microseconds: splitMicroseconds);

    /// (Re)Start the [Timer].
    void start() {
      _start ??= new DateTime.now();
      watch.start();
    }

    /// Stop the [Timer], but it may be restarted later.
    void stop() {
      watch.stop();
      _stop = new DateTime.now();
    }

    /// Resets the [elapsed] count to zero. Note: _This method does not stop or
    /// start the [Timer]_.
    void reset() => watch.reset();
}
