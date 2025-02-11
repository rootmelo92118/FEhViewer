import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fehviewer/models/base/eh_models.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../global.dart';

const String kDirPath = '/fehviewer';
const String kHistoryDirPath = '/fehviewer/history';
const String kHistoryDtlDirPath = '/fehviewer/history/s';
const String kHistoryDelDirPath = '/fehviewer/history/del';
const String kReadDirPath = '/fehviewer/read';

const String idActionLogin = 'action_login';

const String kAESKey = 'fehviewer is very good!!';
const String kAESIV = '0000000000000000';

class WebdavController extends GetxController {
  late webdav.Client? client;

  WebdavProfile get webdavProfile => Get.find();

  bool get validAccount => webdavProfile.user?.isNotEmpty ?? false;

  bool isLongining = false;

  bool _syncHistory = false;
  bool _syncReadProgress = false;

  bool get syncHistory => _syncHistory;
  bool get syncReadProgress => _syncReadProgress;

  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  // url
  final TextEditingController urlController = TextEditingController();

  // user
  final TextEditingController usernameController = TextEditingController();

  // passwd
  final TextEditingController passwdController = TextEditingController();

  final FocusNode nodeUser = FocusNode();
  final FocusNode nodePwd = FocusNode();

  bool loadingLogin = false;
  bool obscurePasswd = true;

  void switchObscure() {
    obscurePasswd = !obscurePasswd;
    update();
  }

  Future<bool?> pressLoginWebDAV() async {
    if (loadingLogin) {
      return null;
    }

    loadingLogin = true;
    update();
    final rult = await addWebDAVProfile(
      urlController.text,
      user: usernameController.text,
      pwd: passwdController.text,
    );

    loadingLogin = false;
    update();
    return rult;
  }

  set syncHistory(bool val) {
    final _dav = webdavProfile.copyWith(syncHistory: val);
    _syncHistory = val;
    update();
    Global.profile = Global.profile.copyWith(webdav: _dav);
    Global.saveProfile();
  }

  set syncReadProgress(bool val) {
    final _dav = webdavProfile.copyWith(syncReadProgress: val);
    _syncReadProgress = val;
    update();
    Global.profile = Global.profile.copyWith(webdav: _dav);
    Global.saveProfile();
  }

  @override
  void onInit() {
    super.onInit();
    if (webdavProfile.url.isNotEmpty) {
      initClient();

      syncHistory = webdavProfile.syncHistory ?? false;
      syncReadProgress = webdavProfile.syncReadProgress ?? false;
    }

    _key = encrypt.Key.fromUtf8(kAESKey);
    _iv = encrypt.IV.fromUtf8(kAESIV);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  void closeClient() {
    client = null;
  }

  void initClient() {
    logger.d('initClient');
    client = webdav.newClient(
      webdavProfile.url,
      user: webdavProfile.user ?? '',
      password: webdavProfile.password ?? '',
      // debug: true,
    );

    // Set the public request headers
    client?.setHeaders({'accept-charset': 'utf-8'});

    // Set the connection server timeout time in milliseconds.
    client?.setConnectTimeout(8000);

    // Set send data timeout time in milliseconds.
    client?.setSendTimeout(8000);

    // Set transfer data time in milliseconds.
    client?.setReceiveTimeout(8000);

    checkDir(dir: kHistoryDtlDirPath)
        .then((value) => checkDir(dir: kHistoryDelDirPath))
        .then((value) => checkDir(dir: kReadDirPath));
  }

  Future<void> checkDir({String dir = kDirPath}) async {
    if (client == null) {
      return;
    }
    try {
      final list = await client!.readDir(dir);
      logger.v('$dir\n${list.map((e) => '${e.name} ${e.mTime}').join('\n')}');
    } on DioError catch (err) {
      if (err.response?.statusCode == 404) {
        logger.d('dir 404, mkdir...');
        await client!.mkdirAll(dir);
      }
    }
  }

  String _getIndexFileName() {
    final DateTime _now = DateTime.now();
    final DateFormat formatter = DateFormat('yyyyMMdd_HHmmss');
    final String _fileName = formatter.format(_now);
    return 'fe_his_index_$_fileName';
  }

  Future<List<String>> getRemotFileList() async {
    if (client == null) {
      return [];
    }
    final list = await client!.readDir(kHistoryDtlDirPath);
    final names = list.map((e) => e.name).toList();
    final _list = <String>[];
    for (final name in names) {
      if (name != null && name.endsWith('.json')) {
        _list.add(name.substring(0, name.indexOf('.')));
      }
    }
    return _list;
  }

  Future<List<String>> getRemotDeleteList() async {
    if (client == null) {
      return [];
    }
    final list = await client!.readDir(kHistoryDelDirPath);
    final names = list.map((e) => e.name).toList();
    final _list = <String>[];
    for (final name in names) {
      if (name != null) {
        _list.add(name);
      }
    }
    return _list;
  }

  Future updateRemoveFlg(String gid) async {
    if (client == null) {
      return;
    }
    await client!.write('$kHistoryDelDirPath/$gid', Uint8List.fromList([]));
  }

  Future<List<HistoryIndexGid>> getRemoteHistoryList() async {
    if (client == null) {
      return [];
    }
    final list = await client!.readDir(kHistoryDtlDirPath);
    final hisObjs = list.map((e) {
      final name = e.name?.substring(0, e.name?.lastIndexOf('.'));
      final gid = name?.split('_')[0];
      final time = int.parse(name?.split('_')[1] ?? '0');
      return HistoryIndexGid(g: gid, t: time);
    }).toList();
    final _list = <HistoryIndexGid>[];
    for (final his in hisObjs) {
      if (his.g != null && his.t! > 0) {
        _list.add(his);
      }
    }
    return _list;
  }

  int _mTime2MillisecondsSinceEpoch(String mTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final _mTime = formatter.parse(mTime);
    return _mTime.millisecondsSinceEpoch;
  }

  Future<void> uploadHistory(GalleryProvider his) async {
    if (client == null) {
      return;
    }
    logger.v('uploadHistory');
    final _path = path.join(Global.tempPath, his.gid);
    final File _file = File(_path);
    final _his = his.copyWith(
      galleryComment: [],
      galleryImages: [],
      tagGroup: [],
    );

    try {
      final _text = jsonEncode(_his);
      // final base64Text = base64Encode(utf8.encode(_text));
      final encrypted = _encrypter.encrypt(_text, iv: _iv);
      logger.v('encrypted.base64 ${encrypted.base64}');
      _file.writeAsStringSync(encrypted.base64);

      await client!.writeFromFile(
          _path, '$kHistoryDtlDirPath/${his.gid}_${his.lastViewTime}.json');
    } on DioError catch (err) {
      logger.d('${err.response?.statusCode}');
      if (err.response?.statusCode == 404) {
        logger.d('file 404');
        rethrow;
      } else {
        rethrow;
      }
    } catch (e, stack) {
      logger.e('$e\n$stack');
      // rethrow;
    }
  }

  Future<GalleryProvider?> downloadHistory(String fileName) async {
    if (client == null) {
      return null;
    }
    logger.v('downloadHistory');
    final _path = path.join(Global.tempPath, fileName);
    try {
      await client!.read2File('$kHistoryDtlDirPath/$fileName.json', _path);
      final File _file = File(_path);
      if (!_file.existsSync()) {
        return null;
      }
      final String _fileText = _file.readAsStringSync();

      late String jsonText;
      if (_fileText.startsWith('{')) {
        jsonText = _fileText;
      } else {
        // jsonText = utf8.decode(base64Decode(_fileText));
        jsonText = _encrypter.decrypt64(_fileText, iv: _iv);
      }
      final _image = GalleryProvider.fromJson(
          jsonDecode(jsonText) as Map<String, dynamic>);

      return _image;
    } catch (err) {
      logger.e('$err');
      return null;
    }
  }

  void chkReadTempDir() {
    final _dirPath = path.join(Global.tempPath, 'read');
    final Directory _directory = Directory(_dirPath);
    if (!_directory.existsSync()) {
      _directory.createSync(recursive: true);
    }
  }

  Future<void> uploadRead(GalleryCache read) async {
    if (client == null) {
      return;
    }
    logger.d('uploadRead');
    chkReadTempDir();

    final _path = path.join(Global.tempPath, 'read', read.gid);
    final File _file = File(_path);
    final _read = read.copyWith(
      columnModeVal: '',
    );
    final _text = jsonEncode(_read);
    // final base64Text = base64Encode(utf8.encode(_text));
    final encrypted = _encrypter.encrypt(_text, iv: _iv);
    _file.writeAsStringSync(encrypted.base64);

    try {
      await client!.writeFromFile(_path, '$kReadDirPath/${read.gid}.json');
    } on DioError catch (err) {
      logger.d('${err.response?.statusCode}');
      if (err.response?.statusCode == 404) {
        logger.d('file 404');
        rethrow;
      } else {
        rethrow;
      }
    } catch (e, stack) {
      logger.e('$e\n$stack');
    }
  }

  Future<GalleryCache?> downloadRead(String gid) async {
    if (client == null) {
      return null;
    }
    logger.d('downloadRead');
    chkReadTempDir();
    final _path = path.join(Global.tempPath, 'read', gid);
    try {
      await client!.read2File('$kReadDirPath/$gid.json', _path);
      final File _file = File(_path);
      if (!_file.existsSync()) {
        return null;
      }
      final String _fileText = _file.readAsStringSync();
      late String jsonText;
      if (_fileText.startsWith('{')) {
        jsonText = _fileText;
      } else {
        // jsonText = utf8.decode(base64Decode(_fileText));
        jsonText = _encrypter.decrypt64(_fileText, iv: _iv);
      }
      final _read =
          GalleryCache.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);

      return _read;
    } catch (err) {
      logger.e('$err');
      return null;
    }
  }

  Future<List<String>> getRemotReadList() async {
    if (client == null) {
      return [];
    }
    final list = await client!.readDir(kReadDirPath);
    final names = list
        .map((e) => e.name?.substring(0, e.name?.lastIndexOf('.')))
        .toList();
    final _list = <String>[];
    for (final name in names) {
      if (name != null) {
        _list.add(name);
      }
    }
    return _list;
  }

  Future<void> _pingWebDAV(String url, {String? user, String? pwd}) async {
    final client = webdav.newClient(
      url,
      user: user ?? '',
      password: pwd ?? '',
    );

    await client.ping();
  }

  Future<bool> addWebDAVProfile(String url, {String? user, String? pwd}) async {
    isLongining = true;
    update([idActionLogin]);
    bool rult = false;
    try {
      _pingWebDAV(url, user: user, pwd: pwd);
      rult = true;
    } catch (e, stack) {
      logger.e('$e\n$stack');
      showToast('$e\n$stack');
    }
    if (rult) {
      // 保存账号 rebuild
      WebdavProfile webdavUser =
          WebdavProfile(url: url, user: user, password: pwd);
      Global.profile = Global.profile.copyWith(webdav: webdavUser);
      Global.saveProfile();
      Get.replace(webdavUser);
      initClient();
    }
    isLongining = false;
    // update([idActionLogin]);
    update();
    return rult;
  }

  Future<void> deleteHistory(HistoryIndexGid? oriRemote) async {
    if (client == null || oriRemote == null) {
      return;
    }

    try {
      await client!
          .remove('$kHistoryDtlDirPath/${oriRemote.g}_${oriRemote.t}.json');
    } catch (err) {
      logger.e('$err');
      return;
    }
  }

  String encryptAES(String plainText) {
    return '';
  }
}
