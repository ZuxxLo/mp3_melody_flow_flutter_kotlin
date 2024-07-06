import 'package:flutter/services.dart';
import 'package:music_player_native/Models/track_model.dart';

class ChannelWithKotlin {
  static const MethodChannel channel = MethodChannel('music_player');
  static bool isServiceNotificationOn = true;

  static Future<List<String>> getMp3FilesPaths() async {
    try {
      final List<String>? mp3FilesPaths =
          await channel.invokeListMethod('getMp3Files');
      return mp3FilesPaths!;
    } on PlatformException catch (e) {
      print("Failed to get MP3 files: '${e.message}'.");
      return <String>[];
    }
  }

  static Future<void> stopService() async {
    try {
      isServiceNotificationOn = false;
      print("isServiceNotificationOn $isServiceNotificationOn");

      await channel.invokeMethod('StopService');
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  static Future<void> updateKotlinTrackName(TrackModel? currentTrack) async {
    String trackName = currentTrack?.metadata?.trackName ??
        currentTrack?.path?.split("/").last ??
        "";

    if (!isServiceNotificationOn) {
      await startService();
    }

    await ChannelWithKotlin.channel.invokeMethod('passTrackNameToKotlin', {
      'trackName': trackName,
    });
  }

  static Future<void> startService() async {
    try {
      print("isServiceNotificationOn $isServiceNotificationOn");

      if (!isServiceNotificationOn) {
        await channel.invokeMethod('StartService');
        print("StartServiceStartServiceStartServiceStartService");
      }
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }
}
