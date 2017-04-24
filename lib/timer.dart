// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

/// A simple timer
//TODO: document
class Timer {
    final Stopwatch watch = new Stopwatch();

    // The end of the last [split], i.e. interval.
    Duration _last = new Duration(microseconds: 0);

    /// The constructor automatically starts the timer.
    Timer() {
        watch.start();
    }

    /// The total elapsed time since the [Timer] as started.
    Duration get elapsed => watch.elapsed;

    /// Returns the [Duration] between the present time and the end
    /// of the last [split].
    Duration get split {
        var now = watch.elapsed;
        var time = now - _last;
        _last = now;
        return time;
    }

    void start() => watch.start();
    void stop() => watch.stop();
    void reset() => watch.stop();
}
