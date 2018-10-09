// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.
//
import 'dart:convert' as cvt;
import 'dart:typed_data';

import 'package:core/core.dart';

/// The Part 10 Header of the DICOM File Format. See PS3.10.
class Part10Header<K, V> {
  final ByteData bd;
  final Fmi fmi;
  final TransferSyntax _ts;

  /// Creates a [Part10Header].
  Part10Header(this.bd, this.fmi, this._ts) {
    if (!hasPrefix) throw ArgumentError('Invalid Prefix: "$prefix"');
    if (fmi.isEmpty) throw ArgumentError('Empty FMI: $fmi');
  }

  /// Returns _true_if no FMI was present.
  bool get isEmpty => bd == null || fmi == null;

  /// _true_if [bd] has the bytes equal to ASCII 'DICM' at offset 128 in [bd].
  bool get hasPrefix => checkPrefix(bd);

  TransferSyntax get ts => _ts ?? global.defaultTransferSyntax;
  bool get isEVR => ts != TransferSyntax.kImplicitVRLittleEndian;

  /// Returns the 128 byte DICOM Part 10 Preamble.
  Uint8List get preamble => bd.buffer.asUint8List(0, 128);

  /// Returns _true_if [preamble] was all zeros.
  bool get wasPreambleZeros => hasPrefix && _checkForZeros();

  /// Returns _true_if the first 128 bytes in [bd] are zero.
  bool _checkForZeros() {
    for (var i = 0; i < 128; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  /// _true_if [TransferSyntax] was specified in this header; otherwise,
  /// _false_, and [TransferSyntax] is default ImplicitVRLittleEndian.
  bool get wasTSSpecified => ts != null;

  @override
  String toString() => '$runtimeType: $ts, FMI(${fmi.length} elements)';

  /// The DICOM Part 10 Prefix.
  static String get prefix => 'DICM';

  /// Returns true if [bd] has a DICOM Prefix.
  static bool checkPrefix(ByteData bd) {
    if (bd == null || bd.lengthInBytes < 132) return false;
    final s = cvt.ascii.decode(bd.buffer.asUint8List(128, 4));
    return s == prefix;
  }
}
