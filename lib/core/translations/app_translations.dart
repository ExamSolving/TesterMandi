import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTranslations extends Translations {
  static Map<String, String> _en = {};
  static Map<String, String> _hi = {};
  static Map<String, String> _es = {};

  static Future<void> load() async {
    final enRaw = await rootBundle.loadString('assets/translations/en.json');
    final hiRaw = await rootBundle.loadString('assets/translations/hi.json');
    final esRaw = await rootBundle.loadString('assets/translations/es.json');
    _en = Map<String, String>.from(jsonDecode(enRaw) as Map);
    _hi = Map<String, String>.from(jsonDecode(hiRaw) as Map);
    _es = Map<String, String>.from(jsonDecode(esRaw) as Map);
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _en,
        'hi_IN': _hi,
        'es_ES': _es,
      };
}
