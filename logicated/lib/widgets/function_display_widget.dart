import 'package:flutter/material.dart';

class FunctionDisplay extends StatelessWidget {
  final String functionDescription;

  const FunctionDisplay({
    super.key,
    required this.functionDescription,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      functionDescription,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
