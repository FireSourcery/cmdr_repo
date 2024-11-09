import 'package:flutter/material.dart';

// child on null, builder checking condition otherwise
// class ConditionalBuilder extends StatelessWidget {
//   const ConditionalBuilder({
//     super.key,
//     required this.condition,
//     required this.builder,
//   });

//   final bool? condition;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Conditional Widget Example'),
//       ),
//       body: Center(
//         child: _buildContent(),
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (condition) {
//       return Text(
//         'Condition is true',
//         style: TextStyle(color: Colors.green, fontSize: 24),
//       );
//     } else {
//       return Text(
//         'Condition is false',
//         style: TextStyle(color: Colors.red, fontSize: 24),
//       );
//     }
//   }
// }

// class _ConditionalBuilder extends ConditionalBuilder {

// }

// class _ConditionalBuilder extends ConditionalBuilder {

// }
