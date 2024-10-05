import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/assignment_list_screen.dart';

void main() => runApp(
      ProviderScope(
        child: MaterialApp(
          title: 'Logicated',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
            useMaterial3: true,
          ),
          home: const AssignmentListScreen(
            isInstructor: true,
          ),
        ),
      ),
    );
