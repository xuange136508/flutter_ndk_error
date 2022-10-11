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
        //adb设置
        AdbSettingDialog(viewModel.adbPath),
        const SizedBox(height: 5),

        Row(
          children: [
            const SizedBox(width: 20),
            const TextView("事件类型："),
            //事件类型过滤
            filterEventType(),
            const SizedBox(width: 12),
            SizedBox(
              height: 30,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  side: const BorderSide(width: 1, color: Colors.grey),
                ),
                onPressed: () {
                  viewModel.tableRows.clear();
                  viewModel.totalLogList.clear();
                  viewModel.clearLog();
                },
                child: const TextView("清空日志",fontSize: 13),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 10),

        //表头
        _buildTableHead(),
        //上报点位筛选框
        _buildReportView(),

        //日志内容显示框
        //_buildLogContentView(),
        const SizedBox(height: 10),
      ],
    );
  }


  /// 选择点位事件类型
  /// */
  Container filterEventType() {
    return Container(
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: PopUpMenuButton(
          viewModel: viewModel.eventTypeViewModel,
          menuTip: "选择事件类型",
        ),
      );
  }



  /// 上报日志分析的表格
  /// */
  Expanded _buildReportView() {
    return Expanded(
      child: Container(
          width: MediaQuery.of(context).size.width,
          color: const Color(0x66F0F0F0),
          child: Consumer<AndroidLogViewModel>(
            builder: (context, viewModel, child) {
              // return SingleChildScrollView(
              //     controller: viewModel.logScrollController,
              //     scrollDirection: Axis.vertical,
              //     child: _getBrandList()
              // );
              // var logList = viewModel.logList;
              //
              // // showToast("打印长度:${logList.length}");
              // // List<DataRow> dateRows = [];
              // // for (int i = 0; i < logList.length; i++) {
              // if(logList.isNotEmpty){
              //   // 解析上报日志
              //   ReportProperties? reportProperties = parseDevLog(logList[logList.length - 1]);
              //   if(reportProperties != null){
              //     String? position = reportProperties?.properties?.first.position;
              //     String? itemType = reportProperties?.properties?.first.itemType;
              //     String? event = reportProperties?.event;
              //     String? itemId = reportProperties?.properties?.first.itemid;
              //     String? itemMark = reportProperties?.properties?.first.itemMark;
              //     //包含itemMark需二次解析
              //     ItemMark? itemMarkBean = parseItemMark(itemMark);
              //     String? itemName = itemMarkBean?.itemName;
              //     String? itemMark1 = itemMarkBean?.itemMark1;
              //     String? itemMark2 = itemMarkBean?.itemMark2;
              //
              //     dateRows.add(DataRow(
              //       cells: [
              //         DataCell(getCommonText((dateRows.length + 1).toString())),
              //         DataCell(getCommonText(position)),
              //         DataCell(getCommonText(itemType)),
              //         DataCell(getCommonText(event)),
              //         DataCell(getCommonText(itemId)),
              //         DataCell(getCommonText(itemName)),
              //         DataCell(getCommonText(itemMark1)),
              //         DataCell(getCommonText(itemMark2)),
              //         //DataCell(getCommonText('$itemMark')),
              //       ],
              //     ));
              //   }
              //   // }
              // }

              if(viewModel.totalLogList.length == 1000){
                showToast("上报日志过多，建议清理!");
              }
              // 上报日志滚动到底部
              // viewModel?.logScrollController?.jumpTo(
              //   viewModel?.logScrollController?.position.maxScrollExtent??0,
              // );
              /// 写法一
              /// */
              /*
              return SingleChildScrollView(
                controller: viewModel.logScrollController,
                scrollDirection: Axis.vertical,
                // child: SingleChildScrollView(
                // scrollDirection: Axis.horizontal,
                child: DataTable(columns: [
                  DataColumn(label: getCommonText('序号', isLimit: true)),
                  DataColumn(label: getCommonText('点位名(position)')),
                  DataColumn(label: getCommonText('点位类型(item_type)')),
                  DataColumn(label: getCommonText('事件类型(event)')),
                  DataColumn(label: getCommonText('点位内容ID(item_id)')),
                  DataColumn(label: getCommonText('点位内容名称(item_name)')),
                  DataColumn(label: getCommonText('扩展内容1(item_mark_1)')),
                  DataColumn(label: getCommonText('扩展内容2(item_mark_2)')),
                  //DataColumn(label: getCommonText('扩展内容(item_mark)')),
                ], rows: viewModel.dateRows),
              // ),
              );*/

              /// 写法二
              /// */
              return SingleChildScrollView(
                  controller: viewModel.logScrollController,
                  scrollDirection: Axis.vertical,
                  child:  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    // columnWidths: const {
                    //   0: FlexColumnWidth(1.5),
                    //   1: FlexColumnWidth(4),
                    //   2: FlexColumnWidth(2.5),
                    // },
                    children:  viewModel.tableRows,
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: Color(0xFFC0C0C0), width: 0.3),
                    ),
                    /*
                    [
                      // TableRow(
                      //     children: [
                      //       getCommonText('序号', isLimit: true),
                      //       getCommonText('点位名(position)'),
                      //       getCommonText('点位类型(item_type)'),
                      //       getCommonText('事件类型(event)'),
                      //       getCommonText('点位内容ID(item_id)'),
                      //       getCommonText('点位内容名称(item_name)'),
                      //       getCommonText('扩展内容1(item_mark_1)'),
                      //       getCommonText('扩展内容2(item_mark_2)'),
                      //       //DataColumn(label: getCommonText('扩展内容(item_mark)')),
                      //     ]
                      // ),
                      TableRow(
                        children: _getBrandItemCell( "么天麟", "8527"),
                      ),
                    ],*/
                  )
              );

            },
          )),
    );
  }



  /// 表头
  /// */
  Container _buildTableHead() {
    return Container(
      //margin: EdgeInsets.only(left: 50, right: 50),
      //padding: const EdgeInsets.only(top: 10),
        width: MediaQuery.of(context).size.width,
        height: 50,
        color: const Color(0x66F0F0F0),
        //color: const Color(0xFF000000),
        child: Consumer<AndroidLogViewModel>(
          builder: (context, viewModel, child) {
            return Table(
              // columnWidths: const {
              //   0: FlexColumnWidth(1.5),
              //   1: FlexColumnWidth(4),
              //   2: FlexColumnWidth(2.5),
              // },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: const TableBorder(
                  bottom: BorderSide(color: Color(0xFFC0C0C0), width: 0.3),
                ),
                children:[
                  TableRow(
                      children: [
                        getCommonText('序号', isLimit: true),
                        getCommonText('点位名(position)'),
                        getCommonText('点位类型(item_type)'),
                        getCommonText('事件类型(event)'),
                        getCommonText('点位内容ID(item_id)'),
                        getCommonText('点位内容名称(item_name)'),
                        getCommonText('扩展内容1(item_mark_1)'),
                        getCommonText('扩展内容2(item_mark_2)'),
                        //DataColumn(label: getCommonText('扩展内容(item_mark)')),
                      ]
                  ),
                ]);
          },
        ));
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
    ));
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
    viewModel.logScrollController.dispose();
  }



  //测试
  /*
  Widget _getBrandList() {
    double screenWidth  = MediaQuery.of(context).size.width;
    return Container(
        margin: const EdgeInsets.fromLTRB(6, 60, 6, 14),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(2.5),
          },
          children: [
            const TableRow(
                children: [
                  Text('排名', style: TextStyle(color: Color(0xFF828CA0), fontSize: 12,)),
                  Text('顾问名', style: TextStyle(color: Color(0xFF828CA0), fontSize: 12,),),
                  Text('售卖量', style: TextStyle(color: Color(0xFF828CA0), fontSize: 12,),),
                ]
            ),
            TableRow(
              children: _getBrandItemCell( "么天麟", "1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"),
            ),
            TableRow(
              children: _getBrandItemCell("么天麟", "8527"),
            ),
            TableRow(
              children: _getBrandItemCell( "么天麟", "8527"),
            ),
          ],
        )
    );
  }

  List<Widget> _getBrandItemCell(String name, String num) {
    List<Widget> lists = [
      Text(num, style: const TextStyle(color: Color(0xFF111E36), fontSize: 16, fontWeight: FontWeight.w500)),
      Container(
        height: 50,
        child: Row(
          children: <Widget>[
            Text(name, style: const TextStyle(color: Color(0xFF111E36), fontSize: 14)),
            SizedBox(width: 10,),
            Text(name, style: const TextStyle(color: Color(0xFF111E36), fontSize: 14))
          ],
        ),
      ),
      Text(num, style: const TextStyle(color: Color(0xFF111E36), fontSize: 16, fontWeight: FontWeight.w500))
    ];
    return  lists;
  }
*/

}


