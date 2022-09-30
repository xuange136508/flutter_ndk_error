import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:substring_highlight/substring_highlight.dart';

import '../../../ItemMark.dart';
import '../../../ReportProperties.dart';
import '../../../widgets/text_view.dart';
import '../../widget/adb_setting_dialog.dart';
import '../../widget/pop_up_menu_button.dart';
import '../common/base_page.dart';
import 'android_log_view_model.dart';

class AndroidLogPage extends StatefulWidget {
  final String deviceId;
  final String adbPathParams;

  const AndroidLogPage(this.adbPathParams,this.deviceId, {Key? key}) : super(key: key);

  @override
  State<AndroidLogPage> createState() => _AndroidLogPageState();
}

class _AndroidLogPageState
    extends BasePage<AndroidLogPage, AndroidLogViewModel> {
  @override
  void initState() {
    super.initState();
    viewModel.init();
    viewModel.adbPath = widget.adbPathParams;
  }

  @override
  Widget contentView(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 16),
            const TextView("筛选："),
            Expanded(
              child: Container(
                height: 33,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // decoration: BoxDecoration(
                //   border: Border.all(color: Colors.grey),
                //   borderRadius: BorderRadius.circular(5),
                // ),
                child: TextField(
                  controller: viewModel.filterController,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    hintText: "请输入需要筛选的内容",
                    border: OutlineInputBorder(),
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const TextView("级别："),
            Container(
              height: 33,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: PopUpMenuButton(
                viewModel: viewModel.filterLevelViewModel,
                menuTip: "选择筛选级别",
              ),
            ),
            const SizedBox(width: 12),
            const TextView("应用："),
            // 选择筛选的应用包名
            packageNameView(context),
            const SizedBox(width: 12),
            // 是否筛选应用
            Selector<AndroidLogViewModel, bool>(
              selector: (context, viewModel) => viewModel.isFilterPackage,
              builder: (context, isFilter, child) {
                return Checkbox(
                  value: isFilter,
                  onChanged: (value) {
                    viewModel.setFilterPackage(value ?? false);
                  },
                );
              },
            ),
            const TextView("筛选应用"),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () {
                viewModel.clearLog();
                //顺便清除上报日志
                clearReport();
              },
              child: const TextView("清除"),
            ),
            const SizedBox(width: 16),
          ],
        ),

        //adb设置
        AdbSettingDialog(viewModel.adbPath),

        //上报点位筛选框
        _buildReportView(),

        //日志内容显示框
        _buildLogContentView(),
        const SizedBox(height: 10),
      ],
    );
  }

  List<DataRow> dateRows = [];

  /// 上报日志分析的表格
  /// */
  Expanded _buildReportView() {
    return Expanded(
      child: Container(
          width: MediaQuery.of(context).size.width,
          color: const Color(0xFFF0F0F0),
          child: Consumer<AndroidLogViewModel>(
            builder: (context, viewModel, child) {
              var logList = viewModel.logList;

              // showToast("打印长度:${logList.length}");
              // List<DataRow> dateRows = [];
              // for (int i = 0; i < logList.length; i++) {
              if(logList.isNotEmpty){
                // 解析上报日志
                ReportProperties? reportProperties = parseDevLog(logList[logList.length - 1]);
                if(reportProperties != null){
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

                  dateRows.add(DataRow(
                    cells: [
                      DataCell(getCommonText((dateRows.length + 1).toString())),
                      DataCell(getCommonText(position)),
                      DataCell(getCommonText(itemType)),
                      DataCell(getCommonText(event)),
                      DataCell(getCommonText(itemId)),
                      DataCell(getCommonText(itemName)),
                      DataCell(getCommonText(itemMark1)),
                      DataCell(getCommonText(itemMark2)),
                      //DataCell(getCommonText('$itemMark')),
                    ],
                  ));
                }
                // }
              }

              if(dateRows.length == 1000){
                showToast("上报日志已满，建议清理");
              }
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(columns: [
                  DataColumn(label: getCommonText('序号')),
                  DataColumn(label: getCommonText('点位名(position)')),
                  DataColumn(label: getCommonText('点位类型(item_type)')),
                  DataColumn(label: getCommonText('事件类型(event)')),
                  DataColumn(label: getCommonText('点位内容ID(item_id)')),
                  DataColumn(label: getCommonText('点位内容名称(item_name)')),
                  DataColumn(label: getCommonText('扩展内容1(item_mark_1)')),
                  DataColumn(label: getCommonText('扩展内容2(item_mark_2)')),
                  //DataColumn(label: getCommonText('扩展内容(item_mark)')),
                ], rows: dateRows),
              );
            },
          )),
    );
  }

  /// 清除上报日志
  /// */
  void clearReport(){
    dateRows.clear();
  }


  /// 设置输出文案格式
  /// */
  Expanded getCommonText(String? content) {
    return Expanded(
        child: Text(validateInput(content),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(
                fontSize: 14,
                //backgroundColor: Colors.red
            )));

  }


  /// 过滤判空
  /// */
  String validateInput(String? input) {
    if (input?.isNotEmpty ?? false) {
      return input!!;
    } else {
      return "";
    }
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



  /// 日志内容显示
  /// */
  Expanded _buildLogContentView() {
    return Expanded(
      child: Container(
        color: const Color(0xFFF0F0F0),
        child: Consumer<AndroidLogViewModel>(
          builder: (context, viewModel, child) {
            return FlutterListView(
              controller: viewModel.scrollController,
              delegate: FlutterListViewDelegate(
                (context, index) {
                  var log = viewModel.logList[index];
                  Color textColor = viewModel.getLogColor(log);
                  return Listener(
                    onPointerDown: (event) {
                      if (event.kind == PointerDeviceKind.mouse &&
                          event.buttons == kSecondaryMouseButton) {
                        //点击鼠标右键进行复制
                        viewModel.copyLog(log);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3, horizontal: 15),
                      child: SubstringHighlight(
                        text: log,
                        textStyle: TextStyle(
                          color: textColor,
                        ),
                        textStyleHighlight: TextStyle(
                          color: viewModel.findIndex == index
                              ? Colors.white
                              : textColor,
                          backgroundColor: viewModel.findIndex == index
                              ? Colors.red
                              : Colors.yellowAccent,
                          fontWeight: viewModel.findIndex == index
                              ? FontWeight.bold
                              : null,
                        ),
                        // 区分大小写
                        caseSensitive: viewModel.isCaseSensitive,
                        // 查找关键词高亮显示
                        term: viewModel.findController.text,
                      ),
                    ),
                  );
                },
                childCount: viewModel.logList.length,
              ),
            );
          },
        ),
      ),
    );
  }


  /// 包名修改组件
  /// */
  Widget packageNameView(BuildContext context) {
    return InkWell(
      onTap: () {
        viewModel.selectPackageName(context);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black.withOpacity(0.5)),
        ),
        height: 33,
        child: Row(
          children: [
            const SizedBox(width: 10),
            Selector<AndroidLogViewModel, String>(
              selector: (context, viewModel) => viewModel.packageName,
              builder: (context, packageName, child) {
                return TextView(
                  packageName.isEmpty ? "未选择筛选应用" : packageName,
                  color: const Color(0xFF666666),
                  fontSize: 12,
                );
              },
            ),
            const SizedBox(
              width: 5,
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  @override
  createViewModel() {
    return AndroidLogViewModel(
      context,
      widget.deviceId,
    );
  }

  @override
  void dispose() {
    super.dispose();
    viewModel.kill();
    viewModel.scrollController.dispose();
  }


}
