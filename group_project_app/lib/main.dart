import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FitnessApp")),
      body: ListView(
        padding: const EdgeInsets.all(24), // spacing
        children: [
          NavigationBox(
            // default : new page
            title: "box 1",
            color: Colors.blueAccent,
            destination: const DetailPage(title: "box 1"),
          ),
          const SizedBox(height: 24),

          const CounterBox(color: Colors.greenAccent), // default : counter +
          const SizedBox(height: 24),

          NavigationBox(
            // default : new page
            title: "box 2",
            color: Colors.orangeAccent,
            destination: const DetailPage(title: "box 2"),
          ),
          const SizedBox(height: 24),

          const CounterBox(color: Colors.purpleAccent), // default : counter +
          const SizedBox(height: 24),

          NavigationBox(
            // default : new page
            title: "box 3",
            color: Colors.redAccent,
            destination: const DetailPage(title: "box 3"),
          ),
        ],
      ),
    );
  }
}

class NavigationBox extends StatelessWidget {
  // for the boxes which take you to new / other pages
  final String title;
  final Color color;
  final Widget destination;

  const NavigationBox({
    super.key,
    required this.title,
    required this.color,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class CounterBox extends StatefulWidget {
  // for the boxes with counters inside
  final Color color;

  const CounterBox({super.key, required this.color});

  @override
  State<CounterBox> createState() => _CounterBoxState();
}

class _CounterBoxState extends State<CounterBox> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Counter: $counter",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                counter++;
              });
            },
            child: const Text("+"),
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  // for navigation
  final String title;

  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "Burası $title",
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
