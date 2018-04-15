//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

//Urgent: finish
///
class ReaderParameters {
  /// If true duplicate Elements are allowed; if false either an
  /// [Error] will be thrown (if [throwOnError] is true; otherwise, the
  /// the Element with the more precise VR will be stored and the other
  /// discarded.
  final bool allowDuplicates;

  /// If true any duplicate characters will be removed.
  final bool removeDuplicates;

  /// If true the Reader will de-identify the Dataset before returning it.
  final bool deIdentify;

  /// If true no warning or errors will be generated for
  /// bad padding characters.
  final bool allowBadPaddingChars;

  final bool checkIssues;
  final bool checkIssuesWhileDecoding;
  final bool checkIssuesAfterDecoding;
  final bool checkIssuesOnAccess;
  final bool checkIssuesOnCreation;
  final bool allowNonZeroDelimiterLengths;
  final bool throwOnError;
  final int shortFileThreshold;

  const ReaderParameters({
    this.deIdentify,
    this.allowDuplicates,
    this.removeDuplicates,
    this.allowBadPaddingChars,
    this.checkIssues,
    this.checkIssuesWhileDecoding,
    this.checkIssuesAfterDecoding,
    this.checkIssuesOnAccess,
    this.checkIssuesOnCreation,
    this.allowNonZeroDelimiterLengths,
    this.throwOnError,
    this.shortFileThreshold
});

  static const ReaderParameters normal = const ReaderParameters(
    deIdentify: false,
    allowDuplicates: true,
      removeDuplicates: false,
    allowBadPaddingChars: true,
    checkIssues: true,
    checkIssuesWhileDecoding: false,
    checkIssuesAfterDecoding: true,
    checkIssuesOnAccess: false,
    checkIssuesOnCreation: true,
    allowNonZeroDelimiterLengths: true,
    throwOnError: false,
      shortFileThreshold: 1024
  );
}
