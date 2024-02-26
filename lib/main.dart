import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';

///  Main entry point 
void main() {
  runApp(const GuadalupeReportaDashboardApp());
}

/// App entry widget
class GuadalupeReportaDashboardApp extends StatelessWidget {
  const GuadalupeReportaDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Seed color scheme
    const seedColor = Color.fromRGBO(60, 105, 27, 0);

    // App title
    const appTitle = "Guadalupe Reporta Dashboard";

    // App theme
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      home: const DashboardPage(title: appTitle),
    );
  }
}

// Dashboard page
class DashboardPage extends StatefulWidget {
  final String title;
  
  const DashboardPage({super.key, required this.title});
  
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
/// State of the Dashboard page
class _DashboardPageState extends State<DashboardPage> {

  /* int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  } */

  late GoogleMapController gmController;
  
  // Plaza de armas de Guadalupe : -7.243271, -79.470281
  final LatLng _latLonCenter = const LatLng(-7.243271, -79.470281);

  void _onMapCreated(GoogleMapController controller) {
    gmController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.title,
            ),
          ],
        ),
        /* title: Text(
          widget.title,
        ), */
        foregroundColor: Theme.of(context).colorScheme.background,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: _latLonCenter, zoom: 15.0),
        onMapCreated: _onMapCreated,
      )
      /* body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ), */
      /* floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), */
    );
  }
}
