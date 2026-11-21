/// Widget library for the CMDR package.
///
/// This library provides a comprehensive collection of Flutter widgets
/// specifically designed for embedded device applications and data visualization.
///
/// ```dart
/// import 'package:cmdr/widgets.dart';
///
/// // Use in your Flutter app
/// VarIOField(varNotifier)
/// TimeChart(chartController: chartController)
/// ```
library;

// Application general widgets
export 'widgets/app_general/bottom_sheet_button.dart';
export 'widgets/app_general/drive_shift.dart';
export 'widgets/app_general/logo.dart';

// Data view widgets
export 'widgets/data_views/selection_chips.dart';
export 'widgets/data_views/map_form_fields.dart';

// Dialog widgets
export 'widgets/dialog/dialog.dart';
export 'widgets/dialog/dialog_anchor.dart';

// Input/Output field widgets
export 'widgets/num_input_formatters.dart';
export 'widgets/io_field/io_field.dart';
export 'widgets/io_field/io_field_ext.dart';
export 'widgets/flyweight_menu/flyweight_menu.dart';
export 'widgets/flyweight_menu/flyweight_menu_widgets.dart';
export 'widgets/main_menu/main_menu.dart';
export 'widgets/main_menu/main_menu_controller.dart';

// Time chart widgets
export 'widgets/time_chart/chart_controller.dart';
export 'widgets/time_chart/chart_data.dart';
export 'widgets/time_chart/chart_file.dart';
export 'widgets/time_chart/chart_legend.dart';
export 'widgets/time_chart/chart_style.dart';
export 'widgets/time_chart/chart_widgets.dart';
export 'widgets/time_chart/time_chart.dart';

// Variable notifier widgets
export 'var_notifier/widgets/var_menu.dart';
export 'var_notifier/widgets/var_io_field.dart';
export 'var_notifier/widgets/var_input_dialog.dart';
export 'var_notifier/widgets/var_widget.dart';
export 'var_notifier/widgets/var_widgets.dart';

export 'widgets/layouts/layouts.dart';
