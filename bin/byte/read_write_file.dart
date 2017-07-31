// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';

//TODO: fix logger so next two import and the DcmReader lines are not necessary
import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';
import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  //TODO: fix logger so next two lines are unnecessary
  DcmReader.log.watermark = Severity.debug2;
  DcmWriter.log.watermark = Severity.debug2;

  // *** Modify the [path0] value to read/write a different file
 // var path = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';
 // var path = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
 // var path = 'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264'
 // '.20120723195848/2.16.840.1.114255.1870665029.949635505.39523.169/2.16.840'
 // '.1.114255.1870665029.949635505.10220.175.dcm';
  var path = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';
  byteReadWriteFileChecked(testPaths[0]);
}
