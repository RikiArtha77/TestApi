import 'package:flutter/material.dart';
import 'package:tesapi/UI/pagePetani.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Pagination',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PagePetani(),
    );
  }
}
