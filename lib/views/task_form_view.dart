import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskFormView extends StatefulWidget {
  final Task? taskToEdit;

  const TaskFormView({super.key, this.taskToEdit});

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  
  late String _title;
  late String _description;
  late String _notes;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TaskPriority _priority;
  late String _category;
  late List<String> _imageAttachments; // base64 strings

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final editTask = widget.taskToEdit;
    
    if (editTask != null) {
      _title = editTask.title;
      _description = editTask.description;
      _notes = editTask.notes;
      _dueDate = editTask.dueDate;
      _dueTime = TimeOfDay.fromDateTime(editTask.dueDate);
      _priority = editTask.priority;
      _category = editTask.category;
      _imageAttachments = List.from(editTask.imageAttachments);
    } else {
      _title = '';
      _description = '';
      _notes = '';
      // Default due date: tomorrow at 9:00 AM
      _dueDate = DateTime.now().add(const Duration(days: 1));
      _dueTime = const TimeOfDay(hour: 9, minute: 0);
      _priority = TaskPriority.medium;
      _category = 'Personal';
      _imageAttachments = [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.goldPrimary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = DateTime(picked.year, picked.month, picked.day, _dueTime.hour, _dueTime.minute);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.goldPrimary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textCharcoal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueTime) {
      setState(() {
        _dueTime = picked;
        _dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day, picked.hour, picked.minute);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Pick image with a cap on size to avoid enormous base64 strings
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        
        setState(() {
          _imageAttachments.add(base64String);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageAttachments.removeAt(index);
    });
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Construct final due date
      final finalDueDate = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (widget.taskToEdit != null) {
        // Edit mode
        final updatedTask = widget.taskToEdit!.copyWith(
          title: _title,
          description: _description,
          notes: _notes,
          dueDate: finalDueDate,
          priority: _priority,
          category: _category,
          imageAttachments: _imageAttachments,
        );
        taskProvider.updateTask(updatedTask);
      } else {
        // Create mode
        final newTask = Task(
          id: const Uuid().v4(),
          title: _title,
          description: _description,
          notes: _notes,
          dueDate: finalDueDate,
          priority: _priority,
          category: _category,
          imageAttachments: _imageAttachments,
          createdAt: DateTime.now(),
        );
        taskProvider.addTask(newTask);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      backgroundColor: AppTheme.creamBg,
      appBar: AppBar(
        title: Text(isEditing ? 'Refine Task' : 'Design Task'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.goldPrimary, size: 28),
            onPressed: _saveForm,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Task Title Input
                Text(
                  'Task Title',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(
                    hintText: 'What needs to be done?',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                  onSaved: (value) => _title = value!.trim(),
                ),

                const SizedBox(height: 20),

                // 2. Task Short Description Input
                Text(
                  'Short Description',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(
                    hintText: 'Brief summary of the objective',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onSaved: (value) => _description = value?.trim() ?? '',
                ),

                const SizedBox(height: 20),

                // 3. Category Picker
                Text(
                  'Category',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: taskProvider.categories.length,
                    itemBuilder: (context, index) {
                      final cat = taskProvider.categories[index];
                      if (cat == 'All') return const SizedBox.shrink(); // Hide 'All' option in form
                      
                      final isSelected = _category == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            AppTheme.getCategoryIcon(cat),
                            color: isSelected ? Colors.white : AppTheme.goldPrimary,
                            size: 16,
                          ),
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textCharcoal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.goldPrimary,
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? AppTheme.goldPrimary : AppTheme.borderGoldLight,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _category = cat;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Date & Time Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderGoldLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_outlined, color: AppTheme.goldPrimary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('yMMMd').format(_dueDate),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textCharcoal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Time',
                            style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderGoldLight),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, color: AppTheme.goldPrimary, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _dueTime.format(context),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textCharcoal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 5. Priority Segmented Control
                Text(
                  'Priority Level',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                ),
                const SizedBox(height: 10),
                Row(
                  children: TaskPriority.values.map((priority) {
                    final isSelected = _priority == priority;
                    final color = AppTheme.getPriorityColor(priority);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _priority = priority;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : AppTheme.borderGoldLight,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              priority.name[0].toUpperCase() + priority.name.substring(1),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textCharcoal,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 6. Notes Rich Field
                Text(
                  'Detailed Notes',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(
                    hintText: 'Add lists, custom instructions, details here...',
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onSaved: (value) => _notes = value?.trim() ?? '',
                ),

                const SizedBox(height: 20),

                // 7. Photo Attachments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Photo Attachments (${_imageAttachments.length})',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.textCharcoal),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.goldPrimary),
                          onPressed: () => _pickImage(ImageSource.camera),
                          tooltip: 'Take a photo',
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: AppTheme.goldPrimary),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          tooltip: 'Add from gallery',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _imageAttachments.isEmpty
                    ? Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGoldLight),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, color: AppTheme.textMuted.withOpacity(0.5), size: 28),
                              const SizedBox(height: 4),
                              Text(
                                'No photos attached yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textMuted.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageAttachments.length,
                          itemBuilder: (context, index) {
                            final base64Image = _imageAttachments[index];
                            final decodedBytes = base64Decode(base64Image);
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      decodedBytes,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 40),

                // 8. Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    style: ElevatedButton.styleFrom(
                      shadowColor: AppTheme.goldPrimary.withOpacity(0.35),
                      elevation: 4,
                    ),
                    child: Text(isEditing ? 'Update Task Plan' : 'Establish Task Plan'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
