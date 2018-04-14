// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/subreader.dart';
import 'package:convert/src/binary/byte/reader/byte_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class ByteEvrSubReader extends EvrSubReader
    with ByteReaderMixin, EvrByteReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;
  factory ByteEvrSubReader(Bytes bytes, DecodingParameters dParams,
          {bool doLogging = false, bool doLookupVRIndex = true}) =>
      new ByteEvrSubReader._(bytes, dParams, new BDRootDataset.empty(),
          doLogging, doLookupVRIndex);

  ByteEvrSubReader._(Bytes bytes, DecodingParameters dParams, this.rds,
      this.doLogging, this.doLookupVRIndex)
      : super(bytes, dParams, rds);

  @override
  Element makePixelData(int code, Bytes eBytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      EvrElement.makePixelData(
          code, eBytes, vrIndex, vfLengthField, ts, fragments);

  @override
  Element makePixelDataFromBytes(int code, Bytes eBytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      EvrElement.makePixelData(
          code, eBytes, vrIndex, vfLengthField, ts, fragments);
}

class ByteIvrSubReader extends IvrSubReader
    with ByteReaderMixin, IvrByteReaderMixin {
  @override
  BDRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  ByteIvrSubReader.from(ByteEvrSubReader evrSubReader)
      : rds = evrSubReader.rds,
        doLogging = evrSubReader.doLogging,
        doLookupVRIndex = evrSubReader.doLookupVRIndex,
        super(evrSubReader.rb, evrSubReader.dParams, evrSubReader.rds);

  @override
  Element makePixelData(int code, Bytes vfBytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      IvrElement.makePixelData(
          code, vfBytes, vrIndex, vfLengthField, ts, fragments);

  @override
  Element makePixelDataFromBytes(int code, Bytes vfBytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      IvrElement.makePixelData(
          code, vfBytes, vrIndex, vfLengthField, ts, fragments);
}
