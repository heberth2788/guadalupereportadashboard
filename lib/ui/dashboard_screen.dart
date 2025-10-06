import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/ui/report_view_model.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

// For firebase support
/* import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart'; */

class DashboardScreen extends StatelessWidget {

  const DashboardScreen({ super.key });

  @override
  Widget build(BuildContext context) {
    // Provider implementation : ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (context) => ReportViewModel(),
      child: const DashboardPage(title: appTitle),
    );
  }
}

// Dashboard page
class DashboardPage extends StatefulWidget {

  final String _title;

  const DashboardPage({ super.key, required String title }) : _title = title;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

/// State of the Dashboard page
class _DashboardPageState extends State<DashboardPage> {

  /// The report that is selected on the map
  Report? _selectedReport;
  bool _visibilityReportCard = false;
  bool _visibilityPhotos = false;

  /// To manage Google Maps state
  late GoogleMapController _gmController;
  // Plaza de armas de Guadalupe : -7.243271, -79.470281
  //final LatLng _latLonCenter = const LatLng(-7.243271, -79.470281);
  void _onMapCreated(GoogleMapController controller) {
    _gmController = controller;
  }

  /// To manage the Drawer state
  int _drawerSelectedIndex = 0;
  void _onItemDrawerTapped(int index) {
    setState(() {
      _drawerSelectedIndex = index;
    });
  }

  /// To manage the Date filters state: From
  DateTime _selectedDateFrom = DateTime.now().subtract(const Duration(days: rangeDays));
  
  Future<void> _onPressedDatePickerFrom(BuildContext context) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: DateTime(startingYear),
      lastDate: DateTime.now(), //DateTime(2999),
      initialDate: _selectedDateFrom,
    );
    if (dateTimePicket != null && dateTimePicket != _selectedDateFrom) {
      setState(() {
        _selectedDateFrom = dateTimePicket;
        print('_DashboardPageState > _onPressedDatePickerFrom : $_selectedDateFrom');
        
      });
    }
  }

  /// To manage the Date filters state: To
  DateTime _selectedDateTo = DateTime.now();
  Future<void> _onPressedDatePickerTo(BuildContext context) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: DateTime(startingYear),
      lastDate: DateTime.now(),
      initialDate: _selectedDateTo,
    );
    if (dateTimePicket != null && dateTimePicket != _selectedDateTo) {
      setState(() {
        _selectedDateTo = dateTimePicket;
        print('_DashboardPageState > _onPressedDatePickerTo : $_selectedDateTo');
      });
    }
  }

  /// To manage Report's Type dropdown button list
  static const List<String> _reportTypeList = <String>[
    'All',
    'Pista o vereda en mal estado',
    'Basura y/o desmonte en la calle',
    'Arbol por podar',
    'Infraestructura o pared peligrosa',
    'Abandono o maltrato animal',
    'Buzón peligroso',
  ];
  String _selectedReportType = _reportTypeList.first;
  void _onChangeReportType(String? newReportType) {
    if (newReportType != null) {
      setState(() {
        _selectedReportType = newReportType;
      });
    }
  }

  /// To manage Report's Status dropdown button list
  static const List<String> _reportStatusList = <String>[
    'All',
    'To Check',
    'In Progress',
    'Done',
    '* Inappropriate',
  ];
  String _selectedReportStatus = _reportStatusList.first;
  void _onChangeReportStatus(String? newReportStatus) {
    if (newReportStatus != null) {
      setState(() {
        _selectedReportStatus = newReportStatus;
      });
    }
  }

  /// To storage the markers(of each report) on the map
  final Set<Marker> _markers = {};

  /// Custom marker icon
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  // Iterating the list of reports to create the markers of the map
  void _updateMarkers(ReportViewModel reportViewModel) {
    print('_DashboardPageState > _updateMarkers');
    Map<String, Report> reportsMap = reportViewModel.reportMap;
    if (reportsMap.isNotEmpty) {
      Marker markerPivot;
      //markers = {};
      //print('Reports quantity : ${ reportsMap.length }');
      for (var report in reportsMap.entries) {
        markerPivot = Marker(
          markerId: MarkerId(report.key),
          position: LatLng(
            report.value.lat ?? 0.0,
            report.value.lon ?? 0.0,
          ),
          icon: _markerIcon, //BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title:
                '${report.value.title ?? ''} \n ${getDatetimeFromTimestamp(report.value.creationTimestamp)}',
            snippet:
                '[ ${report.value.userName ?? ''} | Accuracy : ${report.value.acc?.round() ?? 0}m ]',
            //anchor: const Offset(5.0, 5.0),
            onTap: () {
              print('InfoWindow - onTab : ${report.key}');
            },
          ),
          onTap: () {
            print('Marker - onTab : ${report.key}');

            // Get the photos of the selected report
            reportViewModel.getPhotos(report.value.userId ?? '', report.key);

            // Update the selected report
            Report pivotReport = Report(report.key);
            pivotReport.acc = report.value.acc;
            pivotReport.alt = report.value.alt;
            pivotReport.creationTimestamp = report.value.creationTimestamp;
            pivotReport.description = report.value.description;
            pivotReport.doneTimestamp = report.value.doneTimestamp;
            pivotReport.inProgressTimestamp = report.value.inProgressTimestamp;
            pivotReport.lat = report.value.lat;
            pivotReport.lon = report.value.lon;
            pivotReport.status = report.value.status;
            pivotReport.title = report.value.title;
            pivotReport.userId = report.value.userId;
            pivotReport.userName = report.value.userName;
            pivotReport.visible = report.value.visible;

            setState(() {
              _selectedReport = pivotReport;
              _visibilityReportCard = true;
              _visibilityPhotos = false;  
            });
          },
        );
        _markers.add(markerPivot);
      }
    }
  }

  /// Load a custom pin as a marker icon
  void _loadCustomMarker() {
    print('_DashboardPageState > _loadCustomMarker');
    BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: markerSize),
      'images/pins/pin_red.png',
    ).then((BitmapDescriptor icon) {
      setState(() {
        _markerIcon = icon;
      });
    });
  }

  /// Generate the widget of the photos of the selected report
  List<Widget> _generatePhotoWidgets(List<String> photosUrlList) {
    print('_DashboardPageState > _generatePhotoWidgets');
    List<Widget> listOfWidgets = [];
    int flexValue = photosUrlList.length;
    for (var photoUrlPivot in photosUrlList) {
      listOfWidgets.add(
          Expanded(
              flex: flexValue,
              child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: Stack(children: <Widget>[
                    // Support for url links
                    InkWell(
                      child: Center(
                        child: FadeInImage.memoryNetwork(
                            placeholder: kTransparentImage,
                            image: photoUrlPivot.toString())),
                      onTap: () {
                        launchUrl(Uri.parse(photoUrlPivot.toString()));
                      }), // Open url on the browser when click
                      //onTap: () => launchUrlString(photoUrlPivot.toString()), // Open url on the browser when click
                    //),
                  ]))));
    }
    //setState(() {
    _visibilityPhotos = true;  
    //});
    return listOfWidgets;
  }

  // Button pressed events
  // [START button_events]
  void _generalReportButtonPressed() {
    print('generalReportButtonPressed');
  }

  void _performanceReportButtonPressed() {
    print('performanceReportButtonPressed');
  }

  void _inappropriateButtonPressed() {
    print('inappropriateButtonPressed');
  }

  void _workOrderButtonPressed() {
    print('workOrderButtonPressed');
  }

  void _inProgressButtonPressed() {
    print('inProgressButtonPressed');
  }
  // [END button_events]

  /// Called when this object is inserted into the tree.
  /// The framework will call this method exactly once
  /// for each [State] object it creates.
  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
  }

  /// Home dashboard widget building
  @override
  Widget build(BuildContext context) {
    // Provider implementation : Consumer
    return Consumer<ReportViewModel>(
        builder: (context, reportViewModel, child) {
      // Load reports into markers
      _updateMarkers(reportViewModel);

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget
                    ._title, // A [State] object's configuration is the corresponding [StatefulWidget] instance(_title)
              ),
            ],
          ),
          foregroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Row(
          children: <Widget>[
            // Google map Widget
            Expanded(
              flex: 8,
              child: GoogleMap(
                //mapType: MapType.normal,
                myLocationEnabled: true,
                initialCameraPosition: const CameraPosition(
                    target: latLonGuadalupe, zoom: zoomMapValue),
                onMapCreated: _onMapCreated,
                markers: _markers,
              ),
            ),
            // Right panel : filters, reports generation, information
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(13.0),
                child: Column(
                  children: <Widget>[
                    // Filters : Date From, Date To
                    Card(
                      child: Padding(
                          padding: const EdgeInsets.all(9.0),
                          child: Column(
                            children: <Widget>[
                              // Date from:
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
                                              child: Text(DateFormat(
                                                      'dd/MM/yyyy')
                                                  .format(_selectedDateFrom)),
                                            ),
                                            const Icon(Icons.date_range),
                                          ],
                                        )),
                                  ),
                                ],
                              ),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                              // Date to:
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
                                              child: Text(
                                                  DateFormat('dd/MM/yyyy')
                                                      .format(_selectedDateTo)),
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
                    // Filters : Type and Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(9.0),
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
                                  child: /* Text('Dropdown button'), */
                                      DropdownButton(
                                    isExpanded: true,
                                    value: _selectedReportType,
                                    onChanged: (String? value) {
                                      _onChangeReportType(value);
                                    },
                                    items: _reportTypeList
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
                                  child: /* Text('Dropdown button') */
                                      DropdownButton(
                                    isExpanded: true,
                                    value: _selectedReportStatus,
                                    onChanged: (String? value) {
                                      _onChangeReportStatus(value);
                                    },
                                    items: _reportStatusList
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
                    ),
                    // Padding
                    const Padding(padding: EdgeInsets.only(top: 9.0)),
                    // Button : Generate report
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                              style: buttonStyle,
                              onPressed: _generalReportButtonPressed,
                              child: const Text('General report')),
                        ),
                      ],
                    ),
                    // Padding
                    const Padding(padding: EdgeInsets.only(top: 9.0)),
                    // Button : performance report
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                              style: buttonStyle,
                              onPressed: _performanceReportButtonPressed,
                              child: const Text('Performance report')),
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.only(top: 9.0)),
                    // Report selected's information
                    Visibility(
                      visible: _visibilityReportCard,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(9.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Title of the report
                              Text(
                                style: reportTitleTextStyle,
                                _selectedReport?.title ?? '-',
                                textAlign: TextAlign.start,
                              ),
                              const Padding(padding: EdgeInsets.only(top: 9.0)),
                              // User name and Status of the report
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 7,
                                    child: Text(
                                      style: reportUserAndDateTextStyle,
                                      _selectedReport?.userName ?? '-',
                                      textAlign: TextAlign.start,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      style: reportStatusTextStyle,
                                      getStringStatus(_selectedReport?.status),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              // Creation datetime of the report
                              Text(
                                style: reportUserAndDateTextStyle,
                                getDatetimeFromTimestamp(
                                    _selectedReport?.creationTimestamp),
                                textAlign: TextAlign.end,
                              ),
                              const Padding(padding: EdgeInsets.only(top: 6.0)),
                              // Comment of the report
                              Text(
                                style: reportCommentTextStyle,
                                _selectedReport?.description ?? '-',
                                textAlign: TextAlign.start,
                              ),
                              const Padding(padding: EdgeInsets.only(top: 9.0)),
                              // Photos of the report
                              Stack(
                                children: <Widget>[
                                  const Padding(padding: EdgeInsets.only(top: 3.0), child: Center(child: CircularProgressIndicator())),
                                  Visibility(
                                    visible: _visibilityPhotos,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: _generatePhotoWidgets(reportViewModel.currentReportPhotos)
                                    )
                                  ),
                                ]
                              ),
                              const Padding(padding: EdgeInsets.only(top: 9.0)),
                              // InProgress button
                              Row(children: <Widget>[
                                Expanded(
                                    child: ElevatedButton(
                                        style: buttonStyle,
                                        onPressed: _inProgressButtonPressed,
                                        child: const Text('InProgress'))),
                              ]),
                              const Padding(padding: EdgeInsets.only(top: 9.0)),
                              // Inappropiate and WorkOrder buttons
                              Row(
                                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Expanded(
                                        flex: 5,
                                        child: ElevatedButton(
                                            style: buttonStyle,
                                            onPressed:
                                                _inappropriateButtonPressed,
                                            child: const Text('Inappropiate'))),
                                    const Spacer(),
                                    Expanded(
                                        flex: 5,
                                        child: ElevatedButton(
                                            style: buttonStyle,
                                            onPressed: _workOrderButtonPressed,
                                            child: const Text('Create WO'))),
                                  ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Navigation drawer
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(children: <Widget>[
                    Text(
                      FirebaseAuth.instance.currentUser?.email ?? '-',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                      ),
                    ),
                  ])),
              /* ListTile(
                  selected: (_drawerSelectedIndex == 0),
                  leading: const Icon(Icons.account_circle),
                  title: const Text('Account'),
                  onTap: () {
                    setState(() {
                      _onItemDrawerTapped(0);
                    });
                    Navigator.pop(context);
                  },
                ), */
              ListTile(
                selected: (_drawerSelectedIndex == 1),
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  //setState(() {
                    _onItemDrawerTapped(1);
                  //});
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                  SignedOutAction((context) {
                    Navigator.of(context).pop();
                  });
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}

