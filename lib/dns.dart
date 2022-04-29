import 'dart:async';
import 'dart:io';

import 'package:ddns_client/ddns_updater.dart';

class GenericDyndns2Updater extends Dyndns2Updater {
  late final String dnsHost;

  GenericDyndns2Updater(
      {required String hostname,
      required String dnsHost,
      required String username,
      required String password})
      : super(hostname: hostname, username: username, password: password) {
    if (dnsHost.endsWith('/')) {
      this.dnsHost = dnsHost.substring(0, dnsHost.length - 1);
    } else {
      this.dnsHost = dnsHost;
    }
  }

  @override
  Future<UpdateResult> update(InternetAddress address) {
    StringBuffer sb = StringBuffer();
    if (!dnsHost.startsWith('https://') && !dnsHost.startsWith('http://')) {
      sb.write('https://');
    }

    sb.write(dnsHost);
    sb.write('/nic/update?sytem=dyndns&hostname=');
    sb.write(hostname);
    sb.write('&myip=');
    sb.write(address.address);
    sb.write("&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG&offline=NOCHG");
    Uri uri = Uri.parse(sb.toString());
    HttpClient client = httpClient;
    client.addCredentials(
        uri, 'realm', HttpClientBasicCredentials(username, password));
    return client.getUrl(uri).then(processRequest).then(processResponse);
  }

  @override
  Future<HttpClientResponse> processRequest(HttpClientRequest request) {
    request.headers.set(HttpHeaders.userAgentHeader, "DynDNS2 Client/1.0.0 hi@markusjx.com");
    return request.close();
  }
}
