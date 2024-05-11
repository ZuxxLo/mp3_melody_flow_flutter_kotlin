import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player_native/db.dart';
import 'package:music_player_native/music_player.dart';

import 'channel_with_kotlin.dart';
import 'track_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mp3 Music Player',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      //  theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final Future<List<TrackModel>> mp3Files;
  List<String> mp3FavoritesDB = [];
  List<TrackModel> mp3FilesData1 = [];
  List<TrackModel> mp3FilesData2 = [];

  late StreamSubscription _notifcationActionsSubscription;

  String? notifcationActionPerformed;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    mp3Files = fetchMp3Files(); // Assign your Future to it.
    Db().getAllNotes().then((value) => mp3FavoritesDB = value);
    ChannelWithKotlin.channel.setMethodCallHandler((call) async {
      if (call.method == 'updateActionPerformed') {
        setState(() {
          var callAction = call.arguments['actionPerformed'];
          print(callAction);

          notifcationActionPerformed = callAction;
          if (notifcationActionPerformed == "action.PLAY_PAUSE") {
            MusicPlayer.isPlayingbool
                ? MusicPlayer.pauseAudio()
                : MusicPlayer.resumeAudio();
          } else if (notifcationActionPerformed == "action.PREVIOUS") {
            if (_tabController.index == 0) {
              int currentIndex = mp3FilesData1
                  .indexWhere((element) => element == currentTrack);

              MusicPlayer.playNext(mp3FilesData1, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            } else {
              int currentIndex = mp3FilesData2
                  .indexWhere((element) => element == currentTrack);
              if (currentIndex == -1) {
                currentIndex = 0;
              }

              MusicPlayer.playPrevious(mp3FilesData2, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            }
          } else if (notifcationActionPerformed == "action.NEXT") {
            if (_tabController.index == 0) {
              int currentIndex = mp3FilesData1
                  .indexWhere((element) => element == currentTrack);

              MusicPlayer.playNext(mp3FilesData1, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            } else {
              int currentIndex = mp3FilesData2
                  .indexWhere((element) => element == currentTrack);
              if (currentIndex == -1) {
                currentIndex = 0;
              }

              MusicPlayer.playNext(mp3FilesData2, currentIndex)
                  .then((track) => setState(() {
                        currentTrack = track;
                        ChannelWithKotlin.channel.invokeMethod(
                            'passTrackNameToKotlin',
                            {'trackName': currentTrack!.metadata!.trackName});
                      }));
            }
          } else if (notifcationActionPerformed == "action.SHAKE") {
            MusicPlayer.isPlayingbool
                ? MusicPlayer.pauseAudio()
                : MusicPlayer.resumeAudio();
          }
        });
      }
    });

    _notifcationActionsSubscription =
        ChannelWithKotlin.notifactionActionStream.listen((value) {
      setState(() {
        // print(value);
        // Update the state based on the received data
      });
    });
  }

  @override
  void dispose() {
    _notifcationActionsSubscription.cancel(); // Cancel the stream subscription
    MusicPlayer.player.dispose();

    super.dispose();
  }

  sortingFavorites(List<TrackModel> list1, List<String> list2temp) {
    List<String> list2 = list2temp;
    list1.forEach((track) {
      if (list2.contains(track.path)) {
        track.isFavorite = true;
      }
    });
  }

  List<TrackModel> keepingFavouritsOnly(List<TrackModel> list1) {
    return list1.where((track) => track.isFavorite == true).toList();
  }

  Uint8List? albumArt;
  TrackModel? currentTrack;

  Future<List<TrackModel>> fetchMp3Files() async {
    List<String> files = await ChannelWithKotlin.getMp3FilesPaths();
    List<TrackModel> mp3Files = [];

    print("files: $files");
    files.forEach((file) async {
      final metadata = await MetadataRetriever.fromFile(File(file));
      print(file);
      mp3Files.add(TrackModel(metadata: metadata, path: file));
    });

    return mp3Files;
  }

  double colorOpacity(int length, int index) {
    double result;
    if (index == 0) {
      result = 0.08;
    } else {
      result = index.toDouble() / length.toDouble();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 237, 201, 243),
      floatingActionButton: currentTrack != null
          ? Container(
              height: 70,
              margin: const EdgeInsets.only(left: 60, right: 35),
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.purple.withOpacity(0.4)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.memory(currentTrack!.metadata!.albumArt!,
                      fit: BoxFit.fill),
                  const SizedBox(width: 50),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentTrack!.metadata!.trackName!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                if (_tabController.index == 0) {
                                  int currentIndex = mp3FilesData1.indexWhere(
                                      (element) => element == currentTrack);

                                  MusicPlayer.playPrevious(
                                          mp3FilesData1, currentIndex)
                                      .then((track) => setState(() {
                                            currentTrack = track;
                                            ChannelWithKotlin.channel
                                                .invokeMethod(
                                                    'passTrackNameToKotlin', {
                                              'trackName': currentTrack!
                                                  .metadata!.trackName
                                            });
                                          }));
                                } else {
                                  int currentIndex = mp3FilesData2.indexWhere(
                                      (element) => element == currentTrack);
                                  if (currentIndex == -1) {
                                    currentIndex = 0;
                                  }

                                  MusicPlayer.playPrevious(
                                          mp3FilesData2, currentIndex)
                                      .then((track) => setState(() {
                                            currentTrack = track;
                                            ChannelWithKotlin.channel
                                                .invokeMethod(
                                                    'passTrackNameToKotlin', {
                                              'trackName': currentTrack!
                                                  .metadata!.trackName
                                            });
                                          }));
                                }
                                setState(() {});
                              },
                              icon: const Icon(Icons.skip_previous)),
                          IconButton(
                              onPressed: () {
                                MusicPlayer.isPlayingbool
                                    ? MusicPlayer.pauseAudio()
                                    : MusicPlayer.resumeAudio();

                                setState(() {});
                              },
                              icon: Icon(MusicPlayer.isPlayingbool
                                  ? Icons.pause
                                  : Icons.play_arrow)),
                          IconButton(
                              onPressed: () {
                                if (_tabController.index == 0) {
                                  int currentIndex = mp3FilesData1.indexWhere(
                                      (element) => element == currentTrack);

                                  MusicPlayer.playNext(
                                          mp3FilesData1, currentIndex)
                                      .then((track) => setState(() {
                                            currentTrack = track;
                                            ChannelWithKotlin.channel
                                                .invokeMethod(
                                                    'passTrackNameToKotlin', {
                                              'trackName': currentTrack!
                                                  .metadata!.trackName
                                            });
                                          }));
                                } else {
                                  int currentIndex = mp3FilesData2.indexWhere(
                                      (element) => element == currentTrack);
                                  if (currentIndex == -1) {
                                    currentIndex = 0;
                                  }

                                  MusicPlayer.playNext(
                                          mp3FilesData2, currentIndex)
                                      .then((track) => setState(() {
                                            currentTrack = track;
                                            ChannelWithKotlin.channel
                                                .invokeMethod(
                                                    'passTrackNameToKotlin', {
                                              'trackName': currentTrack!
                                                  .metadata!.trackName
                                            });
                                          }));
                                }
                              },
                              icon: const Icon(Icons.skip_next))
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mp3 Music player'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.audiotrack),
            ),
            Tab(
              icon: Icon(Icons.favorite),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
                future: mp3Files,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    mp3FilesData1 = snapshot.data!;
                    var mp3FilesData = snapshot.data!;
                    sortingFavorites(mp3FilesData, mp3FavoritesDB);
                    return ListView.separated(
                      itemCount: mp3FilesData.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              currentTrack = mp3FilesData[index];
                              ChannelWithKotlin.channel.invokeMethod(
                                  'passTrackNameToKotlin', {
                                'trackName': currentTrack!.metadata!.trackName
                              });

                              MusicPlayer.playAudio(currentTrack!);
                            });
                            // ChannelWithKotlin.startService();

                            setState(() {});
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.purple.withOpacity(
                                    colorOpacity(mp3FilesData.length, index))),
                            height: 60,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.memory(
                                          mp3FilesData[index]
                                              .metadata!
                                              .albumArt!,
                                          fit: BoxFit.fill),
                                      const SizedBox(width: 10),
                                      Text(
                                        mp3FilesData[index]
                                            .metadata!
                                            .trackName!,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      TrackModel track = mp3FilesData[index];
                                      if (track.isFavorite!) {
                                        Db().delete(track: track);
                                        track.isFavorite = false;
                                      } else {
                                        Db().create(track: track);
                                        track.isFavorite = true;
                                      }
                                      Db().getAllNotes().then(
                                          (value) => mp3FavoritesDB = value);

                                      setState(() {});
                                    },
                                    icon: mp3FilesData[index].isFavorite!
                                        ? const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                          )
                                        : const Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                          ))
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }),
          ),

          /////////////// favorits
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
                future: mp3Files,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    var mp3FilesData = snapshot.data!;

                    sortingFavorites(mp3FilesData, mp3FavoritesDB);
                    mp3FilesData = keepingFavouritsOnly(snapshot.data!);
                    mp3FilesData2 = mp3FilesData;

                    return ListView.separated(
                      itemCount: mp3FilesData.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () {
                            //   ChannelWithKotlin.startService();

                            setState(() {
                              currentTrack = mp3FilesData[index];

                              MusicPlayer.playAudio(mp3FilesData[index]);
                              ChannelWithKotlin.channel.invokeMethod(
                                  'passTrackNameToKotlin', {
                                'trackName': currentTrack!.metadata!.trackName
                              });
                            });
                          },
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.purple.withOpacity(
                                    colorOpacity(mp3FilesData.length, index))),
                            height: 60,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Image.memory(
                                          mp3FilesData[index]
                                              .metadata!
                                              .albumArt!,
                                          fit: BoxFit.fill),
                                      const SizedBox(width: 10),
                                      Text(
                                        mp3FilesData[index]
                                            .metadata!
                                            .trackName!,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      TrackModel track = mp3FilesData[index];
                                      if (track.isFavorite!) {
                                        Db().delete(track: track);
                                        track.isFavorite = false;
                                      } else {
                                        Db().create(track: track);
                                        track.isFavorite = true;
                                      }
                                      Db().getAllNotes().then(
                                          (value) => mp3FavoritesDB = value);
                                      setState(() {});
                                    },
                                    icon: mp3FilesData[index].isFavorite!
                                        ? const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                          )
                                        : const Icon(
                                            Icons.favorite_border,
                                            color: Colors.white,
                                          ))
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                }),
          ),
        ],
      ),
    );
  }
}
