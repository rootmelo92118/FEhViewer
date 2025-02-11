import 'dart:async';

import 'package:fehviewer/config/config.dart';
import 'package:fehviewer/models/openl_translation.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/openl/openl_translator.dart';
import 'package:translator/translator.dart';

import 'language.dart';

class TranslatorHelper {
  static Future<String?> getOpenLApikey() async {
    // try {
    //   final String openl = await rootBundle.loadString('assets/openl.json');
    //   final openlJson = json.decode(openl);
    //   return openlJson['apikey'] as String?;
    // } catch (_) {}
    return FeConfig.openLapikey;
  }

  static GoogleTranslator googleTranslator = GoogleTranslator();

  static Future<OpenlTranslation?> openLtranslate(
    String sourceText, {
    String from = 'auto',
    String to = 'en',
    String service = 'deepl',
  }) async {
    final String? apikey = await getOpenLApikey();
    if (apikey == null || apikey.isEmpty) {
      return null;
    }

    final OpenLTranslator openLTranslator = OpenLTranslator(apikey: apikey);
    return openLTranslator.translate(
      sourceText,
      from: from,
      to: to,
      service: service,
    );
  }

  static Future<String?> getfallbackService() async {
    final String? apikey = await getOpenLApikey();
    if (apikey == null || apikey.isEmpty) {
      return null;
    }
    final OpenLTranslator openLTranslator = OpenLTranslator(apikey: apikey);
    return await openLTranslator.getfallbackService();
  }

  static Future<String> translateText(
    String sourceText, {
    String from = 'auto',
    String to = 'en',
    String service = 'deepl',
  }) async {
    bool useGoogleTranslate = false;
    String rultText = '';
    if (OpenLLanguageList.contains(from)) {
      OpenlTranslation? rult =
          await openLtranslate(sourceText, from: from, to: to);

      if (rult == null) {
        useGoogleTranslate = true;
      } else if (rult.status != true) {
        final service = await getfallbackService();
        if (service != null) {
          logger.d('getfallbackService $service');
          try {
            rult = await openLtranslate(
              sourceText,
              from: from,
              to: to,
              service: service,
            );
          } catch (e, stack) {
            logger.e('$e\n$stack');
            useGoogleTranslate = true;
          }
        }
      }
      rultText = rult?.result ?? '';
    } else {
      useGoogleTranslate = true;
    }

    if (useGoogleTranslate) {
      logger.d('useGoogleTranslate');
      try {
        final googleTranslateRult = await googleTranslator.translate(sourceText,
            to: to == 'zh' ? 'zh-cn' : to);
        rultText = googleTranslateRult.text;
      } catch (e, stack) {
        logger.e('$e\n$stack');
      }
    }

    return rultText;
  }
}
