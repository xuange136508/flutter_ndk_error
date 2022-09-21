import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell_run.dart';

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

  LogParserPageState() {
  }

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
    // File file = File("C:\\Users\\admin\\Desktop\\config.gradle");
    File file = File("C:\\Users\\admin\\Desktop\\TEST.json");
    String contents = await file.readAsString();
    // String contents = testLog;
    printLog("内容：$contents");

    //正则匹配
    //教程：https://www.runoob.com/regexp/regexp-rule.html
    //+ 号代表前面的字符必须至少出现一次（1次或多次）。
    //* 号代表前面的字符可以不出现，也可以出现一次或者多次（0次、或1次、或多次）。
    //? 问号代表前面的字符最多只可以出现一次（0次或1次）。
    // RegExp reg = RegExp(r'is[a-zA-Z0-9_]* = [t|r|u|e|f|a|l|s|e]+');
    // 为了匹配等号左右空格无格式化的情况
    //RegExp reg = RegExp(r'is[a-zA-Z0-9_]* *= *[a-z]*.{1}');
    //RegExp reg = RegExp(r'is[a-zA-Z0-9_]* = [a-z]*.{1}');
    RegExp reg = RegExp(r'(?<=ExposuerUtil:)(.*)');
    if (reg.hasMatch(contents)) {
      var matches = reg.allMatches(contents);
      //printLog("${matches.length}");
      for (int i = 0; i < matches.length; i++) {
        printLog("${matches.elementAt(i).group(0)}");
        //解析上报数据
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


  void printLog(Object? object) {
    if (kDebugMode) {
      print(object);
    }
  }

  void jsonDataParser(String? jsonData) {
    ReportProperties reportProperties = ReportProperties.fromJson(jsonDecode(jsonData!));
    printLog("打印属性：${reportProperties.properties?.first.itemMark}");
    //如果是itemMark则二次格式化
    String? mark = reportProperties.properties?.first.itemMark;
    ItemMark itemMark =
        ItemMark.fromJson(jsonDecode((mark?.isEmpty == true) ? "" : mark!));
    printLog("打印itemMark：${itemMark.itemName}");
  }

}
