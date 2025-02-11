import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fehviewer/common/controller/user_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:get/get.dart' hide Response;

class EhCookieInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final cookies =
          options.headers[HttpHeaders.cookieHeader] as String? ?? '';
      logger.v('cookies:$cookies');
      final _cookies = cookies
          .split(';')
          .map((str) => Cookie.fromSetCookieValue(str))
          .toList();
      logger.v('_cookies:$_cookies');

      checkCookies(_cookies);
    } catch (_) {}

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _saveCookies(response)
        .then((_) => super.onResponse(response, handler))
        .catchError((e, StackTrace? stackTrace) {
      DioError err =
          DioError(requestOptions: response.requestOptions, error: e);
      err.stackTrace = stackTrace;
      handler.reject(err, true);
    });
  }

  Future<void> _saveCookies(Response response) async {
    final UserController userController = Get.find();

    var cookies = response.headers[HttpHeaders.setCookieHeader];

    if (cookies != null) {
      logger.v('set-cookie:$cookies');
      final _cookies =
          cookies.map((str) => Cookie.fromSetCookieValue(str)).toList();
      logger.v('_set cookies $_cookies');

      final igneous = getCookiesValue(_cookies, 'igneous');

      final _newSk = getCookiesValue(_cookies, 'sk') ?? '';

      userController.user(userController.user.value.copyWith(
        memberId: getCookiesValue(_cookies, 'ipb_member_id'),
        passHash: getCookiesValue(_cookies, 'ipb_pass_hash'),
        igneous: igneous != 'mystery' && igneous != '' ? igneous : null,
        hathPerks: getCookiesValue(_cookies, 'hath_perks'),
        sk: _newSk.isNotEmpty ? _newSk : null,
      ));

      logger.v('${userController.user.value.toJson()}');
    }
  }

  static String getCookies(List<Cookie> cookies) {
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  static String? getCookiesValue(List<Cookie> cookies, String name) {
    return cookies.firstWhereOrNull((e) => e.name == name)?.value;
  }

  void checkCookies(List<Cookie> cookies) {
    final UserController userController = Get.find();

    final memberId = userController.user.value.memberId;
    if (memberId != null && memberId.isNotEmpty) {
      final _c = cookies
          .firstWhereOrNull((element) => element.name == 'ipb_member_id');
      if (_c != null) {
        _c.value = memberId;
      } else {
        Cookie('ipb_member_id', memberId);
      }
    }

    final passHash = userController.user.value.passHash;
    if (passHash != null && passHash.isNotEmpty) {
      final _c = cookies
          .firstWhereOrNull((element) => element.name == 'ipb_pass_hash');
      if (_c != null) {
        _c.value = passHash;
      } else {
        Cookie('ipb_pass_hash', passHash);
      }
    }

    final igneous = userController.user.value.igneous;
    if (igneous != null && igneous.isNotEmpty) {
      final _c =
          cookies.firstWhereOrNull((element) => element.name == 'igneous');
      if (_c != null) {
        _c.value = igneous;
      } else {
        Cookie('igneous', igneous);
      }
    }

    final hathPerks = userController.user.value.hathPerks;
    if (hathPerks != null && hathPerks.isNotEmpty) {
      final _c =
          cookies.firstWhereOrNull((element) => element.name == 'hath_perks');
      if (_c != null) {
        _c.value = hathPerks;
      } else {
        Cookie('hath_perks', hathPerks);
      }
    }

    final sk = userController.user.value.sk;
    if (sk != null && sk.isNotEmpty) {
      final _c = cookies.firstWhereOrNull((element) => element.name == 'sk');
      if (_c != null) {
        _c.value = sk;
      } else {
        Cookie('sk', sk);
      }
    }
  }
}
