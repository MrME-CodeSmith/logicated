import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../utils/boolean_expression_parser.dart';

class FunctionToCircuitTool extends StatefulWidget {
  FunctionToCircuitTool({
    super.key,
    this.functionDescription = "",
    this.inputNames = const [],
  });

  final String functionDescription;
  final List<String> inputNames;

  @override
  FunctionToCircuitToolState createState() => FunctionToCircuitToolState();
}

class FunctionToCircuitToolState extends State<FunctionToCircuitTool> {
  late CircuitCanvas canvas;
  List<Map<String, bool>> predefinedTruthTable = [];
  final GlobalKey<CircuitCanvasState> canvasKey =
      GlobalKey<CircuitCanvasState>();
  late ExpressionNode expressionTree;

  @override
  void initState() {
    super.initState();
    canvas = CircuitCanvas(
      key: canvasKey,
      inputNames: widget.inputNames,
    );
    expressionTree = parseFunctionDescription(widget.functionDescription);
    predefinedTruthTable = generatePredefinedTruthTable();
  }

  ExpressionNode parseFunctionDescription(String functionDescription) {
    List<String> parts = functionDescription.split('=');
    if (parts.length != 2) {
      throw Exception('Invalid function description format');
    }
    String expressionString = parts[1].trim();

    Tokenizer tokenizer = Tokenizer(expressionString);
    List<Token> tokens = tokenizer.tokenize();

    List<Token> postfixTokens = toPostfix(tokens);

    ExpressionNode expression = buildExpressionTree(postfixTokens);

    return expression;
  }

  List<Map<String, bool>> generatePredefinedTruthTable() {
    List<Map<String, bool>> truthTable = [];
    int numInputs = widget.inputNames.length;
    int numRows = 1 << numInputs;
    for (int i = 0; i < numRows; i++) {
      Map<String, bool> row = {};
      for (int j = 0; j < numInputs; j++) {
        row[widget.inputNames[j]] = ((i >> j) & 1) == 1;
      }

      row['Output'] = computeExpectedOutput(row);
      truthTable.add(row);
    }
    return truthTable;
  }

  bool computeExpectedOutput(Map<String, bool> inputs) {
    return expressionTree.evaluate(inputs);
  }

  Map<String, dynamic> checkCircuit() {
    Gate? userCircuit = canvasKey.currentState?.parseUserCircuit(
      canvasKey.currentState!.gates,
      canvasKey.currentState!.connections,
    );
    if (userCircuit != null) {
      return onCheckCircuit(userCircuit);
    } else {
      return {
        'isCorrect': false,
        'message': "Invalid circuit. Please check your connections.",
      };
    }
  }

  Map<String, dynamic> onCheckCircuit(Gate userCircuit) {
    List<Map<String, bool>> userTruthTable =
        generateTruthTable(userCircuit, widget.inputNames);
    return compareTruthTables(predefinedTruthTable, userTruthTable);
  }


  List<Map<String, bool>> generateTruthTable(
      Gate circuit, List<String> inputNames) {
    int numInputs = inputNames.length;
    int numRows = 1 << numInputs;
    List<Map<String, bool>> truthTable = [];

    for (int i = 0; i < numRows; i++) {
      Map<String, bool> inputs = {};
      for (int j = 0; j < numInputs; j++) {
        inputs[inputNames[j]] = ((i >> j) & 1) == 1;
      }
      bool output = circuit.evaluate(inputs);
      inputs['Output'] = output;
      truthTable.add(inputs);
    }
    return truthTable;
  }

  Map<String, dynamic> compareTruthTables(
      List<Map<String, bool>> T, List<Map<String, bool>> TPrime) {
    for (int i = 0; i < T.length; i++) {
      if (T[i]['Output'] != TPrime[i]['Output']) {
        String message =
            "Incorrect! For inputs ${T[i]}, expected Output ${T[i]['Output']}, but got ${TPrime[i]['Output']}.";
        return {'isCorrect': false, 'message': message};
      }
    }
    return {'isCorrect': true, 'message': "Your circuit is correct!"};
  }


  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          FunctionDisplay(functionDescription: widget.functionDescription),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100, 
                  color: Colors.grey[200],
                  child: const GatePalette(),
                ),
                Expanded(
                  child: canvas,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                final canvasState = canvasKey.currentState;
                if (canvasState != null) {
                  final renderBox = canvasState.context.findRenderObject() as RenderBox;
                  final size = renderBox.size;
                  canvasState.resetCanvas(size.height, size.width);
                }
              },
              child: const Text("Reset Canvas"),
            ),
          ),

          const SizedBox(height: 10),
        ],
      );
    });
  }
}

class CircuitCanvas extends StatefulWidget {
  const CircuitCanvas({super.key, required this.inputNames});

  final List<String> inputNames;

  @override
  CircuitCanvasState createState() => CircuitCanvasState();
}

class CircuitCanvasState extends State<CircuitCanvas> {
  List<PlacedGate> gates = [];
  List<Connection> connections = [];
  PlacedGate? fromGate;
  Offset? currentDragPosition;

  void removeConnectionAt(PlacedGate toGate, Offset localPosition) {
    int? inputIndex = toGate.getInputConnectorIndexAt(localPosition);
    if (inputIndex != null) {
      setState(() {
        connections.removeWhere(
            (conn) => conn.toGate == toGate && conn.inputIndex == inputIndex);
        toGate.inputs.remove(inputIndex);
        evaluateCircuit(); 
      });
    }
  }

  Gate? parseUserCircuit(List<PlacedGate> gates, List<Connection> connections) {
    Map<int, PlacedGate> gateMap = {for (var gate in gates) gate.id: gate};

    Map<int, Map<int, int>> adjacencyList = {}; 
    for (var gate in gates) {
      adjacencyList[gate.id] = {};
    }
    for (var conn in connections) {
      adjacencyList[conn.toGate.id]?[conn.inputIndex] = conn.fromGate.id;
    }

    PlacedGate? outputNode;
    for (var gate in gates) {
      if (gate.gateType == 'OUTPUT') {
        outputNode = gate;
        break;
      }
    }

    if (outputNode == null) {
      return null;
    }

    Map<int, Gate> gateObjects = {};

    Gate? buildGate(PlacedGate placedGate, Set<int> visited) {
      if (visited.contains(placedGate.id)) {
        return null;
      }
      visited.add(placedGate.id);

      if (gateObjects.containsKey(placedGate.id)) {
        return gateObjects[placedGate.id];
      }

      Gate? gate;
      switch (placedGate.gateType) {
        case 'AND':
        case 'OR':
          {
            int maxInputs = placedGate.getMaxInputs();
            Map<int, int>? inputConnections = adjacencyList[placedGate.id];
            if (inputConnections == null || inputConnections.length < 2) {
              return null;
            }
            List<Gate?> inputs = List.filled(maxInputs, null);
            inputConnections.forEach((inputIndex, fromGateId) {
              if (inputIndex < 0 || inputIndex >= maxInputs) {
                return;
              }
              Gate? inputGate = buildGate(gateMap[fromGateId]!, Set.from(visited));
              inputs[inputIndex] = inputGate;
            });
            inputs = inputs.where((input) => input != null).toList();
            if (placedGate.gateType == 'AND') {
              gate = AndGate(inputs.cast<Gate>());
            } else {
              gate = OrGate(inputs.cast<Gate>());
            }
            break;
          }
        case 'NOT':
          {
            Map<int, int>? inputConnections = adjacencyList[placedGate.id];
            if (inputConnections == null || inputConnections.length != 1) {
              return null;
            }
            int? fromGateId = inputConnections[0];
            if (fromGateId == null) {
              return null;
            }
            Gate? input = buildGate(gateMap[fromGateId]!, Set.from(visited));
            if (input == null) {
              return null;
            }
            gate = NotGate(input);
            break;
          }
        case 'INPUT':
          {
            String? inputName = placedGate.inputName;
            if (inputName == null) {
              return null;
            }
            gate = InputGate(inputName);
            break;
          }
        case 'OUTPUT':
          {
            Map<int, int>? inputConnections = adjacencyList[placedGate.id];
            if (inputConnections == null || inputConnections.length != 1) {
              return null;
            }
            int? fromGateId = inputConnections[0];
            if (fromGateId == null) {
              return null;
            }
            Gate? input = buildGate(gateMap[fromGateId]!, Set.from(visited));
            if (input == null) {
              return null;
            }
            gate = input;
            break;
          }
        default:
          return null;
      }

      gateObjects[placedGate.id] = gate;
      return gate;
    }

    Gate? outputGateObject = buildGate(outputNode, {});
    return outputGateObject;
  }

  void evaluateCircuit() {
    Gate? userCircuit = parseUserCircuit(gates, connections);
    if (userCircuit != null) {
      Map<String, bool> inputValues = {
        for (var gate in gates)
          if (gate.gateType == 'INPUT') gate.inputName!: gate.value,
      };

      bool outputValue = userCircuit.evaluate(inputValues);

      setState(() {
        for (var gate in gates) {
          if (gate.gateType == 'OUTPUT') {
            gate.value = outputValue;
            break;
          }
        }
      });
    } else {
      setState(() {
        for (var gate in gates) {
          if (gate.gateType == 'OUTPUT') {
            gate.value = false;
            break;
          }
        }
      });
    }
  }

  void resetCanvas(double availableHeight, double availableWidth) {
    setState(() {
      gates.clear();
      connections.clear();

      int numInputs = widget.inputNames.length;
      double inputSpacing = availableHeight / (numInputs + 1);

      for (int i = 0; i < numInputs; i++) {
        gates.add(PlacedGate(
          gateType: 'INPUT',
          position: Offset(
              20, inputSpacing * (i + 1) - 15),
          inputName: widget.inputNames[i],
          numTotalInputs: 0,
          isMovable: false,
          isDeletable: false,
        ));
      }

      final outputGateX = availableWidth - 70;
      gates.add(PlacedGate(
        gateType: 'OUTPUT',
        position: Offset(outputGateX, availableHeight / 2 - 15), 
        numTotalInputs: 1,
        isMovable: false,
        isDeletable: false,
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      resetCanvas(size.height, size.width);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableHeight = constraints.maxHeight;
      final availableWidth = constraints.maxWidth;
      if (gates.isEmpty) {
        resetCanvas(availableHeight, availableWidth);
      }
      return DragTarget<String>(
        onAcceptWithDetails: (details) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          Offset localPosition = renderBox.globalToLocal(details.offset);
          setState(() {
            String gateType = details.data;
            gates.add(PlacedGate(
              gateType: gateType,
              position: localPosition - const Offset(0, 50),
              numTotalInputs: widget.inputNames.length,
            ));
          });
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTapDown: (details) {
            },
            child: Stack(
              children: [
                CustomPaint(
                  painter: ConnectionPainter(connections),
                  size: Size.infinite,
                ),
                ...gates.map((gate) {
                  return GateWidget(
                    key: ValueKey(gate.id),
                    gate: gate,
                    onConnect: (fromGate, toGate, inputIndex) {
                      setState(() {
                        connections.add(Connection(fromGate, toGate, inputIndex));
                      });
                    },
                    onDelete: (placedGate) {
                      if (!placedGate.isDeletable) {
                        showMessage("This gate cannot be deleted.");
                        return;
                      }
                      setState(() {
                        gates.remove(placedGate);
                        connections.removeWhere((connection) =>
                            connection.fromGate == placedGate ||
                            connection.toGate == placedGate);
                      });
                    },
                  );
                }).toList(),
                if (fromGate != null && currentDragPosition != null)
                  CustomPaint(
                    painter: TempConnectionPainter(
                        fromGate!.getOutputConnectorPosition(),
                        currentDragPosition!),
                    size: Size.infinite,
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  void startConnection(PlacedGate gate, Offset position) {
    setState(() {
      fromGate = gate;
      currentDragPosition = position;
    });
  }

  void updateConnection(Offset position) {
    setState(() {
      currentDragPosition = position;
    });
  }

  void endConnection(Offset localPosition) {
    for (var gate in gates) {
      if (gate != fromGate) {
        Offset gateLocalPosition = localPosition - gate.position;

        if (gate.isOverInputConnector(gateLocalPosition)) {
          int? inputIndex = gate.getInputConnectorIndexAt(gateLocalPosition);
          if (inputIndex != null && !gate.inputs.containsKey(inputIndex)) {
            setState(() {
              gate.inputs[inputIndex] = fromGate!.id;
              connections.add(Connection(fromGate!, gate, inputIndex));
              evaluateCircuit();
            });
          } else {
            showMessage("No available input slots on the selected gate.");
          }
          break;
        }
      }
    }
    setState(() {
      fromGate = null;
      currentDragPosition = null;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class GateWidget extends StatefulWidget {
  final PlacedGate gate;
  final Function(PlacedGate fromGate, PlacedGate toGate, int inputIndex)
      onConnect;
  final Function(PlacedGate placedGate) onDelete;

  final double? left;
  final double? right;

  const GateWidget({
    super.key,
    required this.gate,
    required this.onConnect,
    required this.onDelete,
    this.left,
    this.right,
  });

  @override
  _GateWidgetState createState() => _GateWidgetState();
}

class _GateWidgetState extends State<GateWidget> {
  Offset position = Offset.zero;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    position = widget.gate.position;
  }


  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          if (widget.gate.isTouchOnOutput(details.localPosition)) {
            setState(() {
              isConnecting = true;
            });
            CircuitCanvasState? canvasState =
                context.findAncestorStateOfType<CircuitCanvasState>();
            if (canvasState != null) {
              RenderBox canvasRenderBox =
                  canvasState.context.findRenderObject() as RenderBox;
              Offset localPosition =
                  canvasRenderBox.globalToLocal(details.globalPosition);
              canvasState.startConnection(widget.gate, localPosition);
            }
          } else if (widget.gate.isTouchOnGateBody(details.localPosition)) {
            if (widget.gate.isMovable) {
              setState(() {
                isConnecting = false;
              });
            }
          }
        },
        onPanUpdate: (details) {
          if (isConnecting) {
            CircuitCanvasState? canvasState =
                context.findAncestorStateOfType<CircuitCanvasState>();
            if (canvasState != null) {
              RenderBox canvasRenderBox =
                  canvasState.context.findRenderObject() as RenderBox;
              Offset localPosition =
                  canvasRenderBox.globalToLocal(details.globalPosition);
              canvasState.updateConnection(localPosition);
            }
          } else if (widget.gate.isMovable) {
            setState(() {
              position += details.delta;
              widget.gate.position = position;
            });
          }
        },
        onPanEnd: (details) {
          if (isConnecting) {
            setState(() {
              isConnecting = false;
            });
            CircuitCanvasState? canvasState =
                context.findAncestorStateOfType<CircuitCanvasState>();
            if (canvasState != null) {
              RenderBox canvasRenderBox =
                  canvasState.context.findRenderObject() as RenderBox;
              Offset localPosition =
                  canvasRenderBox.globalToLocal(details.globalPosition);
              canvasState.endConnection(localPosition);
            }
          }
        },
        onLongPress: () {
          widget.onDelete(widget.gate);
        },
        onTapDown: (details) {
          if (widget.gate.isTouchOnInput(details.localPosition)) {
            CircuitCanvasState? canvasState =
                context.findAncestorStateOfType<CircuitCanvasState>();
            if (canvasState != null) {
              canvasState.removeConnectionAt(
                  widget.gate, details.localPosition);
            }
          }
        },
        onDoubleTap: () {
          if (widget.gate.gateType == 'INPUT') {
            setState(() {
              widget.gate.value = !widget.gate.value;
            });
            CircuitCanvasState? canvasState =
                context.findAncestorStateOfType<CircuitCanvasState>();
            canvasState?.evaluateCircuit();
          }
        },
        child: Column(
          children: [
            GateVisual(
              gateType: widget.gate.gateType,
              gate: widget.gate,
            ),
            if (widget.gate.gateType == 'INPUT')
              Text(
                '${widget.gate.inputName ?? ''}: ${widget.gate.value ? '1' : '0'}',
                style: const TextStyle(fontSize: 12),
              ),
            if (widget.gate.gateType == 'OUTPUT')
              Text(
                'OUTPUT: ${widget.gate.value ? '1' : '0'}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class GateVisual extends StatelessWidget {
  final String gateType;
  final PlacedGate gate;

  const GateVisual({
    super.key,
    required this.gateType,
    required this.gate,
  });

  @override
  Widget build(BuildContext context) {
    double width = 60;
    double height = (40 + 10 * gate.getMaxInputs()).toDouble();

    if (gateType == 'NOT') {
      width = 50;
      height = 40;
    } else if (gateType == 'INPUT' || gateType == 'OUTPUT') {
      width = 50;
      height = 30;
    }

    return CustomPaint(
      size: Size(width, height),
      painter: GatePainter(gateType, gate.getMaxInputs()),
    );
  }
}

class GatePainter extends CustomPainter {
  final String gateType;
  final int numInputs;

  GatePainter(this.gateType, this.numInputs);

  @override
  void paint(Canvas canvas, Size size) {
    Paint fillPaint = Paint()..color = Colors.grey[300]!;
    Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    Paint connectorPaint = Paint()..color = Colors.black;

    if (gateType == 'AND') {
      Path path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width / 2, size.height);
      Rect arcRect = Rect.fromLTWH(
          size.width / 2 - size.height / 2, 0, size.height, size.height);
      path.arcTo(arcRect, math.pi / 2, -math.pi, false);
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      for (int i = 0; i < numInputs; i++) {
        double y = size.height * (i + 1) / (numInputs + 1);
        canvas.drawCircle(Offset(0, y), 4, connectorPaint);
      }

      canvas.drawCircle(Offset(size.width, size.height / 2), 4, connectorPaint);

      TextPainter textPainter = TextPainter(
        text: const TextSpan(
          text: 'AND',
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    } else if (gateType == 'OR') {
      Path path = Path();
      path.moveTo(size.width * 0.2, 0);
      path.quadraticBezierTo(0, size.height / 2, size.width * 0.2, size.height);
      path.quadraticBezierTo(
          size.width * 0.6, size.height, size.width, size.height / 2);
      path.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.2, 0);
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      for (int i = 0; i < numInputs; i++) {
        double y = size.height * (i + 1) / (numInputs + 1);
        canvas.drawCircle(Offset(0, y), 4, connectorPaint);
      }

      canvas.drawCircle(Offset(size.width, size.height / 2), 4, connectorPaint);

      TextPainter textPainter = TextPainter(
        text: const TextSpan(
          text: 'OR',
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    } else if (gateType == 'NOT') {
      Path path = Path();
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.8, size.height / 2);
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);

      double bubbleRadius = size.width * 0.05;
      canvas.drawCircle(
          Offset(size.width * 0.85 + bubbleRadius, size.height / 2),
          bubbleRadius,
          borderPaint);

      canvas.drawCircle(Offset(0, size.height / 2), 4, connectorPaint);

      canvas.drawCircle(Offset(size.width, size.height / 2), 4, connectorPaint);

      TextPainter textPainter = TextPainter(
        text: const TextSpan(
          text: 'NOT',
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width * 0.4 - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
    } else if (gateType == 'INPUT' || gateType == 'OUTPUT') {
      Rect rect = Rect.fromLTWH(0, 0, size.width * 0.8, size.height);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);

      if (gateType == 'INPUT') {
        canvas.drawCircle(
            Offset(size.width, size.height / 2), 4, connectorPaint);
      } else {
        canvas.drawCircle(Offset(0, size.height / 2), 4, connectorPaint);
      }

      String label = gateType == 'INPUT' ? 'IN' : 'OUT';
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (rect.width - textPainter.width) / 2,
          (rect.height - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Connection {
  final PlacedGate fromGate;
  final PlacedGate toGate;
  final int inputIndex;

  Connection(this.fromGate, this.toGate, this.inputIndex);
}

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;

  ConnectionPainter(this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    for (var connection in connections) {
      Offset fromPosition = connection.fromGate.getOutputConnectorPosition();
      Offset toPosition =
          connection.toGate.getInputConnectorPosition(connection.inputIndex);

      canvas.drawLine(fromPosition, toPosition, paint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) => true;
}

class TempConnectionPainter extends CustomPainter {
  final Offset fromPosition;
  final Offset toPosition;

  TempConnectionPainter(this.fromPosition, this.toPosition);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    canvas.drawLine(fromPosition, toPosition, paint);
  }

  @override
  bool shouldRepaint(TempConnectionPainter oldDelegate) => true;
}

class PlacedGate {
  String gateType;
  Offset position;
  int id;
  static int _idCounter = 0;
  Map<int, int> inputs;
  String? inputName;
  int numTotalInputs;
  bool isMovable;
  bool isDeletable;
  bool value;

  PlacedGate({
    required this.gateType,
    required this.position,
    this.inputName,
    required this.numTotalInputs,
    this.isMovable = true,
    this.isDeletable = true,
    this.value = false,
  })  : id = _idCounter++,
        inputs = {};

  int getAvailableInputIndex() {
    int maxInputs = getMaxInputs();
    for (int i = 0; i < maxInputs; i++) {
      if (!inputs.containsKey(i)) {
        return i;
      }
    }
    return -1;
  }

  int getMaxInputs() {
    switch (gateType) {
      case 'AND':
      case 'OR':
        return numTotalInputs;
      case 'NOT':
        return 1;
      case 'OUTPUT':
        return 1;
      default:
        return 0;
    }
  }

  int? getInputConnectorIndexAt(Offset localPosition) {
    for (int i = 0; i < getMaxInputs(); i++) {
      Offset connectorPosition = getInputConnectorLocalPosition(i);
      const double radius = 10;
      if ((localPosition - connectorPosition).distance <= radius) {
        return i;
      }
    }
    return null;
  }

  bool isTouchOnInput(Offset localPosition) {
    for (int i = 0; i < getMaxInputs(); i++) {
      Offset connectorPosition = getInputConnectorLocalPosition(i);
      const double radius = 10;
      if ((localPosition - connectorPosition).distance <= radius) {
        return true;
      }
    }
    return false;
  }

  Offset getInputConnectorLocalPosition(int index) {
    switch (gateType) {
      case 'AND':
      case 'OR':
        double y = size.height * (index + 1) / (getMaxInputs() + 1);
        return Offset(0, y);
      case 'NOT':
      case 'OUTPUT':
        return Offset(0, size.height / 2);
      default:
        return Offset.zero;
    }
  }

  Offset getOutputConnectorPosition() {
    if (gateType == 'OUTPUT') {
      return position + Offset(0, size.height / 2);
    }
    return position + Offset(size.width, size.height / 2);
  }

  Offset getInputConnectorPosition(int index) {
    switch (gateType) {
      case 'AND':
      case 'OR':
        double y =
            position.dy + size.height * (index + 1) / (getMaxInputs() + 1);
        return Offset(position.dx, y);
      case 'NOT':
      case 'OUTPUT':
        return position + Offset(0, size.height / 2);
      default:
        return position;
    }
  }

  bool isTouchOnOutput(Offset localPosition) {
    Offset connectorPosition;
    if (gateType == 'OUTPUT') {
      return false;
    } else if (gateType == 'INPUT') {
      connectorPosition = Offset(size.width, size.height / 2);
    } else {
      connectorPosition = Offset(size.width, size.height / 2);
    }
    const double radius = 10;
    return (localPosition - connectorPosition).distance <= radius;
  }

  bool isOverInputConnector(Offset localPosition) {
    return getInputConnectorIndexAt(localPosition) != null;
  }

  bool isTouchOnGateBody(Offset localPosition) {
    return Rect.fromLTWH(0, 0, size.width, size.height).contains(localPosition);
  }

  Size get size {
    double width = 60;
    double height = (40 + 10 * getMaxInputs()).toDouble();

    if (gateType == 'NOT') {
      width = 50;
      height = 40;
    } else if (gateType == 'INPUT' || gateType == 'OUTPUT') {
      width = 50;
      height = 30;
    }

    return Size(width, height);
  }
}

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

class GatePalette extends StatelessWidget {
  const GatePalette({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        GatePaletteItem(gateType: 'AND'),
        GatePaletteItem(gateType: 'OR'),
        GatePaletteItem(gateType: 'NOT'),
      ],
    );
  }
}

class GatePaletteItem extends StatelessWidget {
  final String gateType;

  const GatePaletteItem({super.key, required this.gateType});

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: gateType,
      feedback: Material(
        color: Colors.transparent,
        child: GateVisual(
          gateType: gateType,
          gate: PlacedGate(
            gateType: gateType,
            position: Offset.zero,
            numTotalInputs: 3,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: GateVisual(
          gateType: gateType,
          gate: PlacedGate(
            gateType: gateType,
            position: Offset.zero,
            numTotalInputs: 3,
          ),
        ),
      ),
      child: GateVisual(
        gateType: gateType,
        gate: PlacedGate(
          gateType: gateType,
          position: Offset.zero,
          numTotalInputs: 3,
        ),
      ),
    );
  }
}

abstract class Gate {
  bool evaluate(Map<String, bool> inputs);
}

class AndGate extends Gate {
  List<Gate> inputs;

  AndGate(this.inputs);

  @override
  bool evaluate(Map<String, bool> inputsMap) {
    return inputs.every((input) => input.evaluate(inputsMap));
  }
}

class OrGate extends Gate {
  List<Gate> inputs;

  OrGate(this.inputs);

  @override
  bool evaluate(Map<String, bool> inputsMap) {

    return inputs.any((input) => input.evaluate(inputsMap));
  }
}

class NotGate extends Gate {
  Gate input;

  NotGate(this.input);

  @override
  bool evaluate(Map<String, bool> inputsMap) {
    return !input.evaluate(inputsMap);
  }
}

class InputGate extends Gate {
  String inputName;

  InputGate(this.inputName);

  @override
  bool evaluate(Map<String, bool> inputsMap) {
    return inputsMap[inputName]!;
  }
}
