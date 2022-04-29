import 'dart:async';
import 'dart:io';

import 'package:ddns_client/ddns_updater.dart';

class GenericDyndns2Updater extends Dyndns2Updater {
  final String dnsHost;

  GenericDyndns2Updater(
      {required String hostname,
      required this.dnsHost,
      required String username,
      required String password})
      : super(hostname: hostname, username: username, password: password);

  @override
  Future<UpdateResult> update(InternetAddress address) {
    StringBuffer sb = StringBuffer(
        (dnsHost.startsWith('https://') || dnsHost.startsWith('http://'))
            ? ''
            : 'https://');
    sb.write(dnsHost.endsWith('/')
        ? dnsHost.substring(0, dnsHost.length - 1)
        : dnsHost);
    sb.write('/nic/update?sytem=dyndns&hostname=');
    sb.write(hostname);
    sb.write('&myip=');
    sb.write(address.address);
    //sb.write("1.2.3.323");
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
