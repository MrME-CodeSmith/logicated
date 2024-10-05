import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment.dart';
import '../widgets/exercise_widget.dart';
import 'add_exercise_screen.dart';

class AssignmentDetailScreen extends ConsumerWidget {
  final Assignment assignment;
  final bool isInstructor;

  const AssignmentDetailScreen({
    super.key,
    required this.assignment,
    required this.isInstructor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = assignment.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(assignment.title),
        actions: [
          if (isInstructor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddExercise(context),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ExerciseWidget(
            exercise: exercise,
            isInstructor: isInstructor,
            assignmentId: assignment.id,
          );
        },
      ),
    );
  }

  void _navigateToAddExercise(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExerciseScreen(assignmentId: assignment.id),
      ),
    );
  }
}
