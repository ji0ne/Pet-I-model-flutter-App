import 'package:firstnote/ble_controller.dart';
import 'package:firstnote/pet_eye_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const PetProfileScreen(),
    );
  }
}

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final BleController controller = Get.put(BleController());
  String _movement = '정지';
  double _threshold1 = 1.0;
  double _threshold2 = 5.0;
  Timer? _timer;
  Timer? _dataUpdateTimer;

  bool _alertShown = false;
  bool _startedUpdating = false;
  final Random _random = Random();

  final ValueNotifier<int> _currentBpm = ValueNotifier(74);
  final ValueNotifier<double> _currentTemperature = ValueNotifier(36.4);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (controller.magnitudes.isNotEmpty) {
        double averageMagnitude = controller.magnitudes.reduce((a, b) => a + b) / controller.magnitudes.length;
        setState(() {
          if (averageMagnitude < _threshold1) {
            _movement = '정지';
          } else if (averageMagnitude < _threshold2) {
            _movement = '걷기';
          } else {
            _movement = '뛰기';
          }
        });
        controller.magnitudes.clear();
      }
    });
  }

  void _startDataUpdates() {
    if (!_startedUpdating) {
      _startedUpdating = true;

      Future.delayed(Duration(seconds: 10), () {
        _dataUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          int bpmIncrease = _random.nextInt(3) + 5;
          _currentBpm.value += bpmIncrease;
          if(_currentBpm.value >= 112) {
            _currentBpm.value = 112;

            if(!_alertShown) {
              _showAlertDialog();
              _alertShown = true;
            }
          }

          _currentTemperature.value = 36.5 + (_random.nextDouble() * 0.3);
        });
      });
    }
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 50,
          ),
          content: Text(
            "Alert : 아이의 심장이\n너무 빨리 뛰어요 !",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataUpdateTimer?.cancel();
    _currentBpm.dispose();
    _currentTemperature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                  const Text(
                    '오늘의 히로',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.deepOrange),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.pets, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '히로',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.male, color: Colors.blue),
                    ],
                  ),
                  const Text(
                    '2018.07.06',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _currentBpm,
                    builder: (context, bpm, child) {
                      return Image.asset(
                        bpm >= 100
                            ? 'assets/running-dog-silhouette_47203.png'
                            : 'assets/dog-facing-right.png',
                        width: 24,
                        height: 24,
                      );
                    },
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.black),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: _currentBpm,
                        builder: (context, bpm, child) {
                          Color bpmColor = bpm >= 100 ? Colors.red : Colors.green;
                          return Text(
                            '$bpm bpm',
                            style: TextStyle(fontSize: 16, color: bpmColor),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<double>(
                        valueListenable: _currentTemperature,
                        builder: (context, temperature, child) {
                          Color temperatureColor = temperature >= 37.5 ? Colors.red : Colors.green;
                          return Text(
                            '${temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 16, color: temperatureColor),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: GetBuilder<BleController>(
                builder: (controller) {
                  return StreamBuilder<List<ScanResult>>(
                    stream: controller.scanResults,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(data.device.name.isEmpty ? 'Unknown Device' : data.device.name),
                                subtitle: Text(data.device.id.id),
                                trailing: Text(data.rssi.toString()),
                                onTap: () => controller.connectToDevice(data.device),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text("검색된 기기가 없습니다"));
                      }
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3EE),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      controller.scanDevices();
                      _startDataUpdates();
                    },
                    child: const Text('주변 기기 찾기'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF3EE),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PetEyePage()),
                      );
                    },
                    child: const Text('PET-EYE'),
                  ),
                ],
              ),
            ),

            Container(
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.deepOrange,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.notifications, color: Colors.white),
                  Icon(Icons.favorite, color: Colors.white),
                  Icon(Icons.menu, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}