import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../page/common/base_view_model.dart';
import '../../widget/pop_up_menu_button.dart';
import '../common/app.dart';
import '../common/package_help_mixin.dart';

class AndroidLogViewModel extends BaseViewModel with PackageHelpMixin {
  static const String colorLogKey = 'colorLog';
  static const String filterPackageKey = 'filterPackage';
  static const String caseSensitiveKey = 'caseSensitive';

  String deviceId;

  bool isFilterPackage = false;
  String filterContent = "";

  List<String> logList = [];

  FlutterListViewController scrollController = FlutterListViewController();

  TextEditingController filterController = TextEditingController();
  TextEditingController findController = TextEditingController();

  bool isCaseSensitive = false;

  bool isShowLast = true;

  String pid = "";

  int findIndex = -1;

  Process? _process;

  List<FilterLevel> filterLevel = [
    FilterLevel("Verbose", "*:V"),
    FilterLevel("Debug", "*:D"),
    FilterLevel("Info", "*:I"),
    FilterLevel("Warn", "*:W"),
    FilterLevel("Error", "*:E"),
  ];
  PopUpMenuButtonViewModel<FilterLevel> filterLevelViewModel =
      PopUpMenuButtonViewModel();

  AndroidLogViewModel(
    BuildContext context,
    this.deviceId,
  ) : super(context) {
    App().eventBus.on<DeviceIdEvent>().listen((event) async {
      logList.clear();
      deviceId = event.deviceId;
      kill();
      if (deviceId.isEmpty) {
        resetPackage();
        return;
      }
      await getInstalledApp(deviceId);
      listenerLog();
    });
    App().eventBus.on<AdbPathEvent>().listen((event) {
      logList.clear();
      adbPath = event.path;
      kill();
      listenerLog();
    });
    SharedPreferences.getInstance().then((preferences) {
      isFilterPackage = preferences.getBool(filterPackageKey) ?? false;
      isCaseSensitive = preferences.getBool(caseSensitiveKey) ?? false;
    });

    filterController.addListener(() {
      filter(filterController.text);
    });
    findController.addListener(() {
      findIndex = -1;
      notifyListeners();
    });
    filterLevelViewModel.list = filterLevel;
    filterLevelViewModel.selectValue = filterLevel.first;
    filterLevelViewModel.addListener(() {
      kill();
      listenerLog();
    });
  }

  void init() async {
    adbPath = await App().getAdbPath();
    await getInstalledApp(deviceId);
    pid = await getPid();
    execAdb(["-s", deviceId, "logcat", "-c"]);
    listenerLog();
  }

  void selectPackageName(BuildContext context) async {
    var package = await showPackageSelect(context, deviceId);
    if (packageName == package || package.isEmpty) {
      return;
    }
    packageName = package;
    if (isFilterPackage) {
      logList.clear();
      pid = await getPid();
      kill();
      listenerLog();
      notifyListeners();
    }
  }


  /// 添加抓取adb日志监听方法
  /// */
  void listenerLog() {
    String level = filterLevelViewModel.selectValue?.value ?? "";
    // 设置日志等级
    var list = ["-s", deviceId, "logcat", "$level"];
    if (isFilterPackage) {
      // 过滤应用包名
      list.add("--pid=$pid");
    }
    // 执行adb命令抓取日志
    execAdb(list, onProcess: (process) {
      _process = process;
      process.stdout.transform(const Utf8Decoder()).listen((line) {
        // 过滤包含的关键字
        if (filterContent.isNotEmpty
            ? line.toLowerCase().contains(filterContent.toLowerCase())
            : true) {
          if (logList.length > 1000) {
            logList.removeAt(0);
          }
          // 添加日志
          logList.add(line);

          // 通知刷新列表
           notifyListeners();
          // 滚动到底部
          if (isShowLast) {
            scrollController.jumpTo(
              scrollController.position.maxScrollExtent,
            );
          }
        }
      });
    });
  }

  void filter(String value) {
    filterContent = value;
    if (value.isNotEmpty) {
      logList.removeWhere((element) => !element.contains(value));
    }
    notifyListeners();
  }

  Color getLogColor(String log) {
    var split = log.split(" ");
    split.removeWhere((element) => element.isEmpty);
    String type = "";
    if (split.length > 4) {
      type = split[4];
    }
    switch (type) {
      case "V":
        break;
      case "D":
        return const Color(0xFF017F14);
      case "I":
        return const Color(0xFF0585C1);
      case "W":
        return const Color(0xFFBBBB23);
      case "E":
        return const Color(0xFFFF0006);
      case "F":
      default:
        break;
    }
    return const Color(0xFF383838);
  }

  /// 根据包名获取进程应用进程id
  Future<String> getPid() async {
    var result = await execAdb([
      "-s",
      deviceId,
      "shell",
      "ps | grep ${packageName} | awk '{print \$2}'"
    ]);
    if (result == null) {
      return "";
    }
    return result.stdout.toString().trim();
  }

  void kill() {
    _process?.kill();
    shell.kill();
  }

  Future<void> setFilterPackage(bool value) async {
    isFilterPackage = value;
    SharedPreferences.getInstance().then((preferences) {
      preferences.setBool(filterPackageKey, value);
    });
    if (value) {
      pid = await getPid();
      logList.removeWhere((element) => !element.contains(pid));
    }
    kill();
    listenerLog();
    notifyListeners();
  }




  void copyLog(String log) {
    Clipboard.setData(ClipboardData(text: log));
  }

  void clearLog() {
    logList.clear();
    findIndex = -1;
    notifyListeners();
  }
}

class FilterLevel extends PopUpMenuItem {
  String name;
  String value;

  FilterLevel(this.name, this.value) : super(name);
}
