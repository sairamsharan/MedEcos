import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/medicine_model.dart';
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const Uuid _uuid = Uuid();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      final path = 'med_ecos_patient.db';
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      // Check if empty and seed
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM medicines'));
      if (count == 0) {
        await _seedData(db);
      }
      return db;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'med_ecos_patient.db');

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines(
        id TEXT PRIMARY KEY,
        name TEXT,
        dosage TEXT,
        frequency INTEGER,
        timings TEXT, -- JSON string
        startDate TEXT,
        endDate TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE history(
        id TEXT PRIMARY KEY,
        medicineId TEXT,
        medicineName TEXT,
        takenTime TEXT,
        status TEXT
      )
    ''');
    
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final medicines = [
      Medicine(
        id: _uuid.v4(),
        name: 'Paracetamol',
        dosage: '500mg',
        frequency: 1,
        timings: [
          MedicineTiming(timeType: TimeType.afterMeal, mealRef: MealType.lunch, offsetMinutes: 30)
        ],
        startDate: DateTime.now(),
      ),
      Medicine(
        id: _uuid.v4(),
        name: 'Amoxicillin',
        dosage: '250mg',
        frequency: 2,
        timings: [
          MedicineTiming(timeType: TimeType.afterMeal, mealRef: MealType.breakfast, offsetMinutes: 30),
          MedicineTiming(timeType: TimeType.afterMeal, mealRef: MealType.dinner, offsetMinutes: 30),
        ],
        startDate: DateTime.now(),
      ),
      Medicine(
        id: _uuid.v4(),
        name: 'Pantoprazole',
        dosage: '40mg',
        frequency: 1,
        timings: [
          MedicineTiming(timeType: TimeType.emptyStomach, mealRef: MealType.breakfast, offsetMinutes: -30)
        ],
        startDate: DateTime.now(),
      ),
      Medicine(
        id: _uuid.v4(),
        name: 'Vitamin D',
        dosage: '1000IU',
        frequency: 1,
        timings: [
          MedicineTiming(timeType: TimeType.afterMeal, mealRef: MealType.breakfast, offsetMinutes: 0)
        ],
        startDate: DateTime.now(),
      ),
    ];

    for (var med in medicines) {
      await db.insert(
        'medicines',
        {
          'id': med.id,
          'name': med.name,
          'dosage': med.dosage,
          'frequency': med.frequency,
          'timings': jsonEncode(med.timings.map((e) => e.toMap()).toList()),
          'startDate': med.startDate.toIso8601String(),
          'endDate': med.endDate?.toIso8601String(),
        },
      );
    }
  }


  Future<int> insertMedicine(Medicine medicine) async {
    final db = await database;
    // Serialize timings separately
    return await db.insert(
      'medicines',
      {
        'id': medicine.id,
        'name': medicine.name,
        'dosage': medicine.dosage,
        'frequency': medicine.frequency,
        'timings': jsonEncode(medicine.timings.map((e) => e.toMap()).toList()),
        'startDate': medicine.startDate.toIso8601String(),
        'endDate': medicine.endDate?.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Medicine>> getMedicines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('medicines');

    return List.generate(maps.length, (i) {
      final map = maps[i];
      final List<dynamic> timingsJson = jsonDecode(map['timings']);
      final timings = timingsJson.map((t) => MedicineTiming(
        timeType: TimeType.values[t['timeType']],
        mealRef: MealType.values[t['mealRef']],
        offsetMinutes: t['offsetMinutes'],
      )).toList();

      return Medicine(
        id: map['id'],
        name: map['name'],
        dosage: map['dosage'],
        frequency: map['frequency'],
        timings: timings,
        startDate: DateTime.parse(map['startDate']),
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      );
    });
  }

  Future<void> deleteMedicine(String id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> logMetadata(String medicineId, String medicineName, DateTime takenTime, String status) async {
    final db = await database;
    return await db.insert('history', {
      'id': _uuid.v4(),
      'medicineId': medicineId,
      'medicineName': medicineName,
      'takenTime': takenTime.toIso8601String(),
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return await db.query('history', orderBy: 'takenTime DESC');
  }
}

