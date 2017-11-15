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

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/reader_interface_old.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';



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

typedef Element EReader();

/*
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
int _elementCount;
final bool _statisticsEnabled = true;
bool _elementOffsetsEnabled;
ElementOffsets _inputOffsets;

//final List<String> _exceptions = <String>[];

bool _beyondPixelData;
bool _checkCode = false;
Tag tag;
*/

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
abstract class DebugReader extends DcmReader {
	/// The source of the [Uint8List] being read.
//	final String path;

	/// The [ByteData] being read.
//	final int bdLength;
//	@override
//	final ByteReader rb;
//	@override
//	final RootDataset rds;

	/// If true the [ByteData] buffer ([rb] will be reused.
//	final bool reUseBD;
	final bool showStats;
//	final Dec dParams;
	final bool elementOffsetsEnabled;
	final ElementOffsets inputOffsets;
	@override
//	Dataset cds;
	ParseInfo pInfo;

	/// Creates a new [DcmReader]  where [rb].rIndex = 0.
	DebugReader(ByteData bd, RootDataset rds,
	          {String path = '',
		          this.showStats = false,
		          DecodingParameters dParams,
		          this.elementOffsetsEnabled = true})
			: inputOffsets = (elementOffsetsEnabled) ? new ElementOffsets() : null,
				pInfo = new ParseInfo(rds),
			  super(bd, rds, path: path, DecodingParameters dParams) {
		pInfo..path = path
			..fileLengthInBytes = bd.lengthInBytes
			..shortFileThreshold = shortFileThreshold
			..wasShortFile = (bd.lengthInBytes <= shortFileThreshold);
		rds.parseInfo = pInfo;
		if (elementOffsetsEnabled && inputOffsets != null) {
			_elementOffsetsEnabled = elementOffsetsEnabled;
			_inputOffsets = inputOffsets;
		}
	}

//	bool get isEvr => rds.isEvr;

	bool get isReadable => rb.isReadable;

	Uint8List get rootBytes => rb.buffer.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

	@override
	ElementOffsets get offsets => _inputOffsets;

	String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

	bool hasRemaining(int n) => _rb.hasRemaining(n);


	RootDataset read() {
		if (_pInfo.wasShortFile) return _shortFileError();
		return _read(rds, path, dParams);
	}

	RootDataset readFmi(RootDataset rds) {
		super.readFmi(rds, path, dParams);
	}




	Element readElement(Dataset ds) =>
			(rds.isEVR) ? _readEvrElement() : _readIvrElement(Dataset ds);

	bool readFmi(RootDataset rds. ParseInfo pInfo) {

	log.debug('${_rb.rbb} readFmi($_cds)');
	assert(_cds == rds);
	pInfo.hadPrefix = _readPrefix(path, dParams.checkPreambleAllZeros);
	if (!pInfo.hadPrefix && !dParams.allowMissingPrefix) {
	return false;
	}
	//  log.debug1('$rmm readFMI: prefix($_hadPrefix) $rds');

	while (_rb.isReadable) {
	final code = _rb.peekCode;
	if (code >= 0x00030000) break;
	super.readEvrElement(Dataset ds);
	}

	_isEvr = rds.isEvr;
	pInfo.hadFmi = _rds.hasFmi;

	if (!_rb.hasRemaining(shortFileThreshold - _rb.rIndex)) {
	pInfo.hadParsingErrors = true;
	throw new EndOfDataError(
	'_readFmi', 'index: ${_rb.rIndex} bdLength: ${_rb.lengthInBytes}');
	}

	final ts = rds.transferSyntax;
	pInfo.ts = ts;
	log.debug('TS: $ts');
	if (!system.isSupportedTransferSyntax(ts.asString)) {
	pInfo.hadParsingErrors = true;
	invalidTransferSyntax(ts);
	return false;
	}

	if (dParams.targetTS != null && ts != dParams.targetTS)
	invalidTransferSyntax(ts, dParams.targetTS);
	log.debug('${_rb.ree} readFMI ${rds.total} Elements read');
	return true;
	}

	/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
	/// Returns true if a valid Preamble and Prefix where read.
	bool _readPrefix(String path, bool checkPreamble, pInfo) {
		// try {
		final sb = new StringBuffer();
		if (_rb.rIndex != 0)
			sb.writeln('Attempt to read DICOM Prefix at ByteData[$_rb.rIndex]');
		if (_pInfo.hadPrefix != null)
			sb.writeln('Attempt to re-read DICOM Preamble and Prefix.');
		if (_rb.lengthInBytes <= 132) sb.writeln('ByteData length(${_rb.lengthInBytes}) < 132');
		if (sb.isNotEmpty) {
			_rb.error(sb.toString());
			return false;
		}
		if (checkPreamble) {
			_pInfo.preambleAllZeros = true;
			for (var i = 0; i < 128; i++)
				if (_rb.getUint8(i) != 0) {
					_pInfo.preambleAllZeros = false;
					_pInfo.preamble = _rb.uint8View(0, 128);
				}
		}
		return isDcmPrefixPresent();
	}
	@override
	String toString() => '$runtimeType: rds: $rds, cds: $cds';

	Null _shortFileError() {
		final s = 'Short file error: length(${rb.lengthInBytes}) $path';
		rb.warn('$s ${rb.rrr}');
		if (throwOnError) throw new ShortFileError('Length($rb.lengthInBytes) $path');
		return null;
	}
}
