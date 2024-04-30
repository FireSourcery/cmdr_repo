// import 'package:collection/collection.dart';

// import 'package:cmdr/number_format.dart';
// import '../../mot_reference/mot_reference.dart';
// import 'var_key.dart';

// typedef ViewOfMot = num Function(int mot);
// typedef MotOfView = int Function(num view);
// // ViewOfMot _linearConversionFnOf(num coefficient) => (int motValue) => (motValue * coefficient);
// // MotOfView _invLinearConversionFnOf(num coefficient) => (num viewValue) => (viewValue ~/ coefficient);

// ViewOfMot? linearConversionFnOf(num coefficient) {
//   num linearConversionOf(int motValue) => (motValue * coefficient);
//   return (coefficient == 0 || coefficient == double.infinity) ? null : linearConversionOf;
// }

// MotOfView? invLinearConversionFnOf(num coefficient) {
//   int invLinearConversionOf(num viewValue) => (viewValue ~/ coefficient);
//   return (coefficient == 0 || coefficient == double.infinity) ? null : invLinearConversionOf;
// }

// /// build value conversion function for cache by caller
// extension MotVarConversion on MotVarKey {
//   // include sign extension?
//   ViewOfMot? get viewOfMot {
//     return switch ((tag.format, tag.units)) {
//       (NumberFormat(isInteger: true), _) => null,
//       (_, MotVarUnits(isCalibration: true)) => null,
//       (NumberFormat(isFixedPoint: true), _) => linearConversionFnOf(qFormatCoefficient),
//       (NumberFormat(isScalar: true), _) => linearConversionFnOf(1 / tag.format.reference!),
//       (NumberFormat.adcu, MotVarUnits.volts) => voltsOfAdcu,
//       (NumberFormat.adcu, MotVarUnits.degreesHeat) => degreesOfAdcu,
//       (NumberFormat.cycles, MotVarUnits.ms) => linearConversionFnOf(MotReference().msCoefficient),
//       // (_, MotVarUnits.ms) =>  ,
//       // (MotVarFormat.cycles, _) => 1 / (MotBoard().cyclesReference / tag.units.timeRef),
//       // back up
//       // (MotVarFormat.adcu, MotVarUnits.mV) => (int motValue) => (voltsOfAdcu(motValue) * 1000),
//       _ => null,
//     };
//   }

//   MotOfView? get motOfView {
//     return switch ((tag.format, tag.units)) {
//       (NumberFormat(isInteger: true), _) => null,
//       (_, MotVarUnits(isCalibration: true)) => null,
//       (NumberFormat(isFixedPoint: true), _) => invLinearConversionFnOf(qFormatCoefficient),
//       (NumberFormat(isScalar: true), _) => invLinearConversionFnOf(1 / tag.format.reference!),
//       (NumberFormat.adcu, MotVarUnits.volts) => adcuOfVolts,
//       (NumberFormat.adcu, MotVarUnits.degreesHeat) => adcuOfDegrees,
//       (NumberFormat.cycles, MotVarUnits.ms) => invLinearConversionFnOf(MotReference().msCoefficient),
//       // back up
//       // (MotVarFormat.adcu, MotVarUnits.mV) => (num viewValue) => (adcuOfVolts(viewValue) ~/ 1000),
//       _ => null,
//     };
//   }

//   /// property determined by varName.tag and ref table
//   num get qFormatCoefficient {
//     assert(tag.format.isFixedPoint);
//     assert(tag.format.reference != null);
//     final unitRef = switch (tag.units) {
//       MotVarUnits.rpm => MotReference().rpmFormatRef,
//       MotVarUnits.amps => MotReference().ampsFormatRef,
//       MotVarUnits.volts => MotReference().voltsFormatRef,
//       MotVarUnits.degreesAngle => MotReference().degreesAngleRef,
//       MotVarUnits.percent => MotReference().percentRef,
//       MotVarUnits.unitless => 1,
//       _ => throw TypeError(),
//     };
//     return (unitRef / tag.format.reference!);
//     // return (coefficient == 0 || coefficient == double.infinity) ? 1 : coefficient;
//   }

//   ViewOfMot get voltsOfAdcu {
//     ViewOfMot? voltsOfAdcu;
//     voltsOfAdcu = switch (varName) {
//       MotVarId_Monitor_General.MOT_VAR_V_SOURCE => MotReference().vSource.voltsOf,
//       MotVarId_Monitor_General.MOT_VAR_V_SENSOR => MotReference().vSensors.voltsOf,
//       MotVarId_Monitor_General.MOT_VAR_V_ACCS => MotReference().vAccessories.voltsOf,
//       _ => null,
//     };

//     /// case is MotVarUnits.volts || MotVarUnits.mV, filters non numerical of instance
//     voltsOfAdcu ??= switch (varInstance) {
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SOURCE => MotReference().vSource.voltsOf,
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SENSOR => MotReference().vSensors.voltsOf,
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_ACCS => MotReference().vAccessories.voltsOf,
//       _ => null,
//     };
//     assert(voltsOfAdcu != null);
//     return voltsOfAdcu!;
//   }

//   MotOfView get adcuOfVolts {
//     MotOfView? adcuOfVolts;
//     adcuOfVolts = switch (varName) {
//       MotVarId_Monitor_General.MOT_VAR_V_SOURCE => MotReference().vSource.adcuOf,
//       MotVarId_Monitor_General.MOT_VAR_V_SENSOR => MotReference().vSensors.adcuOf,
//       MotVarId_Monitor_General.MOT_VAR_V_ACCS => MotReference().vAccessories.adcuOf,
//       _ => null,
//     };

//     /// case is MotVarUnits.volts || MotVarUnits.mV, filters non numerical of instance
//     adcuOfVolts ??= switch (varInstance) {
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SOURCE => MotReference().vSource.adcuOf,
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SENSOR => MotReference().vSensors.adcuOf,
//       MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_ACCS => MotReference().vAccessories.adcuOf,
//       _ => null,
//     };
//     assert(adcuOfVolts != null);
//     return adcuOfVolts!;
//   }

//   ////////////////////////////////////////////////////////////////////////////////
//   /// Heat
//   ////////////////////////////////////////////////////////////////////////////////
//   /// realTime => handled by varName, do not have mapped instance
//   /// handled by instance
//   /// MotVarTag.thermistorFaultTrigger
//   /// MotVarTag.thermistorFaultThreshold
//   /// MotVarTag.thermistorWarningTrigger
//   /// MotVarTag.thermistorWarningThreshold
//   ViewOfMot get degreesOfAdcu {
//     assert(varName.isThermistor); // superset of units degrees heat
//     assert(tag.units == MotVarUnits.degreesHeat);

//     ViewOfMot? fn;
//     fn = switch (varName) {
//       MotVarId_Monitor_General.MOT_VAR_HEAT_PCB => MotReference().pcbThermistor.celsiusOf,
//       MotVarId_Monitor_General.MOT_VAR_HEAT_MOSFETS => MotReference().mosfetsThermistor.celsiusOf,
//       MotVarId_Monitor_Motor.MOT_VAR_MOTOR_HEAT => MotReference().motorThermistor.celsiusOf,
//       _ => null,
//     };
//     fn ??= switch (varInstance) {
//       MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_PCB => MotReference().pcbThermistor.celsiusOf,
//       MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_MOSFETS_0 => MotReference().mosfetsThermistor.celsiusOf,
//       // MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_MOSFETS_1 => MotReference().mosfetsThermistor?.celsiusOf, //todo
//       MotVarId_Instance_MotorThermistor.MOT_VAR_ID_THERMISTOR_MOTOR_0 => MotReference().motorThermistor.celsiusOf,
//       // MotVarId_Instance_MotorThermistor.MOT_VAR_ID_THERMISTOR_MOTOR_1 => MotReference().motorThermistor?.celsiusOf, //todo
//       _ => null,
//     };
//     assert(fn != null);
//     return fn!;
//   }

//   MotOfView get adcuOfDegrees {
//     assert(varName.isThermistor);
//     assert(tag.units == MotVarUnits.degreesHeat);

//     MotOfView? fn;
//     fn = switch (varName) {
//       MotVarId_Monitor_General.MOT_VAR_HEAT_PCB => MotReference().pcbThermistor.adcuOfCelsius,
//       MotVarId_Monitor_General.MOT_VAR_HEAT_MOSFETS => MotReference().mosfetsThermistor.adcuOfCelsius,
//       MotVarId_Monitor_Motor.MOT_VAR_MOTOR_HEAT => MotReference().motorThermistor.adcuOfCelsius,
//       _ => null,
//     };
//     fn ??= switch (varInstance) {
//       MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_PCB => MotReference().pcbThermistor.adcuOfCelsius,
//       MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_MOSFETS_0 => MotReference().mosfetsThermistor.adcuOfCelsius,
//       // MotVarId_Instance_BoardThermistor.MOT_VAR_ID_THERMISTOR_MOSFETS_1 => MotReference().mosfetsThermistor?.adcuOfCelsius, //todo
//       MotVarId_Instance_MotorThermistor.MOT_VAR_ID_THERMISTOR_MOTOR_0 => MotReference().motorThermistor.adcuOfCelsius,
//       // MotVarId_Instance_MotorThermistor.MOT_VAR_ID_THERMISTOR_MOTOR_1 => MotReference().motorThermistor?.adcuOfCelsius, //todo
//       _ => null,
//     };
//     assert(fn != null);
//     return fn!;
//   }

 
// }

// ////////////////////////////////////////////////////////////////////////////////
// /// Key for min max extensions
// /// min max overide using name/tag and instance
// ////////////////////////////////////////////////////////////////////////////////
// extension MotVarMinMax on MotVarKey {
//   int? get preferredPrecision => switch (varName) { MotVarId_Params_MotorPid() => 2, _ => 1 };

//   (num, num)? get _overrideMinMax {
//     return switch ((varName, varInstance)) {
//       (MotVarId_Params_MotorPrimary.MOT_VAR_POLE_PAIRS, _) => (0, 100), // alternatively use uint8t format
//       (MotVarId_Params_MotorPid(), _) => (0, 10), // todo freq
//       // todo with nominal + fault
//       (MotVarId_Params_VMonitor.MOT_VAR_VMONITOR_WARNING_UPPER_ADCU, MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_ACCS) => (12, 14),
//       (MotVarId_Params_VMonitor.MOT_VAR_VMONITOR_WARNING_LOWER_ADCU, MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_ACCS) => (10, 12),
//       (MotVarId_Params_VMonitor.MOT_VAR_VMONITOR_WARNING_UPPER_ADCU, MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SENSOR) => (5, 6),
//       (MotVarId_Params_VMonitor.MOT_VAR_VMONITOR_WARNING_LOWER_ADCU, MotVarId_Instance_VMonitor.MOT_VAR_ID_VMONITOR_SENSOR) => (4, 5),
//       _ => null,
//     };
//   }

//   /// alternatively use configurable
//   num get viewMax {
//     if (_overrideMinMax != null) return _overrideMinMax!.$2;
//     return switch (tag.units) {
//       MotVarUnits.amps => MotReference().ampsFormatRef,
//       MotVarUnits.rpm => MotReference().rpmFormatRef,
//       MotVarUnits.volts => MotReference().voltsFormatRef,
//       MotVarUnits.percent => MotReference().percentRef,
//       MotVarUnits.degreesAngle => MotReference().degreesAngleRef,
//       MotVarUnits.degreesHeat => MotReference().degreesHeatRef,
//       // MotVarUnits.ms => 65535,
//       MotVarUnits.ms => 3000, // format == cycles, < uint16 for now
//       MotVarUnits.unitless => (tag.format.reference != null) ? (tag.format.max / tag.format.reference!) : tag.format.max,
//       MotVarUnits.rpmRef => MotReference().rpmRefSelectMax,
//       MotVarUnits.adcuRef => MotReference().motBoard.adcConfig.adcMax,
//       MotVarUnits.vRef => MotReference().voltsMax,
//       //removed
//       // MotVarUnits.mV => 10000,
//     };
//   }

//   num get viewMin {
//     if (_overrideMinMax != null) return _overrideMinMax!.$1;
//     return (tag.format.isSigned) ? -viewMax : 0;
//   }
// }

// extension MotVarMinMaxs on Iterable<MotVarKey> {
//   ////////////////////////////////////////////////////////////////////////////////
//   /// Collective view min max
//   ////////////////////////////////////////////////////////////////////////////////
// // Iterable<(num, num)> get viewMinMaxs => map((e) => e.tag.viewMinMax);
//   Iterable<num> get viewMaxs => map((e) => e.viewMax);
//   Iterable<num> get viewMins => map((e) => e.viewMin);
//   num get viewMax => viewMaxs.max;
//   num get viewMin => viewMins.min;
// }
