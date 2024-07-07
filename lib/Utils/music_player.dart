import 'package:audioplayers/audioplayers.dart';

import 'package:music_player_native/Models/track_model.dart';

class MusicPlayer {
  PlayerState isPlaying = PlayerState.playing;
  bool isPlayingbool = true;
  final player = AudioPlayer();

  playAudio(TrackModel audio) async {
    isPlayingbool = true;

    await player.play(DeviceFileSource(audio.path!));
    player.setReleaseMode(ReleaseMode.loop);
  }

  stopAudio() async {
    await player.stop();
  }

  pauseAudio() async {
    isPlayingbool = false;
    print("inpauseAudio $isPlayingbool");

    await player.pause();
  }

  Future<TrackModel> playNext(List<TrackModel> mp3FilesData, int index) async {
    index++;
    if (mp3FilesData.length == index) {
      index = 0;
    }
  
    await player.play(DeviceFileSource(mp3FilesData[index].path!));
    player.setReleaseMode(ReleaseMode.loop);
    isPlayingbool = true;

    return Future.value(mp3FilesData[index]);
  }

  Future<TrackModel> playPrevious(
      List<TrackModel> mp3FilesData, int index) async {
    index--;
    if (-1 == index) {
      index = mp3FilesData.length - 1;
    }

    await player.play(DeviceFileSource(mp3FilesData[index].path!));
    player.setReleaseMode(ReleaseMode.loop);
    isPlayingbool = true;

    return Future.value(mp3FilesData[index]);
  }

  resumeAudio() async {
    isPlayingbool = true;

    await player.resume();
  }
}
