import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_19/chat.dart';
import 'package:flutter_application_19/global.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Connections example app'),
        ),
        body: const Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;
  Map<String, ConnectionInfo> endpointMap = {};

  String? tempFileUri; //reference to the file currently being transferred
  Map<int, String> map = {}; //store filename mapped to corresponding payloadId

  String userInput = "";
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            const Text(
              "Permissions",
            ),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("checkLocationPermission (<= Android 12)"),
                  onPressed: () async {
                    if (await Permission.location.isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Location permissions granted :)")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Location permissions not granted :(")));
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askLocationPermission"),
                  onPressed: () async {
                    if (await Permission.location.request().isGranted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Location Permission granted :)")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Location permissions not granted :(")));
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("checkBluetoothPermission (>= Android 12)"),
                  onPressed: () async {
                    if (!(await Future.wait([
                      Permission.bluetooth.isGranted,
                      Permission.bluetoothAdvertise.isGranted,
                      Permission.bluetoothConnect.isGranted,
                      Permission.bluetoothScan.isGranted,
                    ]))
                        .any((element) => false)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Bluethooth permissions granted :)")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Bluetooth permissions not granted :(")));
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("askBluetoothPermission (Android 12+)"),
                  onPressed: () {
                    [
                      Permission.bluetooth,
                      Permission.bluetoothAdvertise,
                      Permission.bluetoothConnect,
                      Permission.bluetoothScan
                    ].request();
                  },
                ),
              ],
            ),
            const Divider(),
            Text("User Name: $userName"),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("Start Advertising"),
                  onPressed: () async {
                    try {
                      bool a = await Nearby().startAdvertising(
                        userName,
                        strategy,
                        onConnectionInitiated: onConnectionInit,
                        onConnectionResult: (id, status) {
                          showSnackbar(status);
                        },
                        onDisconnected: (id) {
                          showSnackbar(
                              "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
                          setState(() {
                            endpointMap.remove(id);
                          });
                        },
                      );
                      showSnackbar("ADVERTISING: $a");
                    } catch (exception) {
                      showSnackbar(exception);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Stop Advertising"),
                  onPressed: () async {
                    await Nearby().stopAdvertising();
                  },
                ),
              ],
            ),
            Wrap(
              children: <Widget>[
                ElevatedButton(
                  child: const Text("Start Discovery"),
                  onPressed: () async {
                    try {
                      bool a = await Nearby().startDiscovery(
                        userName,
                        strategy,
                        onEndpointFound: (id, name, serviceId) {
                          // show sheet automatically to request connection
                          showModalBottomSheet(
                            context: context,
                            builder: (builder) {
                              return Center(
                                child: Column(
                                  children: <Widget>[
                                    Text("id: $id"),
                                    Text("Name: $name"),
                                    Text("ServiceId: $serviceId"),
                                    ElevatedButton(
                                      child: const Text("Request Connection"),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Nearby().requestConnection(
                                          userName,
                                          id,
                                          onConnectionInitiated: (id, info) {
                                            onConnectionInit(id, info);
                                          },
                                          onConnectionResult: (id, status) {
                                            showSnackbar(status);
                                          },
                                          onDisconnected: (id) {
                                            setState(() {
                                              endpointMap.remove(id);
                                            });
                                            showSnackbar(
                                                "Disconnected from: ${endpointMap[id]!.endpointName}, id $id");
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        onEndpointLost: (id) {
                          showSnackbar(
                              "Lost discovered Endpoint: ${endpointMap[id]?.endpointName}, id $id");
                        },
                      );
                      showSnackbar("DISCOVERING: $a");
                    } catch (e) {
                      showSnackbar(e);
                    }
                  },
                ),
                ElevatedButton(
                  child: const Text("Stop Discovery"),
                  onPressed: () async {
                    await Nearby().stopDiscovery();
                  },
                ),
              ],
            ),
            Text("Number of connected devices: ${endpointMap.length}"),
            ElevatedButton(
              child: const Text("Stop All Endpoints"),
              onPressed: () async {
                await Nearby().stopAllEndpoints();
                setState(() {
                  endpointMap.clear();
                });
              },
            ),
            const Divider(),
            const Text(
              "Sending Data",
            ),
            // ElevatedButton(
            //   child: const Text("Chat"),
            //   onPressed: () async {
            //     // Navigating to ChatPage with entered text and endpointMap
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ChatPage(
            //           endpointMap: endpointMap,
            //         ),
            //       ),
            //     );
            //   },
            // ),
            Container(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                      ),
                      onSubmitted: (message) {
                        _sendMessage(message);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _sendMessage(textController.text);
                      textController.clear();
                    },
                  ),
                ],
              ),
            ),
            // ElevatedButton(
            //   child: const Text("Chat"),
            //   onPressed: () async {
            //     // Show a dialog to get user input
            //     await showDialog(
            //       context: context,
            //       builder: (BuildContext context) {
            //         return AlertDialog(
            //           title: Text('Enter your message:'),
            //           content: TextField(
            //             onChanged: (value) {
            //               userInput =
            //                   value; // Update userInput as the user types
            //             },
            //           ),
            //           actions: <Widget>[
            //             TextButton(
            //               onPressed: () {
            //                 Navigator.of(context).pop(); // Close the dialog
            //               },
            //               child: Text('Cancel'),
            //             ),
            //             TextButton(
            //               onPressed: () {
            //                 // Send the user input to Nearby Connections
            //                 endpointMap.forEach((key, value) {
            //                   showSnackbar(
            //                       "Sending $userInput to ${value.endpointName}, id: $key");
            //                   Nearby().sendBytesPayload(
            //                       key, Uint8List.fromList(userInput.codeUnits));
            //                 });

            //                 Navigator.of(context).pop(); // Close the dialog
            //               },
            //               child: Text('Send'),
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);
                        showSnackbar("$endid: $str");
                        chatMessages.add('You: $str');
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar("$endid: File transfer started");
                        tempFileUri = payload.uri;
                      }
                    },
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(String message) {
    // Update the chatMessages list
    setState(() {
      chatMessages.add('You: $message');
    });

    // Send the message to all connected devices
    endpointMap.forEach((key, value) {
      showSnackbar("Sending $message to ${value.endpointName}, id: $key");
      Nearby().sendBytesPayload(key, Uint8List.fromList(message.codeUnits));
    });
  }
}
