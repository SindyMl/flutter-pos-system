import 'package:flutter/material.dart';
import 'package:possystem/components/sign_in_button.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/components/style/snackbar_actions.dart';
import 'package:possystem/components/style/text_divider.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/helpers/logger.dart';
import 'package:possystem/services/cache.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/transit/exporter/google_sheet_exporter.dart';
import 'package:possystem/ui/transit/formatter/field_formatter.dart';
import 'package:possystem/ui/transit/formatter/formatter.dart';
import 'package:possystem/ui/transit/widgets.dart';

import 'sheet_namer.dart';
import 'sheet_preview_page.dart';
import 'spreadsheet_selector.dart';

const _cacheKey = 'exporter_google_sheet';
const _importKey = 'importer_google_sheet';

class ExportBasicView extends StatefulWidget {
  final ValueNotifier<String> notifier;

  final GoogleSheetExporter exporter;

  const ExportBasicView({
    super.key,
    required this.exporter,
    required this.notifier,
  });

  @override
  State<ExportBasicView> createState() => _ExportBasicViewState();
}

class _ExportBasicViewState extends State<ExportBasicView> {
  late final List<SheetNamerProperties> sheets;

  final selector = GlobalKey<SpreadsheetSelectorState>();

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SignInButton(
          signedInWidget: SpreadsheetSelector(
            key: selector,
            exporter: widget.exporter,
            notifier: widget.notifier,
            cacheKey: _cacheKey,
            existLabel: S.transitGSSpreadsheetExportExistLabel,
            existHint: S.transitGSSpreadsheetExportExistHint,
            emptyLabel: S.transitGSSpreadsheetExportEmptyLabel,
            emptyHint: S.transitGSSpreadsheetExportEmptyHint(S.transitGSSpreadsheetModelDefaultName),
            defaultName: S.transitGSSpreadsheetModelDefaultName,
            requiredSheetTitles: requiredSheetTitles,
            onUpdated: onSpreadsheetUpdate,
            onPrepared: exportData,
          ),
        ),
      ),
      TextDivider(label: S.transitGSSpreadsheetModelExportDivider),
      for (final sheet in sheets)
        SheetNamer(
          prop: sheet,
          action: (prop) => previewData(prop.type),
          actionIcon: KIcons.preview,
          actionTitle: S.transitExportPreviewTitle,
        ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    sheets = [
      SheetType.menu,
      SheetType.stock,
      SheetType.quantities,
      SheetType.replenisher,
      SheetType.orderAttr,
    ].map((e) {
      final name = Cache.instance.get<String>('$_cacheKey.${e.name}') ?? S.transitModelName(e.name);
      final repo = FormattableModel.find(e.name).toRepository();

      return SheetNamerProperties(
        e,
        name: name,
        checked: repo.isNotEmpty,
        hints: spreadsheet?.sheets.map((e) => e.title),
      );
    }).toList();
  }

  GoogleSpreadsheet? get spreadsheet {
    if (selector.currentState == null) {
      final cached = Cache.instance.get<String>(_cacheKey);
      if (cached != null) {
        return GoogleSpreadsheet.fromString(cached);
      }
    }

    return selector.currentState?.spreadsheet;
  }

  void previewData(SheetType type) {
    final able = FormattableModel.find(type.name);
    final formatter = findFieldFormatter(able);
    showAdaptiveDialog(
      context: context,
      builder: (_) => SheetPreviewPage(
        source: ModelDataTableSource(formatter.getRows()),
        header: formatter.getHeader(),
        title: S.transitModelName(able.name),
      ),
    );
  }

  /// It is used to let [SpreadsheetSelector] help to create the form.
  Map<SheetType, String> requiredSheetTitles() => {
        for (var sheet in sheets.where((sheet) => sheet.checked)) sheet.type: sheet.name,
      };

  /// [SpreadsheetSelector] will check the basic data before actually exporting.
  Future<void> exportData(
    GoogleSpreadsheet ss,
    Map<SheetType, GoogleSheetProperties> kv,
  ) async {
    Log.ger('gs_export', {'spreadsheet': ss.id, 'target': kv.keys.map((e) => e.name).join(',')});

    // cache the sheet names
    final prepared = kv.map((key, value) => MapEntry(
          FormattableModel.values.firstWhere((e) => e.name == key.name),
          value,
        ));
    for (final e in prepared.entries) {
      await _cacheSheetName(e.key.name, e.value.title);
    }

    // prepare data
    final data = <Iterable<Iterable<GoogleSheetCellData>>>[];
    final headers = <Iterable<GoogleSheetCellData>>[];
    for (final able in prepared.keys) {
      final formatter = findFieldFormatter(able);
      data.add(formatter.getRows().map((e) => e.map((v) => GoogleSheetCellData.fromCellData(v))));
      headers.add(formatter.getHeader().map((e) => GoogleSheetCellData.fromCellData(e)));
    }

    // go
    await widget.exporter.updateSheet(ss, prepared.values, data, headers);

    Log.out('export finish', 'gs_export');
    if (mounted) {
      showSnackBar(
        S.actSuccess,
        context: context,
        action: LauncherSnackbarAction(
          label: S.transitGSSpreadsheetSnackbarAction,
          link: ss.toLink(),
          logCode: 'gs_export',
        ),
      );
    }
  }

  Future<void> onSpreadsheetUpdate(GoogleSpreadsheet? other) async {
    for (final sheet in sheets) {
      sheet.hints = other?.sheets.map((e) => e.title);
    }

    // auto set the title to import, to make user easier to import
    if (other != null && Cache.instance.get<String>(_importKey) == null) {
      await Cache.instance.set(_importKey, other.toString());
    }
  }

  Future<void> _cacheSheetName(String label, String title) async {
    final key = '$_cacheKey.$label';
    if (title != Cache.instance.get<String>(key)) {
      await Cache.instance.set<String>(key, title);
    }
  }
}
