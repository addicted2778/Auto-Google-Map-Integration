# Auto-Google-Map-Integration

This Flutter project automatically add Google Map package in selected project.

Steps:-
  1. Run the project in Windows or Mac
  2. Select the project in which you want to add Google map package (Note: This should be a vaild flutter project, otherwise an error will shown)
  3. Input your Google Map API key
  4. That's all. Google Map sucessfully added in your target project.
  5. Add your widget to show Google Map in main.dart file in your target project.
  6. Run the target project.

Replace your main.dart file code with following code 
```
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
 runApp(const MyApp());
}

class MyApp extends StatelessWidget {
 const MyApp({super.key});

 @override
 Widget build(BuildContext context) {
  return MaterialApp(
   home: Scaffold(
    appBar: AppBar(title: Text('Google Maps Example')),
    body: GoogleMap(
     initialCameraPosition: CameraPosition(
      target: LatLng(37.7749, -122.4194), // Default: San Francisco
      zoom: 12,
     ),
    ),
   ),
  );
 }
}
```
