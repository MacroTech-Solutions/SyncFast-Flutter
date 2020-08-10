import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(MyApp());
}

String url = "https://www.macrotechsolutions.us/contact-us.html";
bool initial = true;

String accessCode;
String username;
String password;
var clientJson;
var tempJson;
var lockIcon = Icons.lock_outline;
bool clientLock = true;
var currentSlideNum = "";
var currentPresSlideNum = "";
var maxSlideNum = "";
var slideUrl = "";

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncFast',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      routes: {
        "/": (_) => StreamBuilder(
              stream: getLinksStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var result = snapshot.data;
                  if (snapshot.data.contains("syncfast") &&
                      snapshot.data.contains("?accessKey=")) {
                    accessCode = result.substring(result.indexOf('=') + 1);
                    return ViewLinkPage();
                  } else {
                    return ClientJoinPage();
                  }
                } else {
                  return ClientJoinPage();
                }
              },
            ),
        "/join": (_) => ViewLinkPage(),
      },
      //home: MyHomePage(title: 'SyncFast'),
    );
  }
}

class ClientJoinPage extends StatefulWidget {
  ClientJoinPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ClientJoinPageState createState() => _ClientJoinPageState();
}

class _ClientJoinPageState extends State<ClientJoinPage> {
  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  initState() {
    super.initState();
    if (initial) {
      initPlatformState();
      initial = !initial;
    }
  }

  initPlatformState() async {
    var initialLink;
    try {
      initialLink = await getInitialLink();
      if (initialLink != null) {
        if (initialLink.contains("syncfast") &&
            initialLink.contains("?accessKey=")) {
          accessCode = initialLink.substring(initialLink.indexOf('=') + 1);
          Navigator.pushReplacementNamed(context, "/join");
        }
      }
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
    }
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    String result = "";
    return Scaffold(
          appBar: AppBar(
            title: Text("View Presentation"),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () async {
                    helpContext(
                        context,
                        "Help",
                        Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Enter Access Code\n',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text:
                                    'Enter the access key that you received from your host in the field and press submit.\n',
                                style: TextStyle(fontSize: 20),
                              ),
                              TextSpan(
                                text: '\nScan QR\n',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text:
                                    'If you have a QR code instead, click the Scan QR code button to open a camera view and point the camera at your QR code.\n',
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ));
                  })
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Image(
                      image: AssetImage('assets/logo.png'),
                      height: 150,
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: TextField(
                    decoration: InputDecoration(hintText: "Enter Access Code"),
                    textAlign: TextAlign.center,
                    onChanged: (String str) {
                      setState(() {
                        accessCode = str;
                      });
                    },
                  ),
                ),
                ListTile(
                    title: RaisedButton(
                        onPressed: () async {
                          Map<String, String> headers = {
                            "Content-type": "application/json",
                            "Origin": "*",
                            "accesscode": accessCode
                          };
                          Response response = await post(
                              'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientJoin',
                              headers: headers);
                          //createAlertDialog(context);
                          clientJson = jsonDecode(response.body);
                          if (clientJson["data"] == "Incorrect Access Code") {
                            createAlertDialog(context, "Incorrect Access Code",
                                "Access code $accessCode is invalid. Please try again.");
                          } else {
                            maxSlideNum = clientJson["slidenum"];
                            currentPresSlideNum = clientJson["slidenum"];
                            currentSlideNum = clientJson["slidenum"];
                            slideUrl = clientJson["slideurl"];
                            if (clientJson["lockstate"] == 'false') {
                              clientLock = false;
                            } else {
                              clientLock = true;
                            }
                            dispose() {
                              SystemChrome.setPreferredOrientations([
                                DeviceOrientation.landscapeRight,
                                DeviceOrientation.landscapeLeft,
                                DeviceOrientation.portraitUp,
                                DeviceOrientation.portraitDown,
                              ]);
                              super.dispose();
                            }

                            Navigator.push(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => new ViewPresPage()));
                          }
                        },
                        child: Text("Submit"))),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text(
                    "OR",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
                FloatingActionButton.extended(
                  icon: Icon(Icons.camera_alt),
                  label: Text("Scan QR"),
                  onPressed: () async {
                    try {
                      String qrResult = await BarcodeScanner.scan();
                      result = qrResult;
                      if (result.contains("syncfast") &&
                          result.contains("?accessKey=")) {
                        accessCode = result.substring(result.indexOf('=') + 1);
                        Map<String, String> headers = {
                          "Content-type": "application/json",
                          "Origin": "*",
                          "accesscode": accessCode
                        };
                        Response response = await post(
                            'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientJoin',
                            headers: headers);
                        //createAlertDialog(context);
                        clientJson = jsonDecode(response.body);
                        if (clientJson["data"] == "Incorrect Access Code") {
                          createAlertDialog(context, "Incorrect Access Code",
                              "Access code $accessCode is invalid. Please try again.");
                        } else {
                          maxSlideNum = clientJson["slidenum"];
                          currentPresSlideNum = clientJson["slidenum"];
                          currentSlideNum = clientJson["slidenum"];
                          slideUrl = clientJson["slideurl"];
                          if (clientJson["lockstate"] == 'false') {
                            clientLock = false;
                          } else {
                            clientLock = true;
                          }
                          dispose() {
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeRight,
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]);
                            super.dispose();
                          }

                          Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => new ViewPresPage()));
                        }
                      } else {
                        createAlertDialog(
                            context, "Scan QR", "Invalid QR Code");
                      }
                    } on PlatformException catch (ex) {
                      if (ex.code == BarcodeScanner.CameraAccessDenied) {
                        setState(() {
                          createAlertDialog(context, "Scan QR",
                              "Please enable camera permissions for SyncFast.");
                        });
                      } else {
                        setState(() {
                          result = "Unknown Error $ex";
                          createAlertDialog(
                              context, "Scan QR", "Unkown Error Occured: $ex");
                        });
                      }
                    } on FormatException {
                      setState(() {
                        result =
                            "You pressed the back button before scanning anything";
                        createAlertDialog(
                            context, "Scan QR", "No QR Code was recognized.");
                      });
                    } catch (ex) {
                      setState(() {
                        result = "Unknown Error $ex";
                        createAlertDialog(
                            context, "Scan QR", "Unkown Error Occured: $ex");
                      });
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                )
              ],
            ),
          ),
        );
  }
}

class ViewPresPage extends StatefulWidget {
  ViewPresPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ViewPresPageState createState() => _ViewPresPageState();
}

class _ViewPresPageState extends State<ViewPresPage> {
  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    var channel =
    IOWebSocketChannel.connect("wss://syncfast.macrotechsolutions.us:4211");
    channel.stream.listen((message) async {
      if (message == clientJson["firebasepresentationkey"]) {
        Map<String, String> headers = {
          "Content-type": "application/json",
          "Origin": "*",
          "accesscode": accessCode
        };
        Response response = await post(
            'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientJoin',
            headers: headers);
        setState(() {
          clientJson = jsonDecode(response.body);
        });
        if (int.parse(clientJson["slidenum"]) > int.parse(maxSlideNum)) {
          maxSlideNum = clientJson["slidenum"];
        }
        print(clientJson);
        if (clientJson["lockstate"] == 'false') {
          setState(() {
            clientLock = false;
          });
          print(currentPresSlideNum);
          print(currentSlideNum);
          if (currentPresSlideNum != clientJson["slidenum"]) {
            if (currentPresSlideNum == currentSlideNum) {
              setState(() {
                slideUrl = clientJson["slideurl"];
                currentSlideNum = clientJson["slidenum"];
              });
            }
          }
        } else {
          setState(() {
            clientLock = true;
          });
          if (currentPresSlideNum != clientJson["slidenum"]) {
            currentSlideNum = clientJson["slidenum"];
            setState(() {
              slideUrl = clientJson["slideurl"];
            });
          }
        }
        currentPresSlideNum = clientJson["slidenum"];
      }
    });
    return WillPopScope(
        onWillPop: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new ClientJoinPage()));
          return;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('${clientJson["presentationtitle"]}'),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () async {
                    helpContext(
                        context,
                        "Help",
                        Text.rich(
                          TextSpan(
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Slides\n',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text:
                                'View the slides and navigate through the slides if enabled by host.\n',
                                style: TextStyle(fontSize: 20),
                              ),
                              TextSpan(
                                text: '\nCopy Link\n',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline),
                              ),
                              TextSpan(
                                text:
                                'If you would like to access the voice channel, copy the link and paste in a supported browser to listen in.\n',
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ));
                  }),
              IconButton(
                  icon: Icon(Icons.content_copy),
                  onPressed: () async {
                    Clipboard.setData(ClipboardData(text: "https://syncfast.macrotechsolutions.us/client?accessKey=$accessCode"));
                    createAlertDialog(context, "Link Copied", "Paste the link in your browser to view it on your browser and listen in to the voice chat.");
                  }),
            ],
          ),
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Opacity(
                    opacity: clientLock ? 0.0 : 1.0,
                    child: RaisedButton(
                        color: HexColor("00afce"),
                        onPressed: () async {
                          if (!clientLock) {
                            if (currentSlideNum != "0") {
                              Map<String, String> headers = {
                                "Content-type": "application/json",
                                "Origin": "*",
                                "accesscode": accessCode,
                                "slidenum":
                                (int.parse(currentSlideNum) - 1).toString()
                              };
                              Response response = await post(
                                  'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientGetSlide',
                                  headers: headers);
                              currentSlideNum =
                                  (int.parse(currentSlideNum) - 1).toString();
                              setState(() {
                                tempJson = jsonDecode(response.body);
                              });
                              setState(() {
                                slideUrl = tempJson["slideurl"];
                              });
                            } else {
                              createAlertDialog(context, "Previous Slide",
                                  "You are currently on the first slide.");
                            }
                          }
                        },
                        child: Image(
                          image: AssetImage('assets/previousSlide.png'),
                          width: 75,
                        )),
                  ),
                ),
                Expanded(
                    child: Container(
                        child: Image(
                          image: NetworkImage(slideUrl),
                        ))),
                Container(
                  child: Opacity(
                    opacity: clientLock ? 0.0 : 1.0,
                    child: RaisedButton(
                        color: HexColor("00afce"),
                        onPressed: () async {
                          if (!clientLock) {
                            if (int.parse(currentSlideNum) <
                                int.parse(maxSlideNum)) {
                              Map<String, String> headers = {
                                "Content-type": "application/json",
                                "Origin": "*",
                                "accesscode": accessCode,
                                "slidenum":
                                (int.parse(currentSlideNum) + 1).toString()
                              };
                              Response response = await post(
                                  'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientGetSlide',
                                  headers: headers);
                              currentSlideNum =
                                  (int.parse(currentSlideNum) + 1).toString();
                              setState(() {
                                tempJson = jsonDecode(response.body);
                              });
                              setState(() {
                                slideUrl = tempJson["slideurl"];
                              });
                            } else {
                              createAlertDialog(context, "Next Slide",
                                  "You are currently on the last available slide.");
                            }
                          }
                        },
                        child: Image(
                          image: AssetImage('assets/nextSlide.png'),
                          width: 75,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

class ViewLinkPage extends StatefulWidget {
  ViewLinkPage({Key key, this.code}) : super(key: key);

  final String code;

  @override
  _ViewLinkPageState createState() => _ViewLinkPageState();
}

class _ViewLinkPageState extends State<ViewLinkPage> {
  Future<String> createAlertDialog(
      BuildContext context, String title, String body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, "/");
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  Future<String> helpContext(BuildContext context, String title, Widget body) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(title),
              content: body,
              actions: <Widget>[
                MaterialButton(
                  elevation: 5.0,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ]);
        });
  }

  TextEditingController controller = TextEditingController(text: url);

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      url = controller.text;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      appBar: AppBar(
        title: Text("Join Presentation"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.help),
              onPressed: () async {
                helpContext(
                    context,
                    "Help",
                    Text.rich(
                      TextSpan(
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Join Presentation\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'This app is launched when you open a SyncFast webpage in your browser. Verify the access code and click the submit button.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ));
              })
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(30.0),
                child: Image(
                  image: AssetImage('assets/logo.png'),
                  height: 150,
                )),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0),
              child: Text('Access Code: $accessCode',
                  style: TextStyle(fontSize: 20.0)),
            ),
            ListTile(
                title: RaisedButton(
                    onPressed: () async {
                      Map<String, String> headers = {
                        "Content-type": "application/json",
                        "Origin": "*",
                        "accesscode": accessCode
                      };
                      Response response = await post(
                          'https://syncfast.macrotechsolutions.us:9146/http://localhost/clientJoin',
                          headers: headers);
                      clientJson = jsonDecode(response.body);
                      if (clientJson["data"] == "Incorrect Access Code") {
                        createAlertDialog(context, "Incorrect Access Code",
                            "Access code $accessCode is invalid.");
                      } else {
                        maxSlideNum = clientJson["slidenum"];
                        currentPresSlideNum = clientJson["slidenum"];
                        currentSlideNum = clientJson["slidenum"];
                        slideUrl = clientJson["slideurl"];
                        if (clientJson["lockstate"] == 'false') {
                          clientLock = false;
                        } else {
                          clientLock = true;
                        }
                        dispose() {
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeRight,
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                          ]);
                          super.dispose();
                        }

                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new ViewPresPage()));
                      }
                    },
                    child: Text("Join Presentation"))),
            Padding(
              padding: const EdgeInsets.all(30.0),
            )
          ],
        ),
      ),
    );
  }
}
