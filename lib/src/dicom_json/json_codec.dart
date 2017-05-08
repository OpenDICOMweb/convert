// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:convert';

typedef Object _Reviver(dynamic key, dynamic value);
typedef String _ToEncodable(dynamic o);

class JsonCodec extends Codec<Object, String> {
  final _Reviver _reviver;
  final _ToEncodable _toEncodable;

  const JsonCodec(
      {Object reviver(dynamic key, dynamic value), String toEncodable(dynamic object)})
      : _reviver = reviver,
        _toEncodable = toEncodable;

  JsonCodec.withReviver(dynamic reviver(dynamic key, dynamic value)) : this(reviver: reviver);

  @override
  JsonDecoder get decoder {
    if (_reviver == null) return const JsonDecoder();
    return new JsonDecoder(_reviver);
  }

  @override
  JsonEncoder get encoder {
    if (_toEncodable == null) return const JsonEncoder();
    return new JsonEncoder(_toEncodable);
  }

  //TODO: add correct types to key and value
  @override
  dynamic decode(String source, {Object reviver(dynamic key, dynamic value)}) {
    if (reviver == null) reviver = _reviver;
    if (reviver == null) return decoder.convert(source);
    return new JsonDecoder(reviver).convert(source);
  }

  @override
  String encode(Object value, {String toEncodable(dynamic object)}) {
    if (toEncodable == null) toEncodable = _toEncodable;
    if (toEncodable == null) return encoder.convert(value);
    return new JsonEncoder(toEncodable).convert(value);
  }

  static const JsonCodec json = const JsonCodec();
}

class JsonDecoder extends Converter<String, Object> {
  final _Reviver _reviver;

  const JsonDecoder([dynamic reviver(dynamic key, dynamic value)]) : this._reviver = reviver;

  @override
  dynamic convert(String input) => _parseJson(input, _reviver);

  Object _parseJson(String input, _Reviver _reviver) {
    //TODO: finish
    return input;
  }

  @override
  StringConversionSink startChunkedConversion(Sink<Object> sink) {
    //TODO: finish
    return sink;
  }

  // Override the base class's bind, to provide a better type.
  @override
  Stream<Object> bind(Stream<String> stream) => super.bind(stream);
}

/*
class JsonUtf8Decoder extends Converter<String, List<int>>
    implements ChunkedConverter<Object, List<int>, Object, List<int>> {

  /** Default buffer size used by the JSON-to-UTF-8 encoder. */
  static const int DEFAULT_BUFFER_SIZE = 256;

  /** Indentation used in pretty-print mode, `null` if not pretty. */
  final List<int> _indent;

  /** Function called with each un-encodable object encountered. */
  final _ToEncodable _toEncodable;

  /** UTF-8 buffer size. */
  final int _bufferSize;

  JsonUtf8Encoder([this._bufferSize = 1024 * 1024, this._indent , this._toEncodable]) {

  }

  String encode(List<int> input) => _encodeJson(input, _toEncodable);

  String _encodeJson(List<int> input, _Reviver _toEncodable) {

  }
  }
*/
