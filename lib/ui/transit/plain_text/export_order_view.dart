import 'package:flutter/material.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/transit/exporter/plain_text_exporter.dart';
import 'package:possystem/ui/transit/order_widgets.dart';
import 'package:possystem/ui/transit/widgets.dart';

class ExportOrderView extends StatelessWidget {
  final ValueNotifier<DateTimeRange> ranger;
  final TransitStateNotifier stateNotifier;
  final PlainTextExporter exporter;

  const ExportOrderView({
    super.key,
    required this.ranger,
    required this.stateNotifier,
    this.exporter = const PlainTextExporter(),
  });

  @override
  Widget build(BuildContext context) {
    return TransitOrderList(
      notifier: ranger,
      formatOrder: (order) => Text(formatOrder(order)),
      memoryPredictor: memoryPredictor,
      leading: TransitOrderExportHead(
        title: S.transitCSVShareBtn,
        subtitle: S.transitPTCopyWarning,
        trailing: const Icon(Icons.copy_outlined),
        ranger: ranger,
        onTap: _export,
      ),
    );
  }

  void _export(BuildContext context) {
    stateNotifier.exec(() => showSnackbarWhenFutureError(
          _startExport(),
          'pt_export_failed',
          context: context,
        ).then((value) {
          if (context.mounted) {
            showSnackBar(S.transitPTCopySuccess, context: context);
          }
        }));
  }

  Future<void> _startExport() async {
    final orders = await Seller.instance.getDetailedOrders(
      ranger.value.start,
      ranger.value.end,
    );

    await exporter.exportToClipboard(orders
        .map((o) => [
              S.transitOrderItemTitle(o.createdAt),
              formatOrder(o),
            ].join('\n'))
        .join('\n\n'));
  }

  /// Actual result depends on language, here is English version:
  ///
  /// Total $110, $90 of them are product price.
  /// Paid $150, cost $30.
  /// Customer's dining location is Dine-in, age is 30.
  /// There are 3 (2 kinds) products including:
  /// Cheese Burger (Burger) 1, total $200, ingredients are Cheese (Large, use 3).
  static int memoryPredictor(OrderMetrics m) {
    return (m.count * 60 + m.attrCount! * 18 + m.productCount! * 25 + m.ingredientCount! * 10).toInt();
  }

  static String formatOrder(OrderObject order) {
    final attributes = order.attributes.map((a) {
      return S.transitPTFormatOrderOrderAttributeItem(a.name, a.optionName);
    }).join('、');
    final products = order.products.map((p) {
      final ing = p.ingredients.map((i) {
        return S.transitPTFormatOrderIngredient(
          i.amount,
          i.ingredientName,
          i.quantityName ?? S.transitPTFormatOrderNoQuantity,
        );
      }).join('、');
      return S.transitPTFormatOrderProduct(
        p.ingredients.length,
        p.productName,
        p.catalogName,
        p.count,
        p.totalPrice.toCurrency(),
        ing,
      );
    }).join('；\n');
    final setCount = order.products.length;
    final totalCount = order.productsCount;

    return [
      S.transitPTFormatOrderPrice(
        order.productsPrice == order.price ? 0 : 1,
        order.price.toCurrency(),
        order.productsPrice.toCurrency(),
      ),
      S.transitPTFormatOrderMoney(order.paid.toCurrency(), order.cost.toCurrency()),
      if (attributes != '') S.transitPTFormatOrderOrderAttribute(attributes),
      S.transitPTFormatOrderProductCount(totalCount, setCount, products)
    ].join('\n');
  }
}
