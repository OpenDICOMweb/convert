// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:core/server.dart';
import 'package:convert/convert.dart';

//import 'package:convert/data/test_files.dart';

const String x1evr = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String x2evr = 'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';
const String x3evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x4ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x5ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x6evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x7evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x8ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/163652D2';
const String x9evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/4C810C83/FE74DC49/FF6BE1DE';
const String x10evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x11ivr = 'C:/acr/odw/test_data/6684/2017/5/13/9/9F3A1E64/4B4AEBC7/F57DF821';

void main() {
  Server.initialize(name: 'read_write_file', level: Level.debug);

  // *** Modify the [path0] value to read/write a different file
  const fPath = x11ivr;

  byteReadWriteFileChecked(fPath, fileNumber: 1, width: 5, doLogging: true, fast: true);
}
