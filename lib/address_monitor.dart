import 'dart:async';
import 'dart:io';

import 'package:ddns_client/public_address.dart';
import 'package:synchronized/synchronized.dart';

abstract class AddressMonitor {
  static PublicAddressMonitor _monitor = PublicAddressMonitor();
  static final _lock = Lock();
  static Function? _onStopped;

  static Future<void> setAddress(RandomWebsite? website) {
    return _lock.synchronized(() {
      if (_onStopped != null) _onStopped!();
      _monitor.stopWatching();
      _monitor = PublicAddressMonitor(website);
    });
  }

  static Future<bool> checkAddress() {
    return _lock.synchronized(() => _monitor.checkAddress());
  }

  static Future<Stream<PublicAddressEvent>?> startWatching(
      Duration duration, Function onStopped) {
    return _lock.synchronized(() {
      _onStopped = onStopped;
      return _monitor.startWatching(duration: duration);
    });
  }

  static Future<void> stopWatching() {
    return _lock.synchronized(() => _monitor.stopWatching());
  }

  static Future<InternetAddress?> get address {
    return _lock.synchronized(() => _monitor.address);
  }
}
