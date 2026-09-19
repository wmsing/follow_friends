import 'package:flutter/material.dart';

class WordGloss extends StatelessWidget {
  const WordGloss({
    super.key,
    required this.word,
    required this.selected,
    this.gloss,
    this.loading = false,
    required this.onTap,
    this.lightOnDark = false,
    this.fontSize = 22,
    this.lineColor,
  });

  final String word;
  final bool lightOnDark;
  final double fontSize;
  final Color? lineColor;
  final bool selected;
  final String? gloss;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: fontSize,
                decoration: selected ? TextDecoration.underline : null,
                decorationColor: lineColor ?? theme.colorScheme.primary,
                decorationThickness: 2,
                color: lineColor ?? (lightOnDark ? Colors.white : null),
              ),
            ),
            if (selected && (loading || (gloss != null && gloss!.isNotEmpty)))
              SizedBox(
                height: 18,
                child: loading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Text(
                        gloss!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF1565C0),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
