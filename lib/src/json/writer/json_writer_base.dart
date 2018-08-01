//  Copyright (c) 2016, 2017, 2018, 
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

abstract class JsonWriterBase {
  /// The [RootDataset] to be written.
  final RootDataset rds;

  /// The path to the output file.
  final String path;

  /// An indenting StringBuffer
  final Indenter sb;

  /// _true_ if _Bulkdata_ should be separated from _Metadata_.

  /// The threshold, in number of bytes, beyond which a Value Field
  /// is move to a Bulkdata object.
  final int bulkdataThreshold;
  final bool separateBulkdata;
  final bool separatePixelData;
  final BulkdataList bdList;
  final bool emptyIsList;

  /// _true_ if File Meta-Information should be written as part of
  /// the [RootDataset] being written.
  final bool includeFmi;

  JsonWriterBase(this.rds, this.path,
      {int tabSize = 0,
        this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.separatePixelData = false,
      this.includeFmi = true,
      this.emptyIsList = true})
      : sb = new Indenter('', tabSize),
        bdList = (separateBulkdata) ? new BulkdataList(path) : null;

  JsonWriterBase.indenting(this.rds, this.path,
      {int tabSize = 2,
      this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.separatePixelData = false,
      this.includeFmi = true,
      this.emptyIsList = true})
      : sb = new Indenter('', tabSize),
        bdList = new BulkdataList(path);

  // **** Interface
  String writeRootDataset();
  void writeSimpleElement(Element e, String separator);
  void writeEmptyElement(Element e, String separator);
  void writeSQ(SQ e, String separator);
  void writeElementStart(Element e);
  void writeElementEnd(Element e, String separator);


  // **** End Interface
  String write() => writeRootDataset();

  void writeList(Iterable values) => sb.writeList(values);

  void writeElementList(Iterable<Element> elements, [String separator = '']) {
    if (elements.isEmpty) return;
    final it = elements.iterator;
    final length = elements.length;
    for (var i = 0; i < length - 1; i++) {
      it.moveNext();
      writeElement(it.current, separator);
    }
    it.moveNext();
    writeElement(it.current, '');
  }

  void writeItems(
      List<Item> items, String start, String end, [String separator = '']) {
    final it = items.iterator;
    final length = items.length;
    for (var i = 0; i < length - 1; i++) {
      it.moveNext();
      sb.indent(start);
      writeElementList(it.current, separator);
      sb.outdent('$end$separator');
    }
    it.moveNext();
    sb.indent(start);
    writeElementList(it.current, separator);
    sb.outdent(end);
  }

  String elementId(Element e) => '${e.hex} ${e.vrId}, ${e.keyword}';

  BulkdataUri writeBulkdata(Element e, String separator, BulkdataUri url) {
    sb.writeln('[${elementId(e)} Bulkdata "$url"]]$separator');
    return url;
  }

  void writeElement(Element e, [String separator = '']) {
    if (e.isEmpty) {
      writeEmptyElement(e, separator);
    } else if (e is SQ) {
      writeSQ(e, separator);
    } else if (e.vfLength > bulkdataThreshold &&
          (separateBulkdata || (e is PixelData && separatePixelData))) {
      final url = bdList.add(e.code, e.vfBytes);
      writeBulkdata(e, separator, url);
    }else {
      writeSimpleElement(e, separator);
    }  
  }

  @override
  String toString() => sb.toString();
}
