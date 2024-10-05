import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assignment.dart';
import '../view_models/assignment_view_model.dart';
import 'add_assignment_screen.dart';
import 'assignment_detail_screen.dart';
import 'edit_assignment_screen.dart';

class AssignmentListScreen extends ConsumerWidget {
  final bool isInstructor;

  const AssignmentListScreen({super.key, required this.isInstructor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(assignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          if (isInstructor)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddAssignment(context),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 500,
            maxWidth: 1500,
            minHeight: 500,
            maxHeight: 1000,
          ),
          child: ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              return ListTile(
                title: Text(assignment.title),
                subtitle: Text(assignment.description),
                onTap: () => _navigateToAssignmentDetail(context, assignment),
                trailing: isInstructor
                    ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _navigateToEditAssignment(context, assignment),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToAddAssignment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAssignmentScreen()),
    );
  }

  void _navigateToAssignmentDetail(BuildContext context, Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailScreen(
          assignment: assignment,
          isInstructor: isInstructor,
        ),
      ),
    );
  }

  void _navigateToEditAssignment(BuildContext context, Assignment assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAssignmentScreen(assignment: assignment),
      ),
    );
  }
}
