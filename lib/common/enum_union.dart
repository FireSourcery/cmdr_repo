// abstract mixin class EnumUnionFactory<T extends Enum> {
  
//     EnumUnion cast(T? motVarName) : _this = motVarName ?? MotVarId_Monitor_General.MOT_VAR_ZERO as T;
// // factory MotVarNameUnion.index(int index) => MotVarNameUnion<T>.cast(values<T>().elementAtOrNull(index));
// //   const MotStatus._(this.status);
// //   // const MotStatus.cast(T this.status);
// //   const factory MotStatus.cast(T status) = MotStatus<T>._; // Type defined and inferred by arg
// //   // Type defined by type parameter input
// //   MotStatus.index(int? index) : status = switch (index) { int value when value >= 0 => values<T>().elementAtOrNull(value), _ => null };
// //   //  assert(T != dynamic && T != Enum),

//   // List<List<T>> valuesUnion; 
//   Map<T, List<T>> get typeMap;

//   List<T> get values {
//     return typeMap[T] ?? (throw UnsupportedError('EnumUnionFactory.values: $T'));
//   }
// }

// abstract mixin class EnumUnion<T extends Enum> {
//   // const MotStatus._(this.status);
//   // // const MotStatus.cast(T this.status);
//   // const factory MotStatus.cast(T status) = MotStatus<T>._; // Type defined and inferred by arg
//   // // Type defined by type parameter input
//   // MotStatus.index(int? index) : status = switch (index) { int value when value >= 0 => values<T>().elementAtOrNull(value), _ => null };
//   // //  assert(T != dynamic && T != Enum),

//   T get value;
//   Type get type => T;

//   String get message => status?.name ?? 'Unknown Status';

//   static List<T> values<T extends Enum>() {
//     return switch (T) {
//       const (MotProtocol_GenericStatus) => MotProtocol_GenericStatus.values,
//       const (NvMemory_Status) => NvMemory_Status.values,
//       const (MotVarStatus) => MotVarId_Status.values,
//       const (MotStatusHost) => MotStatusHost.values,
//       const (dynamic) => MotStatusHost.values,
//       _ => throw UnsupportedError('MotStatus.values: $T'),
//     } as List<T>;
//   }

//   @override
//   String toString() => message.toString();
// }

// // alternative to MotVarNameSubtype implements MotVarName
// interface class MotVarNameUnion<T extends Enum> {
//   // const MotVarNameUnion._(this._this);
//   const MotVarNameUnion.cast(T? motVarName) : _this = motVarName ?? MotVarId_Monitor_General.MOT_VAR_ZERO as T;
//   factory MotVarNameUnion.index(int index) => MotVarNameUnion<T>.cast(values<T>().elementAtOrNull(index));
//   final T _this;

//   // int get value => varTypeType.index << 8 | varType.index << 4 | index;
//   // bool get isRealTime => (varTypeType == MotVarId_Type_Type.MOT_VAR_ID_TYPE_REAL_TIME);
//   // bool get isParameter => (varTypeType == MotVarId_Type_Type.MOT_VAR_ID_TYPE_PARAMS);

//   bool get isSensor {
//     return switch (T) { const (MotVarId_Monitor_MotorSensor) || const (MotVarId_Params_MotorEncoder) || const (MotVarId_Params_MotorHall) => true, _ => false };
//   }

//   // static List<T> values<T extends Enum>() {
//   //   return switch (T) {
//   //     const (MotVarId_Monitor_Motor) => MotVarId_Monitor_Motor.values,
//   //     // const (MotVarId_Monitor_MotorFoc) => MotVarId_Monitor_MotorFoc.values,
//   //     _ => throw TypeError(), // of not called with type
//   //   } as List<T>;
//   // }
// }
