import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sidekick/editable_text_field.dart';
import 'package:sidekick/redux/models/fixture_type_model.dart';
import 'package:sidekick/shad_list_item.dart';
import 'package:sidekick/simple_tooltip.dart';
import 'package:sidekick/slotted_list/slot_assignment_controller.dart';
import 'package:sidekick/three_panel_scaffold.dart';
import 'package:sidekick/view_models/fixture_types_view_model.dart';
import 'package:sidekick/widgets/property_field.dart';

class FixtureTypePools extends StatefulWidget {
  final FixtureTypesViewModel viewModel;
  const FixtureTypePools({super.key, required this.viewModel});

  @override
  State<FixtureTypePools> createState() => _FixtureTypePoolsState();
}

class _FixtureTypePoolsState extends State<FixtureTypePools> {
  late final SlotAssignmentController<String, FixtureTypeModel> _controller;

  @override
  void initState() {
    _controller =
        SlotAssignmentController(itemsById: widget.viewModel.itemsById);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SlotAssignmentScope(
      controller: _controller,
      child: ThreePanelScaffold(
          toolbar: const SizedBox.shrink(),
          sidebar:
              _Sidebar(viewModel: widget.viewModel, controller: _controller),
          body: _Body(
            vm: widget.viewModel,
            slotAssignmentController: _controller,
          )),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final FixtureTypesViewModel viewModel;

  const _Sidebar({
    super.key,
    required this.viewModel,
    required SlotAssignmentController<String, FixtureTypeModel> controller,
  }) : _controller = controller;

  final SlotAssignmentController<String, FixtureTypeModel> _controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 300,
        child: ListView.builder(
          itemCount: viewModel.fixtureTypeVms.length,
          itemBuilder: (context, index) {
            final item = viewModel.fixtureTypeVms[index];

            return AvailableItem<String, FixtureTypeModel>(
              controller: _controller,
              id: item.type.uid,
              selectionIndex: index,
              builder: (context, item, isSelected) {
                return ShadListItem(
                  title: Text(item!.item.name),
                  selected: isSelected,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final FixtureTypesViewModel vm;
  final SlotAssignmentController<String, FixtureTypeModel>
      slotAssignmentController;
  const _Body({
    super.key,
    required this.vm,
    required this.slotAssignmentController,
  });

  @override
  Widget build(BuildContext context) {
    final createPoolButton = Center(
      key: const Key('create-pool-button'),
      child: PrimaryButton(
        leading: const Icon(Icons.add),
        onPressed: vm.onCreatePoolButtonPressed,
        child: const Text('Create Pool'),
      ),
    );

    if (vm.poolVms.isEmpty) {
      return createPoolButton;
    }

    return CustomScrollView(
      slivers: [
        SliverReorderableList(
          onReorder: vm.onPoolReorder,
          itemCount: vm.poolVms.length,
          itemBuilder: (context, index) {
            final pool = vm.poolVms[index];

            return _PoolItem(
              key: Key(pool.pool.uid),
              vm: pool,
              index: index,
              slotAssignmentController: slotAssignmentController,
            );
          },
        ),
        SliverToBoxAdapter(child: createPoolButton)
      ],
    );
  }
}

class _PoolItem extends StatelessWidget {
  final FixtureTypePoolViewModel vm;
  final int index;
  final SlotAssignmentController<String, FixtureTypeModel>
      slotAssignmentController;

  const _PoolItem({
    super.key,
    required this.vm,
    required this.index,
    required this.slotAssignmentController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Slot<String, FixtureTypeModel>(
          controller: slotAssignmentController,
          slotIndex: index,
          onItemsLanded: (ids) => vm.onAddFixturesToPool(ids),
          assignedItemId: null,
          builder: (context, item, activated) {
            return Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 400,
                        child: EditableTextField(
                          value: vm.pool.name,
                          hintText: 'Pool Name',
                          style: Theme.of(context).typography.large,
                          onChanged: (newValue) => vm.onNameChanged(newValue),
                        ),
                      ),
                      const Spacer(),
                      Text('${_calculateTotalPoolDraw(vm)}A'),
                      const SizedBox(
                        height: 48,
                        child: VerticalDivider(width: 16),
                      ),
                      SimpleTooltip(
                        message: 'Reorder Pool',
                        child: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SimpleTooltip(
                        message: 'Delete pool',
                        child: IconButton.destructive(
                          icon: const Icon(Icons.delete),
                          size: ButtonSize.small,
                          onPressed: vm.onPoolDeleted,
                        ),
                      ),
                    ],
                  ),
                  if (vm.childVms.isEmpty)
                    Container(
                      alignment: Alignment.center,
                      height: 48,
                      child: Text(
                          'Drag Fixture Types here to add them into this pool',
                          style: Theme.of(context).typography.small.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .mutedForeground,
                              )),
                    ),
                  if (vm.childVms.isNotEmpty)
                    const Divider(
                      height: 16,
                    ),
                  ...vm.childVms
                      .map((child) => _PoolChild(
                            vm: child,
                          ))
                      .toList()
                ],
              ),
            );
          }),
    );
  }

  double _calculateTotalPoolDraw(FixtureTypePoolViewModel vm) {
    return vm.childVms
        .map((child) => child.entry.qty * child.fixtureType.type.amps)
        .fold<double>(0, (accum, value) => accum + value);
  }
}

class _PoolChild extends StatelessWidget {
  final FixtureTypePoolEntryViewModel vm;
  const _PoolChild({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Text(vm.fixtureType.type.name),
          ),
          SizedBox(
            width: 100,
            child: PropertyField(
              value: vm.entry.qty.toString(),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onBlur: vm.onQtyChanged,
              label: 'Qty',
              labelAlign: LabelAlign.center,
            ),
          ),
          const SizedBox(width: 32),
          Text('${vm.fixtureType.type.amps * vm.entry.qty}A'),
          const Spacer(),
          IconButton.ghost(
              icon: const Icon(Icons.clear),
              onPressed: vm.onRemoveFixturePressed)
        ],
      ),
    );
  }
}
