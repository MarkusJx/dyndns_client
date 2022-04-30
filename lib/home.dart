import 'package:dydns2_client/login.dart';
import 'package:dydns2_client/update.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final void Function(String date) setLastUpdated;

  const Home({Key? key, required this.setLastUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            child: const TabBar(
              indicatorColor: Colors.white,
              tabs: <Widget>[
                Tab(
                  icon: Icon(Icons.cloud_outlined),
                  text: "Update DNS",
                ),
                Tab(
                  icon: Icon(Icons.login),
                  text: "Login",
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
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
        body: TabBarView(
          children: <Widget>[
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400
                ),
                child: Update(setLastUpdated: setLastUpdated)
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400
                ),
                child: const Login(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
