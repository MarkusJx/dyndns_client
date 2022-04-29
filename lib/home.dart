import 'package:dydns2_client/login.dart';
import 'package:dydns2_client/update.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            child: const TabBar(
              indicatorColor: Colors.white,
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.cloud_outlined),
                ),
                Tab(
                  icon: Icon(Icons.beach_access_sharp),
                ),
                Tab(
                  icon: Icon(Icons.brightness_5_sharp),
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: HexColor.fromHex("#005096"),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                )
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(
              child: Update(),
            ),
            Center(
              child: Text("It's rainy here"),
            ),
            Center(
              child: Login(),
            )
          ],
        ),
      ),
    );
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
