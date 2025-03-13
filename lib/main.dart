import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const CardMatchingGame(),
    ),
  );
}

class CardMatchingGame extends StatelessWidget {
  const CardMatchingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Matching Game'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Time: ${gameState.timeElapsed} seconds'),
                Text('Score: ${gameState.score}'),
              ],
            ),
          ),
          const Expanded(child: CardGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          gameState.initializeCards();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class CardGrid extends StatelessWidget {
  const CardGrid({super.key});

  @override
  Widget build (BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemCount: gameState.cards.length,
      itemBuilder: (context, index) {
        return CardWidget(index: index);
      },
    );
  }
}

class CardWidget extends StatelessWidget {
  final int index;

  const CardWidget({super.key, required this.index});

  @override
  Widget build (BuildContext context) {
    final gameState  = Provider.of<GameState>(context);
    final card = gameState.cards[index];

    return GestureDetector(
      onTap: () => gameState.flipCard[index],
      child: AnimatedBuilder(
        animation: Listenable.merge([gameState]),
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(card.isFaceUp ? 0 : 3.14),
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: card.isFaceUp ? Colors.white : Colors.blue,
                borderRadius: BorderRadius.circular(8),
                image: card.isFaceUp
                  ? DecorationImage(
                    image: AssetImage(card.frontImage), fit: BoxFit.cover
                  )
                  : DecorationImage(
                    image: AssetImage(card.backImage), fit: BoxFit.cover
                  ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardModel {
  final String frontImage;
  final String backImage;
  bool isFaceUp
  bool isMatch;

  CardModel ({
    required this.frontImage,
    required this.backImage,
    this.isFaceUp = false,
    this.isMatch = false,
  });
}

class GameState extends ChangeNotifier {
  List<CardModel> cards = [];
  int score = 0;
  int timeElapsed = 0;
  bool isGameOver = false;
  Timer? timer;

  GameState() {
    initializeCards();
  }

  void initializeCards() {
    score = 0;
    timeElapsed = 0;
    isGameOver = false;
    timer?.cancel();

    List<String> images = [
      //add assets
    ];
    cards = (images + images)
      .map((image) => CardModel(
        frontImage: image,
        backImage: 'asset/back.png',
      ))
      .toList();
    cards.shuffle();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameOver) {
        timer.cancel();
      }
      else {
        timeElapsed++;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void flipCard(int index) {
    if (cards[index].isMatch || cards[index].isFaceUp) return;

    cards[index].isFaceUp = !cards[index].isFaceUp;
    notifyListeners();

    checkMatch();
  }

  void checkMatch() {
    var faceUpCards = cards.where((card) => card.isFaceUp && !card.isMatch).toList();
    if (faceUpCards.length == 2) {
      if (faceUpCards[0].frontImage == faceUpCards[1].frontImage) {
        faceUpCards[0].isMatch = true;
        faceUpCards[1].isMatch = true;
        score+=10;
      }
      else {
        score-=2;
        Future.delayed(const Duration(seconds: 1), () {
          faceUpCards[0].isFaceUp = false;
          faceUpCards[1].isFaceUp = false;
          notifyListeners();
        });
      }
      notifyListeners();
    }
    if (cards.every((card) => card.isMatch)) {
      isGameOver = true;
      showWin();
    }
  }

  void showWin() {
    print('You Win, Matched all cards in $timeElapsed seconds.');
  }
}