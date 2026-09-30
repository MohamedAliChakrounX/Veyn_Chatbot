import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../l10n/translations.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class Composer extends StatefulWidget {
  final Function(String) onSend;
  final bool busy;

  const Composer({
    super.key,
    required this.onSend,
    required this.busy,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  late final AudioRecorder _audioRecorder;

  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordDuration = 0;
  String? _recordingPath;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Obtient le répertoire temporaire accessible par l'app (path_provider)
  Future<String> _getTempDir() async {
    try {
      if (kIsWeb) return '';
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    } catch (e) {
      debugPrint('[Composer] getTemporaryDirectory échoué, fallback systemTemp: $e');
      return Directory.systemTemp.path;
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('mic_permission_denied')),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      final tempDir = await _getTempDir();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Préférer WAV PCM 16kHz mono (optimal et sans artéfacts pour Whisper)
      // Si WAV non supporté par l'encodeur de la plateforme, utiliser AAC-LC 44.1kHz standard
      final supportsWav = await _audioRecorder.isEncoderSupported(AudioEncoder.wav);
      final encoder = supportsWav ? AudioEncoder.wav : AudioEncoder.aacLc;
      final ext = encoder == AudioEncoder.wav ? 'wav' : 'm4a';
      final sampleRate = encoder == AudioEncoder.wav ? 16000 : 44100;
      final bitRate = encoder == AudioEncoder.wav ? 128000 : 96000;

      final filePath = kIsWeb ? '' : '$tempDir/veyn_voice_$timestamp.$ext';
      _recordingPath = filePath;

      await _audioRecorder.start(
        RecordConfig(
          encoder: encoder,
          sampleRate: sampleRate,
          numChannels: 1, // Mono
          bitRate: bitRate,
        ),
        path: filePath,
      );

      debugPrint('[Composer] Enregistrement démarré ($encoder, $sampleRate Hz): $filePath');

      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordDuration++);
      });
    } catch (e) {
      debugPrint('[Composer] Erreur début enregistrement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('mic_error')} $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      final effectivePath = path ?? _recordingPath;
      if (effectivePath != null && !kIsWeb) {
        try { File(effectivePath).deleteSync(); } catch (_) {}
      }
    } catch (e) {
      debugPrint('[Composer] Erreur annulation: $e');
    }
    _recordingPath = null;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    _timer?.cancel();

    if (!mounted) return;
    // Capturer la langue avant les opérations asynchrones
    final lang = context.read<LanguageProvider>().languageCode;

    setState(() {
      _isRecording = false;
      _recordDuration = 0;
      _isTranscribing = true;
    });

    String? path;
    try {
      path = await _audioRecorder.stop();
    } catch (e) {
      debugPrint('[Composer] Erreur arrêt enregistrement: $e');
    }

    // Si stop() retourne null sur certaines plateformes, utiliser le chemin initial
    path ??= _recordingPath;
    _recordingPath = null;

    // Laisser un bref instant pour que les tampons d'écriture OS soient purgés sur disque
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('[Composer] Fichier audio cible: $path');
    if (path == null || path.isEmpty) {
      debugPrint('[Composer] Aucun chemin de fichier disponible');
      if (mounted) {
        setState(() => _isTranscribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('no_speech')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!kIsWeb) {
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('[Composer] Fichier audio introuvable sur le disque: $path');
        if (mounted) {
          setState(() => _isTranscribing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('no_speech')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      final sizeBytes = file.lengthSync();
      debugPrint('[Composer] Taille fichier audio: $sizeBytes bytes');
      // Un fichier audio vide ou sans entête exploitable fait moins de 50 octets
      if (sizeBytes < 50) {
        debugPrint('[Composer] Fichier audio vide ($sizeBytes bytes)');
        if (mounted) {
          setState(() => _isTranscribing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('no_speech')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        try { file.deleteSync(); } catch (_) {}
        return;
      }
    }

    // Transcription via Whisper Groq
    final text = await _apiService.transcribeAudio(path, language: lang);
    debugPrint('[Composer] Transcription reçue: "$text"');

    // Nettoyage fichier temporaire
    if (!kIsWeb) {
      try { File(path).deleteSync(); } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _isTranscribing = false);

    if (text != null && text.trim().isNotEmpty) {
      widget.onSend(text.trim());
      context.read<TripProvider>().closePanel();
    } else if (text == null) {
      // Erreur serveur / réseau
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de joindre le serveur de transcription. Vérifiez votre connexion.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Transcription vide = aucune parole détectée
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('no_speech')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    final tripProvider = context.read<TripProvider>();
    final canSend = !widget.busy &&
        !_isRecording &&
        !_isTranscribing &&
        (text.isNotEmpty || !tripProvider.trip.isEmpty);

    if (canSend) {
      widget.onSend(text);
      _controller.clear();
      tripProvider.closePanel();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = !widget.busy &&
        !_isRecording &&
        !_isTranscribing &&
        (hasText || !tripProvider.trip.isEmpty);

    return Container(
      decoration: BoxDecoration(
        color: VeynColors.surfaceSunken,
        border: const Border(top: BorderSide(color: VeynColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: VeynColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: VeynColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: _isRecording
            ? _buildRecordingRow()
            : _isTranscribing
                ? _buildTranscribingRow()
                : _buildInputRow(canSend, tripProvider),
      ),
    );
  }

  Widget _buildRecordingRow() {
    return Row(
      children: [
        const SizedBox(width: 8),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${context.tr('recording')}  ${_formatDuration(_recordDuration)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: VeynColors.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: _cancelRecording,
          tooltip: context.tr('cancel'),
          style: IconButton.styleFrom(
            foregroundColor: VeynColors.inkSoft,
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(LucideIcons.trash2, size: 20),
        ),
        IconButton(
          onPressed: _stopAndSendRecording,
          tooltip: context.tr('send_tooltip'),
          style: IconButton.styleFrom(
            backgroundColor: VeynColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(8),
          ),
          icon: const Icon(LucideIcons.check, size: 20),
        ),
      ],
    );
  }

  Widget _buildTranscribingRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: VeynColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            context.tr('transcribing'),
            style: const TextStyle(
              fontSize: 13,
              color: VeynColors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(bool canSend, TripProvider tripProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: context.tr('composer_placeholder'),
              hintStyle: const TextStyle(fontSize: 13, color: VeynColors.inkFaint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 14, color: VeynColors.ink),
          ),
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(bottom: 2, end: 4),
          child: IconButton(
            onPressed: widget.busy ? null : _startRecording,
            tooltip: context.tr('voice_tooltip'),
            style: IconButton.styleFrom(
              foregroundColor: VeynColors.inkSoft,
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(LucideIcons.mic, size: 18),
          ),
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(bottom: 2, end: 2),
          child: IconButton(
            onPressed: canSend ? _submit : null,
            tooltip: context.tr('send_tooltip'),
            style: IconButton.styleFrom(
              backgroundColor: canSend ? VeynColors.accent : VeynColors.lineStrong,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(LucideIcons.arrowUp, size: 18),
          ),
        ),
      ],
    );
  }
}
