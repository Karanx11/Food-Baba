import 'package:sembast_web/sembast_web.dart';

import 'app_database.dart';

DatabaseConfig platformDatabaseConfig(String name) =>
    DatabaseConfig(factory: databaseFactoryWeb, path: () async => name);
