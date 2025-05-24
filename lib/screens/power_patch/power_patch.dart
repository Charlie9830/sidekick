import 'package:flutter/material.dart';
import 'package:sidekick/screens/power_patch/balance_gauge.dart';
import 'package:sidekick/screens/power_patch/location_row.dart';
import 'package:sidekick/screens/power_patch/multi_outlet_row.dart';
import 'package:sidekick/view_models/power_patch_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';
import 'package:sidekick/widgets/toolbar.dart';

class PowerPatch extends StatefulWidget {
  final PowerPatchViewModel vm;
  const PowerPatch({Key? key, required this.vm}) : super(key: key);

  @override
  State<PowerPatch> createState() => _PowerPatchState();
}

class _PowerPatchState extends State<PowerPatch> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant PowerPatch oldWidget) {
    if (widget.vm.rows != oldWidget.vm.rows) {}

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Toolbar(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: PropertyField(
              textAlign: TextAlign.center,
              label: 'Balance Tolerance',
              suffix: '%',
              value: widget.vm.balanceTolerancePercent,
              onBlur: widget.vm.onBalanceToleranceChanged,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
              width: 124,
              child: PropertyField(
                textAlign: TextAlign.center,
                label: 'Max Piggyback Break',
                value: widget.vm.maxSequenceBreak.toString(),
                onBlur: widget.vm.onMaxSequenceBreakChanged,
              )),
          const SizedBox(width: 16),
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BalanceGauge(
                phaseALoad: widget.vm.phaseLoad.a,
                phaseBLoad: widget.vm.phaseLoad.b,
                phaseCLoad: widget.vm.phaseLoad.c,
              )
            ],
          ))
        ],
      )),
      Expanded(
        child: ListView.builder(
          itemCount: widget.vm.rows.length,
          itemBuilder: (context, index) => _buildRow(
            context,
            widget.vm.rows[index],
          ),
        ),
      )
    ]);
  }

  Widget _buildRow(BuildContext context, PowerPatchRowViewModel row) {
    return switch (row) {
      LocationRowViewModel vm => LocationRow(key: Key(vm.uid), vm: vm),
      MultiOutletRowViewModel vm => GestureDetector(
          onTap: () => widget.vm.onMultiOutletPressed(row.multiOutlet.uid),
          child: MultiOutletRow(
            vm: vm,
            selected: vm.uid == widget.vm.selectedMultiOutlet,
            onAddSpareOutlet: widget.vm.onAddSpareOutlet,
            onDeleteSpareOutlet: widget.vm.onDeleteSpareOutlet,
          )),
      _ => const Text("Error"),
    };
  }
}
