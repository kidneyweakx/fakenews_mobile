import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'package:anfa/page/image_page.dart';

final client = MqttServerClient.withPort('broker.hivemq.com','flutter_client', 1883);

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.cameras}) : super(key: key);
  final List<CameraDescription> cameras;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  CameraController controller;
  ImageInfo imageInfo;
  String red= "R", green="G", blue="B";


  // open camera
  @override
  void initState() {
    super.initState();
    connect();
    initCamera(widget.cameras);
    SystemChannels.lifecycle.setMessageHandler((msg) {
      if (msg == AppLifecycleState.resumed.toString()) {
        reloadCamera();
      }
    });
  }

  void reloadCamera() {
    availableCameras().then((cameras) {
      controller = new CameraController(cameras[0], ResolutionPreset.max);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    });
  }

  void initCamera(cameras) async {
    controller = new CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  void captureImage(ImageSource captureMode) async {
    try {
      var imageFile = await ImagePicker.pickImage(source: captureMode);
      _loadImage(imageFile).then((image) {
        if (image != null) {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new CropPage(
                      image: image,
                      imageInfo: new ImageInfo(image: image, scale: 1.0))));
        }
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String timestamp() => new DateTime.now().millisecondsSinceEpoch.toString();

  void sendx(String msg) {
    const pubTopic = 'anfa/fakenews/rpi';
    final builder = MqttClientPayloadBuilder();
    builder.addString(msg);
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);
  }

  Future<String> capture() async {
    if (!controller.value.isInitialized) {
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';
    try {
      await controller.takePicture(filePath);
      try {
        File imageFile = new File(filePath);
        _loadImage(imageFile).then((image) {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new CropPage(
                      image: image,
                      imageInfo: new ImageInfo(image: image, scale: 1.0))));
        });
      } catch (e) {
        print(e);
      }
    } on CameraException catch (e) {
      print(e);
      return null;
    }
    return filePath;
  }

  Future<Widget> _buildImage(BuildContext context) async {
    return new Stack(children: <Widget>[
      new Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: new Transform.scale(
              scale: 1 / controller.value.aspectRatio,
              child: new Center(
                child: new AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: new CameraPreview(controller)),
              ))),
      // rpi function
      new Positioned(
        top: (MediaQuery.of(context).size.height / 10*5 -15),
        height: 30.0,
        width: 30.0,
        left: 15,
        child: new RaisedButton(
            onPressed: () => sendx('R'),
            color: Colors.red,
            padding: EdgeInsets.all(5.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            child: new Icon(Icons.keyboard_arrow_left, size: 20.0, color: Colors.white)),
      ),
      new Positioned(
        top: (MediaQuery.of(context).size.height / 10*6 -15),
        height: 30.0,
        width: 30.0,
        left: 15,
        child: new RaisedButton(
            onPressed: () => sendx('G'),
            color: Colors.green,
            padding: EdgeInsets.all(5.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            child: new Icon(Icons.keyboard_arrow_up, size: 20.0, color: Colors.white)),
      ),
      new Positioned(
        top: (MediaQuery.of(context).size.height / 10*7 -15),
        height: 30.0,
        width: 30.0,
        left: 15,
        child: new RaisedButton(
            onPressed: () => sendx('B'),
            color: Colors.blue,
            padding: EdgeInsets.all(5.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            child: new Icon(Icons.keyboard_arrow_down, size: 20.0, color: Colors.white)),
      ),
      new Positioned(
        top: (MediaQuery.of(context).size.height / 10*8 -15),
        height: 30.0,
        width: 30.0,
        left: 15,
        child: new RaisedButton(
            onPressed: () => sendx('DO'),
            color: Colors.black,
            padding: EdgeInsets.all(5.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            child: new Icon(Icons.keyboard_arrow_right, size: 20.0, color: Colors.white)),
      ),
      // camera
      new Positioned(
        bottom: 20.0,
        height: 60.0,
        width: 60.0,
        left: (MediaQuery.of(context).size.width / 2 - 30.0),
        child: new RaisedButton(
            onPressed: capture,
            padding: EdgeInsets.all(10.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(60.0))),
            child: new Icon(Icons.photo_camera, size: 40.0, color: Colors.blueAccent)),
      ),
      new Positioned(
        bottom: 20.0,
        height: 40.0,
        width: 40.0,
        right: (20.0),
        child: new RaisedButton(
            onPressed: () => captureImage(ImageSource.gallery),
            padding: EdgeInsets.all(10.0),
            shape: new RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40.0))),
            child: new Icon(Icons.photo_library,
                size: 20.0, color: Colors.blueAccent)),
      ),
    ]);
  }

  Future<ui.Image> _loadImage(File img) async {
    if (img != null) {
      var codec = await ui.instantiateImageCodec(img.readAsBytesSync());
      var frame = await codec.getNextFrame();
      return frame.image;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
          child: new Container(
              child: new Column(children: [
        new Expanded(
            child: new Center(
                child: new FutureBuilder(
          future: _buildImage(context),
          builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
            if (snapshot.hasData) {
              return snapshot.data;
            } else {
              return new Container();
            }
          },
        ))),
      ]))), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Future<MqttServerClient> connect() async {
  client.setProtocolV311();
  client.logging(on: true);
  client.keepAlivePeriod = 20;
  await client.connect();
  if (client.connectionStatus.state == MqttConnectionState.connected) {
    print('client connected');
  } else {
    print(
        'client connection failed - disconnecting, state is ${client.connectionStatus.state}');
    client.disconnect();
  }
}