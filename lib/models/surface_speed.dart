import 'dart:math';

class SurfaceSpeed {
  const SurfaceSpeed._({required this.wheelDiameter, required this.gearRatio, required this.units, required this.speedPerRpm});

  SurfaceSpeed(this.wheelDiameter, this.gearRatio, this.units)
      : speedPerRpm = switch (units) {
          SpeedUnits.rpm => 1,
          SpeedUnits.kmh => kmhPerRpmOf(wheelDiameter, gearRatio), // wheelDiameterCm
          SpeedUnits.mph => mphPerRpmOf(wheelDiameter, gearRatio), // wheelDiameterInches
        };

  // if a const initializer is needed
  const SurfaceSpeed.rpm()
      : speedPerRpm = 1,
        wheelDiameter = 0,
        gearRatio = 0,
        units = SpeedUnits.rpm;

  const SurfaceSpeed.mph(this.wheelDiameter, this.gearRatio) // wheelDiameterInches
      : speedPerRpm = wheelDiameter * pi * 60 / 63360 / gearRatio,
        units = SpeedUnits.mph;

  const SurfaceSpeed.kmh(this.wheelDiameter, this.gearRatio) // wheelDiameterCm
      : speedPerRpm = wheelDiameter * pi * 60 / 100000 / gearRatio,
        units = SpeedUnits.kmh;

  static double kmhPerRpmOf(double wheelDiameterCm, double gearRatio) => wheelDiameterCm * pi * 60 / 100000 / gearRatio;
  static double mphPerRpmOf(double wheelDiameterInches, double gearRatio) => wheelDiameterInches * pi * 60 / 63360 / gearRatio;

  /// host side units conversion, read from settings
  final double wheelDiameter;
  final double gearRatio; // wheel:motor
  final double speedPerRpm;
  final SpeedUnits units;

  // final double? min;
  // final double? max;

  // double   unitsPerRpmOf() {
  //   return switch (units) {
  //     SpeedUnits.rpm => 1,
  //     SpeedUnits.kmh => kmhPerRpm,
  //     SpeedUnits.mph => mphPerRpm,
  //   };
  // }

  double groundSpeedOf(num rpm) => rpm * speedPerRpm;

  // converts wheel diameter
  // invalid for rpm
  // double mphOf(num rpm) {
  //   final diameter = wheelDiameter * switch (units) { SpeedUnits.rpm => 1, SpeedUnits.kmh => 2.54, SpeedUnits.mph => 1 };
  //   return rpm * mphPerRpmOf(diameter, gearRatio);
  // }

  // double kmhOf(num rpm) {
  //   final diameter = wheelDiameter / switch (units) { SpeedUnits.rpm => 1, SpeedUnits.kmh => 1, SpeedUnits.mph => 2.54 };
  //   return rpm * kmhPerRpmOf(diameter, gearRatio);
  // }
}

enum SpeedUnits {
  mph,
  kmh,
  rpm,

  // const SpeedUnits();
}
