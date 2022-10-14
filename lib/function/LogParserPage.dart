import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../ItemMark.dart';
import '../ReportProperties.dart';


class LogParserPage extends StatefulWidget {
  const LogParserPage({super.key, required this.title});

  final String title;

  @override
  State<LogParserPage> createState() => LogParserPageState();
}

class LogParserPageState extends State<LogParserPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LogParserPageState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(children: [
            Row(
              children: [
                SizedBox(
                  width: 600,
                  height: 100,
                  child: TextField(
                    controller: _controller,
                    decoration: _normalDecoration(),
                  ),
                ),
                GestureDetector(
                  child: const Text(
                    '日志解析',
                    style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        backgroundColor: Color(0xFF000000)),
                  ),
                  onTap: () async {
                    parseDevLog();
                  },
                ),
              ],
            )
          ])),
    );
  }

  void parseDevLog() async {
    File file = File("C:\\Users\\admin\\Desktop\\TEST.json");
    String contents = await file.readAsString();
    printLog("内容：$contents");
    // 正则匹配
    RegExp reg = RegExp(r'(?<=ExposuerUtil:)(.*)');
    if (reg.hasMatch(contents)) {
      var matches = reg.allMatches(contents);
      //printLog("${matches.length}");
      for (int i = 0; i < matches.length; i++) {
        printLog("${matches.elementAt(i).group(0)}");
        // 解析上报数据
        jsonDataParser(matches.elementAt(i).group(0));
      }
    } else {
      printLog("匹配失败");
    }
  }


  InputDecoration _normalDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.lightBlue.shade100,
      prefixStyle: const TextStyle(color: Colors.orange, fontSize: 18),
      hintText: "解析后的数据",
      suffixIcon: const Icon(Icons.clear),
    );
  }


  /// 日志输出
  /// */
  void printLog(Object? object) {
    if (kDebugMode) {
      print(object);
    }
  }


  /// JSON解析日志
  /// */
  void jsonDataParser(String? jsonData) {
    ReportProperties reportProperties = ReportProperties.fromJson(jsonDecode(jsonData!));
    //printLog("打印属性：${reportProperties.properties?.first.itemMark}");
    //打印多行
    for(Properties properties in reportProperties?.properties?? []){
      String? mark = properties.itemMark;
      printLog("打印mark：$mark");
    }

    //包含itemMark需二次解析
    // String? mark = reportProperties.properties?.first.itemMark;
    // ItemMark itemMark = ItemMark.fromJson(jsonDecode((mark?.isEmpty == true) ? "" : mark!));
    // printLog("打印itemMark：${itemMark.itemName}");
  }

}
