// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:math';

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
double rPullDownOf(num rPullUp, double vIn, double adcVRef, int adcMax, int adcu) {
  return (rPullUp * adcVRef * adcu) / (vIn * adcMax - adcVRef * adcu);
}

/* Thermistor as pull-up */
double rPullUpOf(num rPullDown, double vIn, double adcVRef, int adcMax, int adcu) {
  return (rPullDown * vIn * adcMax) / (adcVRef * adcu) - rPullDown;
}

/* Resistance [Ohm] to ADCU */
int adcuOfR(int adcMax, double adcVRef, double vIn, num rPullUp, num rPullDown) {
  if ((rPullUp + rPullDown) case num(isInfinite: true) || num(isNaN: true) || 0) return 0;
  return (vIn * adcMax * rPullDown) ~/ (adcVRef * (rPullUp + rPullDown));
}

double rNetOf(num rParallel1, num rParallel2) {
  return (rParallel1 * rParallel2) / (rParallel1 + rParallel2); /* 1 / (1/r1 + 1/r2) */
}

double rParallelOf(num rNet, num rParallel) {
  return (rNet * rParallel) / (rNet - rParallel); /* 1 / (1/rNet - 1/rParallel) */
}

/// 1/T = 1/T0 + (1/B)*ln(R/R0)
/// return 1/T
double steinhartB(num b, num t0, num r0, num rThermistor) => (log(rThermistor / r0) / b) + (1.0 / t0);

/// return RThermistor
double invSteinhartB(num b, num t0, num r0, num invT) => exp((invT - 1.0 / t0) * b) * r0;

// static double steinhart(num a, num b, num c, num rThermistor);

class Thermistor {
  const Thermistor({required this.b, required this.r0, this.t0 = roomTemperatureKelvin, required this.rSeries, this.rParallel});

  const Thermistor.forceDefaults({required this.b, required this.r0, required this.rSeries, int? rParallel, double? t0})
      : t0 = t0 ?? roomTemperatureKelvin, // passing null inits to default
        rParallel = (rParallel == 0) ? null : rParallel; // passing 0 inits to null

  const Thermistor.detached({required this.rSeries, this.rParallel})
      : b = 0,
        r0 = 0,
        t0 = roomTemperatureKelvin;

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
    final rThermistor = (rParallel != null && rParallel != 0) ? rParallelOf(rNet, rParallel!) : rNet;
    final invT = steinhartB(b, t0, r0, rThermistor);
    return (1.0 / invT);
  }

  double celsiusOf(int adcu) => kelvinOf(adcu) + absoluteZeroCelsius;

  int adcuOfKelvin(num kelvin) {
    if (kelvin == 0) return 0;
    final invT = 1.0 / kelvin;
    final rThermistor = invSteinhartB(b, t0, r0, invT);
    final rNet = (rParallel != null && rParallel != 0) ? rNetOf(rParallel!, rThermistor) : rThermistor;
    return adcuOfR(adcMax, vAdcRef, vInRef, rSeries, rNet);
  }

  int adcuOfCelsius(num celsius) => adcuOfKelvin(celsius - absoluteZeroCelsius);

  Thermistor copyWith({
    int? r0,
    double? t0,
    int? b,
    int? rSeries,
    int? rParallel,
  }) {
    return Thermistor(
      r0: r0 ?? this.r0,
      t0: t0 ?? this.t0,
      b: b ?? this.b,
      rSeries: rSeries ?? this.rSeries,
      rParallel: rParallel ?? this.rParallel,
    );
  }

  Thermistor asDetached() => Thermistor.detached(rSeries: rSeries, rParallel: rParallel);

  Thermistor updateAsDetached({int? r0, double? t0, int? b}) => copyWith(r0: r0, t0: t0, b: b);

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

// case where compile time const, == operator on known values
// class DetachedThermistor {
//   const DetachedThermistor({required this.rSeries, this.rParallel});

//   final int rSeries;
//   final int? rParallel;

//   Thermistor buildThermistor(int b, int r0, double t0) => Thermistor(b: b, r0: r0, t0: t0, rSeries: rSeries, rParallel: rParallel);

//   DetachedThermistor copyWith({
//     int? rSeries,
//     int? rParallel,
//   }) {
//     return DetachedThermistor(
//       rSeries: rSeries ?? this.rSeries,
//       rParallel: rParallel ?? this.rParallel,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return <String, dynamic>{
//       'rSeries': rSeries,
//       'rParallel': rParallel,
//     };
//   }

//   factory DetachedThermistor.fromMap(Map<String, dynamic> map) {
//     return DetachedThermistor(
//       rSeries: map['rSeries'] as int,
//       rParallel: map['rParallel'] != null ? map['rParallel'] as int : null,
//     );
//   }

//   String toJson() => json.encode(toMap());

//   factory DetachedThermistor.fromJson(String source) => DetachedThermistor.fromMap(json.decode(source) as Map<String, dynamic>);

//   @override
//   String toString() => 'DetachedThermistor(rSeries: $rSeries, rParallel: $rParallel)';

//   @override
//   bool operator ==(covariant DetachedThermistor other) {
//     if (identical(this, other)) return true;

//     return other.rSeries == rSeries && other.rParallel == rParallel;
//   }

//   @override
//   int get hashCode => rSeries.hashCode ^ rParallel.hashCode;
// }
