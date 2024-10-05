// Import necessary packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import your application code

import 'package:logicated/screens/tool.dart';
import 'package:logicated/utils/boolean_expression_parser.dart';

void main() {
  group('Expression Parsing Tests', () {
    test('Parser correctly handles operator precedence and postfix complement',
        () {
      String expression = "A' + B * C";
      ExpressionNode expressionTree =
          parseFunctionDescription('F = $expression');

      Set<String> variables = {};
      expressionTree.collectVariables(variables);
      expect(variables, {'A', 'B', 'C'});

      // Generate truth table
      List<Map<String, dynamic>> truthTable =
          generateTruthTable(expressionTree, variables.toList());

      // Expected truth table
      List<Map<String, dynamic>> expectedTruthTable = [
        {'A': false, 'B': false, 'C': false, 'Output': true},
        {'A': false, 'B': false, 'C': true, 'Output': true},
        {'A': false, 'B': true, 'C': false, 'Output': true},
        {'A': false, 'B': true, 'C': true, 'Output': true},
        {'A': true, 'B': false, 'C': false, 'Output': false},
        {'A': true, 'B': false, 'C': true, 'Output': false},
        {'A': true, 'B': true, 'C': false, 'Output': false},
        {'A': true, 'B': true, 'C': true, 'Output': true},
      ];

      expect(truthTable, expectedTruthTable);
    });

    // Add more tests for different expressions
  });

  group('Expression Evaluation Tests', () {
    test('Expression evaluates correctly for given inputs', () {
      String expression = "(A + B)' * C";
      ExpressionNode expressionTree =
          parseFunctionDescription('F = $expression');

      Map<String, bool> inputs = {'A': false, 'B': false, 'C': true};
      bool output = expressionTree.evaluate(inputs);
      expect(output, true);

      inputs = {'A': true, 'B': false, 'C': true};
      output = expressionTree.evaluate(inputs);
      expect(output, false);
    });

    // Add more tests for different input combinations
  });

  group('Gate Evaluation Tests', () {
    test('AndGate evaluates correctly', () {
      Gate gate = AndGate([
        InputGate('A'),
        InputGate('B'),
      ]);

      Map<String, bool> inputs = {'A': true, 'B': true};
      expect(gate.evaluate(inputs), true);

      inputs = {'A': true, 'B': false};
      expect(gate.evaluate(inputs), false);
    });

    test('OrGate evaluates correctly', () {
      Gate gate = OrGate([
        InputGate('A'),
        InputGate('B'),
      ]);

      Map<String, bool> inputs = {'A': false, 'B': false};
      expect(gate.evaluate(inputs), false);

      inputs = {'A': true, 'B': false};
      expect(gate.evaluate(inputs), true);
    });

    test('NotGate evaluates correctly', () {
      Gate gate = NotGate(InputGate('A'));

      Map<String, bool> inputs = {'A': true};
      expect(gate.evaluate(inputs), false);

      inputs = {'A': false};
      expect(gate.evaluate(inputs), true);
    });

    // Add more tests for complex gate combinations
  });

  group('Circuit Parsing Tests', () {
    test('parseUserCircuit correctly builds gate structure', () {
      // Create a simple circuit: (A AND B) OR C
      // Build PlacedGates and Connections as the user would in the UI
      PlacedGate inputA = PlacedGate(
        gateType: 'INPUT',
        position: Offset.zero,
        inputName: 'A',
        numTotalInputs: 0,
      );
      PlacedGate inputB = PlacedGate(
        gateType: 'INPUT',
        position: Offset.zero,
        inputName: 'B',
        numTotalInputs: 0,
      );
      PlacedGate inputC = PlacedGate(
        gateType: 'INPUT',
        position: Offset.zero,
        inputName: 'C',
        numTotalInputs: 0,
      );
      PlacedGate andGate = PlacedGate(
        gateType: 'AND',
        position: Offset.zero,
        numTotalInputs: 2,
      );
      PlacedGate orGate = PlacedGate(
        gateType: 'OR',
        position: Offset.zero,
        numTotalInputs: 2,
      );
      PlacedGate outputGate = PlacedGate(
        gateType: 'OUTPUT',
        position: Offset.zero,
        numTotalInputs: 1,
      );

      // Create connections
      List<Connection> connections = [
        // Connect inputs to AND gate
        Connection(inputA, andGate, 0),
        Connection(inputB, andGate, 1),
        // Connect AND gate and inputC to OR gate
        Connection(andGate, orGate, 0),
        Connection(inputC, orGate, 1),
        // Connect OR gate to OUTPUT
        Connection(orGate, outputGate, 0),
      ];

      // List of all gates
      List<PlacedGate> gates = [
        inputA,
        inputB,
        inputC,
        andGate,
        orGate,
        outputGate
      ];

      // Parse the user's circuit
      CircuitCanvasState canvasState = CircuitCanvasState();
      Gate? userCircuit = canvasState.parseUserCircuit(gates, connections);

      // Ensure the circuit is not null
      expect(userCircuit, isNotNull);

      // Evaluate the circuit with inputs
      Map<String, bool> inputs = {'A': true, 'B': true, 'C': false};
      bool output = userCircuit!.evaluate(inputs);

      // Expected output: (A AND B) OR C = (true AND true) OR false = true
      expect(output, true);
    });

    // Add more tests for different circuit configurations
  });

  group('Integration Tests', () {
    test('End-to-end test from expression to circuit evaluation', () {
      String functionDescription = 'F = A\' + B * C';
      ExpressionNode expressionTree =
          parseFunctionDescription(functionDescription);

      // Build a circuit representing the same expression
      // For brevity, we'll assume the circuit is built correctly as per the expression

      // Evaluate both the expression tree and the circuit with the same inputs
      Map<String, bool> inputs = {'A': true, 'B': false, 'C': true};

      bool expressionOutput = expressionTree.evaluate(inputs);

      // Build the circuit
      Gate circuit = OrGate([
        NotGate(InputGate('A')),
        AndGate([
          InputGate('B'),
          InputGate('C'),
        ]),
      ]);

      bool circuitOutput = circuit.evaluate(inputs);

      // Both outputs should be the same
      expect(expressionOutput, circuitOutput);
    });

    test('End-to-end test from expression to circuit evaluation for F(A, B, C) = AB\' * (B + C)', () {
      String functionDescription = 'F = A * B\' * (B + C)';
      ExpressionNode expressionTree =
          parseFunctionDescription(functionDescription);

      // Evaluate both the expression tree and the circuit with the same inputs
      Map<String, bool> inputs = {'A': true, 'B': false, 'C': true};

      bool expressionOutput = expressionTree.evaluate(inputs);

      // Build the circuit
      Gate circuit = AndGate([
        AndGate([
          InputGate('A'),
          NotGate(InputGate('B')),
        ]),
        OrGate([
          InputGate('B'),
          InputGate('C'),
        ]),
      ]);

      bool circuitOutput = circuit.evaluate(inputs);

      // Both outputs should be the same
      expect(expressionOutput, circuitOutput);
    });
    // Add more integration tests
  });

  group('Widget Tests', () {
    testWidgets(
        'FunctionDisplay widget displays the correct function description',
        (WidgetTester tester) async {
      String functionDescription = 'F = A\' + B * C';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FunctionDisplay(functionDescription: functionDescription),
        ),
      ));

      expect(find.text(functionDescription), findsOneWidget);
    });

    // Add more widget tests to interact with the UI components
  });
}

// Helper functions (assuming they are accessible or adjust accordingly)

// Parses the function description and returns the expression tree
ExpressionNode parseFunctionDescription(String functionDescription) {
  // Extract the RHS of the function expression
  List<String> parts = functionDescription.split('=');
  if (parts.length != 2) {
    throw Exception('Invalid function description format');
  }
  String expressionString = parts[1].trim();

  // Tokenize using the updated tokenizer
  Tokenizer tokenizer = Tokenizer(expressionString);
  List<Token> tokens = tokenizer.tokenize();

  // Convert to postfix notation using the updated toPostfix function
  List<Token> postfixTokens = toPostfix(tokens);

  // Build the expression tree using the updated buildExpressionTree function
  ExpressionNode expression = buildExpressionTree(postfixTokens);

  return expression;
}

// Generates the truth table for the expression
List<Map<String, dynamic>> generateTruthTable(
    ExpressionNode expressionTree, List<String> inputNames) {
  int numInputs = inputNames.length;
  int numRows = 1 << numInputs; // 2^n combinations
  List<Map<String, dynamic>> truthTable = [];

  for (int i = 0; i < numRows; i++) {
    Map<String, bool> inputs = {};
    for (int j = 0; j < numInputs; j++) {
      inputs[inputNames[j]] = ((i >> (numInputs - j - 1)) & 1) == 1;
    }
    bool output = expressionTree.evaluate(inputs);
    inputs['Output'] = output;
    truthTable.add(inputs);
  }
  return truthTable;
}
