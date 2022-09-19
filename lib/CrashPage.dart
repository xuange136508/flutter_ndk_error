import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_study/result_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';
import 'package:flutter/services.dart' show rootBundle;

String? get userHome =>
    Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

class CrashPage extends StatefulWidget {
  const CrashPage({super.key, required this.title});

  final String title;

  @override
  State<CrashPage> createState() => CrashPageState();
}

// Crash定位集成工具
// 包含 ndk-stack、addr2line、minidump_stackwalk
class CrashPageState extends State<CrashPage> {
  final _controller1 = TextEditingController();
  final _controller2 = TextEditingController();
  final contentController = TextEditingController();
  final errAddrController = TextEditingController();

  CrashPageState() {
    shell = Shell(
      workingDirectory: userHome,
      environment: Platform.environment,
      throwOnError: false,
      stderrEncoding: const Utf8Codec(),
      stdoutEncoding: const Utf8Codec(),
    );
  }

  @override
  void initState() {
    copyExecTools();
    super.initState();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    contentController.dispose();
    errAddrController.dispose();
    super.dispose();
  }

  void getSelectorPath(String path) async {
    printLog("动态库文件路径：$path");
    _controller1.text = path;
  }

  void clearText() {
    _controller1.clear();
  }

  void clearText1() {
    _controller2.clear();
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

  //C:\Users\admin\AppData\Roaming\com.example\flutter_study\exec\minidump_stackwalk C:\Users\admin\Desktop\bug\c.dmp > C:\Users\admin\AppData\Roaming\com.example\flutter_study\exec\flutter_crash.txt
  void executeCmd() async {
    Directory dir = await getApplicationSupportDirectory();
    String appPath = "${dir.path}\\exec";
    String output = "${appPath}\\flutter_crash.txt";
    // File file = File(output);
    // await file.create();

    var cmd = _controller2.text;
    //拼接命令行 minidump_stackwalk C:\Users\admin\Desktop\bug\a.dmp >crash.txt
    var realCmd = "${appPath}\\minidump_stackwalk ${cmd} > ${output}";
    printLog("执行：$realCmd");

    List<String> cmdLines = realCmd.split(" ");
    var cmdStart = cmdLines[0];
    cmdLines.removeAt(0);
    printLog("cmdStart:$cmdStart");
    printLog("cmdLines:$cmdLines");
    var result = await execCmd(cmdStart, cmdLines);
    if (result != null && result.exitCode == 0) {
      contentController.text = result.stdout;
      printLog("执行完成");
    }
  }

  void executeAddrToLine() async {
    Directory dir = await getApplicationSupportDirectory();
    String appPath = "${dir.path}\\exec";

    var soDir = _controller1.text;
    var errAddr = errAddrController.text;
    var realCmd =
        "${appPath}\\aarch64-linux-android-addr2line  -f -C -e ${soDir} ${errAddr}";
    printLog("执行：$realCmd");

    List<String> cmdLines = realCmd.split(" ");
    var cmdStart = cmdLines[0];
    cmdLines.removeAt(0);
    var result = await execCmd(cmdStart, cmdLines);
    if (result != null && result.exitCode == 0) {
      contentController.text = result.stdout;
      printLog("执行完成");
    }
  }

  void executeNdkStack() async {
    Directory dir = await getApplicationSupportDirectory();
    String appPath = "${dir.path}\\exec";

    //错误日志写入
    var errorMsg = contentController.text;
    File errorFile = File("${appPath}\\flutter_error.txt");
    if(errorFile.existsSync()){
      errorFile.delete();
    }
    await errorFile.writeAsString(errorMsg);

    var soDir = _controller1.text;
    Directory mDir = File(soDir).parent;
    var realCmd =
        "${appPath}\\ndk-stack -sym ${mDir.path} -dump ${appPath}\\flutter_error.txt";
    printLog("执行：$realCmd");

    List<String> cmdLines = realCmd.split(" ");
    var cmdStart = cmdLines[0];
    cmdLines.removeAt(0);
    var result = await execCmd(cmdStart, cmdLines);
    if (result != null && result.exitCode == 0) {
      contentController.text = result.stdout;
      printLog("执行完成");

    }else{
      var soDir = _controller1.text;
      Directory mDir = File(soDir).parent;
      var realCmd = "ndk-stack -sym ${mDir.path} -dump ${appPath}\\flutter_error.txt";
      printLog("执行：$realCmd");
      List<String> cmdLines = realCmd.split(" ");
      var cmdStart = cmdLines[0];
      cmdLines.removeAt(0);
      result = await execCmd(cmdStart, cmdLines);
      if (result != null && result.exitCode == 0) {
        contentController.text = result.stdout;
        printLog("执行完成");
      }
    }
  }

  InputDecoration _normalDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixStyle: const TextStyle(color: Colors.orange, fontSize: 18),
      hintText: "动态库文件选择",
      suffixIcon: IconButton(
        icon: Icon(Icons.clear),
        onPressed: clearText,
      ),
    );
  }

  InputDecoration _normalDecoration1() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixStyle: const TextStyle(color: Colors.orange, fontSize: 18),
      hintText: "墓碑文件路径",
      suffixIcon: IconButton(
        icon: Icon(Icons.clear),
        onPressed: clearText1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Row(children: [
              Column(children: [Image.asset("images/mama.jpg", height: 50)]),
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("选择文件"),
                        ),
                        SizedBox(
                          width: 500,
                          height: 40,
                          child: TextField(
                            controller: _controller1,
                            decoration: _normalDecoration(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: OutlinedButton(
                              onPressed: () async {
                                final typeGroup =
                                XTypeGroup(label: 'so', extensions: ['so']);
                                final file =
                                await openFile(acceptedTypeGroups: [typeGroup]);
                                getSelectorPath(file?.path ?? "");
                              },
                              child: const Text("选择")),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("ndk-stack"),
                        ),
                        const SizedBox(
                            width: 500,
                            height: 40,
                            child: TextField(
                            )),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: OutlinedButton(
                              onPressed: () async {
                                executeNdkStack();
                              },
                              child: const Text("执行")),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("addr2line"),
                        ),
                        SizedBox(
                            width: 500,
                            height: 40,
                            child: TextField(
                              controller: errAddrController,
                            )),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: OutlinedButton(
                              onPressed: () async {
                                executeAddrToLine();
                              },
                              child: const Text("解析")),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text("stackwalk"),
                        ),
                        SizedBox(
                          width: 500,
                          height: 40,
                          child: TextField(
                            controller: _controller2,
                            decoration: _normalDecoration1(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: OutlinedButton(
                              onPressed: () async {
                                final typeGroup =
                                XTypeGroup(label: 'dmp', extensions: ['dmp']);
                                final file =
                                await openFile(acceptedTypeGroups: [typeGroup]);
                                _controller2.text = file?.path ?? "";
                              },
                              child: const Text("选择")),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: OutlinedButton(
                              onPressed: () async {
                                executeCmd();
                              },
                              child: const Text("转换")),
                        )
                      ],
                    ),
                    Row(children: [
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: SizedBox(
                              width: 800,
                              height: 300,
                              child: TextField(
                                  maxLines: 1000,
                                  controller: contentController,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 20),
                                    hintText: "请输入崩溃日志内容",
                                    border: OutlineInputBorder(),
                                    hintStyle: TextStyle(fontSize: 14),
                                  ))))
                    ])
                  ])
            ])));
  }

  void copyExecTools() async {
    //获取文件目录：https://www.cnblogs.com/ilgnefz/p/15990429.html
    //File file = File("C:\\Users\\admin\\Desktop\\ndk-stack.cmd");
    // File fileDir = File("C:\\Users\\admin\\Desktop\\exec");
    // if(!fileDir.existsSync()){
    //   fileDir.createSync();
    // }

    // 获取应用程序数据目录
    // Android - getDataDirectory
    // IOS - NSDocumentDirectory
    //Future<Directory> getApplicationDocumentsDirectory() async
    // 获取临时目录
    // Android - getCacheDir
    // IOS - NSCachesDirectory
    //Future<Directory> getTemporaryDirectory() async
    Directory dir = await getApplicationSupportDirectory();
    String appPath = "${dir.path}\\exec";
    printLog("appPath:$appPath");

    //appPath:C:\Users\admin\AppData\Roaming\com.example\flutter_study\exec
    //showResultDialog(content: appPath);

    Directory directory = Directory(appPath);
    await directory.create();

    //ndk-stack
    ByteData data = await rootBundle.load('exec_file/ndk-stack.cmd');
    File file = File("$appPath\\ndk-stack.cmd");
    List<int> bytes =
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);

    //addr2line
    ByteData data1 =
    await rootBundle.load('exec_file/aarch64-linux-android-addr2line.exe');
    File file1 = File("$appPath\\aarch64-linux-android-addr2line.exe");
    List<int> bytes1 =
    data1.buffer.asUint8List(data1.offsetInBytes, data1.lengthInBytes);
    await file1.writeAsBytes(bytes1, flush: true);

    //minidump_stackwalk
    ByteData data2 = await rootBundle.load('exec_file/minidump_stackwalk.exe');
    File file2 = File("$appPath\\minidump_stackwalk.exe");
    List<int> bytes2 =
    data2.buffer.asUint8List(data2.offsetInBytes, data2.lengthInBytes);
    await file2.writeAsBytes(bytes2, flush: true);
  }

  void printLog(Object? object) {
    if (kDebugMode) {
      print(object);
    }
  }

  void showResultDialog({String? title, String? content, bool? isSuccess}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResultDialog(
          title: title,
          content: content,
          isSuccess: isSuccess,
        );
      },
    );
  }
}

