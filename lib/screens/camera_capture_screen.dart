import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:momnt/services/recording_cleanup.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  bool _loading = true;
  bool _taking = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final previous = _camera;
    _camera = null;
    await previous?.dispose();
    CameraController? next;
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', 'Kamera bulunamadı.');
      }
      if (!mounted || generation != _generation) return;
      next = CameraController(
        _cameras[_index],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      setState(() => _camera = next);
    } catch (error) {
      await next?.dispose();
      if (!mounted || generation != _generation) return;
      setState(
        () => _error = error is CameraException && error.code == 'NoCamera'
            ? 'Bu cihazda kamera bulunamadı.'
            : 'Kamera açılamadı. Kamera iznini ve başka bir uygulamanın kamerayı kullanıp kullanmadığını kontrol et.',
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _generation++;
      final camera = _camera;
      _camera = null;
      unawaited(camera?.dispose());
      if (mounted) setState(() => _loading = true);
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      unawaited(_initialize());
    }
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (_taking || camera == null || !camera.value.isInitialized) return;
    setState(() => _taking = true);
    try {
      final photo = await camera.takePicture();
      if (!mounted) {
        await releaseRecording(photo.path);
        return;
      }
      Navigator.pop(context, photo);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf çekilemedi. Yeniden dene.')),
        );
      }
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_camera?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Fotoğraf çek')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _initialize,
                              child: const Text('Tekrar dene'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : camera == null
                  ? const SizedBox.shrink()
                  : Center(child: CameraPreview(camera)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: 'Kamerayı değiştir',
                    color: Colors.white,
                    onPressed: _loading || _taking || _cameras.length < 2
                        ? null
                        : () {
                            _index = (_index + 1) % _cameras.length;
                            unawaited(_initialize());
                          },
                    icon: const Icon(Icons.cameraswitch_outlined),
                  ),
                  IconButton.filled(
                    key: const Key('camera-capture'),
                    tooltip: 'Fotoğraf çek',
                    iconSize: 48,
                    onPressed: _loading || _taking || camera == null
                        ? null
                        : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
