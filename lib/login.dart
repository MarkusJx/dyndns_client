import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool __saving = true;
  final _storage = const FlutterSecureStorage();
  final _passwordFieldController = TextEditingController();
  final _usernameFieldController = TextEditingController();
  final _dnsHostFieldController = TextEditingController();
  final _domainFieldController = TextEditingController();

  _LoginState() {
    _loadData();
  }

  set _saving(bool v) {
    setState(() {
      __saving = v;
    });
  }

  set _password(String? p) {
    if (p != null) {
      setState(() {
        _passwordFieldController.text = p;
      });
    }
  }

  set _username(String? u) {
    if (u != null) {
      setState(() {
        _usernameFieldController.text = u;
      });
    }
  }

  set _dnsHost(String? h) {
    if (h != null) {
      setState(() {
        _dnsHostFieldController.text = h;
      });
    }
  }

  set _domains(String? d) {
    if (d != null) {
      setState(() {
        _domainFieldController.text = d;
      });
    }
  }

  void _loadData() async {
    logger.d("Loading credentials");
    _password = await _storage.read(key: "password");
    _username = await _storage.read(key: "username");
    _dnsHost = await _storage.read(key: "dnsHost");
    _domains = await _storage.read(key: "domains");
    logger.d("Credentials loaded");
    _saving = false;
  }

  void _saveData() async {
    _saving = true;
    logger.d("Saving credentials");
    await _storage.write(key: "username", value: _usernameFieldController.text);
    await _storage.write(key: "password", value: _passwordFieldController.text);
    await _storage.write(key: "dnsHost", value: _dnsHostFieldController.text);
    await _storage.write(key: "domains", value: _domainFieldController.text);
    logger.d("Credentials saved successfully");
    _saving = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          TextField(
              readOnly: __saving,
              controller: _dnsHostFieldController,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "DNS Server URL")),
          const SizedBox(height: 15),
          TextField(
            readOnly: __saving,
            controller: _usernameFieldController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: "Username"),
          ),
          const SizedBox(height: 15),
          PasswordField(
              controller: _passwordFieldController, readOnly: __saving),
          const SizedBox(height: 15),
          TextField(
            readOnly: __saving,
            controller: _domainFieldController,
            maxLines: null,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: "Domains"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
              onPressed: __saving ? null : _saveData, child: const Text("Save"))
        ],
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final bool readOnly;

  const PasswordField(
      {Key? key, required this.controller, required this.readOnly})
      : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: widget.readOnly,
      obscureText: _obscure,
      controller: widget.controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
        ),
      ),
    );
  }
}
