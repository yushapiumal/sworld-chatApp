

import 'package:flutter/material.dart';
import 'package:sworld_flutter/component/Text/textStyle.dart';

class SworldHomePage extends StatefulWidget {
  static String routeName = "HomeScreen";
  const SworldHomePage({super.key, required this.title});
  final String title;
  @override
  State<SworldHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<SworldHomePage> {
  int _counter = 0;
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
   
        title: Text(widget.title , style: AppTextStyles.heading1,),
      ),
      body: Center(

        child: Column(
        
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), 
    );
  }
}