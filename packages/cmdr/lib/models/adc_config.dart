class AdcConfig {
  const AdcConfig(this.vAdcRef, this.adcMax);
  final double vAdcRef;
  final int adcMax;

  static const AdcConfig adc5v = AdcConfig(5, 4095);
}
