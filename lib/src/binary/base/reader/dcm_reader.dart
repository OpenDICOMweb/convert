// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
library odw.sdk.convert.binary.reader;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/reader_interface.dart';
import 'package:dcm_convert/src/binary/base/reader/byte_reader.dart';

part 'package:dcm_convert/src/binary/base/reader/read_evr.dart';
part 'package:dcm_convert/src/binary/base/reader/read_fmi.dart';
//part 'package:dcm_convert/src/binary/base/reader/reader_info.dart';
part 'package:dcm_convert/src/binary/base/reader/read_ivr.dart';
//part 'package:dcm_convert/src/binary/base/reader/read_pixels.dart';
part 'package:dcm_convert/src/binary/base/reader/read_root.dart';
part 'package:dcm_convert/src/binary/base/reader/read_common.dart';
//part 'package:dcm_convert/src/binary/base/reader/read_utils.dart';

// Reader axioms
// 1. The read index (rIndex) should always be at the last place read,
//    and the end of the value field should be calculated by subtracting
//    the length of the delimiter (and delimiter length), which is 8 bytes.
//
// 2. For non-sequence Elements with undefined length (kUndefinedLength)
//    the Value Field Length (vfLength) of a non-Sequence Element.
//    The read index rIndex is left at the end of the Element Delimiter.
//
// 3. [_finishReadElement] is only called from [readEvrElement] and
//    [readIvrElement].

//TODO: redoc to reflect current state of code

typedef Element ElementMaker(EBytes eb, int vrIndex);
typedef PixelData PixelDataMaker(EBytes eb, int vrIndex,
    [TransferSyntax ts, VFFragments fragments]);
typedef SQ SequenceMaker(EBytes eb, Dataset _cds, List<Item> items);
typedef Item ItemMaker(Dataset _cds);

ElementMaker elementMaker;
PixelDataMaker pixelDataMaker;
SequenceMaker sequenceMaker;
ItemMaker itemMaker;

// Local variables used by DcmReader package
ByteReader _rb;
RootDataset _rds;
Dataset _cds;

DecodingParameters _dParams;

bool _isEvr;

ParseInfo _pInfo;
int _elementCount = 0;
final bool _statisticsEnabled = true;
final bool _elementOffsetsEnabled = true;
ElementOffsets _inputOffsets;

//final List<String> _exceptions = <String>[];

bool _beyondPixelData;
Tag tag;

/// Returns the [ByteData] that was actually read, i.e. from 0 to
/// end of last [Element] read.
ByteData bdRead;

/// A [Converter] for [Uint8List]s containing a [Dataset] encoded in the
/// application/dicom media type.
///
/// _Notes_:
/// 1. Reads and returns the Value Fields as they are in the data.
///  For example DcmReader does not trim whitespace from strings.
///  This is so they can be written out byte for byte as they were
///  read. and a byte-wise comparator will find them to be equal.
/// 2. All String manipulation should be handled by the containing
///  [Element] itself.
/// 3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
abstract class DcmReader extends DcmReaderInterface {
  /// The source of the [Uint8List] being read.
  final String path;

  /// The [ByteData] being read.
  final int bdLength;
  @override
  final ByteReader rb;
  @override
  final RootDataset rds;
  final bool async;
  final bool fast;
  final bool fmiOnly;

  /// If true the [ByteData] buffer ([rb] will be reused.
  final bool reUseBD;
  final bool showStats;
  final DecodingParameters dParams;
  @override
  Dataset cds;
  ParseInfo pInfo;

  /// Creates a new [DcmReader]  where [rb].rIndex = 0.
  DcmReader(ByteData bd, this.rds,
      {this.path = '',
      //TODO: make async work and be the default
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
      this.reUseBD = true,
      this.showStats = false,
      this.dParams = DecodingParameters.kNoChange})
      : bdLength = bd.lengthInBytes,
        rb = new ByteReader(bd),
        cds = rds,
        pInfo = new ParseInfo(rds) {
    //  log.debug('ByteData length: ${rb.lengthInBytes}');
    if (bdLength <= shortFileThreshold) {
      final s = 'Short file error: length(${rb.lengthInBytes}) $path';
      rb.warn('$s ${rb.rrr}');
      if (throwOnError) throw new ShortFileError('Length($rb.lengthInBytes) $path');
    }
    _rb = rb;
    _rds = rds;
    _dParams = dParams;
    _pInfo = pInfo
      ..shortFileThreshold = shortFileThreshold
      ..fileLengthInBytes = bd.lengthInBytes;
    if (_elementOffsetsEnabled) _inputOffsets = new ElementOffsets();
  }

  bool get isEvr => rds.isEvr;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.buffer.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  @override
  ElementOffsets get offsets => _inputOffsets;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool hasRemaining(int n) => _rb.hasRemaining(n);

  RootDataset read() {
    cds = rds;
    _read(rds, path, dParams);
    rds.parseInfo = _pInfo;
    if (showStats) print(pInfo);
    return rds;
  }

  RootDataset readFmi() {
    cds = rds;
    _readFmi(rds, path, dParams);
    rds.parseInfo = _pInfo;
    if (showStats) print(pInfo);
    return (rds.hasFmi) ? rds : null;
  }

  Element readElement({bool isEVR = true}) =>
      (isEVR) ? _readEvrElement() : _readIvrElement();

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';

/* TODO: move to ParseInfo
  String get stats => '''${_rb.rmm}
  Statistics
                  isEvr: $isEvr
        Bytes remaining: ${_rb.remaining}
        
              nDatasets: ${pInfo.nDatasets}
       nDefinedDatasets: ${pInfo.nDefinedDatasets}
      nUnefinedDatasets: ${pInfo.nUndefinedDatasets}
             nItemsRead: ${pInfo.nItems}     
      nDefinedItemsRead: ${pInfo.nDefinedDatasets}
    nUndefinedItemsRead: ${pInfo.nUndefinedDatasets}
                                
            rootDSTotal: ${rds.total}
          nElementsRead: ${pInfo.nElements}
          
             nSequences: ${pInfo.nSequences}
      nDefinedSequences: ${pInfo.nDefinedSequences}
    nUndefinedSequences: ${pInfo.nUndefinedSequences}
      nPrivateSequences: ${pInfo.nPrivateSequences}
       lastSequenceRead: ${pInfo.lastSequenceRead}
       endOfLastSequence: ${pInfo.endOfLastSequence}

        lastElementRead: ${pInfo.lastElementRead}
       endOfLastElement: ${dcm(pInfo.endOfLastElement)}
       
        bdLengthInBytes: ${rb.lengthInBytes}
        dsLengthInBytes: ${rds.lengthInBytes}
              remaining: ${rb.remaining}

            rootDSTotal: ${rds.total}
         rootDSTopLevel: ${rds.length}
        rootDSSequences: ${rds.elements.sequences.length}
        rootDSDupLength: ${rds.elements.duplicates.length}
        currentDSLength: ${rds.elements.length}
     currentDSDupLength: ${cds.elements.duplicates.length}
     currentDSSequences: ${cds.elements.sequences}
                totalDS: ${rds.total + rds.dupTotal}''';
*/

}
