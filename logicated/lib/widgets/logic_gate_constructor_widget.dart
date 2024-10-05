import 'package:flutter/material.dart';

class LogicGate extends StatelessWidget {
  final String gateType;

  const LogicGate({
    super.key,
    required this.gateType,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable(
      data: gateType,
      feedback: GateVisual(gateType: gateType),
      child: GateVisual(gateType: gateType),
    );
  }
}

class GateVisual extends StatelessWidget {
  final String gateType;

  const GateVisual({
    super.key,
    required this.gateType,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(60, 40),
      painter: GatePainter(gateType),
    );
  }
}

class GatePainter extends CustomPainter {
  final String gateType;

  GatePainter(this.gateType);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.grey[300]!;
    canvas.drawRect(Offset.zero & size, paint);

    Paint connectorPaint = Paint()..color = Colors.black;
    if (gateType == 'AND' || gateType == 'OR') {
      canvas.drawCircle(Offset(0, size.height * 0.3), 4, connectorPaint);
      canvas.drawCircle(Offset(0, size.height * 0.7), 4, connectorPaint);
    } else if (gateType == 'NOT') {
      canvas.drawCircle(Offset(0, size.height * 0.5), 4, connectorPaint);
    }

    canvas.drawCircle(Offset(size.width, size.height * 0.5), 4, connectorPaint);

    TextPainter textPainter = TextPainter(
      text: TextSpan(text: gateType, style: const TextStyle(color: Colors.black)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}