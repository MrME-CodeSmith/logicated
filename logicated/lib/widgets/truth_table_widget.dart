import 'package:flutter/material.dart';

import '../utils/boolean_expression_parser.dart';


class TruthTableWidget extends StatelessWidget {
  final String expression;

  const TruthTableWidget({super.key, required this.expression});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> tableData = computeTruthTable(expression);
    List<String> variables = tableData['variables'];
    List<Map<String, bool>> truthTable = tableData['truthTable'];

    return DataTable(
      columns: [
        ...variables.map((varName) => DataColumn(label: Text(varName))),
        const DataColumn(label: Text('Result')),
      ],
      rows: truthTable.map((row) {
        return DataRow(
          cells: [
            ...variables
                .map((varName) => DataCell(Text(row[varName]! ? '1' : '0'))),
            DataCell(Text(row['Result']! ? '1' : '0')),
          ],
        );
      }).toList(),
    );
  }
}

