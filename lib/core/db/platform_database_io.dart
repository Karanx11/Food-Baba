import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';

DatabaseConfig platformDatabaseConfig(String name) => DatabaseConfig(
  factory: databaseFactoryIo,
  path: () async =>
      p.join((await getApplicationDocumentsDirectory()).path, name),
);
