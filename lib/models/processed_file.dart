import 'processor_models.dart';

class ProcessedFile {
  const ProcessedFile({
    required this.sourcePath,
    required this.result,
  });

  final String sourcePath;
  final ProcessResult result;
}
