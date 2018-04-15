//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:collection';

/// Reads a Map<directory, List<file>>, where directory and file are [String]s.
class FileListReader extends IterableBase<String> {
  final Map<String, List<String>> fileMap;

  FileListReader.fromMap(this.fileMap);

  @override
  FileListIterator get iterator => new FileListIterator(fileMap);

  @override
  int get length => fileMap.values.length;
}

class FileListIterator implements Iterator<String> {
  Map<String, List<String>> fileMap;
  final Iterable<String> _dirList;
  int _dirIndex;
  int _fileIndex;
  String _currentDir;
  Iterable<String> _fileList;

  FileListIterator(this.fileMap)
      : _dirList = fileMap.keys,
        _dirIndex = 0,
        _fileIndex = -1 {
    _currentDir = _dirList.elementAt(_dirIndex);
    _fileList = fileMap[_currentDir];
  }

  int get reset {
    _dirIndex = 0;
    return _fileIndex = -1;
  }

  @override
  String get current {
    final dir = _currentDir;
    final file = _fileList.elementAt(_fileIndex);
    return '$dir$file';
  }

  @override
  bool moveNext() {
    _fileIndex++;
    if (_fileIndex >= _fileList.length) {
      _dirIndex++;
      if (_dirIndex >= _dirList.length) return false;
      _fileIndex = 0;
      _currentDir = _dirList.elementAt(_dirIndex);
      _fileIndex = 0;
      return true;
    }
    return true;
  }
}
