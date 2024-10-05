import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';

class ExerciseViewModel extends StateNotifier<List<Exercise>> {
  ExerciseViewModel() : super([]);

  void addAssignment(Exercise assignment) {
    state = [...state, assignment];
  }

  void updateAssignment(Exercise updatedAssignment) {
    state = state.map((assignment) {
      return assignment.id == updatedAssignment.id ? updatedAssignment : assignment;
    }).toList();
  }

  void deleteAssignment(String id) {
    state = state.where((assignment) => assignment.id != id).toList();
  }
}

final assignmentProvider = StateNotifierProvider<ExerciseViewModel, List<Exercise>>((ref) {
  return ExerciseViewModel();
});
