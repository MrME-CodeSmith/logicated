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
