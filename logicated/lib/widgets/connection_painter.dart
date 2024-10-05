import 'package:flutter/material.dart';

import 'logic_gate_constructor_widget.dart';

class GateWidget extends StatefulWidget {
  final PlacedGate gate;
  final Function(PlacedGate fromGate, PlacedGate toGate, int inputIndex) onConnect;

  const GateWidget({super.key, required this.gate, required this.onConnect});

  @override
  _GateWidgetState createState() => _GateWidgetState();
}

class _GateWidgetState extends State<GateWidget> {
  bool isConnecting = false;
  Offset position = Offset.zero;

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
      child: Draggable<PlacedGate>(
        data: widget.gate,
        feedback: GateVisual(gateType: widget.gate.gateType),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
            widget.gate.position = position;
          });
        },
        child: GateVisual(gateType: widget.gate.gateType),
      ),
    );
  }

  bool isTouchOnOutput(Offset localPosition) {
    const double connectorX = 60;
    const double connectorY = 20; 
    const double radius = 10; 
    return (localPosition - const Offset(connectorX, connectorY)).distance <= radius;
  }
}


class Connection {
  final PlacedGate fromGate;
  final PlacedGate toGate;

  Connection(this.fromGate, this.toGate);
}

class ConnectionPainter extends CustomPainter {
  final List<Connection> connections;

  ConnectionPainter(this.connections);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.black..strokeWidth = 2;

    for (var connection in connections) {
      Offset fromPosition = connection.fromGate.position + const Offset(60, 20); 
      Offset toPosition = connection.toGate.position + const Offset(0, 20);

      canvas.drawLine(fromPosition, toPosition, paint);
    }
  }

  @override
  bool shouldRepaint(ConnectionPainter oldDelegate) => true;
}

class PlacedGate {
  String gateType;
  Offset position;
  int id;
  static int _idCounter = 0;
  Map<int, int> inputs;
  String? inputName;

  PlacedGate({required this.gateType, required this.position, this.inputName})
      : id = _idCounter++,
        inputs = {};

  List<int> getAvailableInputPositions(Map<String, int> gateInputCounts) {
    int maxInputs = gateInputCounts[gateType]!;
    List<int> availableInputs = [];
    for (int i = 0; i < maxInputs; i++) {
      if (!inputs.containsKey(i)) {
        availableInputs.add(i);
      }
    }
    return availableInputs;
  }
}