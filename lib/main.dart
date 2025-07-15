import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: TicTacToePage(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class TicTacToePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const TicTacToePage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  String winner = '';
  int xScore = 0;
  int oScore = 0;
  List<int> winningLine = [];
  late ConfettiController _confettiController;
  int _timeLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startTimer();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 10);
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          timer.cancel();
          _handleTimeExpired();
        }
      });
    });
  }

  void _handleTimeExpired() {
    if (isXTurn && winner == '') {
      isXTurn = false;
      _aiMove();
    }
  }

  void _handleTap(int index) {
    if (board[index] != '' || winner != '' || !isXTurn) return;

    _timer?.cancel();

    setState(() {
      board[index] = 'X';
      isXTurn = false;
      winner = _checkWinner();

      if (winner == 'X') xScore++;
      if (winner != '' && winner != 'Draw') _confettiController.play();
    });

    if (winner == '') {
      Future.delayed(const Duration(seconds: 1), _aiMove);
    }
  }

  void _aiMove() {
    if (winner != '') return;

    for (int i = 0; i < 9; i++) {
      if (board[i] == '') {
        setState(() {
          board[i] = 'O';
          isXTurn = true;
          winner = _checkWinner();

          if (winner == 'O') oScore++;
          if (winner != '' && winner != 'Draw') _confettiController.play();
        });

        if (winner == '') {
          _startTimer();
        }
        break;
      }
    }
  }

  String _checkWinner() {
    const winPositions = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var pos in winPositions) {
      String a = board[pos[0]];
      String b = board[pos[1]];
      String c = board[pos[2]];
      if (a != '' && a == b && b == c) {
        winningLine = pos;
        return a;
      }
    }

    if (!board.contains('')) {
      winningLine = [];
      return 'Draw';
    }

    winningLine = [];
    return '';
  }

  void _resetGame() {
    _timer?.cancel();
    setState(() {
      board = List.filled(9, '');
      isXTurn = true;
      winner = '';
      winningLine = [];
      _timeLeft = 10;
      _confettiController.stop();
    });
    _startTimer();
  }

  void _resetScores() {
    setState(() {
      xScore = 0;
      oScore = 0;
      _resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.width * 0.8;
    Color tileColor = widget.isDarkMode ? Colors.teal.shade700 : Colors.teal.shade100;
    Color winColor = widget.isDarkMode ? Colors.teal.shade300 : Colors.teal.shade400;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          tooltip: 'Toggle Theme',
          onPressed: widget.onToggleTheme,
        ),
        title: const Text('Tic Tac Toe vs AI'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetScores,
            child: const Text("Reset All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "You (X): $xScore   |   AI (O): $oScore",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "⏳ Time Left: $_timeLeft s",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Text(
                winner == ''
                    ? "Turn: ${isXTurn ? 'You' : 'AI'}"
                    : winner == 'Draw'
                    ? "It's a Draw!"
                    : winner == 'X'
                    ? "You Win! 🎉"
                    : "AI Wins!",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: size,
                  height: size,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final isWinningBox = winningLine.contains(index);
                      return GestureDetector(
                        onTap: () => _handleTap(index),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black),
                            color: isWinningBox ? winColor : tileColor,
                          ),
                          child: Center(
                            child: Text(
                              board[index],
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: board[index] == 'X' ? Colors.blue : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _resetGame,
                child: const Text('Restart Board Only'),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              colors: const [Colors.teal, Colors.red, Colors.blue, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }
}
