import 'package:flutter/material.dart';
import 'function/CrashPage.dart';
import 'function/FileChoosePage.dart';
import 'function/LogParserPage.dart';

List<Color> colors = [
  Colors.red,
  Colors.orange,
  Colors.lightBlue,
  Colors.green,
  Colors.amber,
  Colors.blue,
  Colors.purple,
  Colors.indigo,
  Colors.blueGrey,
  Colors.indigoAccent,
  Colors.brown,
  Colors.cyan,
  Colors.lightGreen,
  Colors.orangeAccent,
  Colors.deepPurpleAccent,
];


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: getFunctionWidget(3),
    );
  }

  Widget? getFunctionWidget(int type) {
    if (type == 1) {
      return const CrashPage(title: 'Crash定位工具');

    } else if (type == 2) {
      return const FileChoosePage(title: '文件选择器');

    } else if (type == 3) {
      return const LogParserPage(title: '日志分析器');

    }
    return null;
  }
}

