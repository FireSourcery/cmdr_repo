import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Example Widgets')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [Placeholder()],
          ),
        ),
      ),
    );
  }
}
