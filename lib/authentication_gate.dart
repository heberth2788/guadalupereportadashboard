import 'package:flutter/material.dart';

// `hide` keyword is for give acces everything from the library, except `EmailAuthCredential` class.
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:guadalupereportadashboard/dashboard.dart';

/// Entry main Widget to manage the login of the user and show the
/// dashboard page if success
class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Const for Material Theme
    const seedColor = Color.fromRGBO(60, 105, 27, 0);
    const appTitle = "Guadalupe Reporta Dashboard";

    // StreamBuilder is a widget that builds itself based on the latest `snapshot`
    // of data from a `Stream` that you pass it. It automatically rebuilds when the
    // Stream emits a new snapshot.
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      ),
      //initialRoute: ,
      //routes: ,
      home: StreamBuilder<User?>(
          // Listen to FirebaseAuth's authStateChanges: a Stream with either
          // the current user (if they are signed in), or null if they are not.
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshotAuthUser) {
            if (!snapshotAuthUser.hasData) {
              // `SigInscreen` widget from `FlutterFire UI` package, this allows
              // the users to sigin.
              return SignInScreen(
                providers: [
                  EmailAuthProvider(),
                ],
                showPasswordVisibilityToggle: true,
              );
            }
            // Only authenticated users can go to Dashboard
            return const Dashboard();
          }),
    );
  }
}
