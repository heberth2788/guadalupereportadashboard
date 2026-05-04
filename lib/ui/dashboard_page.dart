import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guadalupereportadashboard/data/report.dart';
import 'package:guadalupereportadashboard/ui/report_view_model.dart';
import 'package:guadalupereportadashboard/ui/shimmer_content.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:guadalupereportadashboard/util/util.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guadalupereportadashboard/util/report_status_enum.dart';
import 'package:guadalupereportadashboard/data/report_status.dart';
import 'package:guadalupereportadashboard/data/report_type.dart';
import 'loading_overlay.dart';

class DashboardPage extends StatefulWidget {

  final String _title;

  const DashboardPage({
    super.key,
    required String title,
  }): _title = title;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  /// Controller for the response text field
  final TextEditingController _responseTextController = TextEditingController();

  /// Show or hide the report cards (Report and Response)
  bool _showReportCards = false;

  /// To manage Google Maps state
  late GoogleMapController _gmController;
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
  Future<void> _onPressedDatePickerFrom(BuildContext context, DateTime dateFrom, Function(DateTime) onChangeDateFrom) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: getDateTimeAtStartOfDay(DateTime(startingYear)),
      lastDate: getDateTimeAtEndOfDay(DateTime.now()),
      initialDate: dateFrom,
    );
    if (dateTimePicket != null &&
        getDateFromDateTime(dateTimePicket) != getDateFromDateTime(dateFrom)
    ) {
      onChangeDateFrom(getDateTimeAtStartOfDay(dateTimePicket));
    }
  }

  /// To manage the Date filters state: To
  Future<void> _onPressedDatePickerTo(BuildContext context, DateTime dateTo, Function(DateTime) onChangeDateTo) async {
    final DateTime? dateTimePicket = await showDatePicker(
      context: context,
      firstDate: getDateTimeAtStartOfDay(DateTime(startingYear)),
      lastDate: getDateTimeAtEndOfDay(DateTime.now()),
      initialDate: dateTo,
    );
    if (dateTimePicket != null &&
        getDateFromDateTime(dateTimePicket) != getDateFromDateTime(dateTo)
    ) {
      onChangeDateTo(getDateTimeAtEndOfDay(dateTimePicket));
    }
  }

  /// Custom marker icons
  final Set<BitmapDescriptor> _markerIcons = { BitmapDescriptor.defaultMarker };

  /// Iterating the list of reports to create the markers of the map
  Set<Marker> _createMarkers(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _createMarkers');
    Map<String, Report> reportsMap = viewModel.reportMap;

    if (reportsMap.isEmpty) return { };

    return reportsMap.entries.map((report) {

      ReportStatusEnum reportStatus = ReportStatusEnum.findByCode(report.value.status);
      BitmapDescriptor markerIcon = _findPinIcon(reportStatus);

      return Marker(
        markerId: MarkerId(report.key),
        position: LatLng(
          report.value.lat,
          report.value.lon,
        ),
        icon: markerIcon,
        infoWindow: InfoWindow(
          title: '${ report.value.title} '
              '\n ${ getDatetimeFromTimestamp(report.value.creationTimestamp) } '
              '\n\n ${ reportStatus.description } ',
          snippet: '[ ${ report.value.userName} | Precisión : ${ report.value.acc.round()}m ]',
          //anchor: const Offset(5.0, 5.0),
          onTap: () {
            logMsg('dashboard_screen', msg: 'InfoWindow - onTab : ${ report.key }');
          },
        ),
        onTap: () => _onMarkerTap(report.key, viewModel),
      );
    }).toSet();
  }

  void _onMarkerTap(String reportId, ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_onMarkerTap - key: $reportId');

    if (viewModel.isLoading || viewModel.isSavingResponseData) return;

    viewModel.fetchReportData(reportId); // fire and forget

    setState(() {
      _showReportCards = true;
    });
  }

  BitmapDescriptor _findPinIcon(ReportStatusEnum reportStatus) {
    return switch(reportStatus) {
      ReportStatusEnum.created => _markerIcons.elementAt(0),
      ReportStatusEnum.inProgress => _markerIcons.elementAt(1),
      ReportStatusEnum.done => _markerIcons.elementAt(2),
      ReportStatusEnum.canceled => _markerIcons.elementAt(3),
    };
  }

  /// Load a custom pins as a marker icons
  Future<void> _loadCustomMarkers() async {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _loadCustomMarker');
    // Optimization: Don't reload if we already have the custom icon
    if (!_markerIcons.contains(BitmapDescriptor.defaultMarker)) return;

    try {
      // Ensure the widget is still mounted before proceeding with context-dependent calls
      if (!mounted) return;

      final ImageConfiguration imgConfig = createLocalImageConfiguration(context, size: markerSize);
      final List<AssetMapBitmap> pinIcons = await Future.wait([
        BitmapDescriptor.asset(imgConfig, createdPinAssetPath),
        BitmapDescriptor.asset(imgConfig, inProgressPinAssetPath),
        BitmapDescriptor.asset(imgConfig, donePinAssetPath),
        BitmapDescriptor.asset(imgConfig, canceledPinAssetPath),
      ]);

      _markerIcons.clear();
      _markerIcons.addAll(pinIcons);
    } catch (e, stackTrace) {
      logMsg('dashboard_screen', msg: '_DashboardPageState > _loadCustomMarker > error : ${ stackTrace.toString() }');
    }
  }

  /// Generate the widget of the photos of the selected report
  List<Widget> _generatePhotoWidgets(
      List<String> photosUrlList,
      { bool showRemoveButton = false,
        Future<void> Function(String)? deleteImage }
  ) {
    logMsg('dashboard_screen', msg: '_DashboardPageState > _generatePhotoWidgets: ${ photosUrlList.length }');

    List<Widget> listOfWidgets = [];
    int flexValue = photosUrlList.length;

    for (var photoUrlPivot in photosUrlList) {
      listOfWidgets.add(
          Expanded(
              flex: flexValue,
              child: Padding(
                  padding: const EdgeInsets.only(left: 1.0, right: 1.0),
                  child: Stack(
                      children: [
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
                              launchUrl(Uri.parse(photoUrlPivot));
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
                                  logMsg('dashboard_screen', msg: 'delete image button pressed $photoUrlPivot');
                                  deleteImage?.call(photoUrlPivot); // fire and forget
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
    logMsg('dashboard_screen', msg: '_cancelButtonPressed ${ viewModel.currentReport.id }');
    if (viewModel.currentReport.status == ReportStatusEnum.canceled.code) return;

    final String userId = viewModel.currentReport.userId;
    final String reportId = viewModel.currentReport.id;
    final String date = getDateFromTimestamp(viewModel.currentReport.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatusEnum.canceled); // fire and forget
  }

  /// InProgress = 1
  void _inProgressButtonPressed(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_inProgressButtonPressed ${ viewModel.currentReport.id }');
    if (viewModel.currentReport.status == ReportStatusEnum.inProgress.code) return;

    final String userId = viewModel.currentReport.userId;
    final String reportId = viewModel.currentReport.id;
    final String date = getDateFromTimestamp(viewModel.currentReport.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatusEnum.inProgress); // fire and forget
  }

  /// Done = 2
  void _doneButtonPressed(ReportViewModel viewModel) {
    logMsg('dashboard_screen', msg: '_doneButtonPressed ${ viewModel.currentReport.id }');
    if (viewModel.currentReport.status == ReportStatusEnum.done.code) return;

    final String userId = viewModel.currentReport.userId;
    final String reportId = viewModel.currentReport.id;
    final String date = getDateFromTimestamp(viewModel.currentReport.creationTimestamp);

    viewModel.updateReportStatus(userId, reportId, date, ReportStatusEnum.done); // fire and forget
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
    viewModel.uploadResponseImage(
      fileBytes,
      fileExtension,
    );
  }

  void _saveResponseButtonPressed(ReportViewModel viewModel) {
    final String message = _responseTextController.text.trim();
    if (message.isEmpty) return;

    viewModel.upsertAuthorityResponseMessage(message);
  }

  /// Called when this object is inserted into the tree.
  /// The framework will call this method exactly once
  /// for each [State] object it creates.
  @override
  void initState() {
    super.initState();

    // Delay execution until the first frame is rendered to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomMarkers(); // fire and forget
    });
  }

  @override
  void dispose() {
    _responseTextController.dispose();
    super.dispose();
  }

  /// Home dashboard widget building
  @override
  Widget build(BuildContext context) {
    // Provider implementation : Consumer
    return Consumer<ReportViewModel>(
        builder: (context, viewModel, child) {

          // Load reports into markers
          final Set<Marker> markers = _createMarkers(viewModel);
          // Set the response text field
          _responseTextController.text = viewModel.currentResponse.message.trim();

          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget._title),
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
                      markers: markers,
                      mapId: mapId,
                      initialCameraPosition: const CameraPosition(
                        target: latLngGuadalupe,
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
                // Right panel : filters, information cards
                SizedBox(
                  width: rightPanelWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Column(
                      children: [
                        // Filters : Date From, Date To
                        Card(
                          child: Padding(
                              padding: const EdgeInsets.all(9.0),
                              child: Column(
                                children: [
                                  // Date range:
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          strRange,
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              if (!viewModel.isLoading &&
                                                  !viewModel.isSavingResponseData
                                              ) {
                                                _onPressedDatePickerFrom(
                                                    context,
                                                    viewModel.dateFrom,
                                                    viewModel.onChangeDateFrom,
                                                );
                                              }
                                            } ,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(getDateFromDateTime(viewModel.dateFrom)),
                                                ),
                                              ],
                                            )),
                                      ),
                                      const Padding(padding: EdgeInsets.only(right: 9.0)),
                                      Expanded(
                                        flex: 4,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              if (!viewModel.isLoading &&
                                                  !viewModel.isSavingResponseData
                                              ) {
                                                _onPressedDatePickerTo(
                                                    context,
                                                    viewModel.dateTo,
                                                    viewModel.onChangeDateTo,
                                                );
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(getDateFromDateTime(viewModel.dateTo)),
                                                ),
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
                              children: [
                                // Type
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        viewModel.reportType.title,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 7,
                                      child:
                                      DropdownButton(
                                        isExpanded: true,
                                        value: viewModel.selectedType.name,
                                        onChanged: (viewModel.isLoading ||
                                          viewModel.isSavingResponseData) ? null : (String? newType) {
                                          viewModel.onChangeReportType(newType);
                                        },
                                        items: viewModel.reportType.values
                                          .map<DropdownMenuItem<String>>(
                                              (Type type) {
                                                return DropdownMenuItem(
                                                  value: type.name,
                                                  child: Text(
                                                    type.name,
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
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        viewModel.reportStatus.title,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 7,
                                      child: DropdownButton(
                                        isExpanded: true,
                                        value: viewModel.selectedStatus.name,
                                        onChanged: (viewModel.isLoading ||
                                          viewModel.isSavingResponseData) ? null : (String? newStatus) {
                                          viewModel.onChangeReportStatus(newStatus);
                                        },
                                        items: viewModel.reportStatus.values
                                            .map<DropdownMenuItem<String>>(
                                              (Status status) {
                                                return DropdownMenuItem(
                                                  value: status.name,
                                                  child: Text(
                                                    status.name,
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
                                                );
                                              }
                                            ).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Quantity of reports
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(9.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        strReportsQuantity,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 6,
                                      child: Text(
                                        viewModel.reportMap.length.toString(),
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Shimmer if full state is loading
                        if (viewModel.isLoading) ShimmerContent(width: rightPanelWidth),
                        // Selected user report card
                        Visibility(
                          visible: _showReportCards && !viewModel.isLoading,
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(9.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title of the report
                                  Text(
                                    style: reportTitleTextStyle,
                                    viewModel.currentReport.title,
                                    textAlign: TextAlign.start,
                                  ),
                                  const Padding(padding: EdgeInsets.only(top: 9.0)),
                                  // User name and Status of the report
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: Text(
                                          viewModel.currentReport.userName,
                                          style: reportUserAndDateTextStyle,
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          ReportStatusEnum.findByCode(viewModel.currentReport.status).description,
                                          style: reportStatusTextStyle,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Creation datetime and status datetime of the report
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: Text(
                                          getDatetimeFromTimestamp(viewModel.currentReport.creationTimestamp),
                                          style: reportUserAndDateTextStyle,
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          viewModel.currentReport.getStatusDateTime(),
                                          style: reportUserAndDateTextStyle,
                                          textAlign: TextAlign.end,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(padding: EdgeInsets.only(top: 6.0)),
                                  // Photos of the report
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: _generatePhotoWidgets(viewModel.currentReportPhotos),
                                  ),
                                  const Padding(padding: EdgeInsets.only(top: 9.0)),
                                  // Comment of the report
                                  Text(
                                    style: reportCommentTextStyle,
                                    viewModel.currentReport.description,
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Selected authority response card
                        Visibility(
                          visible: _showReportCards && !viewModel.isLoading,
                          child: LoadingOverlay(
                            isLoading: viewModel.isSavingResponseData,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(9.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title of the response and annular button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          style: reportTitleTextStyle,
                                          strResponse,
                                          textAlign: TextAlign.start,
                                        ),
                                        ElevatedButton(
                                          style: buttonStyle,
                                          onPressed: () => _cancelButtonPressed(viewModel),
                                          child: const Text(strCancel),
                                        ),
                                      ],
                                    ),
                                    const Padding(padding: EdgeInsets.only(top: 9.0)),
                                    // Photos of the response
                                    Stack(
                                        children: [
                                          const Padding(padding: EdgeInsets.only(top: 3.0)),
                                          Visibility(
                                              visible: true,
                                              child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: _generatePhotoWidgets(
                                                    viewModel.currentResponsePhotos,
                                                    showRemoveButton: true,
                                                    deleteImage: viewModel.deleteResponseImage,
                                                  )
                                              )
                                          ),
                                        ]
                                    ),
                                    const Padding(padding: EdgeInsets.only(top: 9.0)),
                                    // InProgress, Done and Photo buttons
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ElevatedButton(
                                            style: buttonStyle,
                                            onPressed: () => _inProgressButtonPressed(viewModel),
                                            child: const Text(strInProgress),
                                          ),
                                          const Padding(padding: EdgeInsets.only(right: 9.0)),
                                          ElevatedButton(
                                            style: buttonStyle,
                                            onPressed: () => _doneButtonPressed(viewModel),
                                            child: const Text(strDone),
                                          ),
                                          const Spacer(),
                                          ElevatedButton(
                                            style: buttonStyle,
                                            onPressed:
                                            viewModel.isMaxPhotosReached ?
                                                () => _uploadResponseImage(viewModel)
                                                : null,
                                            child: const Text(strPhoto),
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
                                        hintText: strHintTextWriteResponse,
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
                                            onPressed: () => _saveResponseButtonPressed(viewModel),
                                            child: const Text(strSave),
                                          ),
                                        ]
                                    ),
                                  ],
                                ),
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
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Column(children: [
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? '-',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                          ),
                        ),
                      ])),
                  ListTile(
                    selected: (_drawerSelectedIndex == 1),
                    leading: const Icon(Icons.logout),
                    title: const Text(strLogout),
                    onTap: () {
                      _onItemDrawerTapped(1);
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
