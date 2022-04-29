import 'dart:io';

import 'package:ddns_client/ddns_updater.dart';
import 'package:ddns_client/public_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'dns.dart';

final logger = Logger();

class Update extends StatefulWidget {
  const Update({Key? key}) : super(key: key);

  @override
  State<Update> createState() => _UpdateState();
}

class _UpdateState extends State<Update> {
  bool _running = false;
  bool _buttonsDisabled = false;
  final _storage = const FlutterSecureStorage();

  final _ipTextController = TextEditingController(text: "Unknown");
  final _lastResultController = TextEditingController(text: "None");
  final _lastUpdatedController = TextEditingController(text: "Never");
  final PublicAddressMonitor monitor = PublicAddressMonitor();

  DateFormat? _dateFormat;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
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
    if (_dateFormat == null) {
      final languageCode = Localizations.localeOf(context).languageCode;
      _dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss', languageCode);
    }

    setState(() {
      _lastUpdatedController.text = _dateFormat!.format(date);
    });
  }

  String updateResultToString(UpdateResult res) {
    if (res.contents != null) {
      return res.contents!;
    } else {
      return "No content";
    }
  }

  Future<void> updateIp(InternetAddress address) async {
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

  Future fetchAndUpdateIp({bool force = false}) async {
    buttonsDisabled = true;

    final String lastIp = _ipTextController.text;

    _lastResult = "Updating...";
    _ip = "Updating...";
    logger.d("Updating the address");

    try {
      if (force || await monitor.checkAddress()) {
        if (force) await monitor.checkAddress();
        InternetAddress? address = monitor.address;
        if (address != null) {
          try {
            await updateIp(address);
          } catch (e) {
            logger.e("Could not update the ip", e);
            _lastResult = "Error";
          }
        } else {
          logger.w("Unable to obtain IP Address: The address was null");
          _lastResult = "Error";
          _ip = "Unable to obtain IP Address";
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
    }
    buttonsDisabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                border: OutlineInputBorder(), labelText: "Last Result(s)"),
          ),
          const SizedBox(height: 10),
          TextField(
            readOnly: true,
            controller: _lastUpdatedController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: "Last Update"),
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _buttonsDisabled
                        ? null
                        : () => fetchAndUpdateIp(force: true),
                    child: const Text("Update now")),
                const SizedBox(width: 30),
                ElevatedButton(
                    onPressed: _buttonsDisabled
                        ? null
                        : () {
                            setState(() {
                              _running = !_running;
                            });
                          },
                    child: Text(_running ? "Stop" : "Start"))
              ],
            ),
          )
        ],
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