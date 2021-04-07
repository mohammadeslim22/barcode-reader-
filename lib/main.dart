import 'package:br_reader/helpers/dio.dart';
import 'package:dio/dio.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:wifi/wifi.dart';
import 'package:ping_discover_network/ping_discover_network.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool scanIPs = false;
  bool connected = false;
  String barcodeIp;
  @override
  void initState() {
    super.initState();
  }

  List<String> ipaddresses = <String>[];
  startBarcodeScanStream() async {
    FlutterBarcodeScanner.getBarcodeStreamReceiver(
            "#ff6666", "Cancel", true, ScanMode.BARCODE)
        //     .forEach((Function) async {
        //   dio.post("http://$barcodeIp:3000/barcode",
        //       data: <String, String>{"barcode": barcode});
        // });
        .listen((barcode) async {
      print(barcode);
      await dio.post("http://$barcodeIp:3000/barcode",
          data: <String, String>{"barcode": barcode});
      Navigator.pop(context);
      scanBarcodeNormal();
    });
  }

  void sendToBooklet() {}
  void showInternetError() {
    showGeneralDialog<dynamic>(
        barrierLabel: "Label",
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.73),
        transitionDuration: const Duration(milliseconds: 350),
        context: context,
        pageBuilder: (BuildContext context, Animation<double> anim1,
            Animation<double> anim2) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                height: 250,
                width: 250,
                child: const FlareActor("assets/images/Wifianimation.flr",
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                    animation: "loading"),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          );
        });
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print("barcodeScanRes  $barcodeScanRes");
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    Response<dynamic> res;
    if (!mounted) return;
    for (int i = 0; i < ipaddresses.length; i++) {
      res = await dio.post("http://${ipaddresses[i]}:3000/auth",
          data: <String, String>{"code": "$barcodeScanRes"});
      print("res res res : ${res.data}");
      print("res res res : ${res.statusCode}");
      if (res.statusCode == 200) {
        setState(() {
          barcodeIp = ipaddresses[i];
          connected = true;
        });

        print('connected');
        break;
      }
      Navigator.pop(context);
    }
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes = "";
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;
    print(
        "codeNormalscanBarcodeNormal $barcodeScanRes");
    await dio.post("http://$barcodeIp:3000/barcode",
        data: <String, String>{"barcode": barcodeScanRes});
    scanBarcodeNormal();
  }

  Future<void> scanIps() async {
    showInternetError();

    final String ip = await Wifi.ip;
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final int port = 3000;
    await Future.delayed(Duration(seconds: 3));
    final stream = NetworkAnalyzer.discover2(subnet, port);
    // stream.listen((NetworkAddress addr) async {
    //   if (addr.exists) {
    //     print('Found device: ${addr.ip}');
    //     ipaddresses.add(addr.ip);
    //     setState(() {
    //       scanIPs = true;
    //     });
    //     print(scanIPs);
    //     // res = await dio.get(addr.ip);
    //     // if (res.statusCode == 200) {
    //     //   setState(() {
    //     //     scanIPs = true;
    //     //   });
    //     //   Navigator.pop(context);
    //     // }
    //   }
    // });
    await stream.forEach((NetworkAddress addr) async {
      if (addr.exists) {
        print('Found device: ${addr.ip}');
        ipaddresses.add(addr.ip);
        setState(() {
          scanIPs = true;
        });
        print(scanIPs);
      }
    });
    Navigator.pop(context);
    if (!scanIPs) {
      await showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: new Text('Alert'),
          content: Text('No local device was found :( '),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: new Text('OK'),
            ),
          ],
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: new Text('Alert'),
          content: Text('Please Scan Qr Code to connect to your device'),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                scanQR();
              },
              child: new Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Barcode scanner')),
        body: Builder(builder: (BuildContext context) {
          return Column(
            children: [
              const SizedBox(height: 100),
              Text("Connect to your device on the  Network"),
              const SizedBox(height: 100),
              Container(
                  alignment: Alignment.center,
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Visibility(
                          child: RaisedButton(
                              color: Colors.blue,
                              onPressed: () => scanIps(),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text("Connect to your Local device",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 26))),
                          visible: !connected,
                          replacement: RaisedButton(
                              color: Colors.green,
                              onPressed: () =>  scanBarcodeNormal(),
                              //startBarcodeScanStream(),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text("Start scanning barcodes",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 26))),
                        ),
                        const SizedBox(height: 32),
                        // Visibility(
                        //   visible: connected,
                        //   child: RaisedButton(
                        //       onPressed: () => scanQR(),
                        //       child: Text("Start IP Devices scan")),
                        // ),
                        // RaisedButton(
                        //     onPressed: () => startBarcodeScanStream(),
                        //     child: Text("Start barcode scan stream")),
                        // Text('Scan result : $_scanBarcode\n',
                        //     style: TextStyle(fontSize: 20))
                      ]))
            ],
          );
        }));
  }
}
