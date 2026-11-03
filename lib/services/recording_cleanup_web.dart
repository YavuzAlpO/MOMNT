import 'package:web/web.dart' as web;

Future<void> releaseRecording(String path) async {
  web.URL.revokeObjectURL(path);
}
