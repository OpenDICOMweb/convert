// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.


void main() {
  //var s = '1950-07-18T12:06:04.123456-0500';

  //var s = "TEST^TEST ";
  var b = "TEST";
  var c = [b, b].join('^') + "^";
  print(c);
  //parse(0x00100010, "0");

  /*
  print(fmtTag(kPrivateInformation));
  print(Element.kPrivateInformation);
  print(Element.kLengthToEnd);
  */
}

List<double> parse(int tag, String s) {
  double dsError(String s) {
    //log.error('Invalid DS (decimal) String: "$s"');
    throw 'Bad DS String: "$s"';
  }
  //if (s.length == 0) return new DS(tag, Float.emptyList);
  List<String> strings = s.split('\\');
  List<double> floatList = [];
  print('DS.strings: $strings');
  for (String s in strings) {
    print('DS.s: "$s"');
    var n = double.parse(s, dsError);
    floatList.add(n);
  }
  print('floatList: $floatList');
  return floatList;
}

void foo() {
  var n = double.parse("0", (s) {
    //** log.error('Invalid DS (decimal) String: $s');
    throw 'Bad DS String: "$s"';
  });
  print('n= $n');
}

var tz = new RegExp('[\-+Zz]');

String removeMarks(String s) {
  final marks = new RegExp('[\-:T\s]');
  int i = s.lastIndexOf(tz);
  if (i > -1) s = s.substring(0, i);
  var r = s.replaceAll(marks, "");
  return r;
}

String timeZone(String s) {
  int i = s.lastIndexOf(tz);
  if (i > 0) return s.substring(i);
  return null;
}

final RegExp tzMarks = new RegExp('[\-+Zz]');

/// Parses the [String] specified by the arguments as a DICOM format
/// DateTime [String], and returns the corresponding [DcmDateTime].
//TODO: Make sure TimeZone(s) are being handled correctly
// in particulate when reading a DT with a tzOffset convert it to local time.
/*
DateTime parse(String dt, [int start = 0, int end]) {
  if (end == null) end = dt.length;
  if (end > 26)
   print('Invalid String Length = $end');
  Date d = Date.parse(dt);
  if (dt.length <= 8) return new DcmDateTime(d, null, null);
  int i = dt.lastIndexOf(tzMarks);
  //TimeZone tz = TimeZone.parse(dt.substring(i));
  int u = (dt.length >= 21) ? _readMicrosecond(dt.substring(18, 21)) : -1;
  int ms = (dt.length >= 10) ? _readMillisecond(dt.substring(15, 18)) : -1;
// if (_readDot(s.substring(14, 15)) throw "Invalid decimal point";
  int s = (dt.length >= 6) ? _readSecond(dt.substring(12, 14)) : -1;
  int m = (dt.length >= 4) ? _readMinute(dt.substring(10, 12)) : -1;
  int y = _readYear(dt.substring(0, 4));
  int mm = _readMonth(dt.substring(4, 6));
  int d = _readDay(y, mm, dt.substring(6, 8));
  int h = _readHour(dt.substring(8, 10));
  DateTime newDT = new DateTime(
      y,
      mm,
      d,
      h,
      m,
      s,
      ms,
      u);
  return new DcmDateTime._(newDT.add(tz.timeZone), tz);
}
*/