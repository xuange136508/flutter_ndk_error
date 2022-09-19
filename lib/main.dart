import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_study/result_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell_run.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'CrashPage.dart';
import 'FileChoosePage.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: getFunctionWidget(1),
    );
  }

  Widget? getFunctionWidget(int type){
    if(type == 1){
      return const CrashPage(title: 'Crash定位工具');
    }else if(type == 2){
      return const FileChoosePage(title: '文件选择器');
    }
    return null;
  }
}

