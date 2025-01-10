/// Represents data exported with Video Editor SDK. Contains a number of exported video files,
/// preview file and meta.
class ExportResult {
  List<String> videoSources;
  String? previewFilePath;
  String? metaFilePath;
  String? musicFileName;
  String? draftSequence;

  ExportResult(
      {required this.videoSources,
      required this.previewFilePath,
      required this.metaFilePath,
      required this.draftSequence,
      required this.musicFileName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportResult &&
          runtimeType == other.runtimeType &&
          videoSources == other.videoSources &&
          previewFilePath == other.previewFilePath &&
          musicFileName == other.musicFileName &&
          draftSequence == other.draftSequence &&
          metaFilePath == other.metaFilePath;

  @override
  int get hashCode => videoSources.hashCode ^ previewFilePath.hashCode ^ metaFilePath.hashCode ^ draftSequence.hashCode ^ musicFileName.hashCode;

  @override
  String toString() {
    return 'ExportResult{videoSources: $videoSources, previewFilePath: $previewFilePath, metaFilePath: $metaFilePath, musicFileName: $musicFileName, draftSequence: $draftSequence}';
  }
}
