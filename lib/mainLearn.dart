import 'package:flutter/material.dart';

/// Starting/Main method
void main() {
  runApp(const MyApp());
}

/// Main app widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    //throw UnimplementedError();

    return _MyAppState();
  }
}

/// State of the app
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //throw UnimplementedError();

    return MaterialApp(
      title: 'Hello Dart & Flutter world. By HD.',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(60, 105, 27, 0)),
        useMaterial3: true,
      ),
      home: Text(
        'Hello Dart & Flutter world! \nBy HD.', 
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
