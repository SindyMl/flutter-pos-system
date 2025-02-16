import 'package:flutter/material.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/ui/transit/exporter/excel_exporter.dart';
import 'package:possystem/ui/transit/formatter/field_formatter.dart';
import 'package:possystem/ui/transit/formatter/formatter.dart';
import 'package:possystem/ui/transit/widgets.dart';

class ExportBasicView extends StatelessWidget {
  final ExcelExporter exporter;
  final TransitStateNotifier stateNotifier;

  const ExportBasicView({
    super.key,
    this.exporter = const ExcelExporter(),
    required this.stateNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ExportView(
      icon: Icon(Icons.share_outlined, semanticLabel: '分享'),
      stateNotifier: stateNotifier,
      allowAll: true,
      onExport: _export,
      buildModel: _buildModel,
    );
  }

  Widget _buildModel(BuildContext context, FormattableModel? able) {
    final formatter = findFieldFormatter(able ?? FormattableModel.menu);
    final headers = formatter.getHeader();
    return ModelDataTable(
      headers: headers.map((e) => e.toString()).toList(),
      notes: headers.map((e) => e.note).toList(),
      source: ModelDataTableSource(formatter.getRows()),
    );
  }

  Future<void> _export(BuildContext context, FormattableModel? able) async {
    final names = able?.toL10nNames() ?? FormattableModel.allL10nNames;
    final data = getAllFormattedFieldData(able);

    final ok = await exporter.export(names, data);
    if (context.mounted && ok) {
      showSnackBar('成功匯出 Excel 資料', context: context);
    }
  }
}
