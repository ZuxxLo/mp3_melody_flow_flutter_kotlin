import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../ViewModels/track_view_model.dart';

List<SingleChildWidget> appProviders = [
  ...independentProviders,
];

List<SingleChildWidget> independentProviders = [
  ChangeNotifierProvider<TrackViewModel>(
    create: (_) => TrackViewModel(_),
  ),
];
