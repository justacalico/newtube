class Version implements Comparable<Version> {
  final List<int> core;
  final List<String>? pre;

  Version({required this.core, this.pre}) : assert(core.length == 3);

  static final _corePartPattern = RegExp(r'^(0|[1-9]\d*)$');
  static final _prePattern = RegExp(r'^[0-9A-Za-z-]+$');

  static Version? parse(String? input) {
    if (input == null || input.isEmpty) return null;
    var cleaned = input.trim();
    while (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    final plus = cleaned.indexOf('+');
    if (plus != -1) cleaned = cleaned.substring(0, plus);

    final dash = cleaned.indexOf('-');
    var corePart = cleaned;
    List<String>? pre;
    if (dash != -1) {
      corePart = cleaned.substring(0, dash);
      pre = cleaned.substring(dash + 1).split('.');
      if (pre.isEmpty) return null;
    }

    final parts = corePart.split('.');
    if (parts.length != 3) return null;
    final core = <int>[];
    for (final p in parts) {
      if (!_corePartPattern.hasMatch(p)) return null;
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      core.add(n);
    }

    if (pre != null) {
      for (final p in pre) {
        if (p.isEmpty || !_prePattern.hasMatch(p)) return null;
        if (_isNumeric(p) && p.length > 1 && p.startsWith('0')) return null;
      }
    }

    return Version(
      core: List.unmodifiable(core),
      pre: pre == null ? null : List.unmodifiable(pre),
    );
  }

  @override
  int compareTo(Version other) {
    for (var i = 0; i < 3; i++) {
      final cmp = core[i].compareTo(other.core[i]);
      if (cmp != 0) return cmp;
    }

    final aPre = pre;
    final bPre = other.pre;
    if (aPre == null && bPre == null) return 0;
    if (aPre == null) return 1;
    if (bPre == null) return -1;

    final len = aPre.length < bPre.length ? aPre.length : bPre.length;
    for (var i = 0; i < len; i++) {
      final cmp = _comparePre(aPre[i], bPre[i]);
      if (cmp != 0) return cmp;
    }

    return aPre.length.compareTo(bPre.length);
  }

  static int _comparePre(String a, String b) {
    final aNum = _isNumeric(a);
    final bNum = _isNumeric(b);
    if (aNum && bNum) return int.parse(a).compareTo(int.parse(b));
    if (aNum) return -1;
    if (bNum) return 1;
    return a.compareTo(b);
  }

  static bool _isNumeric(String s) =>
      s.isNotEmpty && s.codeUnits.every((c) => c >= 0x30 && c <= 0x39);

  @override
  String toString() =>
      '${core.join('.')}${pre == null ? '' : '-${pre!.join('.')}'}';
}
