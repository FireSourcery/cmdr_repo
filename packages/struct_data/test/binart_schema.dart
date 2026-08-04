// sealed class Num<V> {
//   const Num();
// }

// class NumEnum extends Num<Enum> {
//   const NumEnum();
// }

// class NumDouble extends Num<double> {
//   const NumDouble();
// }

// let struct map memory, mixin maps enum field descriptors for name and toMap
// final class BinarizableTest extends Struct {
//   @Uint32()
//   external int device;
//   @Uint32()
//   external int flags;

//   // factory BinarizableTest.cast(TypedData typedData) => Struct.create<BinarizableTest>(typedData);

//   @override
//   StructData<Field<Object?>, dynamic> get data => throw UnimplementedError();

//   @override
//   List<Field<Object?>> get keys => SensorField.values;
// }

// enum SensorField implements Field<int> {
//   device,
//   flags,
//   ;

//   @override
//   int getIn(covariant BinarizableTest struct) {
//     return switch (this) {
//       SensorField.device => struct.device,
//       SensorField.flags => struct.flags,
//     };
//   }

//   @override
//   void setIn(covariant Object struct, int value) {
//     // TODO: implement setIn
//   }

//   @override
//   bool testAccess(covariant Object struct) {
//     // TODO: implement testAccess
//     throw UnimplementedError();
//   }
// }
