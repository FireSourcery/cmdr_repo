// typedef ViewOfData = num Function(int data);
// typedef DataOfView = int Function(num view);

typedef Linear = num Function(num);

extension type const LinearConversionFactory(num coefficient) {
  num of(num x) => (x * coefficient); // fn
  num invOf(num y) => (y / coefficient); //invFn

  Linear? get conversionFn => (coefficient.isFinite) ? of : null;
  Linear? get invConversionFn => (coefficient.isFinite && coefficient != 0) ? invOf : null;

  // num viewOf(int dataValue) => (dataValue * coefficient);
  // int dataOf(num viewValue) => (viewValue ~/ coefficient);

  // ViewOfData? get viewOfDataFn => (coefficient.isFinite) ? null : viewOf;
  // DataOfView? get dataOfViewFn => (coefficient.isFinite && coefficient != 0) ? null : dataOf;
}

// ViewOfData _linearConversionFnWith(num coefficient) => ((int dataValue) => (dataValue * coefficient));
// DataOfView _invLinearConversionFnWith(num coefficient) => ((num viewValue) => (viewValue ~/ coefficient));
// ViewOfData? linearConversionFnWith(num coefficient) => (coefficient == 0 || coefficient == double.infinity) ? null : _linearConversionFnWith(coefficient);
// DataOfView? invLinearConversionFnWith(num coefficient) => (coefficient == 0 || coefficient == double.infinity) ? null : _invLinearConversionFnWith(coefficient);

