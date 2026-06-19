import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'task_form_view.dart';

class TaskDetailView extends StatelessWidget {
  final Task task;

  const TaskDetailView({super.key, required this.task});

  void _showFullscreenImage(BuildContext context, String base64Image, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('Photo ${index + 1}', style: const TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Hero(
                tag: 'task_photo_${task.id}_$index',
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    
    // Find current task in provider list (to reflect updates in real-time)
    final currentTaskIndex = taskProvider.tasks.indexWhere((t) => t.id == task.id);
    final currentTask = currentTaskIndex != -1 ? taskProvider.tasks[currentTaskIndex] : task;
    
    final isOverdue = currentTask.dueDate.isBefore(DateTime.now()) && !currentTask.isCompleted;

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.goldPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskFormView(taskToEdit: currentTask),
                ),
              );
            },
            tooltip: 'Edit Task',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.priorityHigh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Delete Task'),
                  content: Text('Are you sure you want to delete "${currentTask.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Pop dialog and pop detail view
                        Navigator.pop(dialogContext);
                        taskProvider.deleteTask(currentTask.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('"${currentTask.title}" deleted')),
                        );
                      },
                      child: const Text('Delete', style: TextStyle(color: AppTheme.priorityHigh, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Delete Task',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Completion & Title Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderGoldLight),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Tag & Priority Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.goldLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.goldPrimary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppTheme.getCategoryIcon(currentTask.category),
                                size: 14,
                                color: AppTheme.goldPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentTask.category,
                                style: const TextStyle(
                                  color: AppTheme.goldDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.getPriorityColor(currentTask.priority).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.getPriorityColor(currentTask.priority).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '${currentTask.priority.name[0].toUpperCase()}${currentTask.priority.name.substring(1)} Priority',
                            style: TextStyle(
                              color: AppTheme.getPriorityColor(currentTask.priority),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      currentTask.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentTask.isCompleted ? AppTheme.textMuted.withValues(alpha: 0.7) : AppTheme.textCharcoal,
                        decoration: currentTask.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Checkbox status toggle bar
                    InkWell(
                      onTap: () {
                        taskProvider.toggleTaskCompletion(currentTask.id);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: currentTask.isCompleted ? AppTheme.goldPrimary.withValues(alpha: 0.1) : AppTheme.creamBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: currentTask.isCompleted ? AppTheme.goldPrimary : AppTheme.borderGoldLight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentTask.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: AppTheme.goldPrimary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              currentTask.isCompleted ? 'Mark Pending' : 'Mark Completed',
                              style: const TextStyle(
                                color: AppTheme.goldDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms),

              const SizedBox(height: 20),

              // 2. Date and Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderGoldLight),
                  boxShadow: AppTheme.premiumShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppTheme.priorityHigh.withValues(alpha: 0.1)
                            : (currentTask.isCompleted ? Colors.green.withValues(alpha: 0.1) : AppTheme.goldLight),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOverdue
                            ? Icons.warning_amber_rounded
                            : (currentTask.isCompleted ? Icons.task_alt : Icons.calendar_month_outlined),
                        color: isOverdue
                            ? AppTheme.priorityHigh
                            : (currentTask.isCompleted ? Colors.green : AppTheme.goldPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date & Time',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, y • h:mm a').format(currentTask.dueDate),
                            style: const TextStyle(
                              color: AppTheme.textCharcoal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Overdue!',
                              style: TextStyle(
                                color: AppTheme.priorityHigh,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else if (currentTask.isCompleted) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms),

              const SizedBox(height: 20),

              // 3. Task Description Section
              if (currentTask.description.isNotEmpty) ...[
                const Text(
                  'Task Description',
                  style: TextStyle(
                    color: AppTheme.textCharcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderGoldLight),
                    boxShadow: AppTheme.premiumShadow,
                  ),
                  child: Text(
                    currentTask.description,
                    style: const TextStyle(
                      color: AppTheme.textCharcoal,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ).animate().fade(delay: 150.ms, duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms),
                const SizedBox(height: 20),
              ],

              // 4. Detailed Notes Section
              if (currentTask.notes.isNotEmpty) ...[
                const Text(
                  'Detailed Notes',
                  style: TextStyle(
                    color: AppTheme.textCharcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderGoldLight),
                    boxShadow: AppTheme.premiumShadow,
                  ),
                  child: Text(
                    currentTask.notes,
                    style: const TextStyle(
                      color: AppTheme.textCharcoal,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ).animate().fade(delay: 200.ms, duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms),
                const SizedBox(height: 20),
              ],

              // 5. Photo Attachments Gallery
              if (currentTask.imageAttachments.isNotEmpty) ...[
                const Text(
                  'Photo Attachments',
                  style: TextStyle(
                    color: AppTheme.textCharcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: currentTask.imageAttachments.length,
                  itemBuilder: (context, index) {
                    final base64Image = currentTask.imageAttachments[index];
                    final decodedBytes = base64Decode(base64Image);
                    return GestureDetector(
                      onTap: () => _showFullscreenImage(context, base64Image, index),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGoldLight),
                          boxShadow: AppTheme.premiumShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: 'task_photo_${currentTask.id}_$index',
                            child: Image.memory(
                              decodedBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fade(delay: 250.ms, duration: 350.ms),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
