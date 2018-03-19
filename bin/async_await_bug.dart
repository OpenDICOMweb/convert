
import 'dart:async';
import 'dart:io';

void main() {

  const path = 'foo';
  final String s = readFile(new File(path));
  print('s $s');


}

FutureOr<String> readFile(File file, {bool doAsync = false}) async =>
  doAsync ? await file.readAsString(): file.readAsStringSync();

