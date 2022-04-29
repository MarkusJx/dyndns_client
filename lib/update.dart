import 'dart:io';

import 'package:ddns_client/ddns_updater.dart';
import 'package:ddns_client/public_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dns.dart';

class Update extends StatefulWidget {
  const Update({Key? key}) : super(key: key);

  @override
  State<Update> createState() => _UpdateState();
}

class _UpdateState extends State<Update> {
  bool _running = false;
  bool _buttonsDisabled = false;
  final _storage = const FlutterSecureStorage();

  final TextEditingController _ipTextController =
      TextEditingController(text: "Unknown");
  final TextEditingController _lastResultController =
      TextEditingController(text: "None");
  final PublicAddressMonitor monitor = PublicAddressMonitor();

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

  String updateResultToString(UpdateResult res) {
    final buf = StringBuffer();
    if (res.contents != null) {
      buf.write("Content: ");
      buf.write(res.contents);
    }

    if (res.statusCode != null) {
      if (buf.isNotEmpty) buf.write("\n");
      buf.write("Status code: ");
      buf.write(res.statusCode);
    }

    if (res.success != null) {
      if (buf.isNotEmpty) buf.write("\n");
      buf.write("Success: ");
      buf.write(res.success);
    }

    if (res.reasonPhrase != null) {
      if (buf.isNotEmpty) buf.write("\n");
      buf.write("Reason: ");
      buf.write(res.reasonPhrase);
    }

    if (res.addressText != null) {
      if (buf.isNotEmpty) buf.write("\n");
      buf.write("Address: ");
      buf.write(res.addressText);
    }

    if (buf.isNotEmpty) {
      buf.write("\n");
      buf.write("Timestamp: ");
      buf.write(res.timestamp.toLocal().toString());
    }

    if (buf.isEmpty) {
      return "No result";
    } else {
      return buf.toString();
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
          .split(RegExp(',|\n'))
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
      for (String host in domains) {
        final updater = GenericDyndns2Updater(
            username: user, password: pass, hostname: host, dnsHost: dns);
        final res = await updater.update(address);
        _lastResult = updateResultToString(res);
      }
    } else {
      _lastResult = "Invalid configuration";
    }
  }

  Future fetchAndUpdateIp({bool force = false}) async {
    buttonsDisabled = true;

    final String lastIp = _ipTextController.text;

    _lastResult = "Updating...";
    _ip = "Updating...";

    try {
      if (force || await monitor.checkAddress()) {
        if (force) await monitor.checkAddress();
        InternetAddress? address = monitor.address;
        if (address != null) {
          try {
            await updateIp(address);
          } catch (_) {
            _lastResult = "Error";
            print(_);
          }
        }
      } else {
        _lastResult = "No update";
        _ip = lastIp;
      }
    } catch (_) {
      _ip = "Error";
      _lastResult = "Error";
    }
    buttonsDisabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        TextField(
            readOnly: true,
            controller: _ipTextController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: "Your IP")),
        TextField(
          readOnly: true,
          controller: _lastResultController,
          maxLines: null,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), labelText: "Last Result"),
        ),
        Row(
          children: [
            ElevatedButton(
                onPressed: _buttonsDisabled
                    ? null
                    : () => fetchAndUpdateIp(force: true),
                child: const Text("Update now")),
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
        )
      ],
    ));
  }
}
