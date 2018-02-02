// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

class Indenter {
  StringBuffer _sb;
  final int increment;
  int _level;
  int _nSpaces;
  String _indent;

  Indenter([this.increment = 2])
      : _sb = new StringBuffer(),
        _level = 0,
        _nSpaces = 0,
        _indent = "";

  String get close {
    _sb = null;
    return toString();
  }

  void _setIndent(int count) {
    _level += count;
    _nSpaces = _level * increment;
    _indent = _spaces(_nSpaces);
    print('incr: $increment, level: $_level, _nSpaces: $_nSpaces, _indent: "$_indent" ');
  }

  void indent(String s, [int count = 1]) {
    _sb.writeln('$_indent$s');
    _setIndent(count);
  }

  void outdent(String s, [int count = 1]) {
    _setIndent(-count);
    _sb.writeln('$_indent$s');
  }

  String get output => toString();

  void write(String s) => _sb.write(s);
  void writeln(String s) => _sb.writeln('$_indent$s');

  void start([String s = '', int count = 1]) {
    _setIndent(count);
    print('nSpaces: $_nSpaces, _indent: $_indent');
    _sb.write('$_indent$s');
  }

  void add(String s) => _sb.write(s);

  void end([String s = '', int count = 1]) {
    _sb.write('$s\n');
    _setIndent(-count);
    print('nSpaces: $_nSpaces, _indent: $_indent');
  }

  String toString() => _sb.toString();
}

String _spaces(int count) => "".padRight(count, ' ');
