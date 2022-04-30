import 'dart:io';

import 'package:dydns2_client/home.dart';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(600, 450);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "DynDNS Client";
    win.show();
  });
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

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  @override
  void initState() {
    super.initState();
    _initSystemTray();
  }

  Future<void> _initSystemTray() async {
    String path = Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    var menu = <MenuItem>[];
    MenuItem? invisibleItem;

    bool visible = true;

    final visibleItem = MenuItem(label: 'Hide', onClicked: () {
      _appWindow.hide();
      menu[0] = invisibleItem!;
      visible = false;
      _systemTray.setContextMenu(menu);
    });

    invisibleItem = MenuItem(label: 'Show', onClicked: () {
        _appWindow.show();
        menu[0] = visibleItem;
        visible = true;
        _systemTray.setContextMenu(menu);
    });

    menu = [
      visibleItem,
      MenuItem(label: 'Exit', onClicked: _appWindow.close),
    ];

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    await _systemTray.setContextMenu(menu);

    // handle system tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == "leftMouseDown") {
        if (visible) {
          _appWindow.hide();
          menu[0] = invisibleItem!;
          visible = false;
          _systemTray.setContextMenu(menu);
        } else {
          _appWindow.show();
          menu[0] = visibleItem;
          visible = true;
          _systemTray.setContextMenu(menu);
        }
      } else if (eventName == "rightMouseDown") {
        _systemTray.popUpContextMenu();
      }
    });
  }

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
