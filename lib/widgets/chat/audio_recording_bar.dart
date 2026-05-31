import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

typedef OnAudioReady = void Function(Uint8List bytes, int seconds, String ext);

class AudioRecordingBar extends StatefulWidget {
  final Color accentColor;
  final OnAudioReady onSend;
  final VoidCallback onCancel;
  final VoidCallback? onPermissionDenied;

  const AudioRecordingBar({
    super.key,
    required this.accentColor,
    required this.onSend,
    required this.onCancel,
    this.onPermissionDenied,
  });

  @override
  State<AudioRecordingBar> createState() => _AudioRecordingBarState();
}

class _AudioRecordingBarState extends State<AudioRecordingBar> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      widget.onPermissionDenied?.call();
      widget.onCancel();
      return;
    }
    const config = RecordConfig(
      encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
    );
    final String path;
    if (kIsWeb) {
      path = '';
    } else {
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      path = '${dir.path}/vocal_$ts.m4a';
    }
    if (!mounted) return;
    await _recorder.start(config, path: path);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopAndSend() async {
    if (_sending) return;
    setState(() => _sending = true);
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted || path == null || path.isEmpty) {
      widget.onCancel();
      return;
    }
    try {
      final Uint8List bytes;
      final String ext;
      if (kIsWeb) {
        ext = 'webm';
        final response = await http.get(Uri.parse(path));
        bytes = response.bodyBytes;
      } else {
        ext = 'm4a';
        bytes = await XFile(path).readAsBytes();
      }
      widget.onSend(bytes, _seconds, ext);
    } catch (_) {
      if (mounted) widget.onCancel();
    }
  }

  void _cancel() {
    _timer?.cancel();
    _recorder.stop();
    widget.onCancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: SafeArea(
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            onPressed: _cancel,
          ),
          const SizedBox(width: 6),
          const _PulsingDot(color: Colors.redAccent),
          const SizedBox(width: 8),
          Text(
            _timeLabel,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Text(
            'Enregistrement...',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          _sending
              ? const SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : GestureDetector(
                  onTap: _stopAndSend,
                  child: CircleAvatar(
                    backgroundColor: widget.accentColor,
                    radius: 22,
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
        ]),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
