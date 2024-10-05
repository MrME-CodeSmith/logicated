import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment.dart';
import '../models/exercise.dart';
import '../view_models/assignment_view_model.dart';
import 'add_exercise_screen.dart';
import 'edit_exercise_screen.dart';

class EditAssignmentScreen extends ConsumerStatefulWidget {
  final Assignment assignment;

  const EditAssignmentScreen({super.key, required this.assignment});

  @override
  ConsumerState<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends ConsumerState<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment.title);
    _descriptionController = TextEditingController(text: widget.assignment.description);

    _titleController.addListener(_updateAssignment);
    _descriptionController.addListener(_updateAssignment);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateAssignment() {
    setState(() {
      // Trigger UI update
    });
  }

  void _saveAssignment() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(assignmentProvider.notifier).updateAssignmentDetails(
            widget.assignment.id,
            _titleController.text,
            _descriptionController.text,
          );
      Navigator.pop(context);
    }
  }

  void _deleteAssignment() {
    ref.read(assignmentProvider.notifier).deleteAssignment(widget.assignment.id);
    Navigator.pop(context);
  }

  void _navigateToAddExercise(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(assignmentId: widget.assignment.id),
      ),
    );
  }

  void _navigateToEditExercise(BuildContext context, Exercise exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExerciseScreen(
          assignmentId: widget.assignment.id,
          exercise: exercise,
        ),
      ),
    );
  }

  void _deleteExercise(Exercise exercise) {
    ref.read(assignmentProvider.notifier).deleteExerciseFromAssignment(
          widget.assignment.id,
          exercise.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = ref.watch(assignmentProvider).firstWhere((a) => a.id == widget.assignment.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Assignment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAssignment,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExercise(context),
        child: const Icon(Icons.add),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...assignment.exercises.map((exercise) => ExerciseItem(
                  exercise: exercise,
                  onEdit: () => _navigateToEditExercise(context, exercise),
                  onDelete: () => _deleteExercise(exercise),
                )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveAssignment,
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExerciseItem extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseItem({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(exercise.label),
        subtitle: Text(exercise.question),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
