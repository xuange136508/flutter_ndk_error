import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:process_run/shell_run.dart';

String? get userHome =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

class FileChoosePage extends StatefulWidget {
  const FileChoosePage({super.key, required this.title});

  final String title;

  @override
  State<FileChoosePage> createState() => FileChoosePageState();
}

class FileChoosePageState extends State<FileChoosePage> {
  //给文本框赋值
  final _controller = TextEditingController();
  final _controller1 = TextEditingController();

  @override
  void initState() {
    // 监听器
    // _controller.addListener(() {
    //   final text = _controller.text.toLowerCase();
    //   _controller.value = _controller.value.copyWith(
    //     text: text,
    //     selection:
    //     TextSelection(baseOffset: text.length, extentOffset: text.length),
    //     composing: TextRange.empty,
    //   );
    // });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller1.dispose();
    super.dispose();
  }

  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  FileChoosePageState() {
    shell = Shell(
      workingDirectory: userHome,
      environment: Platform.environment,
      throwOnError: false,
      stderrEncoding: const Utf8Codec(),
      stdoutEncoding: const Utf8Codec(),
    );
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
                    '选择文件',
                    style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        backgroundColor: Color(0xFF000000)),
                  ),
                  onTap: () async {
                    final typeGroup = XTypeGroup(label: 'txt', extensions: ['txt']);
                    final file = await openFile(acceptedTypeGroups: [typeGroup]);
                    getSelectorPath(file?.path ?? "");
                    //具体读写文件可参考：https://www.cnblogs.com/ilgnefz/p/16010886.html
                    //官方文档：https://blog.csdn.net/flutterdevs/article/details/101048683
                  },
                ),
              ],
            ),
            Row(children: [
              SizedBox(
                width: 600,
                height: 100,
                child: TextField(
                  controller: _controller1,
                  decoration: _normalDecoration1(),
                ),
              ),
              GestureDetector(
                child: const Text(
                  '执行命令',
                  style: TextStyle(
                      color: Color(0xFFFFFFFF), backgroundColor: Color(0xFF000000)),
                ),
                onTap: () async {
                  executeCmd();
                },
              ),
            ]),
          ])),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void getSelectorPath(String path) async {
    /*
    Fluttertoast.showToast(
        msg: "文件路径：$path",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);*/
    printLog("文件路径：$path");
    _controller.text = path;

    //【1】测试文件的读写
    //C:\Users\admin\Desktop\11.9流.txt
    // File file = File("C:\\Users\\admin\\Desktop\\flutter.txt");
    // await file.writeAsString('Hello World');
    // String contents = await file.readAsString();
    // printLog("内容：$contents");

    //【2】读取gradle.properties文件
    // File file = File("C:\\Users\\admin\\Desktop\\gradle.properties");
    // String contents = await file.readAsString();
    // printLog("内容：$contents");
    // List<String> lines = await file.readAsLines();
    // for (int i = 0; i < lines.length; i++) {
    //   String line = lines[i];
    //   if(line.startsWith("#")){
    //     continue;
    //   }
    //   if(line.trim().isEmpty){
    //     continue;
    //   }
    //   List<String> singleLines = line.split("=");
    //   String key = singleLines[0];
    //   String value = singleLines[1];
    //   printLog("第$i行：$key ==== $value");
    // }

    //【3】读取config.gradle文件
    File file = File("C:\\Users\\admin\\Desktop\\config.gradle");
    String contents = await file.readAsString();
    // printLog("内容：$contents");
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

  void executeCmd() async {
    //执行ffmpeg命令: ffmpeg --version
    var cmd = _controller1.text;
    List<String> cmdLines = cmd.split(" ");
    var cmdStart = cmdLines[0];
    cmdLines.removeAt(0);
    printLog("cmdStart:$cmdStart");
    printLog("cmdLines:$cmdLines");
    var result = await execCmd(cmdStart, cmdLines);
    if (result != null && result.exitCode == 0) {
      printLog("执行完成");
    }

    // var result = await execCmd("ffmpeg", ['--version']);
    // if (result != null && result.exitCode == 0) {
    //   printLog("执行完成");
    // }
  }

  late Shell shell;

  Future<ProcessResult?> execCmd(String cmdHead, List<String> arguments,
      {void Function(Process process)? onProcess}) async {
    return await exec(cmdHead, arguments, onProcess: onProcess);
  }

  Future<ProcessResult?> exec(
      String executable,
      List<String> arguments, {
        void Function(Process process)? onProcess,
      }) async {
    try {
      return await shell.runExecutableArguments(executable, arguments,
          onProcess: onProcess);
    } catch (e) {
      printLog(e);
      return null;
    }
  }

  InputDecoration _normalDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.lightBlue.shade100,
      prefixStyle: const TextStyle(color: Colors.orange, fontSize: 18),
      hintText: "文件路径",
      suffixIcon: const Icon(Icons.clear),
    );
  }

  InputDecoration _normalDecoration1() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.lightGreen.shade100,
      prefixStyle: const TextStyle(color: Colors.blue, fontSize: 18),
      hintText: "CMD命令",
      suffixIcon: const Icon(Icons.clear),
    );
  }

  void printLog(Object? object) {
    if (kDebugMode) {
      print(object);
    }
  }
}
