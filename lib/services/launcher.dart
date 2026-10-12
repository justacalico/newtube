import 'package:url_launcher/url_launcher.dart';

typedef UrlLaunch = Future<bool> Function(Uri uri);

Future<bool> defaultLaunch(Uri uri) => launchUrl(uri); // coverage:ignore-line
