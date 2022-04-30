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
    const initialSize = Size(550, 550);
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

  List<MenuItem>? _trayMenu;
  MenuItem? _invisibleItem;
  MenuItem? _visibleItem;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _initSystemTray();
  }

  void _hideWindow() {
    _appWindow.hide();
    _trayMenu![1] = _invisibleItem!;
    _visible = false;
    _systemTray.setContextMenu(_trayMenu!);
  }

  void _showWindow() {
    _appWindow.show();
    _trayMenu![1] = _visibleItem!;
    _visible = true;
    _systemTray.setContextMenu(_trayMenu!);
  }

  void _setLastUpdated(String date) {
    _trayMenu![0] = MenuItem(label: 'Last updated: $date', enabled: false);
  }

  Future<void> _initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    _visibleItem = MenuItem(label: 'Hide', onClicked: _hideWindow);
    _invisibleItem = MenuItem(label: 'Show', onClicked: _showWindow);

    _trayMenu = [
      MenuItem(label: 'Last updated: Never', enabled: false),
      _visibleItem!,
      MenuItem(label: 'Exit', onClicked: _appWindow.close),
    ];

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    await _systemTray.setContextMenu(_trayMenu!);

    // handle system tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == "leftMouseDown") {
        if (_visible) {
          _hideWindow();
        } else {
          _showWindow();
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
      home: Home(setLastUpdated: _setLastUpdated),
    );
  }
}
