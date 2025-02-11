import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:fehviewer/pages/image_view/view/view_page.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../common.dart';
import '../controller/view_controller.dart';
import 'view_image.dart';

class ImagePageView extends GetView<ViewExtController> {
  const ImagePageView({Key? key, this.reverse = false}) : super(key: key);
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final imageView = GetBuilder<ViewExtController>(
      id: idSlidePage,
      builder: (logic) {
        if (logic.vState.columnMode != ViewColumnMode.single) {
          // 双页
          return PhotoViewGallery.builder(
              backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
              pageController: logic.pageController,
              itemCount: logic.vState.pageCount,
              onPageChanged: (pageIndex) =>
                  controller.handOnPageChanged(pageIndex),
              scrollDirection: Axis.horizontal,
              customSize: context.mediaQuery.size,
              scrollPhysics: const CustomScrollPhysics(),
              reverse: reverse,
              builder: (BuildContext context, int pageIndex) {
                // 双页
                return PhotoViewGalleryPageOptions.customChild(
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 5,
                  // scaleStateCycle: lisviewScaleStateCycle,
                  controller: logic.photoViewController,
                  // scaleStateController: logic.photoViewScaleStateController,
                  // disableGestures: true,
                  child: DoublePageView(pageIndex: pageIndex),
                );
              });
        } else {
          if (controller.isPhotoView) {
            /// PhotoView 的看图组件
            /// 存在的问题 子组件和 PhotoViewGallery 没有直接关联
            /// 双击放大图片（子组件的功能）后，PhotoViewGallery 左右滑动时会直接翻页
            /// 需要双指放大图片（PhotoViewGallery），左右滑动才会滑动图片本身
            return PhotoViewGallery.builder(
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                pageController: logic.pageController,
                itemCount: logic.vState.pageCount,
                onPageChanged: (pageIndex) =>
                    controller.handOnPageChanged(pageIndex),
                scrollDirection: Axis.horizontal,
                customSize: context.mediaQuery.size,
                scrollPhysics: const CustomScrollPhysics(),
                reverse: reverse,
                builder: (BuildContext context, int pageIndex) {
                  return PhotoViewGalleryPageOptions.customChild(
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 5,
                    controller: logic.photoViewController,
                    child: ViewImage(
                      imageSer: pageIndex + 1,
                    ),
                  );
                });
          }

          /// ExtendedImageGesturePageView 的看图功能
          /// 存在问题。更新 flutter3 后，Android系统下手势操作异常，不能正常进行滑动
          return ExtendedImageGesturePageView.builder(
            controller: logic.extendedPageController,
            itemCount: logic.vState.pageCount,
            onPageChanged: (pageIndex) =>
                controller.handOnPageChanged(pageIndex),
            scrollDirection: Axis.horizontal,
            // physics: const CustomScrollPhysics(),
            reverse: reverse,
            itemBuilder: (BuildContext context, int index) {
              logger.v('pageIndex $index ser ${index + 1}');

              /// 单页
              ///
              ///  20220519 initialScale 设置默认超过1的比例，暂时能解决手势不能滑动的问题
              /// 但是 enableSlideOutPage 的效果会丢失
              ///
              /// 更新：extended_image 6.2.1 好像已经解决  不设置超过 1.0 的 initialScale也能滑动了
              return ViewImage(
                imageSer: index + 1,
                // enableDoubleTap: false,
                // initialScale:
                //     logic.vState.showPageInterval ? 1.000001 : 1.000001,
                // initialScale: GetPlatform.isAndroid ? 1.00000 : 1.0,
                mode: ExtendedImageMode.gesture,
                // enableSlideOutPage: !GetPlatform.isAndroid,
              );
            },
          );
        }
      },
    );

    // return imageView;

    // 上下滑动图片 返回
    return ExtendedImageSlidePage(
      child: imageView,
      slideAxis: SlideAxis.vertical,
      slideType: SlideType.wholePage,
      resetPageDuration: const Duration(milliseconds: 300),
      slidePageBackgroundHandler: (Offset offset, Size pageSize) {
        double opacity = 0.0;
        opacity = offset.distance /
            (Offset(pageSize.width, pageSize.height).distance / 2.0);
        return CupertinoColors.systemBackground.darkColor
            .withOpacity(min(1.0, max(1.0 - opacity, 0.0)));
      },
      onSlidingPage: (ExtendedImageSlidePageState state) {
        if (controller.vState.showBar) {
          controller.vState.showBar = !state.isSliding;
          controller.update([idViewBar]);
        }
      },
    );
  }
}
