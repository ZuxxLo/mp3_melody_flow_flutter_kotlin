import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

import '../DB/db.dart';
import '../Models/track_model.dart';
import '../Utils/channel_with_kotlin.dart';
import '../Utils/music_player.dart';

class TrackViewModel with ChangeNotifier {
  final MusicPlayer _musicPlayer;
  get getMusicPlayerDispose => _musicPlayer.player.dispose();
  bool get getIsMusicPlaying => _musicPlayer.isPlayingbool;

  late Future<List<TrackModel>> mp3Files;
  List<String> mp3FavoritesDB = [];
  List<TrackModel> mp3FilesData1 = [];
  List<TrackModel> mp3FilesData2 = [];
  String? notificationActionPerformed;
  TrackModel? currentTrack;
  int _currentTabIndex = 0;
  handleTabSelection(TabController controller) {
    _currentTabIndex = controller.index;
  }

  TrackViewModel(context, this._musicPlayer) {
    mp3Files = fetchMp3Files();
    fetchFavorites();
    ChannelWithKotlin.channel.setMethodCallHandler(
      (call) {
        return handleMethodCall(call, context: context);
      },
    );
  }

  Future<void> fetchFavorites() async {
    mp3FavoritesDB = await Db().getFavTracks();
    notifyListeners();
  }

  Future<void> handleMethodCall(MethodCall call, {context}) async {
    if (call.method == 'updateActionPerformed') {
      notificationActionPerformed = call.arguments['actionPerformed'];
      switch (notificationActionPerformed) {
        case "action.PLAY_PAUSE":
          handlePauseResumeTrack();

          break;

        case "action.SHAKE":
          print("SHAKESHAKESHAKESHAKE ");

          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(
                duration: Duration(seconds: 1),
                content: Text('Device shaking, music is paused'),
              ))
              .closed
              .then((value) => ScaffoldMessenger.of(context).clearSnackBars());
          handlePauseResumeTrack();

        case "action.PREVIOUS":
          handlePreviousTrack();
          break;
        case "action.NEXT":
          handleNextTrack();
          break;
        case "action.STOP":
          dismissFloatingActionButton();
          break;

        case "ALLOWED_TO_FIND_MP3_FILES":
          print("s*---------------------****");
          mp3Files = fetchMp3Files();
      }
      notifyListeners();
    }
  }

  void handlePauseResumeTrack() {
    _musicPlayer.isPlayingbool
        ? _musicPlayer.pauseAudio()
        : _musicPlayer.resumeAudio();
    updateKotlinTrackName();

    notifyListeners();
  }

  void handlePreviousTrack() async {
    final List<TrackModel> currentList =
        _currentTabIndex == 0 ? mp3FilesData1 : mp3FilesData2;
    int currentIndex =
        currentList.indexWhere((element) => element == currentTrack);
    currentIndex = currentIndex == -1 ? 0 : currentIndex;
    if (currentList.length > 1) {
      currentTrack = await _musicPlayer.playPrevious(currentList, currentIndex);
    }
    updateKotlinTrackName();
  }

  void handleNextTrack() async {
    final List<TrackModel> currentList =
        _currentTabIndex == 0 ? mp3FilesData1 : mp3FilesData2;
    int currentIndex =
        currentList.indexWhere((element) => element == currentTrack);
    currentIndex = currentIndex == -1 ? 0 : currentIndex;
    if (currentList.length > 1) {
      currentTrack = await _musicPlayer.playNext(currentList, currentIndex);
    }
    updateKotlinTrackName();
  }

  void updateKotlinTrackName() {
    ChannelWithKotlin.updateKotlinTrackName(currentTrack, getIsMusicPlaying);
    notifyListeners();
  }

  Future<List<TrackModel>> fetchMp3Files() async {
    List<String> files = await ChannelWithKotlin.getMp3FilesPaths();
    List<TrackModel> mp3Files = [];
    for (String file in files) {
      final metadata = await MetadataRetriever.fromFile(File(file));
      mp3Files.add(TrackModel(metadata: metadata, path: file));
    }
    print(mp3Files.length);

    return mp3Files;
  }

  void sortingFavorites(List<TrackModel> list1, List<String> list2temp) {
    for (var track in list1) {
      if (list2temp.contains(track.path)) {
        track.isFavorite = true;
      }
    }
  }

  void dismissFloatingActionButton() {
    _musicPlayer.stopAudio();
    currentTrack = null;
    ChannelWithKotlin.stopService();
    notifyListeners();
  }

  void playAudio(TrackModel? mp3File) {
    currentTrack = mp3File;
    _musicPlayer.playAudio(currentTrack!);
    updateKotlinTrackName();
  }

  Future<void> toggleFavorite(TrackModel track) async {
    if (track.isFavorite!) {
      track.isFavorite = false;
      mp3FavoritesDB.removeWhere((element) => element == track.path);
      await Db().delete(track: track);
    } else {
      track.isFavorite = true;
      mp3FavoritesDB.add(track.path!);

      await Db().create(track: track);
    }
    notifyListeners();
  }
}
