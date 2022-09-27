import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:provider/provider.dart';
import 'package:substring_highlight/substring_highlight.dart';

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
              },
              child: const TextView("清除"),
            ),
            const SizedBox(width: 16),
          ],
        ),

        //adb设置
        AdbSettingDialog(viewModel.adbPath),
        //上报点位筛选框

        //内容显示框
        _buildLogContentView(),
        const SizedBox(height: 10),
      ],
    );
  }



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
