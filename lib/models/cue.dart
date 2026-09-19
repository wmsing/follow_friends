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

/// Latest cue whose [start] has passed (karaoke-style). Switches at next
/// [start], not when the previous [end] elapses — avoids merged/long [end]
/// delaying the highlight.
int? activeCueIndex(List<Cue> cues, Duration position) {
  if (cues.isEmpty) return null;

  int? index;
  for (var i = 0; i < cues.length; i++) {
    if (cues[i].start > position) break;
    index = i;
  }
  return index ?? 0;
}

/// Index for lyrics window; same rule as [activeCueIndex].
int? lyricDisplayCueIndex(List<Cue> cues, Duration position) {
  return activeCueIndex(cues, position);
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
