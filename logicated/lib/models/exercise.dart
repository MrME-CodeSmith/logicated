class Exercise {
  final String id;
  final String label;
  final String question;
  final String instruction;
  final String? imagePath;
  final bool isCircuit;
  final List<String> questionVariables;
  final List<Map<String, bool>> truthTable;

  Exercise({
    required this.id,
    required this.label,
    required this.question,
    required this.instruction,
    this.imagePath,
    this.isCircuit = false,
    this.truthTable = const [],
    this.questionVariables = const [],
  });
}
