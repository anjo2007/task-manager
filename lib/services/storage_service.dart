import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'tide_tasks_key';

  // Cache the SharedPreferences instance to avoid repeated async lookups
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Load tasks from SharedPreferences
  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await _getPrefs();
      final String? tasksJson = prefs.getString(_tasksKey);
      if (tasksJson == null || tasksJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decodedList = json.decode(tasksJson);
      return decodedList.map((item) => Task.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      return [];
    }
  }

  // Save tasks to SharedPreferences
  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await _getPrefs();
      final List<Map<String, dynamic>> mapList = tasks.map((t) => t.toMap()).toList();
      final String encodedJson = json.encode(mapList);
      await prefs.setString(_tasksKey, encodedJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }
}
