import 'package:fehviewer/common/service/controller_tag_service.dart';
import 'package:fehviewer/common/service/layout_service.dart';
import 'package:fehviewer/const/const.dart';
import 'package:fehviewer/fehviewer.dart';
import 'package:fehviewer/models/index.dart';
import 'package:fehviewer/network/api.dart';
import 'package:fehviewer/pages/gallery/comm.dart';
import 'package:fehviewer/pages/gallery/controller/comment_controller.dart';
import 'package:fehviewer/pages/gallery/controller/gallery_page_controller.dart';
import 'package:fehviewer/pages/gallery/controller/gallery_page_state.dart';
import 'package:fehviewer/pages/gallery/view/const.dart';
import 'package:fehviewer/pages/gallery/view/gallery_page.dart';
import 'package:fehviewer/pages/gallery/view/gallery_widget.dart';
import 'package:fehviewer/pages/gallery/view/sliver/slivers.dart';
import 'package:fehviewer/pages/tab/view/gallery_base.dart';
import 'package:fehviewer/route/routes.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/widget/refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:share/share.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../header.dart';

const double kHeaderHeight = 200.0 + 52;

class GallerySliverPage extends StatefulWidget {
  @override
  _GallerySliverPageState createState() => _GallerySliverPageState();
}

class _GallerySliverPageState extends State<GallerySliverPage> {
  late final GalleryPageController _controller;
  final _tag = pageCtrlTag;

  GalleryPageState get pageState => _controller.gState;

  @override
  void initState() {
    super.initState();
    logger.v('initState pageCtrlTag:$pageCtrlTag');
    initPageController(tag: _tag);
    _controller = Get.put(GalleryPageController(), tag: _tag);

    Future.delayed(const Duration(milliseconds: 100)).then((value) {
      _controller.scrollController =
          PrimaryScrollController.of(context) ?? ScrollController();
      _controller.scrollController
          .addListener(_controller.scrollControllerLister);
    });
  }

  @override
  void dispose() {
    super.dispose();
    // deletePageController(tag: _tag);
  }

  @override
  Widget build(BuildContext context) {
    final dynamic tabTag = pageState.galleryRepository?.tabTag;
    final GalleryProvider? galleryProvider = pageState.galleryProvider;

    return CupertinoPageScaffold(
      child: CupertinoScrollbar(
        controller: PrimaryScrollController.of(context),
        child: EasyRefresh(
          enableControlFinishRefresh: false,
          enableControlFinishLoad: false,
          onLoad: () async {
            if (pageState.images.isNotEmpty) {
              Get.toNamed(
                EHRoutes.galleryAllPreviews,
                id: isLayoutLarge ? 2 : null,
              );
            }
          },
          footer: BezierBounceFooter(
            backgroundColor: Colors.transparent,
            color: CupertinoColors.inactiveGray,
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // 导航栏
              buildCupertinoSliverNavigationBar(context, galleryProvider),
              // 下拉刷新
              EhCupertinoSliverRefreshControl(
                onRefresh: _controller.handOnRefresh,
              ),
              // 头部
              if (pageState.fromUrl)
                GalleryObxSliver(
                  (state) => SliverToBoxAdapter(
                    child: GalleryHeader(
                      initGalleryProvider: state,
                      tabTag: tabTag,
                    ),
                  ),
                  pageController: _controller,
                )
              else if (galleryProvider != null)
                SliverToBoxAdapter(
                  child: GalleryHeader(
                    initGalleryProvider: galleryProvider,
                    tabTag: tabTag,
                  ),
                ),

              GalleryObxSliver(
                (state) => SliverToBoxAdapter(
                  child: GalleryAtions(
                    galleryProvider: state,
                    pageController: _controller,
                  ),
                ),
                pageController: _controller,
                showLoading: true,
              ),
              // tag 标题
              SliverToBoxAdapter(
                  child: MiniTitle(title: L10n.of(context).tags)),
              // tag
              GalleryObxSliver(
                (state) => SliverPadding(
                  padding: const EdgeInsets.only(
                      left: kPadding, right: kPadding, bottom: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return TagGroupItem(
                            tagGroupData: (state.tagGroup ?? [])[index]);
                      },
                      childCount: (state.tagGroup ?? []).length,
                    ),
                  ),
                ),
                pageController: _controller,
              ),
              // 最上面的部分评论 小标题
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    MiniTitle(title: L10n.of(context).gallery_comments),
                    const Spacer(),
                  ],
                ),
              ),
              // 最上面的部分评论 评论内容
              GalleryObxSliver(
                (state) {
                  return SliverPadding(
                    padding: const EdgeInsets.only(
                        left: kPadding, right: kPadding, bottom: 20),
                    sliver: SliverToBoxAdapter(
                      child: GestureDetector(
                        behavior: HitTestBehavior.deferToChild,
                        onTap: () => Get.toNamed(
                          EHRoutes.galleryComment,
                          id: isLayoutLarge ? 2 : null,
                        ),
                        // child: const TopComment(showBtn: false),
                        child: Obx(() {
                          return TopCommentEx(
                            key: ValueKey(_controller.gState.comments
                                .map((e) => e.id)
                                .join('')),
                            comments: _controller.gState.comments,
                          );
                        }),
                      ),
                    ),
                  );
                },
                pageController: _controller,
              ),
              // 缩略图
              GalleryObxSliver(
                (state) => SliverPadding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: kPadding,
                    right: kPadding,
                  ),
                  sliver: PreviewSliverGrid(
                    images: pageState.firstPageImage,
                    gid: state.gid ?? '',
                  ),
                ),
                pageController: _controller,
              ),
              GalleryObxSliver(
                (state) => SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20),
                  sliver: SliverToBoxAdapter(
                    child: MorePreviewButton(
                        hasMorePreview: pageState.hasMoreImage),
                  ),
                ),
                pageController: _controller,
              ),
            ],
          ),
        ),
      ),
    );
  }

  CupertinoSliverNavigationBar buildCupertinoSliverNavigationBar(
      BuildContext context, GalleryProvider? provider) {
    return CupertinoSliverNavigationBar(
      padding: const EdgeInsetsDirectional.only(end: 10),
      largeTitle: GetBuilder<GalleryPageController>(
        id: GetIds.PAGE_VIEW_HEADER,
        tag: pageCtrlTag,
        builder: (logic) {
          return SelectableText(
            logic.gState.topTitle,
            textAlign: TextAlign.start,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel, context),
              fontWeight: FontWeight.normal,
              fontStyle: FontStyle.italic,
            ),
          );
        },
      ),
      middle: Obx(
        () => pageState.hideNavigationBtn
            ? const SizedBox()
            : GetBuilder<GalleryPageController>(
                id: GetIds.PAGE_VIEW_HEADER,
                tag: pageCtrlTag,
                builder: (logic) {
                  return NavigationBarImage(
                    imageUrl: logic.gState.galleryProvider?.imgUrl ?? '',
                    scrollController: logic.scrollController,
                  );
                },
              ),
      ),
      trailing: Obx(() => pageState.hideNavigationBtn
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  minSize: 38,
                  child: const MouseRegionClick(
                    child: Icon(
                      FontAwesomeIcons.tags,
                      size: 22,
                    ),
                  ),
                  onPressed: () {
                    _controller.addTag();
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(0),
                  minSize: 38,
                  child: const MouseRegionClick(
                    child: Icon(
                      FontAwesomeIcons.share,
                      size: 22,
                    ),
                  ),
                  onPressed: () {
                    if (provider == null) {
                      return;
                    }
                    final String _url =
                        '${Api.getBaseUrl()}/g/${provider.gid}/${provider.token}';
                    logger.v('share $_url');
                    Share.share(_url);
                  },
                ),
              ],
            )
          : ReadButton(gid: provider?.gid ?? '0').paddingOnly(right: 4)),
    );
  }
}
