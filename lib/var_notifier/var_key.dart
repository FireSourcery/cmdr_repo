// import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
 

// typedef GenericFunction<R> = R Function<G>([dynamic context]);

// @immutable
// abstract class VarKey {
//   @override
//   String toString() => 'MotVarKey: $label $asDataId';

//   int get asDataId;
//   int get value;
//   NumberFormat get numberFormat;
//   Units get units;

//   // R callTyped<R>(GenericFunction fn) {
//   //   // if (isHostNameOverride) return fn<MotVarHostName>();
//   //   // return switch (tag.format) {
//   //   //   NumberFormat.enum16 => fn<MotVarValueName>(),
//   //   //   NumberFormat.flags16 => fn<MotVarValueFlags>(),
//   //   //   _ => tag.format.callTyped<R>(fn), // pass format type parameter
//   //   // };
//   // }

//   // MotVar allocateTypedVar( ) {
//   //    callTyped<MotVar>(MotVar.new);
//   // }
//

//
//   @override
//   bool operator ==(covariant VarKey other) {
//     if (identical(this, other)) return true;
//     return other.value == value;
//   }

//   @override
//   int get hashCode => value.hashCode;
// }

// extension MotVarKeys on Iterable<MotVarKey> {
//   Iterable<MotVarTag> get tags => map((e) => e.tag);
//   Iterable<int> get asMotDataIds => map((e) => e.asMotDataId);
 

////////////////////////////////////////////////////////////////////////////////
///
////////////////////////////////////////////////////////////////////////////////
// extension MotVarIdMethods on MotVarId {
//   //alternatively use component maps, still constant time operation
//   static final Map<int, MotVarName> _motDataIdMap = Map.unmodifiable({
//     for (final varName in MotVarId_Type_RealTime.values.expand<MotVarName>((element) => element.varNames)) varName.value: varName,
//     for (final varName in MotVarId_Type_Parameter.values.expand<MotVarName>((element) => element.varNames)) varName.value: varName,
//   });

//   static const MotVarName undefined = MotVarId_Monitor_General.MOT_VAR_ZERO;

//   MotVarName get varName => _motDataIdMap[Name] ?? undefined;
//   MotVarType get varType => varName.varType;

//   /// todo regularize range checked implemented instances
//   MotVarInstance get varInstance {
//     final implemented = switch (varName) {
//       MotVarId_Params_Thermistor() when (InstancePrefix == MotVarId_Instance_Prefix.MOT_VAR_ID_INSTANCE_PREFIX_BOARD.index) => MotVarInstanceImplemented.boardThermistors,
//       MotVarId_Params_Thermistor() when (InstancePrefix == MotVarId_Instance_Prefix.MOT_VAR_ID_INSTANCE_PREFIX_MOTOR.index) => MotVarInstanceImplemented.motorThermistors,
//       MotVarId_Params_VMonitor() => MotVarInstanceImplemented.vMonitors,
//       MotVarId_Params_Protocol() => MotVarInstanceImplemented.protocols,
//       MotVarName(isSingleton: true) => MotVarInstanceImplemented.general,
//       MotVarName(isMotor: true) => MotVarInstanceImplemented.motors,
//       MotVarName(isMotor: false, isSingleton: false) => throw TypeError(),
//     };

//     return implemented.each.elementAtOrNull(Instance) ?? MotVarInstanceGeneral.singleton;
//   }
// }

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

//   static List<T> values<T extends Enum>() {
//     return switch (T) {
//       const (MotVarId_Monitor_Motor) => MotVarId_Monitor_Motor.values,
//       // const (NvMemory_Status) => NvMemory_Status.values,
//       // const (MotVarStatus) => MotVarId_Status.values,
//       // const (MotStatusHost) => MotStatusHost.values,
//       _ => throw TypeError(), // of not called with type
//     } as List<T>;
//   }
// }
 