import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guadalupereportadashboard/ui/authentication_screen.dart';

// For firebase support
import 'package:firebase_core/firebase_core.dart';
import 'package:guadalupereportadashboard/util/constants.dart';
import 'firebase/firebase_options.dart';

///  Main entry point
Future<void> main() async { 
  
  /// Tell Flutter not to start running the application widget 
  /// code until the Flutter framework is completely booted
  WidgetsFlutterBinding.ensureInitialized();

  /// Init the Firebase sdk
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Setup firebase emulators if debug mode
  if (kDebugMode) {
    logMsg('main', msg: 'Setting up firebase emulators');
    await setupDebugModeForFirebase();
  }

  //FirebaseDatabase.instance.setPersistenceEnabled(true);
  runApp(const AuthenticationScreen());
}

Future<void> setupDebugModeForFirebase() async {
  try {
    // Auth emulator
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // Firebase Storage emulator
    await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    // Realtime Database emulator
    FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
  } catch (e, stack) {
    logMsg('setupDebugModeForFirebase', msg: 'Error setting up Firebase emulators: $e\nStackTrace: $stack');
  }
}