import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/exercise.dart';
import '../view_models/assignment_view_model.dart';
import '../widgets/exercise_widget.dart';

import '../utils/boolean_expression_parser.dart';

class EditExerciseScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final Exercise exercise;

  const EditExerciseScreen({
    super.key,
    required this.assignmentId,
    required this.exercise,
  });

  @override
  ConsumerState<EditExerciseScreen> createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends ConsumerState<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _questionController;
  late TextEditingController _instructionController;
  late TextEditingController _questionVariablesController;
  late TextEditingController _correctExpressionController;
  File? _imageFile;
  bool _isCircuit = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.exercise.label);
    _questionController = TextEditingController(text: widget.exercise.question);
    _instructionController =
        TextEditingController(text: widget.exercise.instruction);
    _questionVariablesController = TextEditingController(
        text: widget.exercise.questionVariables.join(', '));
    _isCircuit = widget.exercise.isCircuit;

    _correctExpressionController = TextEditingController();

    if (widget.exercise.imagePath != null) {
      _imageFile = File(widget.exercise.imagePath!);
    }

    // Add listeners to update the preview
    _labelController.addListener(_updatePreview);
    _questionController.addListener(_updatePreview);
    _instructionController.addListener(_updatePreview);
    _questionVariablesController.addListener(_updatePreview);
    _correctExpressionController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _questionController.dispose();
    _instructionController.dispose();
    _questionVariablesController.dispose();
    _correctExpressionController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      // Trigger a rebuild to update the preview
    });
  }

  void _saveExercise() {
    if (_formKey.currentState?.validate() ?? false) {
      List<String> questionVariables = _questionVariablesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final String? exerciseImagePath =
          (_imageFile != null) ? _imageFile!.path : widget.exercise.imagePath;

      List<Map<String, bool>> truthTable = [];

      try {
        if (!_isCircuit) {
          String correctExpression = _correctExpressionController.text;
          if (correctExpression.isEmpty) {
            throw Exception('Please enter the correct Boolean expression.');
          }

          Map<String, dynamic> result = computeTruthTable(correctExpression);
          truthTable = result['truthTable'];
        } else {
          truthTable = widget.exercise.truthTable;
        }

        final updatedExercise = Exercise(
          id: widget.exercise.id,
          label: _labelController.text,
          question: _questionController.text,
          instruction: _instructionController.text,
          isCircuit: _isCircuit,
          questionVariables: questionVariables,
          imagePath: exerciseImagePath,
          truthTable: truthTable,
        );

        ref.read(assignmentProvider.notifier).updateExerciseInAssignment(
              widget.assignmentId,
              updatedExercise,
            );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _deleteExercise() {
    ref.read(assignmentProvider.notifier).deleteExerciseFromAssignment(
          widget.assignmentId,
          widget.exercise.id,
        );

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteExercise,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: isWideScreen
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildForm(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPreview(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildForm(),
                      const SizedBox(height: 16),
                      _buildPreview(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a label';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(labelText: 'Question'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a question';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionController,
              decoration: const InputDecoration(labelText: 'Instruction'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter instructions';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Circuit'),
              value: _isCircuit,
              onChanged: (value) {
                setState(() {
                  _isCircuit = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _questionVariablesController,
              decoration: const InputDecoration(
                  labelText: 'Question Variables (comma-separated)'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter question variables';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (!_isCircuit)
              TextFormField(
                controller: _correctExpressionController,
                decoration: const InputDecoration(
                    labelText: 'Correct Boolean Expression'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the correct Boolean expression';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image'),
                ),
                const SizedBox(width: 16),
                if (_imageFile != null) const Text('Image selected'),
                if (_imageFile == null && widget.exercise.imagePath != null)
                  const Text('Existing image'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveExercise,
              child: const Text('Update Exercise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    List<String> questionVariables = _questionVariablesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final String? exerciseImagePath =
        (_imageFile != null) ? _imageFile!.path : widget.exercise.imagePath;

    List<Map<String, bool>> truthTable = [];

    try {
      if (!_isCircuit && _correctExpressionController.text.isNotEmpty) {
        Map<String, dynamic> result =
            computeTruthTable(_correctExpressionController.text);
        truthTable = result['truthTable'];
      } else if (_isCircuit) {
        truthTable = widget.exercise.truthTable;
      }
    } catch (e) {
      // Ignore errors in preview
    }

    final previewExercise = Exercise(
      id: widget.exercise.id,
      label: _labelController.text.isEmpty ? 'Label' : _labelController.text,
      question: _questionController.text.isEmpty
          ? 'Question'
          : _questionController.text,
      instruction: _instructionController.text.isEmpty
          ? 'Instruction'
          : _instructionController.text,
      isCircuit: _isCircuit,
      imagePath: exerciseImagePath,
      questionVariables: questionVariables,
      truthTable: truthTable,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            child: ExerciseWidget(
              assignmentId: widget.assignmentId,
              exercise: previewExercise,
              isInstructor: false,
              isPreview: true,
            ),
          ),
        ),
      ],
    );
  }
}
