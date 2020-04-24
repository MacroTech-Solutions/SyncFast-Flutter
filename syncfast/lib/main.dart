import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:web_socket_channel/io.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
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
var hostJson;
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
                  return MyHomePage(title: 'SyncFast');
                }
              },
            ),
        "/join": (_) => ViewLinkPage(),
        "/webview": (_) => WebviewScaffold(
              url: url,
              appBar: AppBar(
                title: Text("Contact MacroTech"),
              ),
              withJavascript: true,
              withLocalStorage: true,
              withZoom: true,
            )
      },
      //home: MyHomePage(title: 'SyncFast'),
    );
  }
}

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
  ],
);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  initState() {
    super.initState();
    webView.close();
    controller.addListener(() {
      url = controller.text;
    });
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
        } else {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new ClientJoinPage()));
        }
      }
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
    }
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

  final webView = FlutterWebviewPlugin();
  TextEditingController controller = TextEditingController(text: url);

  @override
  void dispose() {
    webView.dispose();
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
        title: Text(widget.title),
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
                            text: 'View Presentation\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'Use this feature to access a SyncFast presentation with a QR code or an access key.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                          TextSpan(
                            text: '\nHost Remote\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'Use this feature to control an existing presentation hosted on SyncFast.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ));
              })
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(30.0),
                child: Image(
                  image: AssetImage('assets/logo.png'),
                  height: 150,
                )),
            ListTile(
              title: RaisedButton(
                color: HexColor("00b2d1"),
                onPressed: () {
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
                          builder: (context) => new ClientJoinPage()));
                },
                child: Text("View Presentation"),
              ),
            ),
            ListTile(
                title: RaisedButton(
                    color: HexColor("ff5ded"),
                    onPressed: () {
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
                              builder: (context) => new HostSignIn()));
                    },
                    child: Text("Host Remote"))),
            ListTile(
                title: RaisedButton(
                    color: HexColor("c6c6c8"),
                    onPressed: () async {
                      Navigator.of(context).pushNamed("/webview");
                    },
                    child: Text("Contact MacroTech"))),
          ],
        ),
      ),
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
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    String result = "";
    return WillPopScope(
        onWillPop: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new MyHomePage(title: 'SyncFast')));
          return;
        },
        child: Scaffold(
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
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Invoke "debug painting" (press "p" in the console, choose the
              // "Toggle Debug Paint" action from the Flutter Inspector in Android
              // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
              // to see the wireframe for each widget.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
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
                              setState(() {
                                clientLock = false;
                              });
                            } else {
                              setState(() {
                                clientLock = true;
                              });
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
                            setState(() {
                              clientLock = false;
                            });
                          } else {
                            setState(() {
                              clientLock = true;
                            });
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
        ));
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
        //createAlertDialog(context);
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
          ),
          body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Opacity(
                  opacity: clientLock ? 0.0 : 1.0,
                  child: RaisedButton(
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
                Expanded(
                    child: Container(
                        child: Image(
                  image: NetworkImage(slideUrl),
                ))),
                Opacity(
                  opacity: clientLock ? 0.0 : 1.0,
                  child: RaisedButton(
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
              ],
            ),
          ),
        ));
  }
}

class HostSignIn extends StatefulWidget {
  HostSignIn({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HostSignInState createState() => _HostSignInState();
}

class _HostSignInState extends State<HostSignIn> {
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
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    googleSignIn.signOut();
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
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
                            text: 'Sign In\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'Use the same credentials that you used to host your presentation on the SyncFast website to login to the app.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                          TextSpan(
                            text: '\nTroubleshooting\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'If you are receiving a sign in error, please verify that you have a presentation running on the same account at https://syncfast.net.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ));
              })
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0),
              child: TextField(
                decoration: InputDecoration(hintText: "Email Address"),
                onChanged: (String str) {
                  setState(() {
                    username = str;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30.0, right: 30.0),
              child: TextField(
                decoration: InputDecoration(hintText: "Password"),
                obscureText: true,
                onChanged: (String str) {
                  setState(() {
                    password = str;
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
                        "email": username,
                        "password": password
                      };
                      Response response = await post(
                          'https://syncfast.macrotechsolutions.us:9146/http://localhost/remoteEmail',
                          headers: headers);
                      //createAlertDialog(context);
                      hostJson = jsonDecode(response.body);
                      if (hostJson["data"] == "Valid User") {
                        Map<String, String> headers = {
                          "Content-type": "application/json",
                          "Origin": "*",
                          "firebasepresentationkey":
                              hostJson["firebasepresentationkey"]
                        };
                        Response response = await post(
                            'https://syncfast.macrotechsolutions.us:9146/http://localhost/remoteAuth',
                            headers: headers);
                        hostJson = jsonDecode(response.body);
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
                                builder: (context) => new HostRemotePage()));
                      } else {
                        createAlertDialog(context, "Error", hostJson["data"]);
                      }
                    },
                    child: Text("Submit"))),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Text(
                "OR",
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
            SizedBox(height: 50),
            RaisedButton(
              onPressed: () async {
                final GoogleSignInAccount googleSignInAccount =
                    await googleSignIn.signIn();
                Map<String, String> headers = {
                  "Content-type": "application/json",
                  "Origin": "*",
                  "email": googleSignInAccount.email
                };
                Response response = await post(
                    'https://syncfast.macrotechsolutions.us:9146/http://localhost/hostRemote',
                    headers: headers);
                //createAlertDialog(context);
                hostJson = jsonDecode(response.body);
                if (hostJson["data"] == "Valid User") {
                  Map<String, String> headers = {
                    "Content-type": "application/json",
                    "Origin": "*",
                    "firebasepresentationkey":
                        hostJson["firebasepresentationkey"]
                  };
                  Response response = await post(
                      'https://syncfast.macrotechsolutions.us:9146/http://localhost/remoteAuth',
                      headers: headers);
                  hostJson = jsonDecode(response.body);
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
                          builder: (context) => new HostRemotePage()));
                } else {
                  createAlertDialog(context, "Error",
                      "The email address $googleSignInAccount is not associated with an account. Please host a presentationon https://syncfast.macrotechsolutions.us.");
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image(
                        image: AssetImage("assets/google_logo.png"),
                        height: 35.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostRemotePage extends StatefulWidget {
  HostRemotePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HostRemotePageState createState() => _HostRemotePageState();
}

class _HostRemotePageState extends State<HostRemotePage> {
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
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    var channel =
        IOWebSocketChannel.connect("wss://syncfast.macrotechsolutions.us:4211");
    channel.stream.listen((message) async {
      if (message == hostJson["firebasepresentationkey"]) {
        Map<String, String> headers = {
          "Content-type": "application/json",
          "Origin": "*",
          "firebasepresentationkey": hostJson["firebasepresentationkey"]
        };
        Response response = await post(
            'https://syncfast.macrotechsolutions.us:9146/http://localhost/remoteAuth',
            headers: headers);
        setState(() {
          hostJson = jsonDecode(response.body);
          if (hostJson["lockstate"] == "false") {
            setState(() {
              lockIcon = Icons.lock_open;
            });
          } else {
            setState(() {
              lockIcon = Icons.lock_outline;
            });
          }
        });
      }
    });
    googleSignIn.signOut();
    return Scaffold(
      appBar: AppBar(
        title: Text("Access Key - ${hostJson["accesskey"]}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(lockIcon),
            onPressed: () async {
              Map<String, String> headers = {
                "Content-type": "application/json",
                "Origin": "*",
                "firebasepresentationkey": hostJson["firebasepresentationkey"]
              };
              Response response = await post(
                  'https://syncfast.macrotechsolutions.us:9146/http://localhost/hostLock',
                  headers: headers);
            },
            color: Colors.white,
          ),
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
                            text: 'Host Remote\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'This remote allows you to control the presentation running on a web browser without having to interact with that browser directly.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                          TextSpan(
                            text: '\nTroubleshooting\n',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text:
                                'If the functions are not working appropriately, please verify that both the remote and the host device are connected to the internet.\n',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ));
              })
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 30.0),
                child: Text(
                  '${hostJson["presentationtitle"]}',
                  style: TextStyle(
                    fontSize: 25.0,
                  ),
                )),
            Text(
              'Slide #${int.parse(hostJson["slidenum"]) + 1}',
              style: TextStyle(
                fontSize: 25.0,
              ),
            ),
            Expanded(
                child: Container(
              child: Image(image: NetworkImage(hostJson["slideurl"])),
            )),
            ButtonBar(alignment: MainAxisAlignment.center, children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RaisedButton(
                      onPressed: () async {
                        if (hostJson["slidenum"] != "0") {
                          Map<String, String> headers = {
                            "Content-type": "application/json",
                            "Origin": "*",
                            "firebasepresentationkey":
                                hostJson["firebasepresentationkey"]
                          };
                          Response response = await post(
                              'https://syncfast.macrotechsolutions.us:9146/http://localhost/previousSlide',
                              headers: headers);
                        } else {
                          createAlertDialog(context, "Previous Slide",
                              "You are currently on the first slide.");
                        }
                      },
                      child: Image(
                        image: AssetImage('assets/previousSlide.png'),
                        width: 75,
                      ))),
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: RaisedButton(
                      onPressed: () async {
                        if (hostJson["slidenum"] !=
                            (int.parse(hostJson["length"]) - 1).toString()) {
                          Map<String, String> headers = {
                            "Content-type": "application/json",
                            "Origin": "*",
                            "firebasepresentationkey":
                                hostJson["firebasepresentationkey"]
                          };
                          Response response = await post(
                              'https://syncfast.macrotechsolutions.us:9146/http://localhost/nextSlide',
                              headers: headers);
                        } else {
                          createAlertDialog(context, "Next Slide",
                              "You are currently on the last slide.");
                        }
                      },
                      child: Image(
                        image: AssetImage('assets/nextSlide.png'),
                        width: 75,
                      ))),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: 30.0, bottom: 30.0),
              child: Text(
                '${hostJson["notes"]}',
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  final webView = FlutterWebviewPlugin();
  TextEditingController controller = TextEditingController(text: url);

  @override
  void initState() {
    super.initState();

    webView.close();
    controller.addListener(() {
      url = controller.text;
    });
  }

  @override
  void dispose() {
    webView.dispose();
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
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
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
                      //createAlertDialog(context);
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
                          setState(() {
                            clientLock = false;
                          });
                        } else {
                          setState(() {
                            clientLock = true;
                          });
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
