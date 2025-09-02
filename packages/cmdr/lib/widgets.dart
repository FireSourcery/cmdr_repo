/// Widget library for the CMDR package.
///
/// This library provides a comprehensive collection of Flutter widgets
/// specifically designed for embedded device applications and data visualization.
///
/// ## Features
///
/// - Data visualization widgets (charts, gauges, meters)
/// - Input/output field widgets
/// - Dialog and modal components
/// - Application-specific UI components
/// - Layout and navigation widgets
///
/// ## Usage
///
/// ```dart
/// import 'package:cmdr/widgets.dart';
///
/// // Use in your Flutter app
/// VarIoField(varKey: myVarKey)
/// ChartWidget(data: chartData)
/// ```
library cmdr.widgets;

// Application general widgets
export 'widgets/app_general/bottom_sheet_button.dart';
export 'widgets/app_general/drive_shift.dart';
export 'widgets/app_general/logo.dart';

// Data view widgets
export 'widgets/data_views/enum_chips.dart';
export 'widgets/data_views/flag_field_view.dart';
export 'widgets/data_views/map_form_fields.dart';

// Dialog widgets
export 'widgets/dialog/dialog.dart';
export 'widgets/dialog/dialog_anchor.dart';

// Input/Output field widgets
export 'widgets/io_field/io_field.dart';
export 'widgets/io_field/io_field_composites.dart';

// Time chart widgets
export 'widgets/time_chart/chart_controller.dart';
export 'widgets/time_chart/chart_data.dart';
export 'widgets/time_chart/chart_file.dart';
export 'widgets/time_chart/chart_legend.dart';
export 'widgets/time_chart/chart_style.dart';
export 'widgets/time_chart/chart_widgets.dart';
export 'widgets/time_chart/time_chart.dart';

// Variable notifier widgets
export 'var_notifier/widgets/var_io_field.dart';

export 'widgets/layouts/layouts.dart';
