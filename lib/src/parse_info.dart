//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

class ParseInfo {
  /// The path of the Object that was parsed, if any.
  String path = '';

  /// The length of the file in bytes. This should be 132 + dsLengthInBytes.
  int fileLengthInBytes = -1;

  /// The length of the encoded Dataset in bytes.
  int dsLengthInBytes = -1;

  /// The number of bytes below which the Object is considered to be short.
  int shortFileThreshold = -1;

  /// The file had fewer than [shortFileThreshold] bytes.
  bool wasShortFile = false;

  /// The bytes contained in the DICOM _preamble_.
  Uint8List preamble = new Uint8List(0);

  /// if _null_ the preamble was not tested for all zeros. if _true_ all
  /// bytes in the preamble were zeros.
  bool preambleAllZeros = false;

  /// _true_ if the Object has a 128 byte preamble and a 'DICM' prefix.
  bool hadPrefix;
  bool hadFmi = false;
  TransferSyntax ts;

  /// _true_ if encoded as EVR.
  bool isEVR;

  /// There where errors that occurred while parsing the file.
  bool hadParsingErrors = false;

  /// Where Group Length Elements (gggg,0000) present in the Dataset.
  bool hadGroupLengths = false;

  /// The Object had Sequence or Item delimiters that
  /// had length fields that were not zero.
  int nonZeroDelimiterLengths = 0;

  /// The number of Value Fields that had an odd length value.
  int oddLengthValueFields = 0;

  /// The total number of RootDatasets read or written.
  /// This is currently always 1.
  int nRootDatasets = 0;

  /// The total number of Items read or written.
  int nItems = 0;

  /// The total number of Datasets with _defined length_ read or written.
  int nDefinedLengthDatasets = 0;

  /// The total number of Datasets with _undefined length_ read or written.
  int nUndefinedLengthDatasets = 0;

  /// The total number of Sequences read or written.
  int nSequences = 0;

  /// The total number of Sequences with _defined length_ read or written.
  int nDefinedLengthSequences = 0;

  /// The total number of Sequences with _undefined length_ read or written.
  int nUndefinedLengthSequences = 0;

  int nEmptyUNSequences = 0;
  int nNonEmptyUNSequences = 0;

  /// The total number of Private Sequences read or written.
  int nPrivateSequences = 0;
  SQ lastSequence;

  /// The index in the ByteData of the end of the last Sequence read or written.
  int endOfLastSequence = -1;

  /// The total number of Elements read or written.
  int nElements = 0;

  /// The total number of EVR Short Elements
  /// (16-bit length field) read or written.
  ///
  /// _Note_: Only relevant for EVR.
  int nShortElements = 0;

  /// The total number of EVR/IVR Long Elements
  /// (32-bit length field) read or written.
  int nLongElements = 0;

  /// The total number of Elements,
  /// of potentially _undefined length_, read or written.
  int nMaybeUndefinedElements = 0;

  /// The total number of Elements with _defined length_ read or written.
  int nLongDefinedLengthElements = 0;

  /// The total number of Elements with _defined length_ read or written.
  int nUndefinedLengthElements = 0;

  /// The total number of Private Elements read or written.
  int nPrivateElements = 0;

  /// The total number of Duplicate Elements read or written.
  int nDuplicateElements = 0;

  /// The last Element read or written.
  Element lastElement;

  /// The index in the ByteData of the end of the last Element read or written.
  int endOfLastElement = -1;

  /// The last Element read or written.
  int lastPrivateElement;

  /// The VR of the Pixel Data Element, if any.
  int pixelDataVRIndex;

  /// The index in the ByteData of the first byte of Pixel Data.
  int pixelDataStart = -1;

  /// The index in the ByteData of the last byte of Pixel Data.
  int pixelDataEnd = -1;

  /// The _lengthInBytes_ of the Pixel Data.
  int pixelDataLength = -1;

  bool pixelDataHadUndefinedLength = false;

  /// _true_ if the Pixel Data is _encapsulated_.
  bool pixelDataHadFragments = false;

  /// The index in the ByteData of the last byte read or written.
  int lastIndex = -1;

  /// There were bytes after the last valid element.
  int nTrailingBytes = 0;

  /// There were zero at the end of the Object that was parsed.
  bool hadTrailingZeros = false;

  List exceptions = <Object>[];

  final RootDataset rds;

  ParseInfo([this.rds]);

  ParseInfo.options(
      this.rds,
      // Reader info
      this.nElements,
      this.nSequences,
      this.nPrivateElements,
      this.nPrivateSequences,
      {this.isEVR,
      this.path = '',
      this.hadFmi = false,
      this.preamble,
      this.preambleAllZeros,
      this.hadPrefix = false,
      this.hadGroupLengths = false,
      this.hadParsingErrors = false,
      this.nonZeroDelimiterLengths = 0,
      this.oddLengthValueFields = 0,
      this.ts,
      this.pixelDataVRIndex,
      this.pixelDataStart,
      this.pixelDataLength,
      this.lastElement,
      this.endOfLastElement,
      this.dsLengthInBytes,
      this.fileLengthInBytes,
      this.shortFileThreshold,
      this.wasShortFile = false,
      this.nTrailingBytes = 0,
      this.hadTrailingZeros = false,
      this.exceptions});

  @override
  bool operator ==(Object other) => (other is ParseInfo &&
          isEVR == other.isEVR &&
          nElements == other.nElements &&
          nSequences == other.nSequences &&
          nPrivateElements == other.nPrivateElements &&
          nPrivateSequences == other.nPrivateSequences &&
          // Path is not included so we can compare results from different files
          //  path == other.path &&
          hadFmi == other.hadFmi &&
          //TODO: preamble must be compared byte for byte
          //     preamble == other.preamble &&
          preambleAllZeros == other.preambleAllZeros &&
          hadPrefix == other.hadPrefix &&
          hadGroupLengths == other.hadGroupLengths &&
          hadParsingErrors == other.hadParsingErrors &&
          nonZeroDelimiterLengths == other.nonZeroDelimiterLengths &&
          oddLengthValueFields == other.oddLengthValueFields &&
          ts == other.ts &&
          pixelDataVRIndex == other.pixelDataVRIndex &&
          pixelDataStart == other.pixelDataStart &&
          pixelDataEnd == other.pixelDataEnd &&
          lastElement == other.lastElement &&
          endOfLastElement == other.endOfLastElement &&
          dsLengthInBytes == other.dsLengthInBytes &&
          fileLengthInBytes == other.fileLengthInBytes &&
          // TODO: decide if these should be included or not
          // shortFileThreshold == other.shortFileThreshold &&
          // hadTrailingBytes == other.hadTrailingBytes &&
          // hadTrailingZeros == other.hadTrailingZeros) &&
          // exceptions == other.exceptions
          wasShortFile == other.wasShortFile)
      ? true
      : false;

  //TODO: implement hashCode if we keep equals
  @override
  int get hashCode => global.hasher(this);

  int get nDatasets => nItems + 1;
  int get nDefinedItems => nDefinedLengthDatasets - 1;

  int get rootDSTotal => rds.total;
  bool get hadErrors => hadParsingErrors;

  void addItem(SQ sq, Item item) {

  }
  void addElement(Element e) {

  }
  void addSequence(SQ sq) {

  }
  //TODO: this could be (exceptions.length != 0)
  bool get hadWarnings =>
      wasShortFile ||
      !hadFmi ||
      hadParsingErrors ||
      nTrailingBytes != 0 ||
      nonZeroDelimiterLengths != 0;

/*
  /// Returns a [String] containing all values,
  /// except preamble if it was all zeros.
  String info(RootDataset rds) {
    final preambleMsg =
        (preambleAllZeros) ? '' : '\n                  Preamble: $preamble';
    final tsMsg = (ts == null) ? 'Not present' : '$ts';
    return '''$runtimeType: "$path"
  ParseInfo:
                     isEVR: ${rds.isEvr}
                 nDatasets: $nDatasets
          nDefinedDatasets: $nDefinedLengthDatasets
         nUnefinedDatasets: $nUndefinedLengthDatasets

                nItemsRead: $nItems
         nDefinedItemsRead: $nDefinedItems
       nUndefinedItemsRead: $nUndefinedLengthDatasets

${rds.info}

           rootDSSequences: ${rds.elements.sequences.length}
                 Sequences: $nSequences
          DefinedSequences: $nDefinedLengthSequences
        UndefinedSequences: $nUndefinedLengthSequences
         Private Sequences: $nPrivateSequences

                 nElements: $nElements
            nShortElements: $nShortElements
             nLongElements: $nLongElements
   nMaybeUndefinedElements: $nMaybeUndefinedElements
          nDefinedElements: $nDefinedLengthElements
        nUndefinedElements: $nUndefinedLengthElements
          Private Elements: $nPrivateElements
        nDuplicateElements: $nDuplicateElements
         Last Element Read: $lastElementRead
       End Of Last Element: $endOfLastElement

                   Had Fmi: $hadFmi
                Had Prefix: $hadPrefix
        Preamble Was Zeros: $preambleAllZeros
         Had Group Lengths: $hadGroupLengths
        Had Parsing Errors: $hadParsingErrors
Non-Zero Delimiter Lengths: $nonZeroDelimiterLengths
   Odd Length Value Fields: $oddLengthValueFields
              IsExplicitVR: ${rds.isEvr}

           Transfer Syntax: $tsMsg
             Pixel Data VR: $pixelDataVR
          Pixel Data Start: $pixelDataStart
            Pixel Data End: $pixelDataEnd
         Pixel Data Length: $pixelDataLength

        DS Length In Bytes: $dsLengthInBytes
      File Length In Bytes: $fileLengthInBytes
      Short File Threshold: $shortFileThreshold
            Was Short File: $wasShortFile
        Had Trailing Bytes: $nTrailingBytes
        Had Trailing Zeros: $hadTrailingZeros
                Exceptions: ${exceptions.join('\n')}
''';
  }
*/

  String get shortFileMsg => '''
		          *** Was short file: $wasShortFile had $fileLengthInBytes bytes,'
				            ' threshold is $shortFileThreshold\n
''';

  String get preambleMsg => '''
  		  **** Preamble was not zeros: $preamble
  ''';

  String get hadGroupLengthsMsg => '''
  ''';

  String get pixelDataProblems {
    final sb = new StringBuffer();
    final length = pixelDataEnd - pixelDataStart;
    if (length != pixelDataLength)
      sb.writeln('*** Pixel Data stats inconsistent');
    if (pixelDataVRIndex != kOBIndex ||
        pixelDataVRIndex != kOWIndex ||
        pixelDataVRIndex != kUNIndex)
      sb.writeln('*** Invalid Pixel Data VR: $pixelDataVRIndex');
    return sb.toString();
  }

  String get pixelDataStats => '''
  Pixel Data:
                     VR: $pixelDataVRIndex
                  start: $pixelDataStart
                    end: $pixelDataEnd
                 length: $pixelDataLength
   had undefined length: $pixelDataHadUndefinedLength
          had fragments: $pixelDataHadFragments
$pixelDataProblems  
  ''';
  String get trailingMsg => '''\n
    Had Trailing Bytes: $nTrailingBytes
    Had Trailing Zeros: $hadTrailingZeros     
  ''';

  String get tsMsg => (ts == null) ? '*** Not present' : '$ts';

  String get errorMsg {
    final sb = new StringBuffer();
    if (wasShortFile) sb.write(shortFileMsg);

    if (!hadPrefix) sb.write('*** No DICOM Preable or Prefix present');
    if (hadPrefix && !preambleAllZeros) sb.write(preambleMsg);
    if (!hadFmi) sb.write('*** FMI not present');

    if (hadParsingErrors)
      sb.write('          *** Had Parsing Errors: $hadParsingErrors\n');

    if (nonZeroDelimiterLengths > 0)
      sb.write('  Had Non-Zero Delimiter Lengths: $nonZeroDelimiterLengths\n');
    return sb.toString();
  }

  // Should only print out values that are important or not normal.
  @override
  String toString() => '''$runtimeType''';
/*$fileMsg
$summary
$errorMsg
  ''';*/

  String get fileLengthsMsg =>
      (nTrailingBytes + rds.lengthInBytes != fileLengthInBytes)
      ? '''
*** Inconsistent Lengths Error:
		  File length: $fileLengthInBytes' is not equal to
	    RDS length(${rds.lengthInBytes}) + trailing bytes($nTrailingBytes)
	    '''
      : 'File and Root Dataset have unequal lengths';

  String get fileMsg => '''
	  	  $path
	                   File length: $fileLengthInBytes
	                Dataset length: ${rds.lengthInBytes}
                    IsExplicitVR: $isEVR
                 Transfer Syntax: $tsMsg
                 $fileLengthsMsg
	  ''';
  int get totalElements =>
      nShortElements + nLongDefinedLengthElements + nUndefinedLengthElements;

  String summary(RootDataset rds) => '''$runtimeType:    
              Elements read: $nElements
short + defined + undefined: $totalElements
                Elements DS: ${rds.total}
            Duplicates read: $nDuplicateElements
              Duplicates DS: ${rds.dupTotal}

            Sequences read: $nSequences
              Sequences DS: ${rds.sequences.length}
                  Datasets: $nDatasets
         ''';

  String stats(RootDataset rds) => '''$runtimeType:    
             Elements read: $nElements
               Elements DS: ${rds.total}
           Duplicates read: $nDuplicateElements
             Duplicates DS: ${rds.dupTotal}

                 nDatasets: $nDatasets
          nDefinedDatasets: $nDefinedLengthDatasets
         nUnefinedDatasets: $nUndefinedLengthDatasets
         
        root datasets read: $nRootDatasets
                items read: $nItems
                  items DS: \${rds.nItems}
   Defined Length Datasets: $nDefinedLengthDatasets
  Unefined Length Datasets: $nUndefinedLengthDatasets

            Sequences read: $nSequences
              Sequences DS: ${rds.sequences.length}
          DefinedSequences: $nDefinedLengthSequences
        UndefinedSequences: $nUndefinedLengthSequences 
         Private Sequences: $nPrivateSequences 
      End of last Sequence: $endOfLastSequence                             

              Elements read: $nElements
short + defined + undefined: $totalElements
             nShortElements: $nShortElements
           nDefinedElements: $nLongDefinedLengthElements
         nUndefinedElements: $nUndefinedLengthElements
         
              nLongElements: $nLongElements
    nMaybeUndefinedElements: $nMaybeUndefinedElements  
           Private Elements: $nPrivateElements
         Duplicate Elements: $nDuplicateElements
               Last Element: $lastElement
        End Of Last Element: $endOfLastElement
    
  ''';

  String get dsCharacteristics => '''
            Preamble all zeros: $preambleAllZeros
                    Had Prefix: $hadPrefix
                       Had Fmi: $hadFmi
            Had Parsing Errors: $hadParsingErrors
             Had Group Lengths: $hadGroupLengths
       Odd length value fields: $oddLengthValueFields 
Had non-zero delimiter lengths: $nonZeroDelimiterLengths
  ''';

  static final ParseInfo kEmpty = new ParseInfo(null);
}

/*
  String get json => '''{
  '@type': '$runtimeType',
  'path': '$path',
  'isEVR': '$isEVR',
  'sequenceCount': $nSequences,
  'privateElementCount': $nPrivateElements,
  'privateSequenceCount': $nPrivateSequences,
  'hadFmi': $hadFmi,
  'preamble': $preamble,
  'preambleWasZeros': $preambleAllZeros,
  'hadPrefix': $hadPrefix,
  'hadGroupLengths': $hadGroupLengths,
  'hadParsingErrors': $hadParsingErrors,
  'nonZeroDelimiterLengths': $nonZeroDelimiterLengths,
  'oddLengthValueFields': $oddLengthValueFields,
  'transferSyntax': '${ts.asString}',
  'pixelDataVR': $pixelDataVR,
  'pixelDataStart': $pixelDataStart,
  'pixelDataEnd': $pixelDataEnd,
  'endOfLastElement': $endOfLastElement,
  'dsLengthInBytes': $dsLengthInBytes,
  'fileLengthInBytes': $fileLengthInBytes,
  'shortFileThreshold': $shortFileThreshold,
  'wasShortFile': $wasShortFile,
  'HadTrailingBytes': $hadTrailingBytes,
  'HadTrailingZeros': $hadTrailingZeros,
  'Exceptions': $exceptions
  }
  ''';
*/
