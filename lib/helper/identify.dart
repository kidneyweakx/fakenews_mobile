import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

import 'dart:async';

class Identify {
  final api = 'https://fakenews.nsysu.me/api/upload';
  Future<String> get localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return ('${dir.path}/Pictures/tmp.jpg');
  }

  Future<void> writeImg(Uint8List byteList) async {
    var path = await localPath;
    File img = new File(path);
    img.writeAsBytesSync(byteList);
  }

  Future<String> readText() async {
    Dio dio = new Dio();
    var path = await localPath;
    dio.options.headers = {"content-type": "multipart/form-dataitem"};
    FormData formData =
        FormData.fromMap({"image": await MultipartFile.fromFile(path)});
    print(api);
    Response res = await dio.post(api, data: formData);
    return(res.data.toString());
  }
}
