import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sidekick/serialization/project_file_metadata_model.dart';

class AppInfo extends StatefulWidget {
  const AppInfo({super.key});

  @override
  State<AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<AppInfo> {
  String _appVersion = '';
  String _installedTime = '';
  String _hostName = '';
  String _operatingSystem = '';
  String _operatingSystemVersion = '';

  @override
  void initState() {
    _fetchInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _Property(label: 'App Version', value: _appVersion),
        _Property(
            label: 'Project File Version',
            value: kProjectFileVersion.toString()),
        _Property(label: 'Installed', value: _installedTime),
        _Property(label: 'Host Name', value: _hostName),
        _Property(label: 'OS', value: _operatingSystem),
        _Property(label: 'OS Version', value: _operatingSystemVersion),
        TextButton(
            onPressed: () => showLicensePage(context: context),
            child: const Text("License"))
      ],
    );
  }

  void _fetchInfo() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      _appVersion = info.version;
      _installedTime = _formatTime(info.installTime);
      _hostName = Platform.localHostname;
      _operatingSystem = Platform.operatingSystem;
      _operatingSystemVersion = Platform.operatingSystemVersion;
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '';
    }

    final day = time.day;
    final month = time.month;
    final year = time.year;

    final hour = time.hour;
    final minute = time.minute;

    return "$day/$month/$year  $hour:$minute";
  }
}

class _Property extends StatelessWidget {
  final String label;
  final String value;
  const _Property({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey)),
        const SizedBox(width: 8),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
