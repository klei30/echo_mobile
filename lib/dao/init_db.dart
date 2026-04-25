import 'dart:async';
import 'package:chatmcp/utils/platform.dart';
import 'package:chatmcp/utils/storage_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

//TODO : need to refactor the database helper class
// desktop app can use different database for persistent storage like sqlite, postgres, etc.
// mobile app can use in memory database
// for now, currently using in memory database for both desktop and mobile
// need to add support for other databases like postgres, mysql, etc. focus on relational database for now

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const List<String> requiredTables = ['chat', 'chat_message'];
  static const int currentVersion = 4;

  DatabaseHelper._init();

  /// Thread-safe database initialization mechanism using Completer
  /// This implementation ensures that:
  /// 1. Database is initialized only once, even if multiple threads call get database simultaneously
  /// 2. All threads receive the same database instance after initialization
  /// 3. If initialization fails, all waiting threads receive the error
  /// 4. No race conditions occur during initialization
  static Completer<Database>? _initializationCompleter;
  static Database? _database;

  /// Thread-safe getter for database instance
  /// Returns existing database if already initialized
  /// If initialization is in progress, waits for it to complete
  /// If no initialization has started, begins new initialization
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // If initialization is already in progress, wait for it
    if (_initializationCompleter != null) {
      Logger.root.fine('Database initialization already in progress, waiting for completion');
      return _initializationCompleter!.future;
    }

    // Start new initialization
    Logger.root.info('Starting new database initialization process');
    _initializationCompleter = Completer<Database>();

    try {
      Logger.root.info('Step 1: Initializing SQLite database...');
      _database = await _initializeSqlite();
      Logger.root.info('Step 2: SQLite database initialized successfully');
      _initializationCompleter!.complete(_database);
    } catch (e, stackTrace) {
      Logger.root.severe('Database initialization failed: $e\nStack trace:\n$stackTrace');
      _initializationCompleter!.completeError(e, stackTrace);
      _initializationCompleter = null;
      rethrow;
    }

    return _database!;
  }

  Future<Database> _initializeSqlite() async {
    if (kIsDesktop) {
      Logger.root.info('Step 1.1: Initializing SQLite for desktop platform');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (kIsMobile) {
      Logger.root.info('Step 1.1: Initializing SQLite for mobile platform');
      databaseFactory = sqflite.databaseFactory;
    } else if (kIsWeb) {
      Logger.root.info('Step 1.1: Initializing SQLite for web platform');
      databaseFactory = databaseFactoryFfiWeb;
    }

    String dbPath;
    if (kIsWeb) {
      dbPath = 'chatmcp.db';
    } else {
      dbPath = await StorageManager.getDatabasePath();
    }

    Logger.root.info('Step 1.2: Database will be created at: $dbPath');
    if (!kIsWeb) {
      Logger.root.info('Step 1.3: Operating system: ${Platform.operatingSystem}');
    }

    final DatabaseSchemaManager schemaManager = DatabaseSchemaManager();

    try {
      Logger.root.info('Step 1.4: Opening database connection and running migrations');
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: currentVersion, onCreate: schemaManager.onCreate, onUpgrade: schemaManager.onUpgrade),
      );

      Logger.root.info('Step 1.5: Database connection established and migrations completed');
      return db;
    } catch (e, stackTrace) {
      Logger.root.severe('Database initialization failed: $e\nStack trace:\n$stackTrace');
      rethrow;
    }
  }
}

// Database Migration Class Definition
class DatabaseMigration {
  final int version;
  final List<String> sql;

  const DatabaseMigration({required this.version, required this.sql});
}

Future<void> initDb() async {
  try {
    Logger.root.info('Database initialization process started');
    final db = await DatabaseHelper.instance.database;
    // Verify if tables were actually created
    final tables = await db.query('sqlite_master', where: "type = 'table'");
    Logger.root.info('Database initialization completed successfully. Available tables: ${tables.map((t) => t['name']).join(', ')}');
  } catch (e, stackTrace) {
    Logger.root.severe('Database initialization failed: $e\nStack trace:\n$stackTrace');
    rethrow;
  }
}

/// Abstract command class that encapsulates SQL statements needed for each version upgrade
abstract class CommandScript {
  /// Utilize [Batch] to execute statements in bulk, avoiding multiple database calls
  Future<void> execute(Batch batch);
}

/// For example, table creation logic for v1
class CommandScriptV1 extends CommandScript {
  @override
  Future<void> execute(Batch batch) async {
    Logger.root.info('Starting table creation...');
    // Initial table creation scripts
    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        model TEXT,
        createdAt datetime,
        updatedAt datetime
      )
    ''');
    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat_message(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId INTEGER,
        messageId TEXT,
        parentMessageId TEXT,
        body TEXT,
        createdAt datetime,
        updatedAt datetime,
        FOREIGN KEY (chatId) REFERENCES chat(id)
      )
    ''');
    Logger.root.info('Table creation complete');
  }
}

/// Database migration for v2 (placeholder for future changes)
class CommandScriptV2 extends CommandScript {
  @override
  Future<void> execute(Batch batch) async {
    Logger.root.info('Applying database migration v2 (placeholder)');
    // Placeholder for future migrations
  }
}

/// Database migration for v3 - Fix model column issue
class CommandScriptV3 extends CommandScript {
  @override
  Future<void> execute(Batch batch) async {
    Logger.root.info('Applying database migration v3 - fixing model column');

    // Use a completely different approach that's safer
    // Instead of trying to detect columns, we'll backup, recreate, and restore

    // Step 1: Create backup table with only columns we know exist
    batch.execute('''
      CREATE TABLE IF NOT EXISTS chat_backup(
        id INTEGER PRIMARY KEY,
        title TEXT,
        createdAt datetime,
        updatedAt datetime
      )
    ''');

    // Step 2: Backup existing data (only safe columns)
    batch.execute('''
      INSERT OR IGNORE INTO chat_backup (id, title, createdAt, updatedAt)
      SELECT id, title, createdAt, updatedAt 
      FROM chat 
      WHERE id IS NOT NULL
    ''');

    // Step 3: Drop the existing table
    batch.execute('DROP TABLE IF EXISTS chat');

    // Step 4: Create new table with correct schema
    batch.execute('''
      CREATE TABLE chat(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        model TEXT,
        createdAt datetime,
        updatedAt datetime
      )
    ''');

    // Step 5: Restore data from backup (model will be NULL)
    batch.execute('''
      INSERT INTO chat (id, title, model, createdAt, updatedAt)
      SELECT id, title, NULL as model, createdAt, updatedAt 
      FROM chat_backup
    ''');

    // Step 6: Clean up backup table
    batch.execute('DROP TABLE IF EXISTS chat_backup');

    Logger.root.info('Database migration v3 completed successfully');
  }
}

/// Database migration for v4 - Add userId column to chat table
class CommandScriptV4 extends CommandScript {
  @override
  Future<void> execute(Batch batch) async {
    Logger.root.info('Applying database migration v4 - adding userId column to chat');
    batch.execute('ALTER TABLE chat ADD COLUMN userId TEXT');
    Logger.root.info('Database migration v4 completed successfully');
  }
}

/// Management class to organize multiple version migration scripts
class DatabaseSchemaManager {
  /// Map versions to corresponding CommandScript
  final Map<int, CommandScript> _commands = {};

  DatabaseSchemaManager() {
    Logger.root.info('Initializing database schema manager');
    _commands[1] = CommandScriptV1();
    _commands[2] = CommandScriptV2();
    _commands[3] = CommandScriptV3();
    _commands[4] = CommandScriptV4();
  }

  /// On database creation: create tables (version=1)
  Future<void> onCreate(Database db, int version) async {
    Logger.root.info('Creating new database schema (version: $version)');
    final batch = db.batch();
    for (int v = 1; v <= version; v++) {
      final script = _commands[v];
      if (script != null) {
        Logger.root.info('Executing schema creation script for version $v');
        await script.execute(batch);
      }
    }
    await batch.commit();
    Logger.root.info('Database schema creation completed');
  }

  /// On database upgrade: execute scripts from oldVersion+1 to newVersion
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.root.info('Upgrading database from version $oldVersion to $newVersion');
    final batch = db.batch();
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      final script = _commands[v];
      if (script != null) {
        Logger.root.info('Executing upgrade script for version $v');
        await script.execute(batch);
      }
    }
    await batch.commit();
    Logger.root.info('Database upgrade completed successfully');
  }
}
