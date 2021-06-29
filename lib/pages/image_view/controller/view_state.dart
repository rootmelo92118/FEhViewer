import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fehviewer/common/controller/gallerycache_controller.dart';
import 'package:fehviewer/common/service/depth_service.dart';
import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/const/const.dart';
import 'package:fehviewer/models/base/eh_models.dart';
import 'package:fehviewer/pages/gallery/controller/gallery_page_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'view_controller.dart';

enum ViewColumnMode {
  // 双页 奇数页位于左边
  odd,

  // 双页 偶数页位于左边
  even,

  // 单页
  single,
}

class ViewState {
  ViewState() {
    // 初始化 设置Rx变量的ever事件
    // logger.v('初始化ViewState');

    debounce(_itemIndex, (int val) {
      if (_galleryPageController.galleryItem.gid != null &&
          conditionItemIndex) {
        logger.d('debounce 300 _itemIndex to $val');
        _galleryPageController.lastIndex = itemIndex;
        _galleryCacheController.setIndex(
            _galleryPageController.galleryItem.gid ?? '', itemIndex);
      }
    }, time: const Duration(milliseconds: 300));

    debounce(
      _itemIndex,
      (int val) {
        if (_galleryPageController.galleryItem.gid != null) {
          logger.d('debounce 5000 _itemIndex $_itemIndex');
          _galleryCacheController.setIndex(
              _galleryPageController.galleryItem.gid ?? '', itemIndex,
              saveToStore: true);
        }
      },
      time: const Duration(seconds: 5),
    );

    ever<ViewColumnMode>(_columnMode, (ViewColumnMode val) {
      Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
        _galleryCacheController.setColumnMode(
            _galleryPageController.galleryItem.gid ?? '', val);
      });
    });

    _columnMode.value = _galleryCacheController
            .getGalleryCache(_galleryPageController.galleryItem.gid ?? '')
            ?.columnMode ??
        ViewColumnMode.single;

    // 初始页码
    final int _iniIndex = Get.arguments as int;
    // conditionItemIndex = false;
    itemIndex = _iniIndex;
    // conditionItemIndex = true;
  }

  void initSize(BuildContext context) {
    final MediaQueryData _mq = MediaQuery.of(context);
    screensize = _mq.size;
    _paddingLeft = _mq.padding.left;
    _paddingRight = _mq.padding.right;
    _paddingTop = _mq.padding.top;
    _paddingBottom = _mq.padding.bottom;
    _realPaddingTop = _paddingTop;
  }

  final EhConfigService _ehConfigService = Get.find();
  final GalleryCacheController _galleryCacheController = Get.find();
  final GalleryPageController _galleryPageController =
      Get.find(tag: pageCtrlDepth);

  final GlobalKey centkey = GlobalKey();
  final CancelToken getMoreCancelToken = CancelToken();

  List<GalleryImage> get images => _galleryPageController.images;

  Map<int, GalleryImage> get imageMap => _galleryPageController.imageMap;

  int get filecount =>
      int.parse(_galleryPageController.galleryItem.filecount ?? '0');

  /// 横屏翻页模式
  final Rx<ViewColumnMode> _columnMode = ViewColumnMode.single.obs;

  ViewColumnMode get columnMode => _columnMode.value;

  set columnMode(val) => _columnMode.value = val;

  /// 当前查看的图片inde
  final RxInt _itemIndex = 0.obs;

  int get itemIndex => _itemIndex.value;

  set itemIndex(int val) {
    // logger5.d('will set itemIndex to $val');
    _itemIndex.value = val;
  }

  bool conditionItemIndex = true;
  int tempIndex = 0;

  /// pageview下实际的index
  int get pageIndex {
    switch (columnMode) {
      case ViewColumnMode.single:
        return itemIndex;
      case ViewColumnMode.odd:
        return itemIndex ~/ 2;
      case ViewColumnMode.even:
        return (itemIndex + 1) ~/ 2;
      default:
        return itemIndex;
    }
  }

  /// pageview下实际能翻页的总数
  int get pageCount {
    final int imageCount = filecount;
    switch (columnMode) {
      case ViewColumnMode.single:
        return imageCount;
      case ViewColumnMode.odd:
        return (imageCount / 2).round();
      case ViewColumnMode.even:
        return (imageCount / 2).round() + ((imageCount + 1) % 2);
      default:
        return imageCount;
    }
  }

  /// 滑条的值
  double sliderValue = 0.0;

  late Size screensize;
  late double _realPaddingBottom;
  late double _realPaddingTop;
  late double _paddingLeft;
  late double _paddingRight;
  late double _paddingTop;
  late double _paddingBottom;

  EdgeInsets get topBarPadding => EdgeInsets.fromLTRB(
        _paddingLeft,
        _realPaddingTop,
        _paddingRight,
        4.0,
      );

  EdgeInsets get bottomBarPadding => EdgeInsets.only(
        bottom: _realPaddingBottom,
        left: _paddingLeft,
        right: _paddingRight,
      );

  /// 是否显示bar
  final RxBool _showBar = false.obs;

  bool get showBar => _showBar.value;

  set showBar(bool val) => _showBar.value = val;

  // 底栏偏移
  double get bottomBarOffset {
    // 底栏底部距离
    _realPaddingBottom =
        Platform.isAndroid ? 20 + _paddingBottom : _paddingBottom;

    // 底栏隐藏时偏移
    final double _offsetBottomHide = _realPaddingBottom + kBottomBarHeight * 2;
    if (showBar) {
      return 0;
    } else {
      return -_offsetBottomHide - 10;
    }
  }

  // 顶栏偏移
  double get topBarOffset {
    final double _offsetTopHide = kTopBarHeight + _paddingTop;
    if (showBar) {
      return 0;
    } else {
      return -_offsetTopHide - 10;
    }
  }

  ViewMode lastViewMode = ViewMode.LeftToRight;

  /// 阅读模式
  Rx<ViewMode> get _viewMode => _ehConfigService.viewMode;

  ViewMode get viewMode => _viewMode.value;

  set viewMode(val) => _viewMode.value = val;

  /// 显示页面间隔

  RxBool get _showPageInterval => _ehConfigService.showPageInterval;

  bool get showPageInterval => _showPageInterval.value;

  set showPageInterval(bool val) => _showPageInterval.value = val;

  bool fade = true;
  bool needRebuild = false;
}
