// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

/*
const k10KB = 10 * 1024;
const k20KB = 20 * 1024;
const k50KB = 50 * 1024;
const k100KB = 100 * 1024;*/
const k200KB = 200 * 1024;

// Next 3 values are 2x16bit little Endian values as one 32bit value.
const kSequenceDelimitationItem32Bit = 0xfeffdde0;
const kItem32Bit = 0xfeff00e0;
const kItemDelimitationItem32Bit = 0xfeff0de0;

class DcmWriterBase {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.debug2);

  //TODO: make the buffer grow and shrink adaptively.
  //TODO: doc
  //Urgent: this should grow and shrink automatically
  static const int defaultBufferLength = 200 * kMB;
  static ByteData _reuse;

  /// The source of the [Uint8List] being read.
  final String path;

  /// The [TransferSyntax] for the output.
  final TransferSyntax outputTS;

  /// The [Endianness] of the output.
  final Endianness endianness;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// if [true] [Dataset]s will be allowed to be written in IVRLE.
  final bool allowImplicitLittleEndian;

  /// If [true], a DICOM File Prefix (PS3.10) will be written even
  /// if it wasn't present when read.
  final bool addMissingPrefix;

  /// If [true], a DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when read.
  final bool addMissingFMI;

  final bool removeUndefinedLengths;

  final bool reUseBD;

  /// The root Dataset for the object being read.
  final RootByteDataset rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset _currentDS;

  TransferSyntax _transferSyntax;
  bool _isEncapsulated;

  final ByteData bd;
  int _wIndex;

  DcmWriterBase(
    this.rootDS, {
    this.path = "",
    this.outputTS,
    this.endianness = Endianness.LITTLE_ENDIAN,
    this.throwOnError = true,
    this.allowImplicitLittleEndian = true,
    this.addMissingPrefix = false,
    this.addMissingFMI = false,
    this.removeUndefinedLengths = false,
    this.reUseBD = true,
  })
      : _wIndex = 0,
        bd = (reUseBD)
            ? _reuseBD(rootDS.vfLength + 1024)
            : new ByteData(rootDS.vfLength);

  static ByteData _reuseBD([int size = defaultBufferLength]) {
    if (_reuse == null) return _reuse = new ByteData(size);
    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteData(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
          .lengthInBytes}');
    }
    return _reuse;
  }
}
