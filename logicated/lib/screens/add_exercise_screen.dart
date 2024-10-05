import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/exercise.dart';
import '../view_models/assignment_view_model.dart';
import '../widgets/exercise_widget.dart';

import '../utils/boolean_expression_parser.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const AddExerciseScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _questionController = TextEditingController();
  final _instructionController = TextEditingController();
  final _questionVariablesController = TextEditingController();
  final _correctExpressionController = TextEditingController();
  File? _imageFile;
  bool _isCircuit = false;

  @override
  void initState() {
    super.initState();

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _saveExercise() {
    if (_formKey.currentState?.validate() ?? false) {
      List<String> questionVariables = _questionVariablesController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final String? assignmentImage =
          (_imageFile != null) ? _imageFile!.path : null;

      List<Map<String, bool>> truthTable = [];

      try {
        if (!_isCircuit) {
          String correctExpression = _correctExpressionController.text;
          if (correctExpression.isEmpty) {
            throw Exception('Please enter the correct Boolean expression.');
          }

          Map<String, dynamic> result = computeTruthTable(correctExpression);
          truthTable = result['truthTable'];
        }

        final newExercise = Exercise(
          id: const Uuid().v4(),
          label: _labelController.text,
          question: _questionController.text,
          instruction: _instructionController.text,
          isCircuit: _isCircuit,
          questionVariables: questionVariables,
          imagePath: assignmentImage,
          truthTable: truthTable,
        );

        ref.read(assignmentProvider.notifier).addExerciseToAssignment(
              widget.assignmentId,
              newExercise,
            );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercise'),
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
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveExercise,
              child: const Text('Save Exercise'),
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

    final String? assignmentImage =
        (_imageFile != null) ? _imageFile!.path : null;

    List<Map<String, bool>> truthTable = [];

    try {
      if (!_isCircuit && _correctExpressionController.text.isNotEmpty) {
        Map<String, dynamic> result =
            computeTruthTable(_correctExpressionController.text);
        truthTable = result['truthTable'];
      }
    } catch (e) {
      // Ignore errors in preview
    }

    final previewExercise = Exercise(
      id: 'preview',
      label: _labelController.text.isEmpty ? 'Label' : _labelController.text,
      question: _questionController.text.isEmpty
          ? 'Question'
          : _questionController.text,
      instruction: _instructionController.text.isEmpty
          ? 'Instruction'
          : _instructionController.text,
      isCircuit: _isCircuit,
      imagePath: assignmentImage,
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
