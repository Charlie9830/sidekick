import 'package:flutter/material.dart';
import 'package:sidekick/file_select_button.dart';
import 'package:sidekick/screens/file/import_module/fixture_mapping_view_model.dart';
import 'package:sidekick/screens/file/import_module/map_fixture_types.dart';

class FixtureMappingStep extends StatelessWidget {
  final List<FixtureMappingViewModel> viewModels;
  final String fixtureMappingFilePath;
  final String fixtureDatabaseFilePath;
  const FixtureMappingStep({
    super.key,
    required this.viewModels,
    required this.fixtureDatabaseFilePath,
    required this.fixtureMappingFilePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fixture Name Mapping',
              style: Theme.of(context).textTheme.titleSmall),
          const Divider(),
          Expanded(
            child: ListView.builder(
                itemCount: viewModels.length,
                itemBuilder: (context, index) {
                  final vm = viewModels[index];

                  return _FixtureMappingItem(vm: vm);
                }),
          ),
          const Divider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fixture Name and Mode Mapping',
                  style: Theme.of(context).textTheme.labelMedium),
              FileSelectButton(
                path: fixtureMappingFilePath,
                showOpenButton: true,
              ),
              Text('Fixture Database',
                  style: Theme.of(context).textTheme.labelMedium),
              FileSelectButton(
                path: fixtureDatabaseFilePath,
                showOpenButton: true,
              )
            ],
          ),
        ],
      ),
    );
  }
}

const double _kLeadingColumnWidth = 48;
const double _kSourceWidth = 300;
const double _kMappedWidth = 200;
const double _kMapsToIconWidth = 100;

class _FixtureMappingItem extends StatelessWidget {
  final FixtureMappingViewModel vm;
  const _FixtureMappingItem({
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final labelTextStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 64,
          child: Row(children: [
            // Label Segment.
            SizedBox(
              width: _kLeadingColumnWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Type', style: labelTextStyle),
                  Text('Mode', style: labelTextStyle),
                ],
              ),
            ),

            // Source Segment
            SizedBox(
              width: _kSourceWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Value(
                    vm.mapping.sourceFixtureType,
                    alignment: MainAxisAlignment.end,
                  ),
                  _Value(
                    vm.mapping.sourceFixtureMode,
                    alignment: MainAxisAlignment.end,
                  ),
                ],
              ),
            ),

            // Maps To Icon
            const SizedBox(
              width: _kMapsToIconWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MapsToIcon(),
                ],
              ),
            ),

            // Mapped Segment
            SizedBox(
              width: _kMappedWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Value(
                    vm.mapping.mappedFixtureType,
                    alignment: MainAxisAlignment.start,
                  ),
                  _Value(
                    vm.mapping.mappedFixtureMode,
                    alignment: MainAxisAlignment.start,
                  ),
                ],
              ),
            ),

            // Error Display.
            Expanded(
              child: _MappingErrorDisplay(
                fixtureError: vm.mapping.typeMappingError,
                modeError: vm.mapping.modeMappingError,
              ),
            ),

            // Database Existence Column.
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ExistsInDatabaseIcon(
                    mappedFixtureTypeValue: vm.mapping.mappedFixtureType,
                    existsInDatabase: vm.existsInDatabase)
              ],
            ))
          ]),
        ),
      ),
    );
  }
}

class _MappingErrorDisplay extends StatelessWidget {
  final MappingError? fixtureError;
  final MappingError? modeError;
  const _MappingErrorDisplay({this.fixtureError, this.modeError});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildError(context, fixtureError) ?? const Text(''),
        _buildError(context, modeError) ?? const Text(''),
      ],
    );
  }

  Widget? _buildError(BuildContext context, MappingError? error) {
    if (error == null) {
      return null;
    }

    return switch (error) {
      MultipleMatchesMappingError e => Tooltip(
          message: e.message,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.error, color: Colors.redAccent),
              Text("Multiple matches",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.redAccent)),
            ],
          ),
        ),
      NoResultMappingError _ => Tooltip(
          message: "No matches found for the supplied source value.",
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.error, color: Colors.redAccent),
              Text("No matches",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.redAccent)),
            ],
          ),
        ),
      BlankValueMappingError e => Tooltip(
          message: e.message,
          child: Row(
            spacing: 8,
            children: [
              const Icon(Icons.error, color: Colors.redAccent),
              Text("Invalid name (blank)",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.redAccent)),
            ],
          ),
        ),
      _ => throw UnimplementedError()
    };
  }
}

class _Value extends StatelessWidget {
  final String value;
  final MainAxisAlignment alignment;

  const _Value(
    this.value, {
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [Text(value)],
    );
  }
}

class _MapsToIcon extends StatelessWidget {
  const _MapsToIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Maps to',
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Colors.grey, fontSize: 11)),
        const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
      ],
    );
  }
}

class _ExistsInDatabaseIcon extends StatelessWidget {
  final bool existsInDatabase;
  final String mappedFixtureTypeValue;
  const _ExistsInDatabaseIcon(
      {required this.mappedFixtureTypeValue, required this.existsInDatabase});

  @override
  Widget build(BuildContext context) {
    return existsInDatabase
        ? Row(
            spacing: 8,
            children: [
              const Icon(Icons.check, color: Colors.green),
              Text('Found in Database',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.green)),
            ],
          )
        : Tooltip(
            message:
                "The mapped value of \"$mappedFixtureTypeValue\" could not be found in the database.\n"
                "Ensure the database has a corresponding value in the \"Phase ID Column\"",
            child: Row(
              spacing: 8,
              children: [
                const Icon(Icons.close, color: Colors.redAccent),
                Text('Not found in Database',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.redAccent)),
              ],
            ),
          );
  }
}
