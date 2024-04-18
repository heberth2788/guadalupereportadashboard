import 'package:flutter/material.dart';
import 'package:guadalupereportadashboard/authentication_gate.dart';

// For firebase support
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';

///  Main entry point
void main() async { 
  
  /// Init the Firebase sdk
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Tell Flutter not to start running the application widget 
  /// code until the Flutter framework is completely booted
  WidgetsFlutterBinding.ensureInitialized();

  //FirebaseDatabase.instance.setPersistenceEnabled(true);
  runApp(const AuthenticationGate());
}