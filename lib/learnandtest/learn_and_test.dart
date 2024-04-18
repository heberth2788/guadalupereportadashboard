
/// IMPORTANT CONCEPTS
/// 
/// 1. Everything is and object: (Object class)
///    Everything you can place in a variable is an object, and every object is an instance of a class. 
///    Even numbers, functions, and null are objects.
/// 
/// 2. Dart can infer type.
/// 
/// 3. Dart is null safety:
///    Variables can't contain null unless you say they can, you can make a variable nullable by putting a 
///    question mark (?) at the end of its type.
/// 
/// 4. Object is a supper class of all the classes:
///     When you want to explicitly say that any type is allowed, use the `Object` type.
/// 
/// 5. Dart support generic types:
///    Like List<int> or List<Object> 
/// 
/// 6. Dart supports top-level functions and nested or local functions.
/// 
/// 7. Dart supports top-level variables.
/// 
/// 8. Dart doesn't have the keywords public, protected, and private. (Unlike Java)
/// 
/// 9. Identifiers can start with a letter or underscore (_)
/// 
/// 10. Dart has both expressions (which have runtime values) and statements (which don't).
/// 
/// 11. Dart tools can report two kinds of problems: warnings and errors.
/// 
/// Dart data types: 
/// 
///   int, double       : Numbers
///   String            : Strings
///   bool              : Boolean
///   
///   (value1, value2)  : Records
/// 
///   List              : Lists also known as arrays
///   Set               : Sets
///   Map               : Maps
/// 
///   Runes             : Runes, often replaced by characters API. expose the Unicode code points of a string. E.g: \u2665
///   Symbol            : Symbols. You might never need to use symbols, but they're invaluable for APIs that refer to 
///                       identifiers by name, because minification changes identifier names but not identifier symbols. E.g: #radix
///   
///   Null              : null value
/// 
/// Dart modifiers:
///   
///   var
///   const             : Known at compile time
/// 
///   final             : known at runtime (Similar to `val` on Kotlin)
/// 
///   void
/// 
library;

// Imports -----------------------------------------------------------------------------------------
// To import libraries
// E.g: import 'path/to/my_other_file.dart';
import 'dart:io';


// void main() {
//   print('Heberth Dart & Flutter world. \nBy HD.');
// }

void dartTesting() {

  // Type inference -----------------------------------------------------------------------------------------
  var name = 'Heberth Deza'; // String
  var year = 1988; // int
  var antennaDiameter = 3.7; // double
  var flyByObjects = ['Jupoiter', 'Saturn', 'Uranus', 'Neptune']; // List<String>
  var image = {
    'tags' : ['saturn'],
    'url' : '//path/to/saturn.jpg'
  }; // Map<String, Object>

  // Control flow statements -----------------------------------------------------------------------------------------
  // if, for, for-in, while, switch-case, break, continue, assert.

  // Functions : (nested function) -----------------------------------------------------------------------------------------
  int fibonacci(int n) {
    if(n == 0 || n == 1) {
      return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
  void voidFunction() {
    print('voidFunction');
  }

  // Using shorhand sintaxt for anonymous functions : => Arrow
  //flyByObjects.where((element) => element.contains('turn')).forEach((element) { print(element); });
  flyByObjects.where((element) => element.contains('turn')).forEach(print);

  // Comments -----------------------------------------------------------------------------------------
      // This is a normal, one-line comment.

      /// This is a documentation comment, used to document libraries,
      /// classes, and their members. Tools like IDEs and dartdoc treat
      /// doc comments specially.

      /* Comments like these are also supported. */

  // Objects -----------------------------------------------------------------------------------------
  var voyager = Spacecraft('Voyager I', DateTime(1977, 9, 5));
  voyager.describe();

  var voyager3 = Spacecraft.unlaunched('Voyager III');
  voyager3.describe();

  const yourPlanet = Planet.earth;
  if(!yourPlanet.isGiant) {
      print('Your plannet is not a "giant planet"');
  }


}

// Classes -----------------------------------------------------------------------------------------
// In Dart does not exist private, public or private
class Spacecraft {
  
  // Attributes -----------------------------------------------------------------------------------------
  String name;
  DateTime? launchDate;
  // Read-only non-final property
  int? get launchYear => launchDate?.year;

  // Constructor -----------------------------------------------------------------------------------------
  Spacecraft(this.name, this.launchDate) {
    // Initialization code
  }

  // Constructor alternative: named constructor
  Spacecraft.unlaunched(String name) : this(name, null);

  // Methods -----------------------------------------------------------------------------------------
  void describe() {
    print('Spacecraft : $name');
    var launchDate = this.launchDate;
    if(launchDate != null) {
      int years = DateTime.now().difference(launchDate).inDays;
      print('Launched : $launchYear ($years years ago)');
    } else {
      print('Unlaunched');
    }
  }
}

// Enum -----------------------------------------------------------------------------------------
enum PlanetType {
  terrestrial, gas, ice;
}
enum Planet {

  // Enum values: separated by commas
  mercury(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  venus(planetType: PlanetType.terrestrial, moons: 0, hasRings: false),
  uranus(planetType: PlanetType.ice, moons: 27, hasRings: true),
  earth(planetType: PlanetType.terrestrial, moons: 1, hasRings: false),
  neptune(planetType: PlanetType.ice, moons: 14, hasRings: true);

  // A constant generating constructor
  const Planet(
    {
      required this.planetType, 
      required this.moons, 
      required this.hasRings
      }
  );

  // All instance variables are final
  final PlanetType planetType;
  final int moons;
  final bool hasRings;

  // Enhance enums support getters and other methods
  bool get isGiant => (planetType == PlanetType.gas || planetType == PlanetType.ice);
}

// Inheritance -----------------------------------------------------------------------------------------
// Dart support single inheritance
class Orbiter extends Spacecraft {
  double altitude;

  Orbiter(super.name, DateTime super.launchDate, this.altitude);
}

// Mixins -----------------------------------------------------------------------------------------
// A way of reusing code in multiple class hierarchies
mixin Piloted {
  int astronauts = 1;

  void describeCrew() {
    print('Number of astronatus : $astronauts');
  }
}
// Adding mixin's capabilities to the class : using the 'with' keyword
class PilotedCraft extends Spacecraft with Piloted { 

  PilotedCraft(super.name, super.launchDate);
}

// Interfaces -----------------------------------------------------------------------------------------
class MockSapaceship implements Spacecraft {
  @override
  DateTime? launchDate;

  @override
  String name;

  MockSapaceship(this.name);

  @override
  void describe() {
    // TODO: implement describe
  }

  @override
  // TODO: implement launchYear
  int? get launchYear => throw UnimplementedError();
}

// Abstract classes -----------------------------------------------------------------------------------------
abstract class Describable {
  void describe();
  void describeWithEmphasis() {
    print('=========');
    describe();
    print('=========');
  }
}

// Async and Await -----------------------------------------------------------------------------------------
// Avoid callback hell and make your code much more readable by using `async` and `await`.
const oneSecont = Duration(seconds: 1);
Future<void> printWithDelay(String msg) async {
  await Future.delayed(oneSecont);
  print(msg);
}

// Exceptions -----------------------------------------------------------------------------------------
// throw, try, on-catch, finally
void testThrow(int astronauts) {
  if(astronauts == 0) {
    throw StateError('No astronauts');
  }
}
Future<void> describeFlybyObjects(List<String> flybyObjects) async {
  try {
    for(final object in flybyObjects) {
      var description = await File('$object.txt').readAsString();
      print(description);
    }
  } on IOException catch(e) {
    print('Could not describe object : $e');
  } finally {
    flybyObjects.clear();
  }
}





