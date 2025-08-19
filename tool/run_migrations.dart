import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:savessa/services/database/migration_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final migrator = MigrationService();
  await migrator.run();
  // Print a simple success line
  // ignore: avoid_print
  print('Migrations completed successfully.');
}
