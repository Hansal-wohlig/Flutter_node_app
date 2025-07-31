import 'package:flutter/material.dart';
import 'models/task.dart';
import 'services/task_services.dart';
import 'widgets/kanban_board.dart';

void main() => runApp(ToDoApp());

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: TaskPage(),
    );
  }
}

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

enum TaskFilter { all, pending, inProgress, done }

enum ViewMode { list, kanban }

class _TaskPageState extends State<TaskPage> {
  List<Task> tasks = [];
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDueDate;
  final user = "testUser";
  TaskFilter selectedFilter = TaskFilter.all;
  ViewMode viewMode = ViewMode.kanban; // Default to Kanban view
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final allTasks = await TaskService.fetchTasks(user);
      setState(() {
        tasks = allTasks.where((task) {
          switch (selectedFilter) {
            case TaskFilter.pending:
              return task.status == 'pending';
            case TaskFilter.inProgress:
              return task.status == 'in-progress';
            case TaskFilter.done:
              return task.status == 'done';
            default:
              return true;
          }
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks: $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> addTask() async {
    if (_titleController.text.isEmpty) return;
    await TaskService.addTask(
      user,
      _titleController.text,
      _descController.text,
      dueDate: _selectedDueDate,
    );
    _titleController.clear();
    _descController.clear();
    setState(() => _selectedDueDate = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task added!'), duration: Duration(seconds: 1)),
    );
    loadTasks();
  }

  Future<void> editTask(Task task) async {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime? selectedDueDate = task.dueDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDueDate == null
                            ? 'No due date selected'
                            : 'Due: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.calendar_today, size: 18),
                      label: Text('Pick Due Date'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDueDate = picked);
                        }
                      },
                    ),
                    if (selectedDueDate != null)
                      IconButton(
                        icon: Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setDialogState(() => selectedDueDate = null),
                        tooltip: 'Clear Due Date',
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                await TaskService.updateTask(
                  task.id,
                  titleController.text,
                  descController.text,
                  dueDate: selectedDueDate,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task updated!'),
                    duration: Duration(seconds: 1),
                  ),
                );
                loadTasks();
              },
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteTask(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Task'),
        content: Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await TaskService.deleteTask(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task deleted!'),
          duration: Duration(seconds: 1),
        ),
      );
      loadTasks();
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await TaskService.updateTaskStatus(id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task updated!'), duration: Duration(seconds: 1)),
    );
    loadTasks();
  }

  Future<void> clearCompletedTasks() async {
    final completed = tasks.where((t) => t.status == 'done').toList();
    if (completed.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Completed Tasks'),
        content: Text('Delete all completed tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final t in completed) {
        await TaskService.deleteTask(t.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completed tasks cleared!'),
          duration: Duration(seconds: 1),
        ),
      );
      loadTasks();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.task_alt, size: 60, color: Colors.blue[300]),
          ),
          SizedBox(height: 24),
          Text(
            'No tasks yet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedFilter == TaskFilter.all
                ? 'Start by adding your first task above'
                : 'No ${selectedFilter.name.replaceAll('TaskFilter.', '')} tasks found',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (selectedFilter != TaskFilter.all)
            ElevatedButton.icon(
              icon: Icon(Icons.clear),
              label: Text('Clear Filter'),
              onPressed: () {
                setState(() => selectedFilter = TaskFilter.all);
                loadTasks();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(
              viewMode == ViewMode.kanban ? Icons.view_list : Icons.dashboard,
            ),
            onPressed: () {
              setState(() {
                viewMode = viewMode == ViewMode.kanban
                    ? ViewMode.list
                    : ViewMode.kanban;
              });
            },
            tooltip: viewMode == ViewMode.kanban
                ? 'Switch to List View'
                : 'Switch to Kanban View',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadTasks,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: clearCompletedTasks,
            tooltip: 'Clear Completed',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Task',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDueDate == null
                                  ? 'No due date selected'
                                  : 'Due: ' +
                                        '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.calendar_today, size: 18),
                            label: Text('Pick Due Date'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDueDate = picked);
                              }
                            },
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () =>
                                  setState(() => _selectedDueDate = null),
                              tooltip: 'Clear Due Date',
                            ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: addTask,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FILTER CHIPS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      label: Text('All'),
                      selected: selectedFilter == TaskFilter.all,
                      onSelected: (_) {
                        setState(() => selectedFilter = TaskFilter.all);
                        loadTasks();
                      },
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Pending'),
                      selected: selectedFilter == TaskFilter.pending,
                      onSelected: (_) {
                        setState(() => selectedFilter = TaskFilter.pending);
                        loadTasks();
                      },
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('In Progress'),
                      selected: selectedFilter == TaskFilter.inProgress,
                      onSelected: (_) {
                        setState(() => selectedFilter = TaskFilter.inProgress);
                        loadTasks();
                      },
                    ),
                    SizedBox(width: 8),
                    FilterChip(
                      label: Text('Done'),
                      selected: selectedFilter == TaskFilter.done,
                      onSelected: (_) {
                        setState(() => selectedFilter = TaskFilter.done);
                        loadTasks();
                      },
                    ),
                  ],
                ),
              ),
            ),

            Divider(height: 24, thickness: 1.2),

            // TASK VIEW
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                  ? _buildEmptyState()
                  : viewMode == ViewMode.kanban
                  ? RefreshIndicator(
                      onRefresh: loadTasks,
                      child: SingleChildScrollView(
                        child: KanbanBoard(
                          tasks: tasks,
                          onTaskUpdated: loadTasks,
                          onEditTask: editTask,
                          onDeleteTask: deleteTask,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadTasks,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        itemCount: tasks.length,
                        itemBuilder: (ctx, i) {
                          final task = tasks[i];
                          Color statusColor;
                          switch (task.status) {
                            case 'done':
                              statusColor = Colors.green[400]!;
                              break;
                            case 'in-progress':
                              statusColor = Colors.orange[400]!;
                              break;
                            default:
                              statusColor = Colors.blue[300]!;
                          }
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          task.description,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        if (task.dueDate != null) ...[
                                          SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task.status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            DropdownButton<String>(
                                              value: task.status,
                                              items:
                                                  [
                                                    'pending',
                                                    'in-progress',
                                                    'done',
                                                  ].map((status) {
                                                    return DropdownMenuItem(
                                                      value: status,
                                                      child: Text(status),
                                                    );
                                                  }).toList(),
                                              onChanged: (newStatus) {
                                                if (newStatus != null) {
                                                  updateStatus(
                                                    task.id,
                                                    newStatus,
                                                  );
                                                }
                                              },
                                              underline: SizedBox(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue[400],
                                        ),
                                        onPressed: () => editTask(task),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red[400],
                                        ),
                                        onPressed: () => deleteTask(task.id),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
