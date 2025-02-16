import 'package:flutter/material.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/models/xfile.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/transit/exporter/csv_exporter.dart';
import 'package:possystem/ui/transit/formatter/field_formatter.dart';
import 'package:possystem/ui/transit/formatter/formatter.dart';
import 'package:possystem/ui/transit/previews/preview_page.dart';
import 'package:possystem/ui/transit/widgets.dart';

class ImportBasicView extends StatelessWidget {
  final CSVExporter exporter;
  final TransitStateNotifier stateNotifier;

  const ImportBasicView({
    super.key,
    this.exporter = const CSVExporter(),
    required this.stateNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ImportView(
      icon: const Icon(Icons.file_present_sharp, semanticLabel: '選擇檔案'),
      stateNotifier: stateNotifier,
      onLoad: _load,
      onDone: _done,
      allowAll: false,
    );
  }

  Future<PreviewFormatter?> _load(BuildContext context, ValueNotifier<FormattableModel?> _) async {
    final input = await XFile.pick(extensions: const ['csv', 'txt']);
    if (input == null) {
      // ignore: use_build_context_synchronously
      showSnackBar('檔案取得失敗', context: context);

      return null;
    }

    final data = await exporter.import(input);
    return (FormattableModel able) => findFieldFormatter(able).format(data);
  }

  void _done(BuildContext context) {
    showSnackBar(S.actSuccess, context: context);
  }
}
