// import 'dart:ffi';

// import 'package:cmdr/common/basic_types.dart';
// import 'package:test/test.dart';

// typedef _TypedOffset<T extends NativeType> = ({int offset});
// typedef TypedOffset<T extends NativeType> = ({_TypedOffset<T> typedOffset});

// class PacketField<T extends NativeType> {
//   PacketField(this.offset);
//   final int offset;
// }

// // Type<num> type = int;
// void typedFn<T extends NativeType>(TypedOffset<T> a) {
//   switch (T) {
//     case const (Uint8):
//       print('Uint8');
//     case const (Uint16):
//       print('Uint16');
//   }
// }

// typedef typeOf<T> = T;

// enum EnumTest { a, b, c }

// void main() {
//   test('type_test', () {
//     TypeKey<int> typeInt = TypeKey<int>();
//     TypeKey<EnumTest> typeEnum = TypeKey<EnumTest>();

//     print(typeInt.isSubTypeOf<Enum>());
//     print(typeEnum.isSubTypeOf<Enum>());

//     print(List<int>);
//     print(List<int>);
//     print(typeOf<List<int>>);
//     print(sizeOf<Uint8>());
//     print(sizeOf<Uint16>());
//     print(sizeOf<Uint32>());
//     print(typeOf<TypedOffset<Uint8>>);
//     print(sizeOf<Pointer>());
//   });
// }
