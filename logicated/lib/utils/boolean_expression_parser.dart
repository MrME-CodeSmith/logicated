enum TokenType {
  VARIABLE,
  COMPLEMENT,
  AND_OP,
  OR_OP,
  LEFT_PAREN,
  RIGHT_PAREN,
}

class Token {
  TokenType type;
  String value;

  Token(this.type, [this.value = '']);
}

class Tokenizer {
  String input;
  int pos = 0;
  late int length;

  Tokenizer(this.input) {
    length = input.length;
  }

  List<Token> tokenize() {
    List<Token> tokens = [];
    while (pos < length) {
      String ch = input[pos];
      if (ch == ' ' || ch == '\t' || ch == '\n') {
        pos++;
      } else if (isLetter(ch)) {
        tokens.add(Token(TokenType.VARIABLE, ch));
        pos++;
        if (pos < input.length
            && ( isLetter(input[pos]) || input[pos] == "(")) {
          tokens.add(Token(TokenType.AND_OP));
        }
      } else if (ch == '\'') {
        tokens.add(Token(TokenType.COMPLEMENT));
        pos++;
      } else if (ch == '+') {
        tokens.add(Token(TokenType.OR_OP));
        pos++;
      } else if (ch == '.' || ch == '*') {
        tokens.add(Token(TokenType.AND_OP));
        pos++;
      } else if (ch == '(') {
        tokens.add(Token(TokenType.LEFT_PAREN));
        pos++;
      } else if (ch == ')') {
        tokens.add(Token(TokenType.RIGHT_PAREN));
        pos++;
        if (pos < input.length
            && (isLetter(input[pos]) || (input[pos] == '('))
        ) {
          tokens.add(Token(TokenType.AND_OP));
        }
      } else {
        throw Exception('Invalid character: $ch');
      }
    }
    return tokens;
  }

  bool isLetter(String ch) {
    return RegExp(r'^[A-Za-z]$').hasMatch(ch);
  }
}

abstract class ExpressionNode {
  bool evaluate(Map<String, bool> context);

  void collectVariables(Set<String> variables);

  @override
  String toString();
}

class VariableNode extends ExpressionNode {
  String name;

  VariableNode(this.name);

  @override
  bool evaluate(Map<String, bool> context) {
    return context[name] ?? false;
  }

  @override
  void collectVariables(Set<String> variables) {
    variables.add(name);
  }

  @override
  String toString() {
    return name;
  }
}

class NotNode extends ExpressionNode {
  ExpressionNode operand;

  NotNode(this.operand);

  @override
  bool evaluate(Map<String, bool> context) {
    return !operand.evaluate(context);
  }

  @override
  void collectVariables(Set<String> variables) {
    operand.collectVariables(variables);
  }

  @override
  String toString() {
    return "(${operand.toString()})'";
  }
}

class AndNode extends ExpressionNode {
  ExpressionNode left, right;

  AndNode(this.left, this.right);

  @override
  bool evaluate(Map<String, bool> context) {
    return left.evaluate(context) && right.evaluate(context);
  }

  @override
  void collectVariables(Set<String> variables) {
    left.collectVariables(variables);
    right.collectVariables(variables);
  }

  @override
  String toString() {
    return "(${left.toString()} * ${right.toString()})";
  }
}

class OrNode extends ExpressionNode {
  ExpressionNode left, right;

  OrNode(this.left, this.right);

  @override
  bool evaluate(Map<String, bool> context) {
    return left.evaluate(context) || right.evaluate(context);
  }

  @override
  void collectVariables(Set<String> variables) {
    left.collectVariables(variables);
    right.collectVariables(variables);
  }

  @override
  String toString() {
    return "(${left.toString()} + ${right.toString()})";
  }
}

int getPrecedence(TokenType type) {
  switch (type) {
    case TokenType.COMPLEMENT:
      return 3; 
    case TokenType.AND_OP:
      return 2;
    case TokenType.OR_OP:
      return 1;
    default:
      return 0;
  }
}

bool isOperator(TokenType type) {
  return type == TokenType.AND_OP ||
      type == TokenType.OR_OP ||
      type == TokenType.COMPLEMENT;
}

List<Token> toPostfix(List<Token> tokens) {
  List<Token> output = [];
  List<Token> operatorStack = [];

  int i = 0;
  while (i < tokens.length) {
    Token token = tokens[i];

    if (token.type == TokenType.VARIABLE) {
      output.add(token);
      while (
          i + 1 < tokens.length && tokens[i + 1].type == TokenType.COMPLEMENT) {
        i++;
        output.add(tokens[i]); 
      }
    } else if (token.type == TokenType.LEFT_PAREN) {
      operatorStack.add(token);
    } else if (token.type == TokenType.RIGHT_PAREN) {
      while (operatorStack.isNotEmpty &&
          operatorStack.last.type != TokenType.LEFT_PAREN) {
        output.add(operatorStack.removeLast());
      }
      if (operatorStack.isEmpty ||
          operatorStack.last.type != TokenType.LEFT_PAREN) {
        throw Exception("Mismatched parentheses");
      }
      operatorStack.removeLast();
      while (
          i + 1 < tokens.length && tokens[i + 1].type == TokenType.COMPLEMENT) {
        i++;
        output.add(tokens[i]); 
      }
    } else if (isOperator(token.type)) {
      while (operatorStack.isNotEmpty &&
          isOperator(operatorStack.last.type) &&
          getPrecedence(operatorStack.last.type) >= getPrecedence(token.type)) {
        output.add(operatorStack.removeLast());
      }
      operatorStack.add(token);
    } else {
      throw Exception("Invalid token: ${token.type}");
    }
    i++;
  }

  while (operatorStack.isNotEmpty) {
    if (operatorStack.last.type == TokenType.LEFT_PAREN ||
        operatorStack.last.type == TokenType.RIGHT_PAREN) {
      throw Exception("Mismatched parentheses");
    }
    output.add(operatorStack.removeLast());
  }

  return output;
}

ExpressionNode buildExpressionTree(List<Token> postfixTokens) {
  List<ExpressionNode> stack = [];

  for (Token token in postfixTokens) {
    if (token.type == TokenType.VARIABLE) {
      stack.add(VariableNode(token.value));
    } else if (token.type == TokenType.COMPLEMENT) {
      if (stack.isEmpty) {
        throw Exception("Invalid expression: NOT operator with no operand");
      }
      ExpressionNode operand = stack.removeLast();
      stack.add(NotNode(operand));
    } else if (token.type == TokenType.AND_OP ||
        token.type == TokenType.OR_OP) {
      if (stack.length < 2) {
        throw Exception(
            "Invalid expression: Operator with insufficient operands");
      }
      ExpressionNode right = stack.removeLast();
      ExpressionNode left = stack.removeLast();
      if (token.type == TokenType.AND_OP) {
        stack.add(AndNode(left, right));
      } else {
        stack.add(OrNode(left, right));
      }
    } else {
      throw Exception("Invalid token in postfix expression: ${token.type}");
    }
  }

  if (stack.length != 1) {
    throw Exception("Invalid expression");
  }

  return stack[0];
}

List<Map<String, bool>> generateTruthAssignments(List<String> variables) {
  int numVars = variables.length;
  int numRows = 1 << numVars;
  List<Map<String, bool>> assignments = [];
  for (int i = 0; i < numRows; i++) {
    Map<String, bool> assignment = {};
    for (int j = 0; j < numVars; j++) {
      bool value = ((i >> (numVars - j - 1)) & 1) == 1;
      assignment[variables[j]] = value;
    }
    assignments.add(assignment);
  }
  return assignments;
}

Map<String, dynamic> computeTruthTable(String input) {
  Tokenizer tokenizer = Tokenizer(input);
  List<Token> tokens = tokenizer.tokenize();

  List<Token> postfixTokens = toPostfix(tokens);

  ExpressionNode expression = buildExpressionTree(postfixTokens);

  Set<String> variableSet = {};
  expression.collectVariables(variableSet);
  List<String> variables = variableSet.toList();
  variables.sort();

  List<Map<String, bool>> assignments = generateTruthAssignments(variables);

  List<Map<String, bool>> truthTable = [];

  for (Map<String, bool> assignment in assignments) {
    Map<String, bool> row = Map<String, bool>.from(assignment);
    bool result = expression.evaluate(assignment);
    row['Result'] = result;
    truthTable.add(row);
  }

  return {
    'variables': variables,
    'truthTable': truthTable,
  };
}
