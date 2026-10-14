import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract class ShareActions {
  Future<void> share(String text);
}

class SheetShareActions implements ShareActions {
  SheetShareActions();

  @override
  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));
}

class ClipboardShareActions implements ShareActions {
  ClipboardShareActions();

  @override
  Future<void> share(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
