#  Customizations

## Usage

Create instance of the ```FeaturesConfig``` to apply various Video Editor configurations. 

Pass the ```FeaturesConfig``` instance to any Video Editor [start method](example/lib/main.dart#L54-L112). For example:

```dart
Future<void> _startVideoEditorInCameraMode() async {
    final config = FeaturesConfigBuilder()
    .setAudioBrowser(AudioBrowser.fromSource(AudioBrowserSource.local))
    // ...
    .build();
    try {
      dynamic exportResult =
          await _veSdkFlutterPlugin.openCameraScreen(_licenseToken, config);
      _handleExportResult(exportResult);
    } on PlatformException catch (e) {
      _handlePlatformException(e);
    }
}
```

## Configurations

1. [AI Captions](ai_captions_guide.md)
2. [AI Clipping](ai_clipping_guide.md)
3. [Audio Browser](audio_browser_guide.md)
4. [Editor screen](editor_screen_guide.md)
5. [Draft](draft_guide.md)