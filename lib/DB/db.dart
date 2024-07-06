import 'package:music_player_native/Models/track_model.dart';
import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class Db {
  final tableName = "musicplayer";

  createTable(Database database) async {
    await database.execute("""CREATE TABLE IF NOT EXISTS $tableName (
         "path" TEXT NOT NULL,
         PRIMARY KEY ("path" ));""");
  }

  create({required TrackModel track}) async {
    final database = await DatabaseHelper().dataBase;
    return await database.rawInsert(
        '''INSERT INTO $tableName (path) VALUES (?)''', [track.path]);
  }

  delete({required TrackModel track}) async {
    final database = await DatabaseHelper().dataBase;
    return await database
        .delete(tableName, where: "path=?", whereArgs: [track.path]);
  }

  clearFavourits() async {
    final database = await DatabaseHelper().dataBase;

    return await database.rawDelete("DELETE FROM $tableName");
  }

  Future<List<String>> getFavTracks() async {
    final database = await DatabaseHelper().dataBase;
    final tracks = await database.rawQuery('''SELECT * FROM $tableName ''');
    List<String> paths = tracks.map((e) => e["path"] as String).toList();
    for (var element in paths) {
      print(element);
    }

    return paths;
  }
}
