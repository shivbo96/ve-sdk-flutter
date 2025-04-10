import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ve_sdk_flutter/export_result.dart';
import 'package:ve_sdk_flutter/features_config.dart';
import 'package:ve_sdk_flutter/ve_sdk_flutter.dart';

import 'main.dart';

class DraftList extends StatefulWidget {
  DraftList({super.key, this.draftList});

  List<dynamic>? draftList;

  @override
  State<DraftList> createState() => _DraftListState();
}

class _DraftListState extends State<DraftList> {
  final _veSdkFlutterPlugin = VeSdkFlutter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of items per row
            crossAxisSpacing: 10, // Spacing between columns
            mainAxisSpacing: 10, // Spacing between rows
          ),
          itemCount: widget.draftList?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () async {
                final FeaturesConfigBuilder configBuilder = FeaturesConfigBuilder()
                    .setDraftsConfig(DraftsConfig.fromOption(DraftsOption.auto))
                    .setEditorConfig(const EditorConfig(enableVideoCover: false, enableVideoAspectFill: false));

                const VideoDurationConfig durationConfig = VideoDurationConfig(videoDurations: [60, 30, 15], maxTotalVideoDuration: 60);

                configBuilder.setVideoDurationConfig(durationConfig);

                final FeaturesConfig config = configBuilder.build();
                final ExportResult? exportResult =
                await _veSdkFlutterPlugin.openEditorFromDraft(licenseToken, '', config);
                _handleExportResult(exportResult);
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Positioned.fill(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // Corner radius
                        ),
                        color: Colors.blueAccent,
                        child: Image.file(
                          File(widget.draftList?[index] ?? ''),
                          fit: BoxFit.cover,
                        ),
                      )),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final bool? isRemovedFromList =
                        await _veSdkFlutterPlugin.removeDraftFromList(licenseToken, draftSequenceId: '');

                        if (isRemovedFromList ?? false) {
                          final List<dynamic>? exportResult = await _veSdkFlutterPlugin.getAllDraftList(licenseToken);

                          setState(() {
                            widget.draftList = exportResult;
                          });
                        }
                      },
                      color: Colors.red,
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleExportResult(ExportResult? result) {
    if (result == null) {
      debugPrint('No export result! The user has closed video editor before export');
      return;
    }

    debugPrint('Exported musicFileName = ${result.audioMeta?.firstOrNull?.title}');

    // The list of exported video file paths
    debugPrint('Exported video files = ${result.videoSources}');

    // Preview as a image file taken by the user. Null - when preview screen is disabled.
    debugPrint('Exported preview file = ${result.previewFilePath}');

    // Meta file where you can find short data used in exported video
    debugPrint('Exported meta file = ${result.metaFilePath}');
  }
}