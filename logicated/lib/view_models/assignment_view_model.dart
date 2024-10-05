import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment.dart';
import '../models/exercise.dart';

class AssignmentViewModel extends StateNotifier<List<Assignment>> {
  AssignmentViewModel() : super([
    Assignment(
      id: '1',
      title: 'Assignment 1',
      description: 'This is the first assignment',
      exercises: [
        Exercise(
          id: "1",
          label: "Exercise 1",
          question: "Proceed with creating a logic gate circuit for the following expression",
          instruction: "F(A,B,C) = A + B.C",
          isCircuit: true,
          questionVariables: ["A", "B", "C"],
        )
      ],
    ),
  ]);

  void addAssignment(Assignment assignment) {
    state = [...state, assignment];
  }

  void updateAssignmentDetails(String assignmentId, String title, String description) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        return Assignment(
          id: assignment.id,
          title: title,
          description: description,
          exercises: assignment.exercises,
        );
      }
      return assignment;
    }).toList();
  }

  void deleteAssignment(String id) {
    state = state.where((assignment) => assignment.id != id).toList();
  }

  void addExerciseToAssignment(String assignmentId, Exercise exercise) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        return Assignment(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          exercises: [...assignment.exercises, exercise],
        );
      }
      return assignment;
    }).toList();
  }

  void updateExerciseInAssignment(String assignmentId, Exercise updatedExercise) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        final updatedExercises = assignment.exercises.map((exercise) {
          return exercise.id == updatedExercise.id ? updatedExercise : exercise;
        }).toList();
        return Assignment(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          exercises: updatedExercises,
        );
      }
      return assignment;
    }).toList();
  }

  void deleteExerciseFromAssignment(String assignmentId, String exerciseId) {
    state = state.map((assignment) {
      if (assignment.id == assignmentId) {
        final updatedExercises = assignment.exercises
            .where((exercise) => exercise.id != exerciseId)
            .toList();
        return Assignment(
          id: assignment.id,
          title: assignment.title,
          description: assignment.description,
          exercises: updatedExercises,
        );
      }
      return assignment;
    }).toList();
  }
}

final assignmentProvider =
    StateNotifierProvider<AssignmentViewModel, List<Assignment>>((ref) {
  return AssignmentViewModel();
});
