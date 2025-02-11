import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:fehviewer/common/controller/cache_controller.dart';
import 'package:fehviewer/common/global.dart';
import 'package:fehviewer/common/service/dns_service.dart';
import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/common/service/layout_service.dart';
import 'package:fehviewer/common/service/locale_service.dart';
import 'package:fehviewer/common/service/theme_service.dart';
import 'package:fehviewer/const/locale.dart';
import 'package:fehviewer/const/theme_colors.dart';
import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/route/routes.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../component/setting_base.dart';

class AdvancedSettingPage extends StatelessWidget {
  const AdvancedSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget cps = Obx(() {
      return CupertinoPageScaffold(
          backgroundColor: !ehTheme.isDarkMode
              ? CupertinoColors.secondarySystemBackground
              : null,
          navigationBar: CupertinoNavigationBar(
            // transitionBetweenRoutes: true,
            middle: Text(L10n.of(context).advanced),
          ),
          child: const SafeArea(
            bottom: false,
            child: ListViewAdvancedSetting(),
          ));
    });

    return cps;
  }
}

class ListViewAdvancedSetting extends StatelessWidget {
  const ListViewAdvancedSetting({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EhConfigService _ehConfigService = Get.find();
    final DnsService _dnsService = Get.find();
    final CacheController _cacheController = Get.find();

    void _handlePureDarkChanged(bool newValue) {
      _ehConfigService.isPureDarkTheme.value = newValue;
    }

    void _handleDoHChanged(bool newValue) {
      // if (!newValue && !_dnsService.enableCustomHosts) {
      //   /// 清除hosts 关闭代理
      //   logger.d(' 关闭代理');
      //   HttpOverrides.global = null;
      // } else if (newValue) {
      //   /// 设置全局本地代理
      //   HttpOverrides.global = Global.httpProxy;
      // }
      _dnsService.enableDoH = newValue;
    }

    void _handleDFChanged(bool newValue) {
      _dnsService.enableDomainFronting = newValue;
      if (!newValue) {
        HttpOverrides.global = null;
      } else {
        HttpOverrides.global = Global.dfHttpOverrides;
        final HttpClient eClient =
            ExtendedNetworkImageProvider.httpClient as HttpClient;
        eClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
          return true;
        };
      }
    }

    final List<Widget> _list = <Widget>[
      _buildLanguageItem(context),
      const ItemSpace(),
      _buildThemeItem(context),
      Obx(() => TextSwitchItem(
            L10n.of(context).dark_mode_effect,
            intValue: _ehConfigService.isPureDarkTheme.value,
            onChanged: _handlePureDarkChanged,
            desc: L10n.of(context).gray_black,
            descOn: L10n.of(context).pure_black,
          )),
      if (context.isTablet)
        Obx(() => TextSwitchItem(
              L10n.of(context).tablet_layout,
              intValue: _ehConfigService.tabletLayout,
              onChanged: (bool val) => _ehConfigService.tabletLayout = val,
            )),
      if (!Get.find<EhConfigService>().isSafeMode.value)
        SelectorSettingItem(
          hideLine: true,
          title: L10n.of(context).tabbar_setting,
          selector: '',
          onTap: () {
            Get.toNamed(
              EHRoutes.pageSetting,
              id: isLayoutLarge ? 2 : null,
            );
          },
        ),
      const ItemSpace(),
      // 清除缓存
      _cacheController.obx(
          (String? state) => SelectorSettingItem(
                title: L10n.of(context).clear_cache,
                selector: state ?? '',
                hideLine: true,
                onTap: () {
                  logger.d(' clear_cache');
                  _cacheController.clearAllCache();
                },
              ),
          onLoading: SelectorSettingItem(
            title: L10n.of(context).clear_cache,
            selector: '',
            hideLine: true,
            onTap: () {
              logger.d(' clear_cache');
              _cacheController.clearAllCache();
            },
          )),
      const ItemSpace(),
      TextSwitchItem(
        L10n.of(context).domain_fronting,
        intValue: _dnsService.enableDomainFronting,
        onChanged: _handleDFChanged,
        desc: 'By pass SNI',
      ),
      // Obx(() {
      //   return AnimatedCrossFade(
      //     alignment: Alignment.center,
      //     crossFadeState: _dnsService.enableDomainFronting
      //         ? CrossFadeState.showSecond
      //         : CrossFadeState.showFirst,
      //     firstCurve: Curves.easeIn,
      //     secondCurve: Curves.easeOut,
      //     duration: const Duration(milliseconds: 200),
      //     firstChild: const SizedBox(),
      //     secondChild: SelectorSettingItem(
      //       title: L10n.of(context).custom_hosts,
      //       selector: _dnsService.enableCustomHosts
      //           ? L10n.of(context).on
      //           : L10n.of(context).off,
      //       onTap: () {
      //         Get.toNamed(
      //           EHRoutes.customHosts,
      //           id: isLayoutLarge ? 2 : null,
      //         );
      //       },
      //       hideLine: true,
      //     ),
      //   );
      // }),
      Obx(() => SelectorSettingItem(
            title: L10n.of(context).custom_hosts,
            selector: _dnsService.enableCustomHosts
                ? L10n.of(context).on
                : L10n.of(context).off,
            onTap: () {
              if (!_dnsService.enableDomainFronting) {
                return;
              }
              Get.toNamed(
                EHRoutes.customHosts,
                id: isLayoutLarge ? 2 : null,
              );
            },
            titleColor: !_dnsService.enableDomainFronting
                ? CupertinoColors.secondaryLabel
                : null,
            hideLine: true,
          )),
      // TextSwitchItem(
      //   'DNS-over-HTTPS',
      //   intValue: _dnsConfigController.enableDoH.value,
      //   onChanged: _handleDoHChanged,
      //   desc: '优先级低于自定义hosts',
      // ),
      const ItemSpace(),
      TextSwitchItem(
        L10n.of(context).vibrate_feedback,
        intValue: _ehConfigService.vibrate.value,
        onChanged: (bool val) => _ehConfigService.vibrate.value = val,
        hideLine: true,
      ),
      const ItemSpace(),
      SelectorSettingItem(
        title: 'Log',
        onTap: () {
          Get.toNamed(
            EHRoutes.logfile,
            id: isLayoutLarge ? 2 : null,
          );
        },
      ),
      TextSwitchItem(
        'Log debugMode',
        intValue: _ehConfigService.debugMode,
        onChanged: (bool val) => _ehConfigService.debugMode = val,
        hideLine: true,
      ),
    ];

    return ListView.builder(
      itemCount: _list.length,
      itemBuilder: (BuildContext context, int index) {
        return _list[index];
      },
    );
  }

  /// 语言设置部件
  Widget _buildLanguageItem(BuildContext context) {
    final LocaleService localeService = Get.find();
    final String _title = L10n.of(context).language;

    final Map<String, String> localeMap = <String, String>{
      '': L10n.of(context).follow_system,
    };

    localeMap.addAll(languageMenu);

    List<Widget> _getLocaleList(BuildContext context) {
      return List<Widget>.from(localeMap.keys.map((String element) {
        return CupertinoActionSheetAction(
            onPressed: () {
              Get.back(result: element);
            },
            child: Text(localeMap[element] ?? ''));
      }).toList());
    }

    Future<String?> _showDialog(BuildContext context) {
      return showCupertinoModalPopup<String>(
          context: context,
          builder: (BuildContext context) {
            final CupertinoActionSheet dialog = CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(L10n.of(context).cancel)),
              actions: <Widget>[
                ..._getLocaleList(context),
              ],
            );
            return dialog;
          });
    }

    return Obx(() => SelectorSettingItem(
          title: _title,
          selector: localeMap[localeService.localCode.value] ?? '',
          hideLine: true,
          onTap: () async {
            logger.v('tap LanguageItem');
            final String? _result = await _showDialog(context);
            if (_result is String) {
              localeService.localCode.value = _result;
            }
            // logger.v('$_result');
          },
        ));
  }

  /// 主题设置部件
  Widget _buildThemeItem(BuildContext context) {
    final String _title = L10n.of(context).theme;
    final ThemeService themeService = Get.find();

    final Map<ThemesModeEnum, String> themeMap = <ThemesModeEnum, String>{
      ThemesModeEnum.system: L10n.of(context).follow_system,
      ThemesModeEnum.ligthMode: L10n.of(context).light,
      ThemesModeEnum.darkMode: L10n.of(context).dark,
    };

    List<Widget> _getThemeList(BuildContext context) {
      return List<Widget>.from(themeMap.keys.map((ThemesModeEnum themesMode) {
        return CupertinoActionSheetAction(
            onPressed: () {
              Get.back(result: themesMode);
            },
            child: Text(themeMap[themesMode] ?? ''));
      }).toList());
    }

    Future<ThemesModeEnum?> _showDialog(BuildContext context) {
      return showCupertinoModalPopup<ThemesModeEnum>(
          context: context,
          builder: (BuildContext context) {
            final CupertinoActionSheet dialog = CupertinoActionSheet(
              cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Get.back();
                  },
                  child: Text(L10n.of(context).cancel)),
              actions: <Widget>[
                ..._getThemeList(context),
              ],
            );
            return dialog;
          });
    }

    return SelectorSettingItem(
      title: _title,
      selector: themeMap[themeService.themeModel] ?? '',
      onTap: () async {
        logger.v('tap ThemeItem');
        final ThemesModeEnum? _result = await _showDialog(context);
        if (_result is ThemesModeEnum) {
          themeService.themeModel = _result;
        }
      },
    );
  }
}
