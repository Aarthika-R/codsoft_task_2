import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; 
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class Quote {
  final String text;
  final String author;
  final bool isFavorite;

  Quote({
    required this.text,
    required this.author,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'author': author,
        'isFavorite': isFavorite,
      };

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'],
        author: json['author'],
        isFavorite: json['isFavorite'] ?? false,
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Initialize with a fallback quote
  Quote currentQuote = Quote(
    text: "Be the change you wish to see in the world",
    author: "Mahatma Gandhi",
  );

  List<Quote> favoriteQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadQuoteOfTheDay();
    _loadFavorites();
  }

  Future<void> _loadQuoteOfTheDay() async {
    final url = Uri.parse("https://zenquotes.io/api/random");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          currentQuote = Quote(
            text: data[0]['q'], // Quote text
            author: data[0]['a'], // Quote author
          );
        });
      } else {
        throw Exception('Failed to fetch quote');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch quote: $e")),
      );
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList('favorites') ?? [];

    setState(() {
      favoriteQuotes = favoritesJson
          .map((json) => Quote.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (favoriteQuotes.any((q) => q.text == currentQuote.text)) {
        favoriteQuotes.removeWhere((q) => q.text == currentQuote.text);
      } else {
        favoriteQuotes.add(Quote(
          text: currentQuote.text,
          author: currentQuote.author,
          isFavorite: true,
        ));
      }
    });

    await prefs.setStringList(
      'favorites',
      favoriteQuotes.map((q) => jsonEncode(q.toJson())).toList(),
    );
  }

  void _shareQuote() {
    Share.share('"${currentQuote.text}" - ${currentQuote.author}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade200,
      appBar: AppBar(
        title: const Text('Quote of the Day'),
        backgroundColor: Colors.deepPurple.shade500,
        shadowColor: Colors.purpleAccent,
        elevation: 15,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 25,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            iconSize: 35,
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FavoritesScreen(favorites: favoriteQuotes),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 15,
                shadowColor: Colors.purpleAccent,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        currentQuote.text,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text('- ${currentQuote.author}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      favoriteQuotes.any((q) => q.text == currentQuote.text)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    iconSize: 30,
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    iconSize: 30,
                    color: Colors.black,
                    onPressed: _shareQuote,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text("New Quote"),
        onPressed: _loadQuoteOfTheDay,
        icon: Icon(Icons.refresh),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Quote> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade200,
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        shadowColor: Colors.lightBlueAccent,
        elevation: 15,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 25,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final quote = favorites[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                ),
                child: Card(
                  shadowColor: Colors.blue,
                  elevation: 15,
                  child: ListTile(
                    title: Text(quote.text),
                    subtitle: Text(quote.author),
                    trailing: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}