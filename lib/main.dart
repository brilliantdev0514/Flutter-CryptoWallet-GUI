import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:flutter_window_close/flutter_window_close.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Shell Command'),
    );
  }
}

class MyHomePage extends StatefulWidget  {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  List<String> output = <String>[];
  bool isRunning = false;

  ShellLinesController controller = ShellLinesController();
  Shell shell = Shell();

   @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    print('Lifecycle state changed to: $state');

    if (state == AppLifecycleState.resumed) {
      // App is resumed, might be a good place to refresh UI or data
    } else if (state == AppLifecycleState.paused) {
      // App is paused, might be a good time to save data or stop animations
    } else if (state == AppLifecycleState.inactive) {
      // App is inactive, handle this state accordingly
      
    } else if (state == AppLifecycleState.detached) {
      // App is about to be terminated, release resources and finalize things
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    shell = Shell(stdout: controller.sink, verbose: false);
    shellListener();   
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      if (_index == 0) {
        if (_alertShowing) return false;
        _alertShowing = true;

        return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  title: const Text('Do you really want to quit?'),
                  actions: [
                    ElevatedButton(
                        onPressed: () async {
                          shell.kill();
                          if (await fileExists("lock")) {
                            await shell.run("taskkill /f /im xcv-alpha-go_win_amd64.exe");
                            await shell.run("del lock");
                          }
                          await Future.delayed(const Duration(seconds: 2));
                          Navigator.of(context).pop(false);
                          _alertShowing = false;
                          exit(0);
                        },
                        child: const Text('Yes')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          _alertShowing = false;
                        },
                        child: const Text('No'))
                  ]);
            });
      } else if (_index == 1) {
        final result = await FlutterPlatformAlert.showCustomAlert(
          windowTitle: "Really?",
          text: "Do you really want to quit?",
          positiveButtonTitle: "Quit",
          negativeButtonTitle: "Cancel",
        );
        return result == CustomButton.positiveButton;
      } else if (_index == 3) {
        return await Future.delayed(const Duration(seconds: 1), () => true);
      }
      return true;
    });
  }

  void shellListener() {
    controller.stream.listen((event) {
      setState(() {
        output.add(event);
      });
    });
  }

  var _alertShowing = false;
  var _index = 0;

 
  Future<bool> fileExists(String filePath) async {
    var file = File(filePath);
    return await file.exists();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void runCommand() async {
    if (await fileExists("lock")) {
      await shell.run("taskkill /f /im xcv-alpha-go_win_amd64.exe");
      await shell.run("del lock");
    }
    if (!isRunning) {
      setState(() {
        output = [];
      });
      try {
        await shell.run("xcv-alpha-go_win_amd64");
      } catch (e) {
        setState(() {
          output.add(e.toString());
        });
      }
    } else {
      shell.kill();
      setState(() {
        output = [];
      });
    }
    setState(() {
      isRunning = !isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 800,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  child: ElevatedButton(
                    onPressed: () {
                      runCommand();
                    },
                    child: isRunning
                        ? const Icon(Icons.stop)
                        : const Icon(Icons.play_arrow),
                  ),
                ),
                Column(
                  children: [for (var out in output) Text(out, textAlign: TextAlign.start,)],
                ),
                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
