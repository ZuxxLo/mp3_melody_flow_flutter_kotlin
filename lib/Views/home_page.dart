import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player_native/ViewModels/track_view_model.dart';
import 'package:provider/provider.dart';
import '../Models/track_model.dart';
import '../color_transition_gradient.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() =>
        context.read<TrackViewModel>().handleTabSelection(_tabController));
  }
//                 context.read<TrackViewModel>(). handleTabSelection(_tabController);

  @override
  void deactivate() {
    context.read<TrackViewModel>().getMusicPlayerDispose;
    context.read<TrackViewModel>().dispose();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 237, 201, 243),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Consumer<TrackViewModel?>(
        builder: (context, provider, child) {
          return provider!.currentTrack != null
              ? Dismissible(
                  key: UniqueKey(),
                  onDismissed: (direction) =>
                      provider.dismissFloatingActionButton(),
                  child: BuildFloatingActionButton(
                    currentTrack: provider.currentTrack!,
                    buildControlButtons: BuildControlButtons(
                      isMusicPlaying: provider.getIsMusicPlaying,
                      handlePreviousTrack: provider.handlePreviousTrack,
                      handlePauseResumeTrack: provider.handlePauseResumeTrack,
                      handleNextTrack: provider.handleNextTrack,
                    ),
                  ),
                )
              : const SizedBox();
        },
      ),
      appBar: AppBar(
        toolbarHeight: 40,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xff9796f0), Color(0xfffbc7d4)]),
          ),
        ),
        centerTitle: true,
        title: const Text('Mp3 MelodyFlow'),
        bottom: TabBar(
          unselectedLabelColor: Colors.white,
          labelColor: Colors.white,
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.audiotrack)),
            Tab(icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TrackListView(isFavoritesTab: false),
          TrackListView(isFavoritesTab: true),
        ],
      ),
    );
  }
}

class TrackListView extends StatelessWidget {
  final bool isFavoritesTab;

  const TrackListView({Key? key, required this.isFavoritesTab})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    void sortingFavorites(List<TrackModel> list1, List<String> list2temp) {
      for (var track in list1) {
        if (list2temp.contains(track.path)) {
          track.isFavorite = true;
        }
      }
    }

    List<TrackModel> keepingFavoritesOnly(List<TrackModel> list1) {
      return list1.where((track) => track.isFavorite == true).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Consumer<TrackViewModel>(
        builder: (context, trackProvider, child) {
          print("TrackListViewTrackListViewTrackListViewTrackListView");
          return FutureBuilder<List<TrackModel>>(
            future: trackProvider.mp3Files,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                List<TrackModel> mp3FilesData = snapshot.data!;
                sortingFavorites(mp3FilesData, trackProvider.mp3FavoritesDB);
                if (isFavoritesTab) {
                  mp3FilesData = keepingFavoritesOnly(mp3FilesData);
                  trackProvider.mp3FilesData2 = mp3FilesData;
                } else {
                  trackProvider.mp3FilesData1 = mp3FilesData;
                }
                if (mp3FilesData.isEmpty) {
                  return Image.asset(
                    "assets/images/empty-folder.png",
                    scale: 3,
                    color: Color.fromARGB(255, 164, 163, 255),
                  );
                } else {
                  return ListView(
                    children: [
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: mp3FilesData.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 5),
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () =>
                                trackProvider.playAudio(mp3FilesData[index]),
                            child: BuildTrackListItem(
                              mp3fileMetaData: mp3FilesData[index].metadata!,
                              mp3FilesData: mp3FilesData,
                              index: index,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}

class BuildTrackListItem extends StatelessWidget {
  final Metadata mp3fileMetaData;
  final List<TrackModel> mp3FilesData;
  final int index;

  const BuildTrackListItem({
    Key? key,
    required this.mp3fileMetaData,
    required this.mp3FilesData,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double colorOpacity(int length, int index) {
      return index == 0 ? 0.08 : index.toDouble() / length.toDouble();
    }

    LinearGradient gradient = LinearGradient(
      colors: [
        const Color(0xff9796f0).withOpacity((index + 1) / mp3FilesData.length),
        const Color(0xfffbc7d4).withOpacity((index + 1) / mp3FilesData.length)
      ],
      end: Alignment.topLeft,
      begin: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(
          strokeAlign: BorderSide.strokeAlignOutside,
          color: Colors.white,
        ),
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                mp3fileMetaData.albumArt != null
                    ? Image.memory(
                        mp3FilesData[index].metadata!.albumArt!,
                        fit: BoxFit.fill,
                      )
                    : SizedBox(
                        width: 60,
                        height: 60,
                        child: ColorTransitionGradient(index: index),
                      ),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    mp3FilesData[index].metadata!.trackName ??
                        mp3FilesData[index].path!.split("/").last,
                  ),
                ),
              ],
            ),
          ),
          Consumer<TrackViewModel>(builder: (context, value, child) {
            return IconButton(
              icon: Icon(
                mp3FilesData[index].isFavorite!
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: mp3FilesData[index].isFavorite! ? Colors.red : null,
              ),
              onPressed: () {
                value.toggleFavorite(mp3FilesData[index]);
              },
            );
          }),
        ],
      ),
    );
  }
}

class BuildFloatingActionButton extends StatelessWidget {
  final TrackModel currentTrack;
  final Widget buildControlButtons;
  const BuildFloatingActionButton({
    super.key,
    required this.currentTrack,
    required this.buildControlButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 70,
      width: MediaQuery.sizeOf(context).width / 1.4,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 4,
            offset: Offset(0, 8), // Shadow position
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 236, 240, 252),
            Color.fromARGB(255, 254, 182, 200),
            // Color.fromARGB(255, 231, 188, 255)
          ],
          stops: [0, 0.81],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(0.5),
        )

        // LinearGradient(
        //   colors: [Color(0xff9796f0), Color(0xfffbc7d4)],
        //   stops: [0, 1],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // )

        ,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          currentTrack.metadata!.albumArt != null
              ? Image.memory(currentTrack.metadata!.albumArt!, fit: BoxFit.fill)
              : const SizedBox(
                  width: 70,
                  height: 70,
                  child: ColorTransitionGradient(index: 0)),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      currentTrack.metadata!.trackName ??
                          currentTrack.path!.split("/").last,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  Expanded(child: buildControlButtons),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class BuildControlButtons extends StatelessWidget {
  final void Function() handlePreviousTrack;
  final void Function() handlePauseResumeTrack;
  final void Function() handleNextTrack;

  final bool isMusicPlaying;

  const BuildControlButtons({
    Key? key,
    required this.handlePreviousTrack,
    required this.handlePauseResumeTrack,
    required this.handleNextTrack,
    required this.isMusicPlaying,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: handlePreviousTrack,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: handlePauseResumeTrack,
          icon: Icon(isMusicPlaying ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          onPressed: handleNextTrack,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}
