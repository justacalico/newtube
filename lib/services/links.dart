import 'dart:async';

import 'package:app_links/app_links.dart';

abstract class LinkActions {
  Stream<Uri> get links;
  Future<Uri?> get initial;
}

// coverage:ignore-start
class AppLinksActions implements LinkActions {
  AppLinksActions() : _links = AppLinks();

  final AppLinks _links;

  @override
  Stream<Uri> get links => _links.uriLinkStream;

  @override
  Future<Uri?> get initial => _links.getInitialLink();
}
// coverage:ignore-end
