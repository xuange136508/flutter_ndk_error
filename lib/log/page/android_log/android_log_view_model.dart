import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../ItemMark.dart';
import '../../../ReportProperties.dart';
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

  // 上报日志滚动控制器
  ScrollController logScrollController = ScrollController();

  FlutterListViewController scrollController = FlutterListViewController();

  TextEditingController filterController = TextEditingController();
  TextEditingController findController = TextEditingController();

  bool isCaseSensitive = false;

  bool isShowLast = true;

  String pid = "";

  int findIndex = -1;

  Process? _process;

  // 日志等级
  List<FilterLevel> filterLevel = [
    FilterLevel("Verbose", "*:V"),
    FilterLevel("Debug", "*:D"),
    FilterLevel("Info", "*:I"),
    FilterLevel("Warn", "*:W"),
    FilterLevel("Error", "*:E"),
  ];
  PopUpMenuButtonViewModel<FilterLevel> filterLevelViewModel = PopUpMenuButtonViewModel();

  // 事件类型
  List<FilterLevel> filterEventType = [
    FilterLevel("全部", ""),
    FilterLevel("曝光", "impression"),
    FilterLevel("点击", "click"),
    FilterLevel("分享", "share"),
    FilterLevel("收藏", "collect"),
    FilterLevel("取消收藏", "uncollect"),
    FilterLevel("关注", "attention"),
    FilterLevel("取消关注", "unattention"),
    FilterLevel("关闭", "close"),
    FilterLevel("拖拉", "drag"),
    FilterLevel("长按", "longPress"),
    FilterLevel("点赞", "applaud"),
    FilterLevel("取消点赞", "unapplaud")
  ];
  PopUpMenuButtonViewModel<FilterLevel> eventTypeViewModel = PopUpMenuButtonViewModel();


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

    // 事件类型筛选设置
    eventTypeViewModel.list = filterEventType;
    eventTypeViewModel.selectValue = filterEventType.first;
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
          if (logList.length > 500) {
            logList.removeAt(0);
          }
          // 添加日志
          logList.add(line);

          // 上报日志解析处理
          handleReportList(line);

          // 上报日志滚动到底部
          // logScrollController.jumpTo(
          //   logScrollController.position.maxScrollExtent,
          // );

          // 通知刷新列表
           notifyListeners();

          // 滚动到底部
          // if (isShowLast) {
          //   scrollController.jumpTo(
          //     scrollController.position.maxScrollExtent,
          //   );
          // }
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



  /// 筛选事件类型
  /// */
  void listenerEventType() {
    String event = eventTypeViewModel.selectValue?.value ?? "";
    // 过滤当前日志类型，通知页面刷新


  }


  void copyLog(String log) {
    Clipboard.setData(ClipboardData(text: log));
  }

  void clearLog() {
    logList.clear();
    findIndex = -1;
    notifyListeners();
  }

  List<TableRow> tableRows = [];

  // 表格数据集合
  List<DataRow> dateRows = [];

  //过滤重复日志
  String previousLog = "";

  /// 上报日志解析处理
  /// */
  void handleReportList(String curLog) {
    if (curLog?.isEmpty == true) {
      return;
    }
    if(previousLog != "" && curLog.startsWith(previousLog)){
      //curLog.replaceFirst(previousLog, "");
      //dateRows.removeLast();
      return;
    }
    previousLog = curLog;
    // showToast("打印长度:${logList.length}");
    // List<DataRow> dateRows = [];
    // for (int i = 0; i < logList.length; i++) {
    // 解析上报日志
    ReportProperties? reportProperties = parseDevLog(curLog);
    if (reportProperties != null) {
      String? position = reportProperties?.properties?.first.position;
      String? itemType = reportProperties?.properties?.first.itemType;
      String? event = reportProperties?.event;
      String? itemId = reportProperties?.properties?.first.itemid;
      String? itemMark = reportProperties?.properties?.first.itemMark;
      //包含itemMark需二次解析
      ItemMark? itemMarkBean = parseItemMark(itemMark);
      String? itemName = itemMarkBean?.itemName;
      String? itemMark1 = itemMarkBean?.itemMark1;
      String? itemMark2 = itemMarkBean?.itemMark2;

      // dateRows.add(DataRow(
      //   cells: [
      //     DataCell(getCommonText((dateRows.length + 1).toString(), isLimit: true)),
      //     DataCell(getCommonText(position)),
      //     DataCell(getCommonText(itemType)),
      //     DataCell(getCommonText(event)),
      //     DataCell(getCommonText(itemId)),
      //     DataCell(getCommonText(itemName)),
      //     DataCell(getCommonText(itemMark1)),
      //     DataCell(getCommonText(itemMark2)),
      //     //DataCell(getCommonText('$itemMark')),
      //   ],
      // ));

      //测试
      tableRows.add(TableRow(
              children: [
                getCommonText((tableRows.length + 1).toString(), isLimit: true),
                getCommonText(position),
                getCommonText(itemType),
                getCommonText(event),
                getCommonText(itemId),
                getCommonText(itemName),
                getCommonText(itemMark1),
                getCommonText(itemMark2),
                //getCommonText('$itemMark'),
              ]
          ));
      //const Divider(height: 1.0, indent: 60.0, color: Colors.grey)

      // 上报日志滚动到底部
      logScrollController.jumpTo(
        logScrollController.position.maxScrollExtent,
      );
    }
    // }
  }

  /// 清除上报日志
  /// */
  void clearReport(){
    //dateRows.clear();
    tableRows.clear();
  }


  /// 日志解析
  /// */
  ReportProperties? parseDevLog(String? contents) {
    if(contents?.isEmpty == true || contents == null){
      return null;
    }
    try{
      printLog("内容：$contents");
      // 正则匹配
      RegExp reg = RegExp(r'(?<=ExposuerUtil:)(.*)');
      // 匹配时间
      //RegExp reg = RegExp(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3})');
      if (reg.hasMatch(contents)) {
        var matches = reg.allMatches(contents);
        //printLog("${matches.length}");
        for (int i = 0; i < matches.length; i++) {
          printLog("${matches.elementAt(i).group(0)}");
          // 解析上报数据
          String? jsonData = matches.elementAt(i).group(0);
          ReportProperties reportProperties = ReportProperties.fromJson(jsonDecode(jsonData!));
          return reportProperties;
          // printLog("打印属性：${reportProperties.properties?.first.itemMark}");
          // return reportProperties.properties?.first.position;
          //包含itemMark需二次解析
          // String? mark = reportProperties.properties?.first.itemMark;
          // ItemMark itemMark = ItemMark.fromJson(jsonDecode((mark?.isEmpty == true) ? "" : mark!));
          // printLog("打印itemMark：${itemMark.itemName}");
        }
      } else {
        printLog("匹配失败");
      }
      return null;
    }
    on Exception{
      printLog('解析异常');
      return null;
    }
  }

  /// ItemMark解析
  /// */
  ItemMark? parseItemMark(String? itemMark) {
    if(itemMark?.isEmpty == true || itemMark == null){
      return null;
    }
    try {
      ItemMark itemMarkBean = ItemMark.fromJson(
          jsonDecode(itemMark!));
      return itemMarkBean;
    } on Exception {
      printLog('解析异常');
      return null;
    }
  }

  /// 日志输出
  /// */
  void printLog(Object? object) {
    if (kDebugMode) {
      // print(object);
    }
  }


  /// 设置输出文案格式
  /// */
  Container getCommonText(String? content,{bool isLimit = false}) {
    return Container(
        //margin: EdgeInsets.only(left: 50, right: 50),
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: SizedBox(
            width: isLimit? 30: 160,
            child: Text(validateInput(content),
                //overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  //backgroundColor: Colors.red
                ))
        )
      );
  }
  // Expanded getCommonText(String? content) {
  //   return Expanded(
  //       child: Text(validateInput(content),
  //           overflow: TextOverflow.ellipsis,
  //           textAlign: TextAlign.left,
  //           style: const TextStyle(
  //             fontSize: 14,
  //             //backgroundColor: Colors.red
  //           )));
  //
  // }
  // ConstrainedBox getCommonText(String? content) {
  //   return ConstrainedBox(
  //       constraints: const BoxConstraints(
  //         maxWidth: 100,
  //       ),
  //       child: Text(validateInput(content),
  //           overflow: TextOverflow.ellipsis,
  //           textAlign: TextAlign.left,
  //           style: const TextStyle(
  //               fontSize: 14,
  //               //backgroundColor: Colors.red
  //           ))
  //   );
  // }

  /// 过滤判空
  /// */
  String validateInput(String? input) {
    if (input?.isNotEmpty ?? false) {
      return input!!;
    } else {
      return "";
    }
  }


}

class FilterLevel extends PopUpMenuItem {
  String name;
  String value;

  FilterLevel(this.name, this.value) : super(name);
}
