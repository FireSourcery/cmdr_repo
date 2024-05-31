import 'dart:collection';

import 'package:meta/meta.dart';

import '../common/fixed_map.dart';
import 'typed_field.dart';
import 'word.dart';
import 'bits.dart';

/// [Bits] + operators <WordField, int> + [Bytes] up to 8 bytes
///
/// [Word] with named fields
///
/// Implementation centric DataMap, up to 8 bytes, int values only
///   a special case where the data struct is known, does not need child constructor
/// alternatively WordModel
///
/// mixin as interface and implementation
abstract mixin class WordFields<T extends WordField<NativeType>> implements FixedMap<T, int>, Word {
  const WordFields();
  const factory WordFields.withKeys(List<T> keys, int value) = WordFieldsWithKeys<T>;
  // WordFields.initWith(Map<WordField, int> newValue) : this(Word(newValue.fold()));

  @override
  Bits get bits;
  @override
  List<T> get keys; // with Enum.values

  @mustBeOverridden
  // return as child type
  WordFields<T> copyWithBase(int state); //if modify and return as child type is required
  // WordFields<T> copyWithBase(WordFields<T> state);

  @protected
  Bits _modify(T key, int newValue) => Bits(key.modifyWord(bits, newValue));

  S modifyAll<S extends WordFields<T>>(Map<T, int> map) => copyWithBase(map.fold()) as S;
  S modifyEntry<S extends WordFields<T>>(T key, int value) => copyWithBase(key.modifyWord(bits, value)) as S;

  // index, list based
  // WordFields<T> updateEntryAt(int index, int value) => copyWithBase(modify(keys[index], value));
  // WordFields<T> modifyAll(Iterable<int> numbers) => copyWithBase(numbers.toBytes().toInt(Endian.big));

  @override
  int operator [](T key) => key.valueOfWord(bits);
  @override
  void operator []=(T key, int? value) => throw UnsupportedError('WordFields does not support assignment');
  @override
  void clear() => throw UnsupportedError('WordFields does not support clear');

  WordFields<T> fromJson(Map<String, dynamic> json) {
    if (json is Map<String, int>) {
      return copyWithBase(FixedMapBuffer<WordField, int>(keys).fromMapByName<FixedMap<WordField, int>>(json).fold());
    } else {
      throw FormatException('WordFields.fromJson: $json is not of type Map<String, int>');
    }
  }
}

// /// a field within a Word, unlike BitField
// for user to define map operator and name
/// interface for including [TypedField<T>], [Enum]
abstract interface class WordField<V extends NativeType> implements TypedField<V>, Enum {
  // int valueOfWord(int source);
  // int modifyWord(int source, int value);
  // alternatively store the bitmask
  // Bitmask get bitmask => Bitmask(offset, size);
}

/// Must extend Word for const constructor, until const expressions are supported
/// Keep as bodyless to pass constructor
abstract class WordFieldsBase<T extends WordField<NativeType>> = Word with MapBase<T, int>, FixedMap<T, int>, WordFields<T>;

class WordFieldsWithKeys<T extends WordField<NativeType>> extends WordFieldsBase<T> implements WordFields<T> {
  const WordFieldsWithKeys(this.keys, super.value);

  @override
  final List<T> keys;

  @override
  WordFields<T> copyWithBase(int state) => WordFields.withKeys(keys, state);
}

/// on both [Map<WordField, int>] and [WordFieldsBase]
extension WordFieldMapValue on Map<WordField<NativeType>, int> {
  // valueByFold
  int fold() => entries.fold<int>(0, (previous, element) => element.key.modifyWord(previous, element.value));
}
