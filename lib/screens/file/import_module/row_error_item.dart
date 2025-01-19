import 'package:flutter/material.dart';
import 'package:sidekick/excel/patch_data_item_error.dart';

class RowErrorItem extends StatelessWidget {
  final PatchDataItemError value;

  const RowErrorItem({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: switch (value.level) {
        PatchDataErrorLevel.warning =>
          const Icon(Icons.warning, color: Colors.orangeAccent),
        PatchDataErrorLevel.critical =>
          const Icon(Icons.error, color: Colors.redAccent),
      },
      title: Text(_getTitle(value)),
      subtitle: Text(_getSubtitle(value)),
    );
  }

  String _getTitle(PatchDataItemError error) {
    return switch (error) {
      NoRowDataError() => 'No Data',
      MalformedRowError() => 'Malformed Row',
      MissingDataError() => 'Missing Data',
      InvalidDataTypeError() => 'Invalid Data Type',
      DataFormatError() => 'Bad Format', 
      NoMatchingFixtureTypeError() => 'No Fixture Type Match',
      NoMatchingLocationError() => 'No Matching Location',
    };
  }

  String _getSubtitle(PatchDataItemError error) {
    return switch (error) {
      NoRowDataError() => 'Row is blank.',
      MalformedRowError() => 'Row is missing columns',
      MissingDataError() => 'No data in the ${error.columnName} column',
      InvalidDataTypeError() =>
        'Invalid data type in ${error.columnName}. Expected type ${error.expectedType}. Data received ${error.data.toString()}',
      DataFormatError() =>
        'Bad Format data in the ${error.columnName} column. Data received ${error.data.toString()}',
      NoMatchingFixtureTypeError() =>
        'No match for Fixture Type. Data received ${error.originalFixtureValue}',
      NoMatchingLocationError() =>
        'No match for Location. Data received ${error.originalLocationValue}',
    };
  }
}
