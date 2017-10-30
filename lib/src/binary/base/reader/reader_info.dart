// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;


//TODO: redoc to reflect current state of code


/*
  /// If [true] and Preamble and Prefix are not present, abort reading.
  final bool allowMissingPrefix;

  /// If [true] and File Meta Information (FMI) is not present, abort reading.
  final bool allowMissingFMI;

  /// If [true], then duplicate [Element]s will be stored.
  final bool allowDuplicates;

  /// Only read the file if it has the same [TransferSyntax] as [targetTS].
  final TransferSyntax targetTS;

  //Urgent: todo make this a parameter
  /// If [true] any EVR [Element]s will be checked for being Sequences.
  final bool checkForUNSequence;

  /// If [true] elements with VR.kUN will be converted to correct VR if known.
  final bool doConvertUndefinedVR;

  /// If [true] the [ByteData] buffer ([_rootBD] will be reused.
  final bool reUseBD;

  final DecodingParameters decoding;
*/

  // **** stats and debugging
  final bool statisticsEnabled = true;
  final bool elementOffsetsEnabled = true;
  final List<String> exceptions = <String>[];

  /// Returns the [ByteData] that was actually read, i.e. from 0 to
  /// end of last [Element] read.
  ByteData bdRead;
  // ParseInfo values
  int _nElementsRead = 0;
  int _nSequencesRead = 0;
  int _nItemsRead = 0;
  int _nDSequencesRead = 0;
  int _nUSequencesRead = 0;
  int _nPrivateElementsRead = 0;
  int _nPrivateSequencesRead = 0;

  bool _hadFmi = false;
  Uint8List _preamble;
  bool _preambleWasZeros;
  bool _hadPrefix;
  bool _hadGroupLengths = false;
  bool _hadParsingErrors = false;
  int _nonZeroDelimiterLengths = 0;
  int _nOddLengthValueFields = 0;

  TransferSyntax _tsUid;
  VR _pixelDataVR;
  int _pixelDataStart;
  int _pixelDataEnd;
  int _lastElementCode = 0;
  Element _lastTopLevelElementRead;
  Element _lastElementRead;
  int _endOfLastValueRead = 0;
  bool _beyondPixelData = false;
  bool _endOfDataError = false;

  /// The index where the last element in the [RootDataset] ended.
  int _dsLengthInBytes;

  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;

ParseInfo getParseInfo() => new ParseInfo(
		_nElementsRead,
		_nSequencesRead,
		_nPrivateElementsRead,
		_nPrivateSequencesRead,
		_rootDS.total,
		_rootDS.length,
		_rootDS.elements.duplicates.length,
		0,
		0,
		0,
		_path,
		_preamble,
		_nonZeroDelimiterLengths,
		_nOddLengthValueFields,
		_tsUid,
		_pixelDataVR,
		_pixelDataStart,
		_pixelDataEnd,
		_lastTopLevelElementRead,
		_lastElementCode,
		_endOfLastValueRead,
		_dsLengthInBytes,
		_rootBD.lengthInBytes,
		shortFileThreshold,
		exceptions,
		isEVR: _isEVR,
		wasShortFile: _wasShortFile,
		hadFmi: _hadFmi,
		hadPrefix: _hadPrefix,
		preambleWasZeros: _preambleWasZeros,
		hadParsingErrors: _hadParsingErrors,
		hadGroupLengths: _hadGroupLengths,
		hadTrailingBytes: _hadTrailingBytes,
		hadTrailingZeros: _hadTrailingZeros);


String get stats => '''$rmm Statistics
          nElementsRead: $_nElementsRead
         nSequencesRead: $_nSequencesRead
            nDSequences: $_nDSequencesRead
            nUSequences: $_nUSequencesRead
             nItemsRead: $_nItemsRead
   nPrivateElementsRead: $_nPrivateElementsRead
  nPrivateSequencesRead: $_nPrivateSequencesRead
lastTopLevelElementRead: $_lastTopLevelElementRead
        lastElementRead: $_lastElementRead
        lastElementCode: ${dcm(_lastElementCode)}
        bdLengthInBytes: ${_rootBD.lengthInBytes}
        dsLengthInBytes: $_dsLengthInBytes
         endOfDataError: $_endOfDataError
           bytesUnread: $_bytesUnread
            rootDSTotal: ${_rootDS.total}
         rootDSTopLevel ${_rootDS.length}
        rootDSSequences: ${_rootDS.elements.sequences}
        rootDSDupLength: ${_rootDS.elements.duplicates.length}
        currentDSLength: ${_rootDS.elements.length}
     currentDSDupLength: ${_currentDS.elements.duplicates.length}
     currentDSSequences: ${_currentDS.elements.sequences}
                totalDS: ${_rootDS.total + _rootDS.dupTotal}''';

ParseInfo _getParseInfo() => new ParseInfo(
		_nElementsRead,
		_nSequencesRead,
		_nPrivateElementsRead,
		_nPrivateSequencesRead,
		_rootDS.total,
		_rootDS.length,
		_rootDS.elements.duplicates.length,
		0,
		0,
		0,
		_path,
		_preamble,
		_nonZeroDelimiterLengths,
		_nOddLengthValueFields,
		_tsUid,
		_pixelDataVR,
		_pixelDataStart,
		_pixelDataEnd,
		_lastTopLevelElementRead,
		_lastElementCode,
		_endOfLastValueRead,
		_dsLengthInBytes,
		_rootBD.lengthInBytes,
		shortFileThreshold,
		exceptions,
		isEVR: _isEVR,
		wasShortFile: _wasShortFile,
		hadFmi: _hadFmi,
		hadPrefix: _hadPrefix,
		preambleWasZeros: _preambleWasZeros,
		hadParsingErrors: _hadParsingErrors,
		hadGroupLengths: _hadGroupLengths,
		hadTrailingBytes: _hadTrailingBytes,
		hadTrailingZeros: _hadTrailingZeros);


