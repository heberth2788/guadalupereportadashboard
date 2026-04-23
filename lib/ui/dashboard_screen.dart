import 'package:flutter/material.dart';
import 'package:guadalupereportadashboard/ui/report_view_model.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';

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