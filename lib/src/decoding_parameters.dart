// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:dictionary/dictionary.dart';

//Urgent: Test
class DecodingParameters {
  /// if [true] [Dataset]s will be allowed to be encoded in IVRLE.
  /// The default is [false].
  final bool allowImplicitLittleEndian;

  /// Encodes the Root [Dataset] even if it does not have any FMI.
  final bool allowMissingFMI;

  /// If [true] [Element]s will be checked for valid VR by looking up Tag.
  final bool doCheckVR;

  /// If [true], ODW FMI (with clean preamble) will be added or replaced,
  /// undefined lengths will be removed, if RootDS is in Implicit VR it
  /// will be converted to Explicit VR, all fragments will be removed.
  final bool doConvertToNormalForm;

  /// If [true], a DICOM File Prefix (PS3.10) will be written, and
  /// DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when the [Dataset] was decoded (parsed).
 final bool doAddMissingFMI;

  /// If [true] write ODW FMI into encoded output.
  final bool doUpdateFMI;

  /// If the Root Dataset had a non-zero preamble, replace it with all zeros.
  final bool doCleanPreamble;

  /// Replace any undefined length [Element]s with defined length, except
  /// for Encapsulated [kPixelData].
  final bool doConvertUndefinedLengths;

  /// Remove fragments from encapsulated [kPixelData] frames.
  final bool doRemoveFragments;

  /// Replace any non-zero end of Value Field delimiter lengths with zero.
  final bool doRemoveNoZeroDelimiterLengths;

  /// Correct any padding error in value fields being output.
  final bool doFixPaddingErrors;

  /// Separates encoded output into Metadata and Bulkdata.
  final bool doSeparateBulkdata;

  /// The number of bytes in a value field at which point it is converted
  /// to [bulkdata].
  final int bulkdataThreshold;

  const DecodingParameters({
    this.allowImplicitLittleEndian = true,
    this.allowMissingFMI = true,
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

  static const kNoChange = const DecodingParameters();

  static const kCanonical = const DecodingParameters(
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

  static const kCanonicalWithBulkdata = const DecodingParameters(
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