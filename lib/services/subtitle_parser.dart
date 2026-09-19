import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/cue.dart';

List<Cue> cuesFromClosedCaptions(Iterable<ClosedCaption> captions) {
  return captions
      .map(
        (c) => Cue(
          start: c.offset,
          end: c.end,
          text: c.text.replaceAll('\n', ' ').trim(),
        ),
      )
      .where((c) => c.text.isNotEmpty)
      .toList();
}

bool subtitleEndsSentence(String text) {
  var trimmed = text.trimRight();
  if (trimmed.isEmpty) return false;
  while (trimmed.length > 1) {
    final last = trimmed[trimmed.length - 1];
    if (last == '"' || last == "'" || last == ')' || last == ']') {
      trimmed = trimmed.substring(0, trimmed.length - 1).trimRight();
      continue;
    }
    break;
  }
  if (trimmed.endsWith('...')) return true;
  final end = trimmed[trimmed.length - 1];
  return end == '.' || end == '?' || end == '!';
}

/// Merge YouTube caption fragments until a sentence ends with . ? or !
List<Cue> mergeCuesIntoSentences(List<Cue> raw) {
  if (raw.isEmpty) return [];

  final merged = <Cue>[];
  var text = '';
  Duration? start;
  Duration? end;

  void flush() {
    final line = text.trim();
    if (line.isEmpty || start == null || end == null) return;
    merged.add(Cue(start: start!, end: end!, text: line));
    text = '';
    start = null;
    end = null;
  }

  for (final cue in raw) {
    start ??= cue.start;
    end = cue.end;
    text = text.isEmpty ? cue.text : '$text ${cue.text}';
    if (subtitleEndsSentence(text)) {
      flush();
    }
  }
  flush();
  return merged;
}

/// Split subtitle line into tappable tokens (words + punctuation attached).
List<String> splitSubtitleWords(String text) {
  final normalized = text
      .replaceAll(RegExp(r' ([.,!?:;])'), r'$1')
      .replaceAll(RegExp(r" (['"")])"), r'$1')
      .replaceAll(' ...', '...');

  return normalized
      .split(RegExp(r'(\s+)'))
      .where((w) => w.trim().isNotEmpty)
      .toList();
}

String normalizeLookupWord(String token) {
  return token.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '').toLowerCase();
}

List<int> wordIndicesInRange(int anchor, int index) {
  final from = anchor < index ? anchor : index;
  final to = anchor > index ? anchor : index;
  return [for (var i = from; i <= to; i++) i];
}

String phraseFromIndices(List<String> words, List<int> indices) {
  return indices.map((i) => words[i]).join(' ');
}
