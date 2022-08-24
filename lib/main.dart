import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dyndns_client/home.dart';
import 'package:flutter/material.dart' hide MenuItem;
import 'package:system_tray/system_tray.dart';

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

  Future<void> _hideWindow() async {
    _appWindow.hide();
    _trayMenu![1] = _invisibleItem!;
    _visible = false;
    final Menu menu = Menu();
    await menu.buildFrom(_trayMenu!);
    await _systemTray.setContextMenu(menu);
  }

  Future<void> _showWindow() async {
    _appWindow.show();
    _trayMenu![1] = _visibleItem!;
    _visible = true;
    final Menu menu = Menu();
    await menu.buildFrom(_trayMenu!);
    await _systemTray.setContextMenu(menu);
  }

  void _setLastUpdated(String date) {
    _trayMenu![0] = MenuItemLable(label: 'Last updated: $date', enabled: false);
  }

  Future<void> _initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';

    _visibleItem = MenuItemLable(label: 'Hide', onClicked: (_) => _hideWindow);
    _invisibleItem =
        MenuItemLable(label: 'Show', onClicked: (_) => _showWindow);

    _trayMenu = [
      MenuItemLable(label: 'Last updated: Never', enabled: false),
      _visibleItem!,
      MenuItemLable(label: 'Exit', onClicked: (_) => _appWindow.close),
    ];

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(
      title: "",
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom(_trayMenu!);
    await _systemTray.setContextMenu(menu);

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
