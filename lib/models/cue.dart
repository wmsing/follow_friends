class Cue {
  const Cue({
    required this.start,
    required this.end,
    required this.text,
  });

  final Duration start;
  final Duration end;
  final String text;

  bool contains(Duration position) {
    return position >= start && position < end;
  }
}

Cue? activeCue(List<Cue> cues, Duration position) {
  final index = activeCueIndex(cues, position);
  if (index == null) return null;
  return cues[index];
}

int? activeCueIndex(List<Cue> cues, Duration position) {
  for (var i = 0; i < cues.length; i++) {
    if (cues[i].contains(position)) return i;
  }
  return null;
}

/// Index for lyrics UI: exact match, or hold previous line in gaps between cues.
int? lyricDisplayCueIndex(List<Cue> cues, Duration position) {
  if (cues.isEmpty) return null;

  int? lastStarted;
  for (var i = 0; i < cues.length; i++) {
    if (position < cues[i].start) {
      return lastStarted ?? 0;
    }
    lastStarted = i;
    if (cues[i].contains(position)) return i;
  }
  return lastStarted;
}

/// Window around the active cue: [before] earlier + active + [after] later.
List<int> lyricVisibleCueIndices(
  int? activeIndex,
  int cueCount, {
  int before = 2,
  int after = 2,
  int? pinnedCueIndex,
}) {
  if (cueCount == 0) return [];

  final indices = <int>{};
  if (activeIndex != null) {
    final from = (activeIndex - before).clamp(0, cueCount - 1);
    final to = (activeIndex + after).clamp(0, cueCount - 1);
    for (var i = from; i <= to; i++) {
      indices.add(i);
    }
  }
  if (pinnedCueIndex != null &&
      pinnedCueIndex >= 0 &&
      pinnedCueIndex < cueCount) {
    indices.add(pinnedCueIndex);
  }
  if (indices.isEmpty) return [];
  final sorted = indices.toList()..sort();
  return sorted;
}
