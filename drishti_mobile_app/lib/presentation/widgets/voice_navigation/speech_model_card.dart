/// Speech Model Download Widget
///
/// Shows download status and progress for the on-device Whisper STT model.
/// Can be used as a card in settings or as a standalone dialog.
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/voice_service.dart';

/// A card widget that shows STT model download status and allows downloading
class SpeechModelCard extends StatefulWidget {
  const SpeechModelCard({super.key});

  @override
  State<SpeechModelCard> createState() => _SpeechModelCardState();
}

class _SpeechModelCardState extends State<SpeechModelCard> {
  final VoiceService _voiceService = VoiceService();
  bool _isDownloading = false;
  double _progress = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    if (_voiceService.isModelsReady) {
      _status = 'Ready';
    } else if (_voiceService.isDownloading) {
      _status = 'Downloading...';
      _isDownloading = true;
    } else {
      _status = 'Not downloaded';
    }
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0;
      _status = 'Starting download...';
    });

    final success = await _voiceService.downloadModels(
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress.clamp(0.0, 1.0);
            _status = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        if (success) {
          _status = 'Ready';
        } else {
          _status = 'Download failed. Tap to retry.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = _voiceService.isModelsReady;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.record_voice_over,
                color: isReady ? Colors.green : AppColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Speech Recognition Model',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReady
                          ? 'Whisper Small (on-device) — $_status'
                          : 'Whisper Small — ${_voiceService.modelSizeString}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isReady && !_isDownloading)
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: isDark ? Colors.white12 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ],
          if (!isReady && !_isDownloading) ...[
            const SizedBox(height: 8),
            Text(
              'Required for voice commands. Downloads once, works offline.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Show a dialog prompting the user to download speech models
Future<bool> showSpeechModelDownloadDialog(BuildContext context) async {
  final voiceService = VoiceService();
  if (voiceService.isModelsReady) return true;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _SpeechModelDownloadDialog(),
  );

  return result ?? false;
}

class _SpeechModelDownloadDialog extends StatefulWidget {
  const _SpeechModelDownloadDialog();

  @override
  State<_SpeechModelDownloadDialog> createState() =>
      _SpeechModelDownloadDialogState();
}

class _SpeechModelDownloadDialogState
    extends State<_SpeechModelDownloadDialog> {
  final VoiceService _voiceService = VoiceService();
  bool _isDownloading = false;
  double _progress = 0;
  String _status = 'Voice recognition requires a one-time download.';
  bool _downloadComplete = false;
  bool _downloadFailed = false;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
      _status = 'Starting download...';
      _downloadFailed = false;
    });

    final success = await _voiceService.downloadModels(
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _progress = progress.clamp(0.0, 1.0);
            _status = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadComplete = success;
        _downloadFailed = !success;
        _status = success
            ? 'Speech model ready!'
            : 'Download failed. Please check your connection.';
      });

      if (success) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            _downloadComplete
                ? Icons.check_circle
                : Icons.record_voice_over_outlined,
            color: _downloadComplete ? Colors.green : AppColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Speech Recognition', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_status, style: Theme.of(context).textTheme.bodyMedium),
          if (!_isDownloading && !_downloadComplete) ...[
            const SizedBox(height: 12),
            Text(
              'Model: Whisper Small (${_voiceService.modelSizeString})\n'
              'Runs fully on-device — no internet needed after download.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading && !_downloadComplete)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
        if (!_isDownloading && !_downloadComplete)
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download, size: 18),
            label: Text(_downloadFailed ? 'Retry' : 'Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        if (_downloadComplete)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
      ],
    );
  }
}
