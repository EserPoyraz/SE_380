import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


/*void main() {
  runApp(const MainApp());
}*/

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
    int stepCount = Random().nextInt(9000)+1000; // Random step count between 1000 and 9999
    return Scaffold(
      appBar: AppBar(title: const Text("FitnessApp")),
      body: ListView(
        padding: const EdgeInsets.all(24), // spacing
        children: [
          StepCounterBox(
            steps : stepCount,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 24),
          WaterTrackerBox(color: Colors.cyanAccent), // default : counter +
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
class StepCounterBox extends StatelessWidget{
  final int steps;
  final Color color;
  const StepCounterBox({super.key, required this.steps, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_) => StepCounterPage(steps: steps),
        ))  ;
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          "Steps: $steps",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold
        ),
        ),
      ),
    );
  }
}
class StepCounterPage extends StatelessWidget{
  final int steps;
  final int stepGoal = 10000;
  const StepCounterPage({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
   double progress = steps / stepGoal;

    return Scaffold(
      appBar: AppBar(title: Text("Step Counter")),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0,1),
                    strokeWidth: 14,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blueAccent,
                  ),
                ),

                Text(
                  "$steps / $stepGoal",
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "%${(progress * 100).toStringAsFixed(1)} completed",
              style: const TextStyle(fontSize: 20),
            ),
          ],
        )
      ),
    );
  }
}
class WaterTrackerBox extends StatefulWidget {
  final Color color;

  const WaterTrackerBox({super.key, required this.color});

  @override
  State<WaterTrackerBox> createState() => _WaterTrackerBoxState();
}
class _WaterTrackerBoxState extends State<WaterTrackerBox> {
  int water = 0;

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
            "Water : $water ml",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                water+=200;
              });
            },
            child: const Text("Drink💧(200 ml)"),
          ),
        ],
      ),
    );
  }
}











void main() async {
  // Flutter'ın async işlemler için hazırlanması
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatıyoruz
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Firebase Test App",
      home: Scaffold(
        appBar: AppBar(title: const Text("Firebase Connected")),
        body: const Center(
          child: Text(
            "Firebase Başarıyla Başlatıldı! 🎉",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
