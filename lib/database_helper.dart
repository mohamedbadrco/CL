// In lib/database_helper.dart

import 'package:flutter/material.dart'; // Required for TimeOfDay
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Event {
  final int? id;
  final String title;
  final DateTime date; // Represents the specific day of the event
  final String startTime; // Store as "HH:mm"
  final String endTime;   // Store as "HH:mm"
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

  // Helper to convert stored string "HH:mm" to TimeOfDay
  TimeOfDay get startTimeAsTimeOfDay {
    final parts = startTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  TimeOfDay get endTimeAsTimeOfDay {
    final parts = endTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Helper for compatibility with existing UI logic if needed
  int get durationInMinutes {
    final start = startTimeAsTimeOfDay;
    final end = endTimeAsTimeOfDay;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // id is fine here, sqflite handles null for autoincrement
      'title': title,
      'date': date.toIso8601String().substring(0,10), // Store only YYYY-MM-DD
      'startTime': startTime, // "HH:mm"
      'endTime': endTime,     // "HH:mm"
      'location': location,
      'description': description,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String), // Parse YYYY-MM-DD
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

  EventAttachment({
    this.id,
    required this.eventId,
    required this.filePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'filePath': filePath,
    };
  }

  factory EventAttachment.fromMap(Map<String, dynamic> map) {
    return EventAttachment(
      id: map['id'] as int?,
      eventId: map['eventId'] as int,
      filePath: map['filePath'] as String,
    );
  }
}

class DatabaseHelper {
  static const _databaseName = "CalendarApp.db";
  static const _databaseVersion = 2; // Increment if schema changes

  static const tableEvents = 'events';
  static const tableAttachments = 'attachments';
  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDate = 'date';
  static const columnStartTime = 'startTime'; // New
  static const columnEndTime = 'endTime';     // New
  static const columnLocation = 'location';   // New
  static const columnDescription = 'description';
  static const columnEventId = 'eventId';
  static const columnFilePath = 'filePath';

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
    return await openDatabase(path,
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
        $columnDate TEXT NOT NULL,      -- YYYY-MM-DD
        $columnStartTime TEXT NOT NULL, -- HH:MM
        $columnEndTime TEXT NOT NULL,   -- HH:MM
        $columnLocation TEXT,
        $columnDescription TEXT
      )
      ''');
    if (version >= 2) {
      await db.execute('''
        CREATE TABLE $tableAttachments (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnEventId INTEGER NOT NULL,
          $columnFilePath TEXT NOT NULL,
          FOREIGN KEY ($columnEventId) REFERENCES $tableEvents($columnId) ON DELETE CASCADE
        )
        ''');
    }
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
  }

  Future<int> insertEvent(Event event) async {
    Database db = await instance.database;
    // Use toMap, but remove 'id' if it's null, as database generates it.
    // Or ensure toMap returns a map where 'id' can be null for insert.
    // The current toMap is fine as sqflite handles null id for autoincrement.
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
    String dateString = date.toIso8601String().substring(0,10); // YYYY-MM-DD
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
    return await db.update(tableEvents, event.toMap(),
        where: '$columnId = ?', whereArgs: [event.id]);
  }

  Future<int> deleteEvent(int id) async {
    Database db = await instance.database;
    return await db.delete(tableEvents, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<EventAttachment>> getAttachmentsForEvent(int eventId) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableAttachments,
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
    return await db.delete(tableAttachments, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> resetDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}
