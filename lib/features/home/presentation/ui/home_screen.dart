import 'package:flutter/material.dart';
import 'package:nojob/features/home/presentation/ui/chart_widget.dart';
import 'package:nojob/features/home/presentation/ui/pie_chart.dart';
import 'package:nojob/features/logs/presentation/ui/log_widget2.dart';
import 'package:nojob/features/url_input/presentation/url_field_widget.dart';
import 'package:nojob/shared/extensions.dart';
import 'package:nojob/shared/ui/horizontal_line_label.dart';
import 'package:nojob/shared/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapshot_system/data/db.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final main = Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        verticalDirection: VerticalDirection.down,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (context.isMobile) const SizedBox(height: 16),
          Row(
            children: [
              TextButton(onPressed: () async {
                l.e("add pressed");
                final id = await SnapshotAPI(1).add("testname_testdesc");


                final prefs = await SharedPreferences.getInstance();

                prefs.setInt("key", id);

                l.e("add result: $id");
              }, child: Text("Add")),
              TextButton(onPressed: () async {
                final test = "test_string";
                final hash = test.toSha256();
                final id = await SnapshotAPI(1).remove(hash);

                l.e("remove result: $id");
              }, child: Text("remove")),
              TextButton(onPressed: () async {
                final test = "test_string";
                final hash = test.toSha256();
                final id = await SnapshotAPI(1).modify(hash, "new_data");

                l.e("modify result: $id");
              }, child: Text("modify")),
              TextButton(onPressed: () async {
                final result = await SnapshotAPI(1).getAll();

                final data = result.map((e) => e.toJson()).toList();

                l.e("getAll result: $data");
              }, child: Text("get all"))
            ],
          ),

          SizedBox(
            child: Wrap(
              textDirection: TextDirection.rtl,
              verticalDirection: VerticalDirection.up,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                const LineChartWidget(),
                const PieWidget(chartSize: 230),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const UrlFieldWidget(),
          HorizontalLineLabel(text: context.res.logs),
          const SizedBox(height: 8),
          const LogWidget2(),
          const SizedBox(height: 32),
        ],
      ),
    );

    return context.isMobile
        ? SingleChildScrollView(child: main)
        : Center(child: main);
  }
}
