// In lib/database_helper.dart

import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert'; // For jsonEncode
import 'package:crypto/crypto.dart'; // For sha256

class Event {
  final int? id;
  final String title;
  final DateTime date; // Represents the specific day of the event
  final String startTime; // Store as "HH:mm"
  final String endTime; // Store as "HH:mm"
  final String location;
  final String description;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.description = '',
  });

  TimeOfDay get startTimeAsTimeOfDay {
    final parts = startTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  TimeOfDay get endTimeAsTimeOfDay {
    final parts = endTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  int get durationInMinutes {
    final start = startTimeAsTimeOfDay;
    final end = endTimeAsTimeOfDay;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  DateTime get startTimeAsDateTime {
    final time = startTimeAsTimeOfDay;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime get endTimeAsDateTime {
    final time = endTimeAsTimeOfDay;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String().substring(0, 10),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'description': description,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      location: map['location'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

class EventAttachment {
  final int? id;
  final int eventId;
  final String filePath;

  EventAttachment({this.id, required this.eventId, required this.filePath});

  Map<String, dynamic> toMap() {
    return {'id': id, 'eventId': eventId, 'filePath': filePath};
  }

  factory EventAttachment.fromMap(Map<String, dynamic> map) {
    return EventAttachment(
      id: map['id'] as int?,
      eventId: map['eventId'] as int,
      filePath: map['filePath'] as String,
    );
  }
}

class AiSummary {
  final String date; // YYYY-MM-DD, primary key
  final String summary;
  final String lastUpdated; // ISO8601 DateTime string
  final String eventsHash;

  AiSummary({
    required this.date,
    required this.summary,
    required this.lastUpdated,
    required this.eventsHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'summary': summary,
      'lastUpdated': lastUpdated,
      'eventsHash': eventsHash,
    };
  }

  factory AiSummary.fromMap(Map<String, dynamic> map) {
    return AiSummary(
      date: map['date'] as String,
      summary: map['summary'] as String,
      lastUpdated: map['lastUpdated'] as String,
      eventsHash: map['eventsHash'] as String,
    );
  }
}

class DatabaseHelper {
  static const _databaseName = "CalendarApp.db";
  static const _databaseVersion = 3; // Incremented version

  static const tableEvents = 'events';
  static const tableAttachments = 'attachments';
  static const tableAiSummaries = 'ai_summaries'; // New table

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDate = 'date'; // Also used as primary key in ai_summaries
  static const columnStartTime = 'startTime';
  static const columnEndTime = 'endTime';
  static const columnLocation = 'location';
  static const columnDescription = 'description';
  static const columnEventId = 'eventId';
  static const columnFilePath = 'filePath';

  // Columns for ai_summaries table
  static const columnSummary = 'summary';
  static const columnLastUpdated = 'lastUpdated';
  static const columnEventsHash = 'eventsHash';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableEvents (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnStartTime TEXT NOT NULL,
        $columnEndTime TEXT NOT NULL,
        $columnLocation TEXT,
        $columnDescription TEXT
      )
      ''');
    await db.execute('''
      CREATE TABLE $tableAttachments (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnEventId INTEGER NOT NULL,
        $columnFilePath TEXT NOT NULL,
        FOREIGN KEY ($columnEventId) REFERENCES $tableEvents($columnId) ON DELETE CASCADE
      )
      ''');
    // Create ai_summaries table
    await _createAiSummariesTable(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $tableAttachments (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnEventId INTEGER NOT NULL,
          $columnFilePath TEXT NOT NULL,
          FOREIGN KEY ($columnEventId) REFERENCES $tableEvents($columnId) ON DELETE CASCADE
        )
        ''');
    }
    if (oldVersion < 3) {
      await _createAiSummariesTable(db);
    }
  }

  Future<void> _createAiSummariesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAiSummaries (
        $columnDate TEXT PRIMARY KEY,
        $columnSummary TEXT NOT NULL,
        $columnLastUpdated TEXT NOT NULL,
        $columnEventsHash TEXT NOT NULL
      )
      ''');
  }

  Future<int> insertEvent(Event event) async {
    Database db = await instance.database;
    return await db.insert(tableEvents, event.toMap());
  }

  Future<List<Event>> getAllEvents() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableEvents);
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<List<Event>> getEventsForDate(DateTime date) async {
    Database db = await instance.database;
    String dateString = date.toIso8601String().substring(0, 10);
    final List<Map<String, dynamic>> maps = await db.query(
      tableEvents,
      where: "$columnDate = ?",
      whereArgs: [dateString],
    );
    if (maps.isEmpty) {
      return [];
    }
    return List.generate(maps.length, (i) {
      return Event.fromMap(maps[i]);
    });
  }

  Future<int> updateEvent(Event event) async {
    Database db = await instance.database;
    return await db.update(
      tableEvents,
      event.toMap(),
      where: '$columnId = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableEvents,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<List<EventAttachment>> getAttachmentsForEvent(int eventId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAttachments,
      where: '$columnEventId = ?',
      whereArgs: [eventId],
    );
    return List.generate(maps.length, (i) => EventAttachment.fromMap(maps[i]));
  }

  Future<int> insertAttachment(int eventId, String filePath) async {
    Database db = await instance.database;
    return await db.insert(tableAttachments, {
      columnEventId: eventId,
      columnFilePath: filePath,
    });
  }

  Future<int> deleteAttachment(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableAttachments,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // New methods for AI Summaries
  Future<void> upsertAiSummary(AiSummary summary) async {
    Database db = await instance.database;
    await db.insert(
      tableAiSummaries,
      summary.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replaces if date already exists
    );
  }

  Future<AiSummary?> getAiSummary(String dateString) async {
    // dateString is YYYY-MM-DD
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableAiSummaries,
      where: '$columnDate = ?',
      whereArgs: [dateString],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AiSummary.fromMap(maps.first);
    }
    return null;
  }

  // Helper to generate a hash for a list of events
  String generateEventsHash(List<Event> events) {
    if (events.isEmpty) {
      return ''; // Or a specific hash for empty list
    }
    // Sort events by ID to ensure consistent hash for the same set of events
    events.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    String combined = events.map((e) => jsonEncode(e.toMap())).join('|');
    return sha256.convert(utf8.encode(combined)).toString();
  }

  Future<void> resetDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}
