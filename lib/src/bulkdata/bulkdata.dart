// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

const String bulkdataFileExtension = '.bd';

class BulkdataUri {
  final String scheme = 'https';
  final String path;
  final String query;
  final int offset;
  final int length;

  BulkdataUri(this.path, this.offset, this.length)
  : query = 'bytes=$offset-$length' {
    print('uri: ${Uri.encodeFull('$uri')}');
  }

  Uri get uri =>  new Uri(scheme: scheme, path: path, query: query);

  @override
  String toString() => Uri.encodeFull('$uri');
}

class Bulkdata {
  /// Dicom Tag Code
  int code;
  /// The byte offset of this in the Bulkdata File.
  int index;
  /// Value Field
  Uint8List vf;

  Bulkdata(this.code, this.index, this.vf);

  int get length => vf.lengthInBytes;

}

