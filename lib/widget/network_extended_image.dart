import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fehviewer/fehviewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NetworkExtendedImage extends StatefulWidget {
  const NetworkExtendedImage({
    Key? key,
    required this.url,
    this.height,
    this.width,
    this.fit,
    this.retries = 3,
    this.placeholder,
    this.errorWidget,
    this.progressIndicatorBuilder,
  }) : super(key: key);
  final String url;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final int retries;

  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  @override
  _NetworkExtendedImageState createState() => _NetworkExtendedImageState();
}

class _NetworkExtendedImageState extends State<NetworkExtendedImage>
    with SingleTickerProviderStateMixin {
  Map<String, String> _httpHeaders = {};
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    _httpHeaders = {
      'Cookie': Global.profile.user.cookie,
      'host': Uri.parse(widget.url).host,
    };

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url.dfUrl,
      width: widget.width,
      height: widget.height,
      headers: _httpHeaders,
      retries: widget.retries,
      fit: widget.fit,
      // enableLoadState: false,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            // return null;
            return widget.placeholder?.call(context, widget.url.dfUrl) ??
                Container(
                  alignment: Alignment.center,
                  child: const CupertinoActivityIndicator(),
                );
          case LoadState.completed:
            animationController.forward();

            return FadeTransition(
              opacity: animationController,
              child: state.completedWidget,
            );

          // return ExtendedRawImage(
          //   fit: BoxFit.contain,
          //   image: state.extendedImageInfo?.image,
          // );

          // return FadeTransition(
          //   opacity: animationController,
          //   child: ExtendedRawImage(
          //     fit: BoxFit.contain,
          //     image: state.extendedImageInfo?.image,
          //   ),
          // );
          case LoadState.failed:
            return Container(
              alignment: Alignment.center,
              child: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}

class ExtendedImageRect extends StatefulWidget {
  const ExtendedImageRect({
    Key? key,
    required this.url,
    this.sourceRect,
    this.height,
    this.width,
    this.fit,
    this.onLoadComplet,
  }) : super(key: key);
  final String url;
  final Rect? sourceRect;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final VoidCallback? onLoadComplet;

  @override
  _ExtendedImageRectState createState() => _ExtendedImageRectState();
}

class _ExtendedImageRectState extends State<ExtendedImageRect>
    with SingleTickerProviderStateMixin {
  Map<String, String> _httpHeaders = {};
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    _httpHeaders = {
      'Cookie': Global.profile.user.cookie,
      'host': Uri.parse(widget.url).host,
    };

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      widget.url.dfUrl,
      width: widget.width,
      height: widget.height,
      headers: _httpHeaders,
      // fit: widget.fit,
      fit: BoxFit.fitHeight,
      // enableLoadState: false,
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            // return null;
            return Center(
              child: Container(
                alignment: Alignment.center,
                color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGrey5.withOpacity(0.2), context),
                child: const CupertinoActivityIndicator(),
              ),
            );
          case LoadState.completed:
            animationController.forward();

            widget.onLoadComplet?.call();

            return ExtendedRawImage(
              image: state.extendedImageInfo?.image,
              width: widget.sourceRect?.width,
              height: widget.sourceRect?.height,
              fit: BoxFit.fill,
              sourceRect: widget.sourceRect,
            );

            return state.completedWidget;

            // return ExtendedRawImage(
            //   fit: BoxFit.contain,
            //   image: state.extendedImageInfo?.image,
            // );

            return FadeTransition(
              opacity: animationController,
              child: ExtendedRawImage(
                fit: BoxFit.contain,
                image: state.extendedImageInfo?.image,
              ),
            );
          case LoadState.failed:
            return Container(
              alignment: Alignment.center,
              child: const Icon(
                Icons.error,
                color: Colors.red,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
