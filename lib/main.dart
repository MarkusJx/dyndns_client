import 'package:dydns2_client/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

Map<int, Color> color = {
  50: const Color.fromRGBO(0, 80, 150, .1),
  100: const Color.fromRGBO(0, 80, 150, .1),
  200: const Color.fromRGBO(0, 80, 150, .3),
  300: const Color.fromRGBO(0, 80, 150, .4),
  400: const Color.fromRGBO(0, 80, 150, .5),
  500: const Color.fromRGBO(0, 80, 150, .6),
  600: const Color.fromRGBO(0, 80, 150, .7),
  700: const Color.fromRGBO(0, 80, 150, .8),
  800: const Color.fromRGBO(0, 80, 150, .9),
  900: const Color.fromRGBO(0, 80, 150, 1),
};

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DynDNS Client',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF005096, color),
      ),
      home: const Home()
    );
  }
}
