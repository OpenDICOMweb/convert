// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:core/core.dart';

class DecodingParameters {
	final int shortFileThreshold;
  /// if true Datasets will be allowed to be encoded in IVRLE.
  /// The default is false.
  final bool allowImplicitLittleEndian;

  /// If true and Preamble is not all zeros, abort reading.
  final bool checkPreambleAllZeros;

  /// If true and Preamble and Prefix are not present, abort reading.
  final bool allowMissingPrefix;

  /// If true and File Meta Information (FMI) is not present, abort reading.
  final bool allowMissingFMI;

  /// If true, then duplicate Elements will be stored.
  final bool allowDuplicates;

  /// Only read the file if it has the same [TransferSyntax] as [targetTS].
  final TransferSyntax targetTS;

  /// If true Elements with VR.kUN will be check to see if they
  /// are Sequences.
  final bool checkForUNSequence;

  /// If true elements with VR.kUN or with _invalid_ VRs will be converted
  /// to correct VR if known.
  final bool doCorrectVR;

  /// If true Elements will be checked for valid VR by looking up Tag.
  final bool doCheckVR;

  /// If true, ODW FMI (with clean preamble) will be added or replaced,
  /// undefined lengths will be removed, if RootDS is in Implicit VR it
  /// will be converted to Explicit VR, all fragments will be removed.
  final bool doConvertToNormalForm;

  /// If true, a DICOM File Prefix (PS3.10) will be written, and
  /// DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when the Dataset was decoded (parsed).
  final bool doAddMissingFMI;

  /// If true write ODW FMI into encoded output.
  final bool doUpdateFMI;

  /// If the Root Dataset had a non-zero preamble, replace it with all zeros.
  final bool doCleanPreamble;

  /// Replace any undefined length Elements with defined length, except
  /// for Encapsulated kPixelData.
  final bool doConvertUndefinedLengths;

  /// Remove fragments from encapsulated kPixelData frames.
  final bool doRemoveFragments;

  /// Replace any non-zero end of Value Field delimiter lengths with zero.
  final bool doRemoveNoZeroDelimiterLengths;

  /// Correct any padding error in value fields being output.
  final bool doFixPaddingErrors;

  /// Separates encoded output into Metadata and Bulkdata.
  final bool doSeparateBulkdata;

  /// The number of bytes in a value field at which point it is converted
  /// to bulkdata.
  final int bulkdataThreshold;

  const DecodingParameters({
	  this.shortFileThreshold = 131,
    this.allowImplicitLittleEndian = true,
    this.targetTS,
	  this.checkPreambleAllZeros = true,
    this.allowMissingPrefix = false,
    this.allowMissingFMI = true,
    this.allowDuplicates = true,
    this.checkForUNSequence = true,
    this.doCorrectVR = false,
    this.doCheckVR = true,
    this.doConvertToNormalForm = false,
    this.doSeparateBulkdata = false,
    this.bulkdataThreshold = -1,
    this.doAddMissingFMI = false,
    this.doUpdateFMI = false,
    this.doCleanPreamble = false,
    this.doConvertUndefinedLengths = false,
    this.doRemoveFragments = false,
    this.doRemoveNoZeroDelimiterLengths = false,
    this.doFixPaddingErrors = false,
  });

  static const DecodingParameters kNoChange = const DecodingParameters();

  static const DecodingParameters kCanonical = const DecodingParameters(
      allowImplicitLittleEndian: false,
      allowMissingFMI: false,
      doCheckVR: true,
      doSeparateBulkdata: false,
      bulkdataThreshold: -1,
      doConvertToNormalForm: true,
      doAddMissingFMI: true,
      doUpdateFMI: true,
      doCleanPreamble: true,
      doConvertUndefinedLengths: true,
      doRemoveFragments: true,
      doRemoveNoZeroDelimiterLengths: true,
      doFixPaddingErrors: true);

  static const DecodingParameters kCanonicalWithBulkdata = const DecodingParameters(
      allowImplicitLittleEndian: false,
      allowMissingFMI: false,
      doCheckVR: true,
      doSeparateBulkdata: true,
      bulkdataThreshold: 1024,
      doConvertToNormalForm: true,
      doAddMissingFMI: true,
      doUpdateFMI: true,
      doCleanPreamble: true,
      doConvertUndefinedLengths: true,
      doRemoveFragments: true,
      doRemoveNoZeroDelimiterLengths: true,
      doFixPaddingErrors: true);
}
