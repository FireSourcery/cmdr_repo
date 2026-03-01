import 'dart:math';

import 'package:binary_data/binary_format/quantity_format.dart';

////////////////////////////////////////////////////////////////////////////////
/// Math
////////////////////////////////////////////////////////////////////////////////
const double absoluteZeroCelsius = -273.15;
const double roomTemperatureKelvin = 25 - absoluteZeroCelsius;

/*
  Thermistor wired as pull-down resistor R2
  RSeries wired as pull-up resistor R1

  R2 = VOUT*R1/(VIN-VOUT)
  R2 = (ADC*VREF/ADC_MAX)*R1 / (VIN-(ADC*VREF/ADC_MAX))
  R2 = R1/(VIN*ADC_MAX/(ADC*VREF)-1)
  R2 = (R1*ADC*VREF)/(VIN*ADC_MAX - ADC*VREF)
*/
double rPullDownOf(num rPullUp, num vIn, num adcVRef, int adcMax, int adcu) => (rPullUp * adcVRef * adcu) / (vIn * adcMax - adcVRef * adcu);

/* Thermistor as pull-up */
double rPullUpOf(num rPullDown, num vIn, num adcVRef, int adcMax, int adcu) => (rPullDown * vIn * adcMax) / (adcVRef * adcu) - rPullDown;

/* Resistance [Ohm] to ADCU */
int _adcuOfR(int adcMax, num adcVRef, num vIn, num rPullUp, num rPullDown) => (vIn * adcMax * rPullDown) ~/ (adcVRef * (rPullUp + rPullDown));

int adcuOfR(int adcMax, num adcVRef, num vIn, num rPullUp, num rPullDown) {
  assert(adcVRef != 0);
  if ((rPullUp + rPullDown) case num(isFinite: false) || 0) return 0;
  return _adcuOfR(adcMax, adcVRef, vIn, rPullUp, rPullDown);
}

/* 1 / (1/r1 + 1/r2) */
double _rNetOf(num rParallel1, num rParallel2) => (rParallel1 * rParallel2) / (rParallel1 + rParallel2);

num rNetOf(num rParallel1, num? rParallel2) {
  if (rParallel2 == null) return rParallel1; // rParallel2 is infinite, rNet = rParallel1
  return _rNetOf(rParallel1, rParallel2);
}

/* 1 / (1/rNet - 1/rParallel) */
double _rParallelOf(num rNet, num rParallel) => (rNet * rParallel) / (rNet - rParallel);

num rParallelOf(num rNet, num? rParallel) {
  if (rParallel == null) return rNet; // rParallel is infinite, rParallelOf = rNet
  return _rParallelOf(rNet, rParallel);
}

/// 1/T = 1/T0 + (1/B)*ln(R/R0)
/// return 1/T
double steinhartB(num b, num t0, num r0, num rThermistor) => (log(rThermistor / r0) / b) + (1.0 / t0);

/// return RThermistor
double invSteinhartB(num b, num t0, num r0, num invT) => exp((invT - 1.0 / t0) * b) * r0;

// static double steinhart(num a, num b, num c, num rThermistor);

class Thermistor {
  const Thermistor({required this.b, required this.r0, this.t0 = roomTemperatureKelvin, required this.rSeries, this.rParallel}) : assert(rParallel != 0);

  const Thermistor.passDefaults({required this.b, required this.r0, required this.rSeries, int? rParallel, double? t0})
    : t0 = t0 ?? roomTemperatureKelvin, // passing null inits to default
      rParallel = (rParallel == 0) ? null : rParallel; // passing 0 inits to null

  const Thermistor.board({required this.rSeries, this.rParallel}) : b = 0, r0 = 0, t0 = roomTemperatureKelvin;

  const Thermistor.zero() : this.board(rSeries: 0);

  final int b;
  final int r0;
  final double t0; /* In Kelvin */
  // int? a;
  // int? c;

  final int rSeries;
  final int? rParallel;

  static double vAdcRef = 5;
  static double vInRef = 5;
  static int adcMax = 4095;

  ////////////////////////////////////////////////////////////////////////////////
  /// Instance
  /// thermistor as pull down only
  /// pull down case treat rParallel 0 as null/infinite
  ////////////////////////////////////////////////////////////////////////////////
  double kelvinOf(int adcu) {
    final rNet = rPullDownOf(rSeries, vInRef, vAdcRef, adcMax, adcu);
    final rThermistor = rParallelOf(rNet, rParallel);
    final invT = steinhartB(b, t0, r0, rThermistor);
    return (1.0 / invT);
  }

  int adcuOfKelvin(num kelvin) {
    if (kelvin == 0) return 0;
    final invT = 1.0 / kelvin;
    final rThermistor = invSteinhartB(b, t0, r0, invT);
    final rNet = rNetOf(rThermistor, rParallel);
    return adcuOfR(adcMax, vAdcRef, vInRef, rSeries, rNet);
  }

  double celsiusOf(int adcu) => kelvinOf(adcu) + absoluteZeroCelsius;
  int adcuOfCelsius(num celsius) => adcuOfKelvin(celsius - absoluteZeroCelsius);

  NumDataConversion? get conversionCelsius {
    assert(rParallel != 0);
    if (b == 0 || r0 == 0 || rSeries == 0) return null; // no coefficients, no conversion
    return (viewOfData: celsiusOf, dataOfView: adcuOfCelsius);
  }

  Thermistor copyWith({int? r0, double? t0, int? b, int? rSeries, int? rParallel}) {
    return Thermistor(r0: r0 ?? this.r0, t0: t0 ?? this.t0, b: b ?? this.b, rSeries: rSeries ?? this.rSeries, rParallel: rParallel ?? this.rParallel);
  }

  Thermistor copyWithoutCoeffcients() => Thermistor.board(rSeries: rSeries, rParallel: rParallel);
  Thermistor copyWithCoeffcients({int? r0, double? t0, int? b}) => copyWith(r0: r0, t0: t0, b: b);
  // or use separate class?
  // keep only the fixed values for comparison
  // WiredThermistor asWired() => Thermistor.detached(rSeries: rSeries, rParallel: rParallel);
  // BoardThermistor updateAsBoard({int? r0, double? t0, int? b}) => copyWith(r0: r0, t0: t0, b: b);

  @override
  bool operator ==(covariant Thermistor other) {
    if (identical(this, other)) return true;

    return other.b == b && other.r0 == r0 && other.t0 == t0 && other.rSeries == rSeries && other.rParallel == rParallel;
  }

  @override
  int get hashCode {
    return b.hashCode ^ r0.hashCode ^ t0.hashCode ^ rSeries.hashCode ^ rParallel.hashCode;
  }
}
