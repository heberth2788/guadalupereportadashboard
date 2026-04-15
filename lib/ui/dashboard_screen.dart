import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/ui/report_view_model.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Controller for the response text field
  final TextEditingController _responseTextController = TextEditingController();

  /// The report that is selected on the map
  Report? _selectedReport;
  bool _showReportCards = false;

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
        logMsg('_DashboardPageState',  msg: '_onPressedDatePickerFrom > $_selectedDateFrom');
        
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
        logMsg('dashboard_screen', msg: '_DashboardPageState > _onPressedDatePickerTo : $_selectedDateTo');
      });
    }
  }

  /// To manage Report's Type dropdown button list
  static const List<String> _reportTypeList = <String>[
    'Todo',
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
    'Todo',
    'Reportado',
    'En progreso',
    'Atendido',
    'Anulado',
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
  final Set<Marker> _markers = { };

  /// Custom marker icon
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  // Iterating the list of reports to create the markers of the map
  void _updateMarkers(ReportViewModel reportViewModel) {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _updateMarkers');
    Map<String, Report> reportsMap = reportViewModel.reportMap;

    /*if (_selectedReport != null && reportsMap.containsKey(_selectedReport?.id)) {
      String id = _selectedReport?.id ?? '';
      _selectedReport = reportsMap[id];
    }*/

    // Clear existing markers to handle deletions and avoid duplicates
    _markers.clear();

    if (reportsMap.isNotEmpty) {
      Marker markerPivot;
      //markers = {};
      for (MapEntry<String, Report> report in reportsMap.entries) {
        markerPivot = Marker(
          markerId: MarkerId(report.key),
          position: LatLng(
            report.value.lat,
            report.value.lon,
          ),
          icon: _markerIcon, //BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: '${ report.value.title} '
                    '\n ${ getDatetimeFromTimestamp(report.value.creationTimestamp) } '
                    '\n ${ ReportStatus.findByCode(report.value.status).description } ',
            snippet: '[ ${ report.value.userName} | Precisión : ${ report.value.acc.round()}m ]',
            //anchor: const Offset(5.0, 5.0),
            onTap: () {
              logMsg('dashboard_screen', msg: 'InfoWindow - onTab : ${ report.key }');
            },
          ),
          onTap: () {
            logMsg('dashboard_screen', msg: 'Marker - onTab : ${ report.key } '
                ', ${ ReportStatus.findByCode(report.value.status).description }');

            // Get the photos of the selected report
            reportViewModel.getPhotos(report.value.userId, report.key);

            logMsg('dashboard_screen', msg: report.value.toString());

            setState(() {
              _selectedReport = report.value;
              _showReportCards = true;
            });
          },
        );
        _markers.add(markerPivot);
      }
    }
  }

  /// Load a custom pin as a marker icon
  Future<void> _loadCustomMarker() async {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _loadCustomMarker');
    try {
      final ImageConfiguration imgConfig = createLocalImageConfiguration(context, size: markerSize);
      final BitmapDescriptor icon = await BitmapDescriptor.asset(imgConfig, redPinAssetPath);
      if (mounted) {
        setState(() {
          _markerIcon = icon;
        });
      }
    } catch(e) { // TODO: this catch body is always executed, why?
      logMsg('dashboard_screen', msg: '_DashboardPageState > _loadCustomMarker > error : $e');
    }
  }

  /// Generate the widget of the photos of the selected report
  List<Widget> _generatePhotoWidgets(
      List<String> photosUrlList,
      { bool showRemoveButton = false }
  ) {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _generatePhotoWidgets');
    List<Widget> listOfWidgets = [];
    int flexValue = photosUrlList.length;

    for (var photoUrlPivot in photosUrlList) {
      listOfWidgets.add(
          Expanded(
              flex: flexValue,
              child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: Stack(
                    children: <Widget>[
                      // Support for url links: Open url on the browser when click
                      InkWell(
                        child: Center(
                          child: FadeInImage.memoryNetwork(
                              placeholder: kTransparentImage,
                              image: photoUrlPivot.toString(),
                              height: 150.0,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              fadeInCurve: Curves.easeIn,
                          )
                        ),
                        onTap: () {
                          launchUrl(Uri.parse(photoUrlPivot.toString()));
                        }
                      ),
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: showRemoveButton ? Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () {
                              logMsg('dashboard_screen', msg: 'delete image button pressed ${ photoUrlPivot.toString() }');
                            }
                          ),
                        ) : Container(),
                      )
                    ]
                  )
                )
            )
        );
    }

    return listOfWidgets;
  }

  /// Canceled = 666
  void _cancelButtonPressed(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_cancelButtonPressed ${ _selectedReport?.id }');
    if (_selectedReport?.status == ReportStatus.canceled.code || !_isSelectedReportOk()) {
      logMsg('dashboard_screen', msg: 'A');
      return;
    }
    logMsg('dashboard_screen', msg: 'B');

    final String userId = _selectedReport!.userId;
    final String reportId = _selectedReport!.id;
    final String date = getDateFromTimestamp(_selectedReport!.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatus.canceled); // fire and forget
  }

  /// InProgress = 1
  void _inProgressButtonPressed(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_inProgressButtonPressed ${ _selectedReport?.id }');
    if (_selectedReport?.status == ReportStatus.inProgress.code || !_isSelectedReportOk()) {
      logMsg('dashboard_screen', msg: 'A');
      return;
    }
    logMsg('dashboard_screen', msg: 'B');

    final String userId = _selectedReport!.userId;
    final String reportId = _selectedReport!.id;
    final String date = getDateFromTimestamp(_selectedReport!.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatus.inProgress); // fire and forget
  }

  /// Done = 2
  void _doneButtonPressed(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_doneButtonPressed ${ _selectedReport?.id }');
    if (_selectedReport?.status == ReportStatus.done.code || !_isSelectedReportOk()) {
      logMsg('dashboard_screen', msg: 'A');
      return;
    }
    logMsg('dashboard_screen', msg: 'B');

    final String userId = _selectedReport!.userId;
    final String reportId = _selectedReport!.id;
    final String date = getDateFromTimestamp(_selectedReport!.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatus.done); // fire and forget
  }

  bool _isSelectedReportOk() {
    return _selectedReport != null
        && _selectedReport?.userId != null
        && _selectedReport?.creationTimestamp != null;
  }
  
  Future<void> _uploadResponseImage(ReportViewModel viewModel) async {
    logMsg('_DashboardPageState', msg: '_uploadResponseImage');

    // Use image picker to select an image from local storage
    final FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (filePickerResult == null || filePickerResult.files.isEmpty) {
      logMsg('_DashboardPageState', msg: '_uploadResponseImage > User canceled the picker');
      return;
    }

    final Uint8List? fileBytes = filePickerResult.files.first.bytes;
    final String? fileExtension = filePickerResult.files.first.extension;
    if (fileBytes == null || fileExtension == null) {
      logMsg('_DashboardPageState', msg: '_uploadResponseImage > No file bytes or file extention');
      return;
    }

    // Upload the image to firebase storage
    if (_selectedReport == null) {
      logMsg('_DashboardPageState', msg: '_uploadResponseImage > No report selected');
      return;
    }
    viewModel.uploadResponseImage(fileBytes, fileExtension, _selectedReport!.userId, _selectedReport!.id);
  }

  /// Called when this object is inserted into the tree.
  /// The framework will call this method exactly once
  /// for each [State] object it creates.
  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // fire and forget
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
                  widget._title, // A [State] object's configuration is the corresponding [StatefulWidget] instance(_title)
                ),
              ],
            ),
            foregroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: Row(
            children: [
              // Left panel: Google map Widget
              Expanded(
                child: PointerInterceptor(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    markers: _markers,
                    initialCameraPosition: const CameraPosition(
                      target: latLonGuadalupe,
                      zoom: zoomMapValue,
                    ),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onMapCreated: _onMapCreated,
                  ),
                ),
              ),
              // Divider
              const VerticalDivider(width: 1, thickness: 1),
              // Right panel : filters, information
              SizedBox(
                width: 500,
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Column(
                    children: [
                      // Filters : Date From, Date To
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(9.0),
                          child: Column(
                            children: <Widget>[
                              // Date range:
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                        'Fechas :',
                                        style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: ElevatedButton(
                                        onPressed: () => _onPressedDatePickerFrom(context),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(DateFormat('dd/MM/yyyy')
                                                  .format(_selectedDateFrom)),
                                            ),
                                            //const Icon(Icons.date_range),
                                          ],
                                        )),
                                  ),
                                  const Padding(padding: EdgeInsets.only(right: 9.0)),
                                  Expanded(
                                    flex: 4,
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
                                          //const Icon(Icons.date_range),
                                        ],
                                      )
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ),
                      ),
                      // Filters : Type and Status
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(9.0),
                          child: Column(
                            children: <Widget>[
                              // Type
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                        'Tipo :',
                                        style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 7,
                                    child:
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
                                                child: Text(
                                                    value,
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                ),
                                              );
                                            }
                                          ).toList(),
                                      ),
                                  ),
                                ],
                              ),
                              // Status
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                        'Estado : ',
                                        style: Theme.of(context).textTheme.titleSmall,
                                    ),
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
                                          child: Text(
                                              value,
                                              style: Theme.of(context).textTheme.labelLarge,
                                          ),
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
                      // Selected user report card
                      Visibility(
                        visible: _showReportCards,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title of the report
                                Text(
                                  style: reportTitleTextStyle,
                                  _selectedReport?.title ?? '-',
                                  textAlign: TextAlign.start,
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // User name and Status of the report
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: Text(
                                        _selectedReport?.userName ?? '-',
                                        style: reportUserAndDateTextStyle,
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        ReportStatus.findByCode(_selectedReport?.status).description,
                                        style: reportStatusTextStyle,
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
                                // Photos of the report
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: _generatePhotoWidgets(reportViewModel.currentReportPhotos),
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // Comment of the report
                                Text(
                                  style: reportCommentTextStyle,
                                  _selectedReport?.description ?? '-',
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Selected authority response card
                      Visibility(
                        visible: _showReportCards,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget> [
                                // Title of the response and annular button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      style: reportTitleTextStyle,
                                      'Respuesta',
                                      textAlign: TextAlign.start,
                                    ),
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed: () => _cancelButtonPressed(Provider.of<ReportViewModel>(context, listen: false)),
                                      child: const Text('Anular'),
                                    ),
                                  ],
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // Photos of the response
                                Stack(
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.only(top: 3.0),
                                      //child: Center(child: CircularProgressIndicator()),
                                    ),
                                    Visibility(
                                      visible: true,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: _generatePhotoWidgets(reportViewModel.currentResponsePhotos, showRemoveButton: true)
                                      )
                                    ),
                                  ]
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // Upload image progress indicator
                                Visibility(
                                  visible: !reportViewModel.isImageUploadProcessFinished,
                                  child: LinearProgressIndicator(
                                    value: reportViewModel.isImageUploadProcessFinished ? 1.0 : null,
                                    backgroundColor: Colors.grey,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      reportViewModel.isImageUploadProcessFinished ? Colors.green : Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // InProgress, Done and Photo buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed: () => _inProgressButtonPressed(Provider.of<ReportViewModel>(context, listen: false)),
                                      child: const Text('En progreso'),
                                    ),
                                    const Padding(padding: EdgeInsets.only(right: 9.0)),
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed: () => _doneButtonPressed(Provider.of<ReportViewModel>(context, listen: false)),
                                      child: const Text('Atendido'),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed:
                                      reportViewModel.isMaxPhotosReached ?
                                          () => _uploadResponseImage(Provider.of<ReportViewModel>(context, listen: false))
                                          : null,
                                      child: const Text('Foto'),
                                    ),
                                  ]
                                ),
                                const Padding(padding: EdgeInsets.only(top: 9.0)),
                                // Text field for the response
                                TextField(
                                  controller: _responseTextController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Escribir respuesta...',
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                                  autofocus: true,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                  showCursor: true,
                                  maxLength: 200,
                                ),
                                const Padding(padding: EdgeInsets.only(top: 6.0)),
                                // Save button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      style: buttonStyle,
                                      onPressed: () { logMsg("dashboard_screen", msg: "Guardar"); },
                                      child: const Text('Guardar'),
                                    ),
                                  ]
                                ),
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
      }
    );
  }
}

