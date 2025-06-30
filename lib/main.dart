import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = '';
  String result = '';
  bool isDarkMode = false;

  final FocusNode _focusNode = FocusNode();

  final List<List<String>> buttons = [
    ['C', '(', ')', '/'],
    ['7', '8', '9', '*'],
    ['4', '5', '6', '-'],
    ['1', '2', '3', '+'],
    ['0', '.', '=', '^'],
    ['sin', 'cos', 'tan', '√', 'log'],
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  void onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final key = event.logicalKey.keyLabel;
      if (RegExp(r'[0-9+\-*/.=cC()]').hasMatch(key)) {
        onButtonClick(key.toUpperCase() == 'C' ? 'C' : key);
      }
    }
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == 'C') {
        input = '';
        result = '';
      } else if (value == '=') {
        // Auto close brackets
        int openParens = '('.allMatches(input).length;
        int closeParens = ')'.allMatches(input).length;
        int missing = openParens - closeParens;
        if (missing > 0) input += ')' * missing;

        try {
          if (input.isEmpty) {
            result = '';
            return;
          }
          if (RegExp(r'[^\d.+\-*/^()a-zA-Z]').hasMatch(input)) {
            result = 'Invalid input';
            return;
          }
          result = evaluate(input);
        } catch (e) {
          result = 'Error';
        }
      } else if (value == '√') {
        input += 'sqrt(';
      } else if (value == '^') {
        input += '^';
      } else if (value == 'sin' ||
          value == 'cos' ||
          value == 'tan' ||
          value == 'log') {
        input += '$value(';
      } else {
        input += value;
      }
    });
  }

  String evaluate(String expression) {
    expression = expression.replaceAll('×', '*').replaceAll('÷', '/');

    // Convert degrees to radians for trig functions
    expression = expression.replaceAllMapped(RegExp(r'sin\(([^)]+)\)'), (
      match,
    ) {
      final deg = double.tryParse(match[1]!);
      if (deg == null) return 'sin(0)';
      final rad = deg * 3.1415926535 / 180;
      return 'sin($rad)';
    });

    expression = expression.replaceAllMapped(RegExp(r'cos\(([^)]+)\)'), (
      match,
    ) {
      final deg = double.tryParse(match[1]!);
      if (deg == null) return 'cos(0)';
      final rad = deg * 3.1415926535 / 180;
      return 'cos($rad)';
    });

    expression = expression.replaceAllMapped(RegExp(r'tan\(([^)]+)\)'), (
      match,
    ) {
      final deg = double.tryParse(match[1]!);
      if (deg == null) return 'tan(0)';
      final rad = deg * 3.1415926535 / 180;
      return 'tan($rad)';
    });

    Parser p = Parser();
    Expression exp = p.parse(expression);
    ContextModel cm = ContextModel();
    double eval = exp.evaluate(EvaluationType.REAL, cm);
    return eval.toStringAsFixed(4);
  }

  bool isOperator(String x) {
    return [
      '+',
      '-',
      '*',
      '/',
      '=',
      '√',
      '^',
      'sin',
      'cos',
      'tan',
      'log',
      'C',
    ].contains(x);
  }

  Widget buildButton(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOp = isOperator(text);
    final isFunc = ['sin', 'cos', 'tan', 'log', '√'].contains(text);

    return Padding(
      padding: const EdgeInsets.all(6),
      child: ElevatedButton(
        onPressed: () => onButtonClick(text),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          minimumSize: Size(isFunc ? 70 : 60, 55),
          backgroundColor: isOp
              ? colorScheme.primary
              : colorScheme.secondaryContainer,
          foregroundColor: isOp
              ? colorScheme.onPrimary
              : colorScheme.onSecondaryContainer,
          shadowColor: Colors.black45,
          elevation: 6,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: isFunc ? 16 : 18,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: onKey,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: const Text('Calculator'),
          backgroundColor: colorScheme.primary,
          actions: [
            IconButton(
              icon: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                  final brightness = isDarkMode
                      ? Brightness.dark
                      : Brightness.light;
                  WidgetsBinding
                      .instance
                      .platformDispatcher
                      .onPlatformBrightnessChanged = () =>
                      setState(() {});
                });
              },
              tooltip: 'Toggle Light/Dark Mode',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Column(
            children: [
              // Display area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          input,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons grid
              ...buttons.map((row) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row.map((btn) {
                      return Flexible(
                        fit: FlexFit.loose,
                        child: buildButton(btn),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
