import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zolozkit_for_flutter/zolozkit_for_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  await Permission.microphone.request();
  // await Permission.storage.request();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // String URL = "https://zoloz-sdk.herokuapp.com/";

  String URL = "http://192.168.0.104:8080/";

  String FACE_INIT = "zoloz/facecapture/initialize";

  String FACE_RESULT = "zoloz/facecapture/checkresult";

  bool loading = false;
  double height(BuildContext ctx) => MediaQuery.of(ctx).size.height;
  double width(BuildContext ctx) => MediaQuery.of(ctx).size.width;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(child: _zolozFlutter()),
    );
  }

  void setLoading(bool active) {
    setState(() {
      loading = active;
    });
  }

  Scaffold _zolozFlutter() {
    return Scaffold(
      body: Builder(builder: (context) {
        if (loading) {
          return loadingWidget(context);
        }
        if (resultFace == null) {
          return Center(
            child: _openZolozBtn(),
          );
        } else {
          return successWidget(context);
        }
      }),
    );
  }

  Padding successWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: height(context) / 3,
              width: width(context) / 2,
              child: imageFromBase64String(resultFace!.extInfo!.imageContent!)),
          resultDesc(),
          const SizedBox(height: 40),
          _openZolozBtn()
        ],
      ),
    );
  }

  SizedBox loadingWidget(BuildContext context) {
    return SizedBox(
      height: height(context),
      width: width(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CupertinoActivityIndicator(radius: 40),
          SizedBox(height: 20),
          Text(
            "Please wait",
            style: TextStyle(
                color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Column resultDesc() {
    var rmImage64 = resultFace!.extInfo!.toJson();
    var data = resultFace!.toJson();
    data.remove("extInfo");
    rmImage64.remove("imageContent");
    data.addAll(rmImage64);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("check result",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((e) {
              return Text("${e.key} : ${e.value}");
            }).toList()),
      ],
    );
  }

  ElevatedButton _openZolozBtn() {
    return ElevatedButton(
        onPressed: _openZoloz(), child: const Text("face detect"));
  }

  void Function() _openZoloz() {
    return () async {
      setLoading(true);
      var _metaInfo = await ZolozkitForFlutter.metaInfo;
      var _initFaceRes = await initFace(_metaInfo);
      await zolozSdk(_initFaceRes);
    };
  }

  Future<ZolozMicroServicesResponse> initFace(String? metaInfo) async {
    var response = await Dio().post(URL + FACE_INIT, data: metaInfo);
    var _res = ZolozMicroServicesResponse.fromJson(response.data);
    return _res;
  }

  CheckFaceResult? resultFace;

  Future<void> zolozSdk(ZolozMicroServicesResponse _initFaceRes) async {
    var _zolozInit = await ZolozkitForFlutter.start(_initFaceRes.clientCfg!, {},
        (res) async {
      if (res) {
        var _res = await checkResult(_initFaceRes.transactionId!);
        resultFace = CheckFaceResult.fromJson((_res as Response<dynamic>).data);
        setLoading(false);
      } else {
        setLoading(false);
        return;
      }
    });
  }

  Future<dynamic> checkResult(String transactionId) async {
    try {
      var res = await Dio().post('$URL$FACE_RESULT', data: transactionId);
      return res;
    } catch (e) {
      return "$e";
    }
  }

  Image imageFromBase64String(String base64String) {
    return Image.memory(base64Decode(base64String));
  }
}

class ZolozMicroServicesResponse {
  ZolozMicroServicesResponse({
    this.result,
    this.clientCfg,
    this.transactionId,
  });
  Result? result;
  String? clientCfg;
  String? transactionId;

  ZolozMicroServicesResponse.fromJson(Map<String, dynamic> json) {
    result = Result.fromJson(json['result']);
    clientCfg = json['clientCfg'];
    transactionId = json['transactionId'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['result'] = result?.toJson();
    _data['clientCfg'] = clientCfg;
    _data['transactionId'] = transactionId;
    return _data;
  }
}

class Result {
  Result({
    this.resultStatus,
    this.resultCode,
    this.resultMessage,
  });
  String? resultStatus;
  String? resultCode;
  String? resultMessage;

  Result.fromJson(Map<String, dynamic> json) {
    resultStatus = json['resultStatus'];
    resultCode = json['resultCode'];
    resultMessage = json['resultMessage'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['resultStatus'] = resultStatus;
    _data['resultCode'] = resultCode;
    _data['resultMessage'] = resultMessage;
    return _data;
  }
}

class CheckFaceResult {
  CheckFaceResult({
    this.result,
    this.extInfo,
  });
  Result? result;
  ExtInfo? extInfo;

  CheckFaceResult.fromJson(Map<String, dynamic> json) {
    result = Result.fromJson(json['result']);
    extInfo = ExtInfo.fromJson(json['extInfo']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['result'] = result?.toJson();
    _data['extInfo'] = extInfo?.toJson();
    return _data;
  }
}

class ExtInfo {
  ExtInfo({
    this.imageContent,
    this.rect,
    this.retryCount,
    this.faceAttack,
    this.quality,
  });
  String? imageContent;
  Rect? rect;
  int? retryCount;
  bool? faceAttack;
  String? quality;

  ExtInfo.fromJson(Map<String, dynamic> json) {
    imageContent = json['imageContent'];
    rect = Rect.fromJson(json['rect']);
    retryCount = json['retryCount'];
    faceAttack = json['faceAttack'];
    quality = json['quality'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['imageContent'] = imageContent;
    _data['rect'] = rect?.toJson();
    _data['retryCount'] = retryCount;
    _data['faceAttack'] = faceAttack;
    _data['quality'] = quality;
    return _data;
  }
}

class Rect {
  Rect({
    this.top,
    this.left,
    this.bottom,
    this.right,
  });
  int? top;
  int? left;
  int? bottom;
  int? right;

  Rect.fromJson(Map<String, dynamic> json) {
    top = json['top'];
    left = json['left'];
    bottom = json['bottom'];
    right = json['right'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['top'] = top;
    _data['left'] = left;
    _data['bottom'] = bottom;
    _data['right'] = right;
    return _data;
  }
}
