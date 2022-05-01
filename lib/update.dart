import 'dart:io';

import 'package:ddns_client/ddns_updater.dart';
import 'package:ddns_client/public_address.dart';
import 'package:dydns_client/address_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'dns.dart';

final logger = Logger();

class Update extends StatefulWidget {
  final void Function(String time) setLastUpdated;

  const Update({Key? key, required this.setLastUpdated}) : super(key: key);

  @override
  State<Update> createState() => _UpdateState();
}

class _UpdateState extends State<Update> {
  bool _running = false;
  bool _buttonsDisabled = false;
  bool _updateIntervalFieldReadOnly = false;
  String _selectedAddressWebsite = "Random";
  final _storage = const FlutterSecureStorage();

  final _ipTextController = TextEditingController(text: "Unknown");
  final _lastResultController = TextEditingController(text: "None");
  final _lastUpdatedController = TextEditingController(text: "Never");
  final _updateIntervalController = TextEditingController(text: "3600");

  final _settingsSavedSnackbar =
      const SnackBar(content: Text("Settings saved"));

  DateFormat? _dateFormat;
  FocusNode? _updateIntervalFocusNode;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _updateIntervalFocusNode = FocusNode();

    _updateIntervalFocusNode!.addListener(() async {
      if (!_updateIntervalFocusNode!.hasFocus) {
        try {
          logger.d("Saving update interval");
          _storage.write(
              key: 'updateInterval', value: _updateIntervalController.text);
          logger.d("Update interval saved");
          ScaffoldMessenger.of(context).showSnackBar(_settingsSavedSnackbar);
        } catch (e) {
          logger.e("Could not save the update interval", e);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Could not save the update interval")));
        }
      }
    });

    _storage.read(key: 'updateInterval').then((value) {
      if (value != null) {
        logger.d("Loaded the update interval");
        setState(() => _updateIntervalController.text = value);
      } else {
        logger.d("The update interval was unset");
      }
    }, onError: (e) {
      logger.e("Could not read the update interval", e);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not read the update interval")));
    });

    _storage.read(key: 'addressWebsite').then((value) {
      if (value != null && value != "Random") {
        logger.d("Loaded the address website");
        setState(() => _selectedAddressWebsite = value);
      }
    }, onError: (e) {
      logger.e("Could not read the address website", e);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not read the address website")));
    });
  }

  @override
  void dispose() {
    _updateIntervalFocusNode?.dispose();
    super.dispose();
  }

  set buttonsDisabled(bool disabled) {
    setState(() {
      _buttonsDisabled = disabled;
    });
  }

  set _lastResult(String result) {
    setState(() {
      _lastResultController.text = result;
    });
  }

  set _ip(String ip) {
    setState(() {
      _ipTextController.text = ip;
    });
  }

  set _lastUpdated(DateTime date) {
    setState(() {
      _lastUpdatedController.text = _dateToString(date);
    });
  }

  String _dateToString(DateTime date) {
    if (_dateFormat == null) {
      final languageCode = Localizations.localeOf(context).languageCode;
      _dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', languageCode);
    }

    return _dateFormat!.format(date);
  }

  void _setRunning(bool r) {
    setState(() {
      _updateIntervalFieldReadOnly = r;
      _running = r;
    });
  }

  String updateResultToString(UpdateResult res) {
    if (res.contents != null) {
      return res.contents!;
    } else {
      return "No content";
    }
  }

  Future<void> _updateIp(InternetAddress address) async {
    _ip = address.address;
    final user = await _storage.read(key: "username");
    final pass = await _storage.read(key: "password");
    final domainText = await _storage.read(key: "domains");
    final dns = await _storage.read(key: "dnsHost");

    Iterable<String>? domains;
    if (domainText != null) {
      domains = domainText
          .split(RegExp(',|\n', multiLine: true))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
    }

    if (user != null &&
        user.isNotEmpty &&
        pass != null &&
        pass.isNotEmpty &&
        domains != null &&
        domains.isNotEmpty &&
        dns != null &&
        dns.isNotEmpty) {
      logger.d('Updating ${domains.length} domain(s)');
      final results = List.generate(domains.length, (_) => "", growable: false);

      for (int i = 0; i < domains.length; i++) {
        final updater = GenericDyndns2Updater(
            username: user,
            password: pass,
            hostname: domains.elementAt(i),
            dnsHost: dns);
        final res = await updater.update(address);
        _lastUpdated = res.timestamp;
        widget.setLastUpdated(_dateToString(res.timestamp));
        results[i] = domains.elementAt(i) + ": " + updateResultToString(res);
        logger.d(res.toJson());
      }

      _lastResult = results.join("\n");
      logger.d("Successfully updated the domains");
    } else {
      logger.w("Any configuration entry was empty");
      _lastResult = "Invalid configuration";
    }
  }

  Future<void> _fetchAndUpdateIp({bool force = false}) async {
    buttonsDisabled = true;

    final String lastIp = _ipTextController.text;

    _lastResult = "Updating...";
    _ip = "Updating...";
    logger.d("Updating the address");

    try {
      if (force || await AddressMonitor.checkAddress()) {
        if (force) await AddressMonitor.checkAddress();
        InternetAddress? address = await AddressMonitor.address;
        if (address != null) {
          try {
            await _updateIp(address);
          } catch (e) {
            logger.e("Could not update the ip", e);
            _lastResult = "Error";
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Could not update the ip")));
          }
        } else {
          logger.w("Unable to obtain IP Address: The address was null");
          _lastResult = "Error";
          _ip = "Unable to obtain IP Address";
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text("Unable to obtain IP Address: The address was null")));
        }
      } else {
        logger.d("The address is already up-to-date");
        _lastResult = "No update";
        _ip = lastIp;
      }
    } catch (e) {
      logger.e("Could not check the address", e);
      _ip = "Error";
      _lastResult = "Error";
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not check the IP address")));
    }
    buttonsDisabled = false;
  }

  Future<void> _startWatching() async {
    try {
      logger.d("Start watching");
      buttonsDisabled = true;
      _setRunning(true);
      final int? secs = int.tryParse(_updateIntervalController.text);
      if (secs == null) {
        logger.e("Could not parse the update interval");
      } else {
        logger.d('Updating every $secs seconds');
      }

      await _fetchAndUpdateIp();
      final stream = await AddressMonitor.startWatching(
          Duration(seconds: secs ?? 3600), _stopWatching);

      if (stream != null) {
        stream.listen((PublicAddressEvent event) {
          if (event.oldAddress == null ||
              event.oldAddress != event.newAddress) {
            logger.d("The ip address has changed, updating the hostname(s)");
            _updateIp(event.newAddress)
                .catchError((e) => logger.e("Could not update the IP", e));
          } else {
            logger.d("The ip has not changed");
          }
        });

        buttonsDisabled = false;
      } else {
        await AddressMonitor.stopWatching();
        logger.e("The address event stream was null");
        buttonsDisabled = false;
        _setRunning(false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not start watching")));
      }
    } catch (e) {
      logger.e("Could not start watching", e);
      buttonsDisabled = false;
      _setRunning(false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not start watching")));
    }
  }

  Future<void> _stopWatching() async {
    try {
      logger.d("Stop watching");
      buttonsDisabled = true;
      await AddressMonitor.stopWatching();
      _setRunning(false);
      buttonsDisabled = false;
    } catch (e) {
      logger.e("Could not stop watching", e);
      buttonsDisabled = false;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not stop watching")));
    }
  }

  List<DropdownMenuItem<String>>? _getAddressWebsites() {
    try {
      final websites = PublicAddressWebsite.websites
          .map(
            (e) => DropdownMenuItem(
                child: Text(e.uri.host), value: e.uri.toString()),
          )
          .toList();
      websites.insert(
          0, const DropdownMenuItem(child: Text("Random"), value: "Random"));

      return websites;
    } catch (e) {
      logger.e("Could not get the address websites", e);
      return null;
    }
  }

  Future<void> _setAddressWebsite(String value) async {
    try {
      logger.d('Updating the address website to $value');
      if (value == "Random") {
        await AddressMonitor.setAddress(null);
      } else {
        final site = PublicAddressWebsite.websites
            .singleWhere((e) => e.uri.toString() == value);
        await AddressMonitor.setAddress(() => site);
      }

      _storage.write(key: 'addressWebsite', value: value);
      logger.d("Saved the address website");
      ScaffoldMessenger.of(context).showSnackBar(_settingsSavedSnackbar);
    } catch (e) {
      logger.e("Could not set the address website", e);
      AddressMonitor.setAddress(null).catchError((_) => null);
      setState(() => _selectedAddressWebsite = "Random");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not set the address website")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(25.0),
            constraints:
                BoxConstraints(maxWidth: 400, minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextField(
                    readOnly: true,
                    controller: _ipTextController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Your IP")),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  controller: _lastResultController,
                  maxLines: null,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Last Result(s)"),
                ),
                const SizedBox(height: 10),
                TextField(
                  readOnly: true,
                  controller: _lastUpdatedController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Last Update"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _updateIntervalController,
                  keyboardType: TextInputType.number,
                  readOnly: _updateIntervalFieldReadOnly,
                  focusNode: _updateIntervalFocusNode,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Update Interval (seconds)"),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(3.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black38),
                    borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("IP check server:"),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        items: _getAddressWebsites(),
                        elevation: 16,
                        value: _selectedAddressWebsite,
                        onChanged: _updateIntervalFieldReadOnly
                            ? null
                            : (String? value) {
                                _setAddressWebsite(value!);
                                setState(() => _selectedAddressWebsite = value);
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _buttonsDisabled
                          ? null
                          : () async {
                              setState(
                                  () => _updateIntervalFieldReadOnly = true);
                              await _fetchAndUpdateIp(force: true);
                              setState(
                                  () => _updateIntervalFieldReadOnly = false);
                            },
                      child: const Text("Update now"),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton(
                      onPressed: _buttonsDisabled
                          ? null
                          : () {
                              if (_running) {
                                _stopWatching();
                              } else {
                                _startWatching();
                              }
                            },
                      child: Text(_running ? "Stop" : "Start"),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension SerializableUpdateResult on UpdateResult {
  Map<String, dynamic> toJson() => {
        'success': success,
        'statusCode': statusCode,
        'reason': reasonPhrase,
        'address': addressText,
        'contents': contents,
        'timestamp': timestamp
      };
}
