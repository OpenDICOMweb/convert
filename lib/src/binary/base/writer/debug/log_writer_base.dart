// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A library for encoding [Dataset]s in the DICOM File Format.
///
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
/// Does not currently support BIG ENDIAN which is retired.
///
/// _Notes_:
///   1. In all cases [WriterBase] writes the Value Fields as they
///   are in the data; thus, all Value Fields should have an even length.
///   2. All String manipulation should be handled in the attribute itself.
// Note: There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
abstract class WriterBase extends DcmWriterBase {
  /// Creates a new [WriterBase], where [wIndex] = 0.
  WriterBase(
      RootDataset rds, EncodingParameters eParams, int minBDLength, bool reUseBD)
      : super(rds, eParams, minBDLength, reUseBD);

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  @override
  Uint8List writeRootDataset(RootDataset rds) {
    log.debug('${wb.wbb} writeRootDataset $rds :${wb.remaining}');
    final bytes = super.writeRootDataset(rds);
    log.debug('${wb.wee} writeRootDataset  :${wb.remaining}');
    return bytes;
  }

  int itemCount;

  @override
  void writeItems(List<Item> items) {
    itemCount = 0;
    log.debug('${wb.wbb} Writing ${items.length} Items', 1);
    for (var item in items) {
      writeItem(item);
      itemCount++;
    }
    log.debug('${wb.wee} Wrote $itemCount Items', -1);
  }

  @override
  void writeItem(Item item) {
    log.debug('${wb.wbb} Writing Item: $item', 1);
    super.writeItem(item);
    log.debug('${wb.wee} Wrote Item: $item', -1);
  }

  @override
  void writeUndefinedLengthDataset(Item item) {
    log.debug('${wb.wbb} Writing item #$itemCount', 1);
    ((item.hasULength && !eParams.doConvertUndefinedLengths))
        ? _writeUndefinedLengthDataset(item)
        : _writeDefinedLengthDataset(item);
    log.debug('${wb.wee} Wrote item #$itemCount', -1);
  }

  void _writeUndefinedLengthDataset(Item item) {
    log.debug('${wb.wbb} Writing item #$itemCount', 1);
    super.writeUndefinedLengthDataset(item);
    log.debug('${wb.wee} Wrote item #$itemCount', -1);
  }

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthDataset(Dataset ds) {
    log.debug('${wb.wbb} Writing $ds #$itemCount', 1);
    super.writeDefinedLengthDataset(ds);
    log.debug('${wb.wee} Wrote item #$itemCount', -1);
  }

  @override
  void writeEncapsulatedPixelData(Element e) {
    log.debug('${wb.wbb} Writing Encapsulated pixel data $e', 1);
    super.writeEncapsulatedPixelData(e);
    log.debug('${wb.wee} Wrote Encapsulated pixel data', -1);
  }
}
