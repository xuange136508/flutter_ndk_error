import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell_run.dart';


//测试解析日志
String testLog = "2022-09-15 15:11:16.866 11514-11727/cn.mama.pregnant E/ExposuerUtil: {\"os\":\"android\",\"user_tr\":\"PVk8NxtNr79eNA7BdsK5ZbHYljFP7xoqg9zbuAvDKx8GvSPbZpDO6cnR4rDf1vrLpYXFcUv4fWrjLqPaFsulIQxQrv4b%2FfxGWPH0Gsluo1SzCVbjJXw%2BNgS%2FIx%2FYZ5dF96Mfb5E3zJb4Jp29uhJ6Ze9xBieCfJfXGOXcFvh%2FbOpJS%2F6ugSynrG3Yei4b%2BsnoAhwaHsgM0Fcjqxe2sYfIIv1xeeU6qNICZBYmMhuwNni80K0Z0CL4sXXwFjUcCOQhsETb8qy%2BEksnv3e1XUmyGVvRzw7nVActzNc0%2B5SfMPkmFFEFjxiXhbn%2Fa%2B%2FCMj3D\",\"event\":\"duration\",\"content\":{\"app\":\"pt\",\"search_keyword\":"",\"app_ver\":\"12.9.0\",\"action\":"",\"context_type\":"",\"contextid\":""},\"properties\":[{\"itemid\":\"-1\",\"item_mark\":\"{\"item_mark_1\":\"1663225874\",\"item_mark_2\":\"0\"}\",\"item_type\":\"pt_os\",\"close_reason\":"",\"position\":\"OS_INIT\",\"sessionid\":\"70d8deba\",\"time\":\"1663225876794\"}]}";

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
    //File file = File("C:\\Users\\admin\\Desktop\\config.gradle");
    //String contents = await file.readAsString();
    String contents = testLog;
    printLog("内容：$contents");

    //正则匹配
    //教程：https://www.runoob.com/regexp/regexp-rule.html
    //+ 号代表前面的字符必须至少出现一次（1次或多次）。
    //* 号代表前面的字符可以不出现，也可以出现一次或者多次（0次、或1次、或多次）。
    //? 问号代表前面的字符最多只可以出现一次（0次或1次）。
    // RegExp reg = RegExp(r'is[a-zA-Z0-9_]* = [t|r|u|e|f|a|l|s|e]+');
    // 为了匹配等号左右空格无格式化的情况
    //RegExp reg = RegExp(r'is[a-zA-Z0-9_]* *= *[a-z]*.{1}');
    RegExp reg = RegExp(r'is[a-zA-Z0-9_]* = [a-z]*.{1}');
    if (reg.hasMatch(contents)) {
      var matches = reg.allMatches(contents);
      printLog("${matches.length}");
      for (int i = 0; i < matches.length; i++) {
        printLog("${matches.elementAt(i).group(0)}");
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
}
