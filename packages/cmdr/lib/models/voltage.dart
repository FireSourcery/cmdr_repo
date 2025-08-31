import '../interfaces/binary_format.dart';

class VDivider {
  const VDivider(this.r1, this.r2);
  const VDivider.zero() : r1 = 0, r2 = 1;

  final int r1;
  final int r2;

  static double vAdcRef = 5;
  static int adcMax = 4095;

  double get voltsPerAdcu => (vAdcRef * (r1 + r2) / (adcMax * r2));

  // num voltsOf(int adcu) => adcu * voltsPerAdcu;
  // int adcuOf(num volts) => volts ~/ voltsPerAdcu;

  // assert(voltsPerAdcu != 1)
  // 0 => null,
  // num(isFinite: false) => null,
  BinaryNumConversion? get conversion => BinaryLinearConversion(voltsPerAdcu).conversion;

  @override
  bool operator ==(covariant VDivider other) {
    if (identical(this, other)) return true;

    return other.r1 == r1 && other.r2 == r2;
  }

  @override
  int get hashCode => r1.hashCode ^ r2.hashCode;
}

class VBattery {
  const VBattery(this.vEmpty, this.vFull);
  final double vEmpty; // v0
  final double vFull; // v100

  double chargeOf(num volts) => (volts - vEmpty) / (vFull - vEmpty);
  // double chargeOfAdcu(int adcu) => adcu;
}
