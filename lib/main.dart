import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// To manage Google Maps state
  late GoogleMapController gmController;
  // Plaza de armas de Guadalupe : -7.243271, -79.470281
  final LatLng _latLonCenter = const LatLng(-7.243271, -79.470281);
  void _onMapCreated(GoogleMapController controller) {
    gmController = controller;
  }

  /// To manage the Drawer state
  int _drawerSelectedIndex = 0;
  void _onItemDrawerTapped(int index) {
    setState(() {
      _drawerSelectedIndex = index;
    });
  }

  /// To manage the Date filters state: From
  DateTime selectedDateFrom = DateTime.now().subtract(const Duration(days: 15));
  Future<void> _onPressedDatePickerFrom(BuildContext context) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(), //DateTime(2999),
      initialDate: selectedDateFrom,
    );
    if (dateTimePicket != null && dateTimePicket != selectedDateFrom) {
      setState(() {
        selectedDateFrom = dateTimePicket;
      });
    }
  }

  /// To manage the Date filters state: To
  DateTime selectedDateTo = DateTime.now();
  Future<void> _onPressedDatePickerTo(BuildContext context) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDate: selectedDateTo,
    );
    if (dateTimePicket != null && dateTimePicket != selectedDateTo) {
      setState(() {
        selectedDateTo = dateTimePicket;
      });
    }
  }

  /// To manage Report's Type dropdown button list
  static const List<String> reportTypeList = <String>[
    'All',
    'Pista o vereda en mal estado',
    'Basura y/o desmonte en la calle',
    'Arbol por podar',
    'Infraestructura o pared peligrosa',
    'Abandono o maltrato animal',
    'Buzón peligroso',
  ];
  String selectedReportType = reportTypeList.first;
  void _onChangeReportType(String? newReportType) {
    if (newReportType != null) {
      setState(() {
        selectedReportType = newReportType;
      });
    }
  }

  /// To manage Report's Status dropdown button list
  static const List<String> reportStatusList = <String>[
    'All',
    'To Check',
    'In Progress',
    'Done',
    '* Inappropriate',
  ];
  String selectedReportStatus = reportStatusList.first;
  void _onChangeReportStatus(String? newReportStatus) {
    if(newReportStatus != null) {
      setState(() {
        selectedReportStatus = newReportStatus;
      });
    }
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
        foregroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _latLonCenter, zoom: 15.0),
              onMapCreated: _onMapCreated,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Column(
                children: <Widget>[
                  Card(
                    child: Padding(
                        padding: const EdgeInsets.all(9.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  flex: 3,
                                  child: Text('From : '),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: ElevatedButton(
                                      onPressed: () =>
                                          _onPressedDatePickerFrom(context),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(DateFormat('dd/MM/yyyy')
                                                .format(selectedDateFrom)),
                                          ),
                                          const Icon(Icons.date_range),
                                        ],
                                      )),
                                ),
                              ],
                            ),
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6.0)),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  flex: 3,
                                  child: Text('To : '),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: ElevatedButton(
                                      onPressed: () =>
                                          _onPressedDatePickerTo(context),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text(DateFormat('dd/MM/yyyy')
                                                .format(selectedDateTo)),
                                          ),
                                          const Icon(Icons.date_range),
                                        ],
                                      )),
                                ),
                              ],
                            ),
                          ],
                        )),
                  ),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(9.0),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                flex: 3,
                                child: Text('Type : '),
                              ),
                              Expanded(
                                flex: 7,
                                child: /* Text('Dropdown button'), */ DropdownButton(
                                  isExpanded: true,
                                  value: selectedReportType,
                                  onChanged: (String? value) {
                                    _onChangeReportType(value);
                                  },
                                  items: reportTypeList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              const Expanded(
                                flex: 3,
                                child: Text('Status : '),
                              ),
                              Expanded(
                                flex: 7,
                                child: /* Text('Dropdown button') */ DropdownButton(
                                  isExpanded: true,
                                  value: selectedReportStatus,
                                  onChanged: (String? value) {
                                    _onChangeReportStatus(value);
                                  },
                                  items: reportStatusList
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Column(children: <Widget>[
                  // const Image(
                  //   image: AssetImage('images/person.png'),
                  // ),
                  Text(
                    "Heberth Deza",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 24,
                    ),
                  ),
                ])),
            ListTile(
              selected: (_drawerSelectedIndex == 0),
              leading: const Icon(Icons.account_circle),
              title: const Text('Account'),
              onTap: () {
                setState(() {
                  _onItemDrawerTapped(0); // _selectedIndex = 0;
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              selected: (_drawerSelectedIndex == 1),
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                setState(() {
                  _onItemDrawerTapped(1); // _selectedIndex = 1;
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
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
