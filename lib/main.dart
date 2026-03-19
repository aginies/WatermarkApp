import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import 'watermark_processor.dart';

class _ProcessedFile {
  const _ProcessedFile({
    required this.sourcePath,
    required this.result,
  });

  final String sourcePath;
  final ProcessResult result;
}

void main() {
  runApp(const WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watermark App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126A5A)),
        useMaterial3: true,
      ),
      home: const WatermarkPage(),
    );
  }
}

class WatermarkPage extends StatefulWidget {
  const WatermarkPage({super.key});

  @override
  State<WatermarkPage> createState() => _WatermarkPageState();
}

class _WatermarkPageState extends State<WatermarkPage> {
  final TextEditingController _textController = TextEditingController();
  double _transparency = 90;
  double _density = 35;
  bool _useRandomColor = true;
  Color _selectedColor = Colors.red;
  bool _dragging = false;
  bool _processing = false;
  String _statusMessage = '';
  List<String> _selectedPaths = <String>[];
  List<_ProcessedFile> _processedFiles = <_ProcessedFile>[];
  int _previewIndex = 0;

  bool get _supportsDesktopDrop =>
      !kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows);

  _ProcessedFile? get _currentProcessedFile {
    if (_processedFiles.isEmpty) {
      return null;
    }
    final safeIndex = _previewIndex.clamp(0, _processedFiles.length - 1);
    return _processedFiles[safeIndex];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark App'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final controls = _buildControlsPanel(theme);
                final preview = _buildPreviewPanel(theme);

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 360,
                          child: SingleChildScrollView(child: controls),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: preview),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      controls,
                      const SizedBox(height: 16),
                      SizedBox(height: 420, child: preview),
                    ],
                  ),
                );
              },
            ),
            if (_processing) _buildLoadingOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsPanel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextCard(),
        const SizedBox(height: 16),
        _buildPrimaryActionCard(),
        const SizedBox(height: 16),
        _buildColorCard(),
        const SizedBox(height: 16),
        _buildActionButtons(),
        const SizedBox(height: 16),
        Text(
          _statusMessage,
          style: theme.textTheme.bodyMedium,
        ),
        if (_processedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Ready to save ${_processedFiles.length} file${_processedFiles.length == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (_supportsDesktopDrop) ...[
          const SizedBox(height: 16),
          _buildDropArea(),
        ],
      ],
    );
  }

  Widget _buildPreviewPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: _processedFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedPaths.isEmpty
                        ? 'Enter watermark text and pick one or more image or PDF files'
                        : 'Files selected. Click Apply Watermark to generate previews',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  File(_currentProcessedFile!.sourcePath).uri.pathSegments.last,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: PageView.builder(
                      itemCount: _processedFiles.length,
                      onPageChanged: (index) {
                        setState(() {
                          _previewIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final previewBytes = _processedFiles[index].result.previewBytes;
                        if (previewBytes == null) {
                          return Center(
                            child: Text(
                              'Preview unavailable',
                              style: theme.textTheme.bodyMedium,
                            ),
                          );
                        }

                        return Image.memory(previewBytes, fit: BoxFit.contain);
                      },
                    ),
                  ),
                ),
                if (_processedFiles.length > 1) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Swipe left for next, right for previous (${_previewIndex + 1}/${_processedFiles.length})',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    final message = _statusMessage.isEmpty ? 'Processing file...' : _statusMessage;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.18),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text('Applying watermark...', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard() {
    final selectedCount = _selectedPaths.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _processing ? null : _pickFile,
              icon: const Icon(Icons.file_open),
              label: const Text('Pick Image or PDF Files'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
            if (selectedCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                selectedCount == 1
                    ? 'Selected file: ${File(_selectedPaths.first).uri.pathSegments.last}'
                    : 'Selected files: $selectedCount',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _processing || _selectedPaths.isEmpty ? null : _applyWatermark,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Apply Watermark'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            FilledButton.icon(
              onPressed: _processing || _processedFiles.isEmpty ? null : _saveCurrent,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save All'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            FilledButton.icon(
              onPressed: _processing || _processedFiles.isEmpty ? null : _shareCurrent,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share All'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _processing ? null : _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _textController,
          enabled: !_processing,
          decoration: const InputDecoration(
            labelText: 'Watermark text',
            hintText: 'Enter the text to stamp with date and time',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _buildColorCard() {
    const palette = <Color>[
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.yellow,
      Colors.white,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            final selectionControls = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: true, label: Text('Random color')),
                    ButtonSegment<bool>(value: false, label: Text('Selected color')),
                  ],
                  selected: <bool>{_useRandomColor},
                  onSelectionChanged: _processing
                      ? null
                      : (selection) {
                          _updateColorMode(selection.first);
                        },
                ),
                if (!_useRandomColor) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: palette.map((color) {
                      final isSelected = color.value == _selectedColor.value;
                      return InkWell(
                        onTap: _processing
                            ? null
                            : () => _selectColor(color),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.grey.shade400,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            );

            final sliders = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransparencyControl(),
                const SizedBox(height: 18),
                _buildDensityControl(),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: selectionControls),
                  const SizedBox(width: 20),
                  SizedBox(width: 220, child: sliders),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                selectionControls,
                const SizedBox(height: 16),
                sliders,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransparencyControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transparency: ${_transparency.round()}%'),
        Slider(
          value: _transparency,
          min: 10,
          max: 90,
          divisions: 80,
          onChanged: _processing
              ? null
              : (value) {
                  setState(() {
                    _transparency = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildDensityControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Density: ${_density.round()}%'),
        Slider(
          value: _density,
          min: 20,
          max: 100,
          divisions: 16,
          onChanged: _processing
              ? null
              : (value) {
                  setState(() {
                    _density = value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildTransparencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Watermark transparency: ${_transparency.round()}%'),
            Slider(
              value: _transparency,
              min: 10,
              max: 90,
              divisions: 80,
              onChanged: _processing
                  ? null
                  : (value) {
                      setState(() {
                        _transparency = value;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropArea() {
    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          _dragging = false;
        });
      },
      onDragDone: (detail) async {
        setState(() {
          _dragging = false;
        });

        if (detail.files.isEmpty) {
          return;
        }

        final paths = detail.files
            .map((file) => file.path)
            .whereType<String>()
            .toSet()
            .toList();
        if (paths.isEmpty) {
          setState(() {
            _statusMessage = 'The dropped file paths are unavailable.';
          });
          return;
        }

        _selectPaths(paths);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _dragging ? const Color(0xFFE1F3EE) : const Color(0xFFF7F7F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _dragging ? const Color(0xFF126A5A) : const Color(0xFF9BB5AE),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_upload_outlined, size: 36),
            SizedBox(height: 10),
            Text('Desktop drop area'),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    const group = XTypeGroup(
      label: 'Images and PDFs',
      extensions: <String>['jpg', 'jpeg', 'png', 'pdf'],
      uniformTypeIdentifiers: <String>['public.jpeg', 'public.png', 'com.adobe.pdf'],
    );

    final files = await openFiles(acceptedTypeGroups: <XTypeGroup>[group]);
    if (files.isEmpty) {
      return;
    }

    _selectPaths(files.map((file) => file.path).toList());
  }

  void _selectPaths(List<String> paths) {
    final uniquePaths = paths.toSet().toList();

    setState(() {
      _selectedPaths = uniquePaths;
      _processedFiles = <_ProcessedFile>[];
      _previewIndex = 0;
      _statusMessage = uniquePaths.length == 1
          ? 'Selected ${File(uniquePaths.first).uri.pathSegments.last}. Click Apply Watermark.'
          : 'Selected ${uniquePaths.length} files. Click Apply Watermark.';
    });
  }

  Future<void> _processPaths(List<String> paths) async {
    setState(() {
      _processing = true;
      _processedFiles = <_ProcessedFile>[];
      _previewIndex = 0;
      _statusMessage = 'Processing 0/${paths.length} files...';
    });

    final processedFiles = <_ProcessedFile>[];

    try {
      for (var i = 0; i < paths.length; i++) {
        final path = paths[i];

        if (!mounted) {
          return;
        }

        setState(() {
          _statusMessage = 'Processing ${i + 1}/${paths.length}: ${File(path).uri.pathSegments.last}';
        });

        final result = await WatermarkProcessor.processFile(
          file: File(path),
          transparency: _transparency,
          density: _density,
          watermarkText: _textController.text,
          useRandomColor: _useRandomColor,
          selectedColorValue: _selectedColor.toARGB32(),
        );

        if (result != null) {
          processedFiles.add(_ProcessedFile(sourcePath: path, result: result));
        }
      }

      if (!mounted) {
        return;
      }

      if (processedFiles.isEmpty) {
        setState(() {
          _statusMessage = 'Unsupported file or processing failed.';
          _processing = false;
        });
        return;
      }

      setState(() {
        _processedFiles = processedFiles;
        _previewIndex = 0;
        _statusMessage = 'Preview ready for ${processedFiles.length} file${processedFiles.length == 1 ? '' : 's'}. You can save or share them.';
        _processing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Error: $error';
        _processing = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _dragging = false;
      _processing = false;
      _selectedPaths = <String>[];
      _processedFiles = <_ProcessedFile>[];
      _previewIndex = 0;
      _statusMessage = '';
    });
  }

  Future<void> _applyWatermark() async {
    if (_selectedPaths.isEmpty) {
      return;
    }
    await _processPaths(_selectedPaths);
  }

  Future<void> _saveCurrent() async {
    if (_processedFiles.isEmpty) {
      return;
    }

    for (final file in _processedFiles) {
      await File(file.result.outputPath).writeAsBytes(file.result.outputBytes);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = 'Saved ${_processedFiles.length} file${_processedFiles.length == 1 ? '' : 's'}.';
    });
  }

  Future<void> _shareCurrent() async {
    if (_processedFiles.isEmpty) {
      return;
    }

    for (final file in _processedFiles) {
      await File(file.result.outputPath).writeAsBytes(file.result.outputBytes);
    }

    final shareFiles = _processedFiles
        .map(
          (file) => XFile(
            file.result.outputPath,
            mimeType: _mimeTypeForPath(file.result.outputPath),
          ),
        )
        .toList();

    final result = await SharePlus.instance.share(
      ShareParams(
        files: shareFiles,
        subject: 'Watermarked files',
        text: 'Shared from Watermark App',
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = result.status == ShareResultStatus.success
          ? 'Shared ${_processedFiles.length} file${_processedFiles.length == 1 ? '' : 's'}.'
          : 'Share sheet opened for ${_processedFiles.length} file${_processedFiles.length == 1 ? '' : 's'}.';
    });
  }

  String _mimeTypeForPath(String path) {
    return switch (p.extension(path).toLowerCase()) {
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  void _updateColorMode(bool useRandomColor) {
    setState(() {
      _useRandomColor = useRandomColor;
    });
  }

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }
}
