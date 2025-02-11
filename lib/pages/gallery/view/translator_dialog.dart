import 'package:fehviewer/const/theme_colors.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/openl/translator_helper.dart';
import 'package:fehviewer/utils/vibrate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:translator/translator.dart';

Future<void> showTranslatorDialog(String inputText,
    {String? from, String? to}) {
  vibrateUtil.medium();
  return showCupertinoDialog<void>(
      context: Get.context!,
      barrierDismissible: true,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text('Translator'),
          content: TranslatorDialogView(inputText, from: from, to: to),
          actions: <Widget>[],
        );
      });
}

class TranslatorDialogView extends StatefulWidget {
  const TranslatorDialogView(this.inputText, {Key? key, this.from, this.to})
      : super(key: key);

  final String inputText;
  final String? from;
  final String? to;

  @override
  _TranslatorDialogViewState createState() => _TranslatorDialogViewState();
}

class _TranslatorDialogViewState extends State<TranslatorDialogView> {
  final GoogleTranslator _translator = GoogleTranslator();

  late Future<String?> _future;

  Future<String?> _getTrans() async {
    try {
      final Translation _trans =
          await _translator.translate(widget.inputText, to: 'zh-cn');
      return _trans.text;
    } catch (e, stack) {
      logger.e('$e\n$stack');
      return null;
    }
  }

  Future<String?> _getTransOpenL() async {
    try {
      return await TranslatorHelper.translateText(widget.inputText, to: 'zh');
    } catch (e, stack) {
      logger.e('$e\n$stack');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // _future = _getTrans();
    _future = _getTransOpenL();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return CupertinoButton(
                padding: const EdgeInsets.all(0),
                child: const Icon(
                  Icons.refresh,
                  size: 30,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _future = _getTrans();
                  });
                },
              );
            } else {
              final _trans = snapshot.data;
              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  child: Text(
                    _trans ?? '',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      height: 1.5,
                      color: CupertinoDynamicColor.resolve(
                          ThemeColors.commitText, context),
                    ),
                  ),
                ),
              );
            }
          } else {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: const CupertinoActivityIndicator(),
            );
          }
          return Container();
        });
  }
}
