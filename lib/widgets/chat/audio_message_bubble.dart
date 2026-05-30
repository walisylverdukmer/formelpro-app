import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudioMessageBubble extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final bool isMe;
  final Color accentColor;
  final DateTime? timestamp;

  const AudioMessageBubble({
    super.key,
    required this.audioUrl,
    required this.isMe,
    required this.accentColor,
    this.durationSeconds,
    this.timestamp,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null) {
      _total = Duration(seconds: widget.durationSeconds!);
    }
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) {
        setState(() => _state = s);
        if (s == PlayerState.completed) {
          setState(() => _position = Duration.zero);
        }
      }
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final bgColor =
        widget.isMe ? widget.accentColor : const Color(0xFFE2E8F0);
    final textColor =
        widget.isMe ? Colors.white : const Color(0xFF1E293B);
    final iconColor = widget.isMe ? Colors.white : widget.accentColor;
    final activeTrack =
        widget.isMe ? Colors.white : widget.accentColor;
    final inactiveTrack = widget.isMe
        ? Colors.white.withValues(alpha: 0.35)
        : widget.accentColor.withValues(alpha: 0.2);

    final totalSec = _total.inSeconds > 0 ? _total.inSeconds : 1;
    final progress = (_position.inSeconds / totalSec).clamp(0.0, 1.0);
    final label = isPlaying ? _fmt(_position) : _fmt(_total);

    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
        constraints: const BoxConstraints(maxWidth: 256),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              GestureDetector(
                onTap: _togglePlay,
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: iconColor,
                  size: 38,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                        overlayShape:
                            SliderComponentShape.noOverlay,
                        trackHeight: 3,
                        activeTrackColor: activeTrack,
                        inactiveTrackColor: inactiveTrack,
                        thumbColor: activeTrack,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (v) {
                          final pos = Duration(
                              seconds: (v * totalSec).round());
                          _player.seek(pos);
                        },
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            if (widget.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${widget.timestamp!.hour.toString().padLeft(2, '0')}:'
                  '${widget.timestamp!.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
