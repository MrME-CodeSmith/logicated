import './exercise.dart';

class Assignment {
  final String id;
  final String title;
  final String description;
  final List<Exercise> exercises;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    this.exercises = const [],
  });
}
