import 'package:music_player_native/Utils/music_player.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../ViewModels/track_view_model.dart';

List<SingleChildWidget> appProviders = [
  ...independentProviders,
  ...dependentProviders,
];

List<SingleChildWidget> independentProviders = [
  Provider(
    create: (_) => MusicPlayer(),
    lazy: true,
    dispose: (context, value) {
      print("disposedisposedisposedisposeMusicPlayer");
      value.player.dispose();
    },
  ),
];

List<SingleChildWidget> dependentProviders = [
  ChangeNotifierProxyProvider<MusicPlayer, TrackViewModel>(
    create: (context) => TrackViewModel(context, context.read<MusicPlayer>()),
    update: (context, musicPlayer, trackViewModel) =>
        trackViewModel ?? TrackViewModel(context, musicPlayer),
  )
];
