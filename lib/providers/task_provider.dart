import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

class TaskProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Due Date'; // 'Due Date', 'Priority', 'Created Date'
  String _filterStatus = 'All'; // 'All', 'Pending', 'Completed'

  // Cache for filtered/sorted tasks
  List<Task>? _cachedFilteredTasks;
  bool _isDirty = true;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  String get filterStatus => _filterStatus;

  // Categories list
  final List<String> categories = ['All', 'Personal', 'Work', 'Wellness', 'Shopping', 'Ideas'];

  // Auto-load tasks on creation
  TaskProvider() {
    fetchTasks();
  }

  // Initialize and load tasks
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();
    _tasks = await _storageService.loadTasks();
    _isLoading = false;
    _invalidateCache();
    notifyListeners();
  }

  void _invalidateCache() {
    _isDirty = true;
    _cachedFilteredTasks = null;
  }

  // Filtered and sorted tasks (cached)
  List<Task> get filteredAndSortedTasks {
    if (!_isDirty && _cachedFilteredTasks != null) {
      return _cachedFilteredTasks!;
    }

    List<Task> filtered = List.from(_tasks);

    // Apply Status Filter
    if (_filterStatus == 'Pending') {
      filtered = filtered.where((task) => !task.isCompleted).toList();
    } else if (_filterStatus == 'Completed') {
      filtered = filtered.where((task) => task.isCompleted).toList();
    }

    // Apply Category Filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((task) => task.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.notes.toLowerCase().contains(query);
      }).toList();
    }

    // Apply Sorting
    if (_sortBy == 'Due Date') {
      filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else if (_sortBy == 'Priority') {
      // High (2) -> Medium (1) -> Low (0)
      filtered.sort((a, b) {
        final valA = a.priority == TaskPriority.high ? 2 : (a.priority == TaskPriority.medium ? 1 : 0);
        final valB = b.priority == TaskPriority.high ? 2 : (b.priority == TaskPriority.medium ? 1 : 0);
        return valB.compareTo(valA); // Descending order: High priority first
      });
    } else if (_sortBy == 'Created Date') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
    }

    _cachedFilteredTasks = filtered;
    _isDirty = false;
    return filtered;
  }

  // Add Task
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    _invalidateCache();
    notifyListeners();
    await _storageService.saveTasks(_tasks);
  }

  // Insert task at specific position (for undo delete)
  Future<void> insertTask(Task task, int position) async {
    final clampedPos = position.clamp(0, _tasks.length);
    _tasks.insert(clampedPos, task);
    _invalidateCache();
    notifyListeners();
    await _storageService.saveTasks(_tasks);
  }

  // Update Task
  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _invalidateCache();
      notifyListeners();
      await _storageService.saveTasks(_tasks);
    }
  }

  // Delete Task — returns the index for undo support
  Future<int> deleteTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks.removeAt(index);
      _invalidateCache();
      notifyListeners();
      await _storageService.saveTasks(_tasks);
    }
    return index;
  }

  // Toggle Task Completion
  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      _invalidateCache();
      notifyListeners();
      await _storageService.saveTasks(_tasks);
    }
  }

  // Get task count for a given category (for badge display)
  int getTaskCountForCategory(String category) {
    if (category == 'All') return _tasks.length;
    return _tasks.where((t) => t.category.toLowerCase() == category.toLowerCase()).length;
  }

  // Setters for filters and sorting
  void setSearchQuery(String query) {
    _searchQuery = query;
    _invalidateCache();
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _invalidateCache();
    notifyListeners();
  }

  void setSortBy(String sortByOption) {
    _sortBy = sortByOption;
    _invalidateCache();
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _invalidateCache();
    notifyListeners();
  }
}
