import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'task_form_view.dart';
import 'task_detail_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDateFilter = DateTime.now();
  bool _filterByDate = false;

  // Cached week dates — computed once per session, not every build
  late final List<DateTime> _weekDates;

  // Debounce timer for search
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Cache week dates from today + 6 days
    final now = DateTime.now();
    _weekDates = List.generate(7, (index) => now.add(Duration(days: index)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _onSearchChanged(String val) {
    // Trigger setState immediately for the clear button visibility
    setState(() {});
    // Debounce the actual provider update
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        Provider.of<TaskProvider>(context, listen: false).setSearchQuery(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    // Filter tasks if timeline date is selected
    List<Task> tasksToShow = taskProvider.filteredAndSortedTasks;
    if (_filterByDate) {
      tasksToShow = tasksToShow.where((task) {
        return task.dueDate.year == _selectedDateFilter.year &&
            task.dueDate.month == _selectedDateFilter.month &&
            task.dueDate.day == _selectedDateFilter.day;
      }).toList();
    }

    // Calculations for stats — guarded against NaN
    final totalTasks = taskProvider.tasks.length;
    final completedTasks = taskProvider.tasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final pendingTasks = totalTasks - completedTasks;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => taskProvider.fetchTasks(),
          color: AppTheme.goldPrimary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            slivers: [
              // 1. Sleek Header Area
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getGreeting()}, Creator',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.goldPrimary, width: 1.5),
                          color: AppTheme.goldLight,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.waves,
                          color: AppTheme.goldPrimary,
                          size: 24,
                        ),
                      ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),

              // 2. Ambient Statistics Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.goldPrimary,
                          AppTheme.goldAccent.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.glowShadow,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Tide Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pendingTasks == 0 && totalTasks > 0
                                    ? 'All tasks completed!'
                                    : '$pendingTasks tasks remaining',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Custom Premium Linear Progress Bar
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    height: 8,
                                    width: MediaQuery.of(context).size.width * 0.45 * completionRate,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Circular Progress Representation
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularProgressIndicator(
                                value: completionRate,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            Text(
                              '${(completionRate * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Search and Quick Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldPrimary.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search tasks, notes...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldPrimary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _searchDebounce?.cancel();
                                        Provider.of<TaskProvider>(context, listen: false).setSearchQuery('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter options trigger popup menu
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderGoldLight),
                          ),
                          child: const Icon(Icons.filter_list_rounded, color: AppTheme.goldPrimary),
                        ),
                        onSelected: (val) {
                          taskProvider.setFilterStatus(val);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'All', child: Text('All Statuses')),
                          const PopupMenuItem(value: 'Pending', child: Text('Pending Only')),
                          const PopupMenuItem(value: 'Completed', child: Text('Completed Only')),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Sort options trigger popup menu
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderGoldLight),
                          ),
                          child: const Icon(Icons.sort_rounded, color: AppTheme.goldPrimary),
                        ),
                        onSelected: (val) {
                          taskProvider.setSortBy(val);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'Due Date', child: Text('Sort by Due Date')),
                          const PopupMenuItem(value: 'Priority', child: Text('Sort by Priority')),
                          const PopupMenuItem(value: 'Created Date', child: Text('Sort by Created Date')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Horizontal Category Filter Strip (with task count badges)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: taskProvider.categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final cat = taskProvider.categories[index];
                      final isSelected = taskProvider.selectedCategory == cat;
                      final count = taskProvider.getTaskCountForCategory(cat);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            taskProvider.setSelectedCategory(cat);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.goldPrimary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppTheme.goldPrimary : AppTheme.borderGoldLight,
                                width: 1,
                              ),
                              boxShadow: isSelected ? AppTheme.glowShadow : AppTheme.premiumShadow,
                            ),
                            child: Row(
                              children: [
                                if (cat != 'All') ...[
                                  Icon(
                                    AppTheme.getCategoryIcon(cat),
                                    color: isSelected ? Colors.white : AppTheme.goldPrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textCharcoal,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppTheme.goldLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppTheme.goldPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 5. Horizontal Calendar Timeline Strip
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Timeline Filter',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.textCharcoal,
                              fontSize: 15,
                            ),
                          ),
                          if (_filterByDate)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterByDate = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Clear Date Filter',
                                style: TextStyle(color: AppTheme.goldPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _weekDates.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final date = _weekDates[index];
                          final isToday = DateFormat('yMd').format(date) == DateFormat('yMd').format(DateTime.now());
                          final isSelected = _filterByDate &&
                              date.year == _selectedDateFilter.year &&
                              date.month == _selectedDateFilter.month &&
                              date.day == _selectedDateFilter.day;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDateFilter = date;
                                  _filterByDate = true;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 55,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.goldAccent
                                      : (isToday ? AppTheme.goldLight : Colors.white),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.goldAccent
                                        : (isToday ? AppTheme.goldPrimary : AppTheme.borderGoldLight),
                                    width: isToday || isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: isSelected ? AppTheme.glowShadow : AppTheme.premiumShadow,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('E').format(date).substring(0, 2),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('d').format(date),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textCharcoal,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 6. Task List Section
              taskProvider.isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
                      ),
                    )
                  : tasksToShow.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.goldLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppTheme.goldPrimary,
                                      size: 48,
                                    ),
                                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                  const SizedBox(height: 24),
                                  Text(
                                    'The Tide is Calm',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _filterByDate || taskProvider.selectedCategory != 'All' || taskProvider.searchQuery.isNotEmpty
                                        ? 'No tasks match your current filters.'
                                        : 'You have no scheduled tasks. Enjoy the peace or create a new task below.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = tasksToShow[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Dismissible(
                                  key: Key(task.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.priorityHigh.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppTheme.priorityHigh,
                                      size: 28,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    // Confirm deletion
                                    return await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text('Delete Task'),
                                        content: Text('Are you sure you want to delete "${task.title}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: AppTheme.priorityHigh, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    final deletedIndex = await taskProvider.deleteTask(task.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${task.title}" deleted'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          textColor: AppTheme.goldAccent,
                                          onPressed: () {
                                            taskProvider.insertTask(task, deletedIndex);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TaskDetailView(task: task),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.borderGoldLight),
                                        boxShadow: AppTheme.premiumShadow,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Row(
                                          children: [
                                            // Priority strip indicator
                                            Container(
                                              width: 6,
                                              height: 90,
                                              color: AppTheme.getPriorityColor(task.priority),
                                            ),
                                            const SizedBox(width: 16),
                                            // Task Info
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Category & Date row
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          AppTheme.getCategoryIcon(task.category),
                                                          size: 14,
                                                          color: AppTheme.goldPrimary,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          task.category,
                                                          style: theme.textTheme.bodyMedium?.copyWith(
                                                            fontSize: 12,
                                                            color: AppTheme.goldPrimary,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const Spacer(),
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 12,
                                                          color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                                                              ? AppTheme.priorityHigh
                                                              : AppTheme.textMuted,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          DateFormat('MMM d, h:mm a').format(task.dueDate),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                                                                ? AppTheme.priorityHigh
                                                                : AppTheme.textMuted,
                                                            fontWeight: task.dueDate.isBefore(DateTime.now()) && !task.isCompleted
                                                                ? FontWeight.bold
                                                                : FontWeight.normal,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    // Task Title
                                                    Text(
                                                      task.title,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: task.isCompleted
                                                            ? AppTheme.textMuted.withValues(alpha: 0.6)
                                                            : AppTheme.textCharcoal,
                                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Description Snippet & Icons Indicators
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            task.description.isNotEmpty
                                                                ? task.description
                                                                : 'No description',
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: theme.textTheme.bodyMedium?.copyWith(
                                                              color: task.isCompleted
                                                                  ? AppTheme.textMuted.withValues(alpha: 0.4)
                                                                  : AppTheme.textMuted,
                                                            ),
                                                          ),
                                                        ),
                                                        if (task.notes.isNotEmpty) ...[
                                                          const Icon(Icons.sticky_note_2_outlined, size: 14, color: AppTheme.textMuted),
                                                          const SizedBox(width: 4),
                                                        ],
                                                        if (task.imageAttachments.isNotEmpty) ...[
                                                          const Icon(Icons.photo_outlined, size: 14, color: AppTheme.textMuted),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            '${task.imageAttachments.length}',
                                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                          ),
                                                          const SizedBox(width: 4),
                                                        ],
                                                        const SizedBox(width: 16),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Checkbox
                                            Padding(
                                              padding: const EdgeInsets.only(right: 16),
                                              child: GestureDetector(
                                                onTap: () {
                                                  taskProvider.toggleTaskCompletion(task.id);
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: task.isCompleted ? AppTheme.goldPrimary : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: task.isCompleted ? AppTheme.goldPrimary : AppTheme.goldPrimary.withValues(alpha: 0.6),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: task.isCompleted
                                                      ? const Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fade(duration: 350.ms).slideY(begin: 0.1, end: 0, duration: 350.ms, curve: Curves.easeOutQuad);
                            },
                            childCount: tasksToShow.length,
                          ),
                        ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Space for FAB
            ],
          ),
        ),
      ),
      // Glowing Custom Float Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppTheme.glowShadow,
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskFormView(),
              ),
            );
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack),
    );
  }
}
