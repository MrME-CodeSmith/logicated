import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../screens/edit_exercise_screen.dart';
import '../screens/tool.dart';

import '../utils/boolean_expression_parser.dart';

class ExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final bool isInstructor;
  final bool isPreview;
  final String assignmentId;

  const ExerciseWidget({
    Key? key,
    required this.exercise,
    required this.isInstructor,
    required this.assignmentId,
    this.isPreview = false,
  }) : super(key: key);

  @override
  State<ExerciseWidget> createState() => _ExerciseWidgetState();
}

class _ExerciseWidgetState extends State<ExerciseWidget> {
  final TextEditingController boolFunctionController = TextEditingController();
  String resultMessage = '';
  Map<String, bool>? counterexample;
  final GlobalKey<FunctionToCircuitToolState> _functionToCircuitToolKey =
      GlobalKey<FunctionToCircuitToolState>();

  @override
  void dispose() {
    boolFunctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInsets = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.label,
              style: const TextStyle(fontSize: 24),
            ),
            if (widget.exercise.imagePath != null)
              Center(
                child: _buildImage(),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.question,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
                if (widget.isInstructor && !widget.isPreview)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _navigateToEditExercise(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            widget.exercise.isCircuit
                ? SizedBox(
                    height: screenHeight * 0.4,
                    width: double.infinity,
                    child: FunctionToCircuitTool(
                      key: _functionToCircuitToolKey,
                      functionDescription: widget.exercise.instruction,
                      inputNames: widget.exercise.questionVariables,
                    ),
                  )
                : TextField(
                    controller: boolFunctionController,
                    decoration: InputDecoration(
                      labelText: widget.exercise.instruction,
                      labelStyle: const TextStyle(fontSize: 21),
                      border: const OutlineInputBorder(),
                    ),
                  ),
            if (!widget.isPreview)
              ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text("Submit"),
              ),
            if (resultMessage.isNotEmpty && !widget.isPreview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  resultMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color:
                        resultMessage == 'Correct!' ? Colors.green : Colors.red,
                  ),
                ),
              ),
            if (counterexample != null && !widget.isPreview)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _formatCounterexample(counterexample!),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            SizedBox(
              height: bottomInsets > 0 ? bottomInsets + screenHeight * 0.2 : 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(widget.exercise.imagePath!);
    } else {
      return Image.file(File(widget.exercise.imagePath!));
    }
  }

  void _navigateToEditExercise(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExerciseScreen(
          assignmentId: widget.assignmentId,
          exercise: widget.exercise,
        ),
      ),
    );
  }

  void _handleSubmit() {
    setState(() {
      resultMessage = '';
      counterexample = null;
    });

    if (widget.exercise.isCircuit) {
      final functionToolState = _functionToCircuitToolKey.currentState;
      if (functionToolState != null) {
        final result = functionToolState.checkCircuit();
        setState(() {
          resultMessage = result['message'];
        });
      }
    } else {
      try {
        String expressionInput = boolFunctionController.text;

        Map<String, dynamic> result = computeTruthTable(expressionInput);

        List<String> variables = result['variables'];
        List<Map<String, bool>> studentTruthTable = result['truthTable'];

        List<Map<String, bool>> expectedTruthTable = widget.exercise.truthTable;

        bool isCorrect = compareTruthTables(
          expectedTruthTable,
          studentTruthTable,
          variables,
        );

        if (isCorrect) {
          setState(() {
            resultMessage = 'Correct!';
          });
        } else {
          counterexample = findCounterexample(
            expectedTruthTable,
            studentTruthTable,
            variables,
          );
          setState(() {
            resultMessage = 'Incorrect';
          });
        }
      } catch (e) {
        setState(() {
          resultMessage = 'Syntax Error: ${e.toString()}';
        });
      }
    }
  }

  bool compareTruthTables(
    List<Map<String, bool>> expectedTable,
    List<Map<String, bool>> studentTable,
    List<String> variables,
  ) {
    if (expectedTable.length != studentTable.length) {
      return false;
    }

    for (int i = 0; i < expectedTable.length; i++) {
      Map<String, bool> expectedRow = expectedTable[i];
      Map<String, bool> studentRow = studentTable[i];

      bool inputsMatch = true;
      for (var variable in variables) {
        if (expectedRow[variable] != studentRow[variable]) {
          inputsMatch = false;
          break;
        }
      }
      if (!inputsMatch) {
        continue; 
      }

      if (expectedRow['Result'] != studentRow['Result']) {
        return false;
      }
    }
    return true;
  }

  Map<String, bool>? findCounterexample(
    List<Map<String, bool>> expectedTable,
    List<Map<String, bool>> studentTable,
    List<String> variables,
  ) {
    for (int i = 0; i < expectedTable.length; i++) {
      Map<String, bool> expectedRow = expectedTable[i];
      Map<String, bool> studentRow = studentTable[i];

      bool inputsMatch = true;
      for (var variable in variables) {
        if (expectedRow[variable] != studentRow[variable]) {
          inputsMatch = false;
          break;
        }
      }
      if (!inputsMatch) {
        continue; 
      }

      if (expectedRow['Result'] != studentRow['Result']) {
        Map<String, bool> counterexample = {};
        for (var variable in variables) {
          counterexample[variable] = expectedRow[variable]!;
        }
        counterexample['expected'] = expectedRow['Result']!;
        counterexample['student'] = studentRow['Result']!;
        return counterexample;
      }
    }
    return null;
  }

  String _formatCounterexample(Map<String, bool> counterexample) {
    String inputValues = widget.exercise.questionVariables
        .map((varName) => '$varName=${counterexample[varName]! ? '1' : '0'}')
        .join(', ');
    bool expectedOutput = counterexample['expected']!;
    bool studentOutput = counterexample['student']!;

    return 'For input ($inputValues), expected output is ${expectedOutput ? '1' : '0'}, but your function gives ${studentOutput ? '1' : '0'}.';
  }
}
