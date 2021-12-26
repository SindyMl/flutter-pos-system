import 'package:flutter/material.dart';
import 'package:possystem/components/style/sliding_up_opener.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/ui/order/cart/cart_snapshot.dart';
import 'package:provider/provider.dart';
import 'package:simple_tip/simple_tip.dart';

class OrderBySlidingPanel extends StatefulWidget {
  final Widget row1;
  final Widget row2;
  final Widget row3;
  final Widget row4;
  final GlobalKey<TipGrouperState>? tipGrouper;

  const OrderBySlidingPanel({
    Key? key,
    required this.row1,
    required this.row2,
    required this.row3,
    required this.row4,
    this.tipGrouper,
  }) : super(key: key);

  @override
  State<OrderBySlidingPanel> createState() => OrderBySlidingPanelState();
}

class OrderBySlidingPanelState extends State<OrderBySlidingPanel> {
  final opener = GlobalKey<SlidingUpOpenerState>();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const snapshotHeight = 72.0;
    final panelHeight =
        mediaQuery.size.height - mediaQuery.padding.top - kToolbarHeight - 64.0;

    final collapsed = OrderedTip(
      id: 'panel',
      grouper: widget.tipGrouper,
      order: 10,
      version: 1,
      title: '新版點餐設計',
      message: '為了讓點選產品可以更方便，\n'
          '我們把點餐後的產品設定至於此面板，點選或滑動以查看。\n'
          '如果需要一次顯示所有訊息的排版，可以至「設定」>「點餐的外觀」設定。',
      child: ChangeNotifierProvider.value(
        value: Cart.instance,
        builder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: kSpacing0),
          child: CartSnapshot(key: Key('cart.collapsed')),
        ),
      ),
    );

    return SlidingUpOpener(
      key: opener,
      minHeight: snapshotHeight,
      maxHeight: panelHeight,
      collapsed: collapsed,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: widget.row3), widget.row4],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        widget.row1,
        Expanded(child: widget.row2),
      ]),
    );
  }

  void reset() {
    setState(() {
      opener.currentState?.close();
    });
  }
}
