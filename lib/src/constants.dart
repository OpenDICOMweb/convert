// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.


const kKB = 1024;
const kMB = 1024 * 1024;
const kGB = 1024 * 1024 * 1024;

/// DICOM constants
///
/// This is the value of a DICOM Undefined Length from a 32-bit Value Field Length.
const kUndefinedLength = 0xFFFFFFFF;

/// The maximum Value Field length of Value Representations with "short" (16-bit) lengths.
const kMaxShortLength = 0xFFFF;

/// The maximum Value Field length of Value Representations with "long" (32-bit) lengths.
/// These depend on the [elementSizeInBytes] of the values in the Value Field.
const kMaxInt8LongLength = kUndefinedLength- 1;
const kMaxUint8LongLength = kUndefinedLength - 1;
const kMaxInt16LongLength = kUndefinedLength - 2;
const kMaxUint16LongLength = kUndefinedLength - 2;
const kMaxInt32LongLength = kUndefinedLength - 4;
const kMaxUint32LongLength = kUndefinedLength - 4;
const kMaxInt64LongLength = kUndefinedLength - 8;
const kMaxUint64LongLength = kUndefinedLength - 8;
const kMaxFloat32LongLength = kUndefinedLength - 4;
const kMaxFloat64LongLength = kUndefinedLength - 8;


