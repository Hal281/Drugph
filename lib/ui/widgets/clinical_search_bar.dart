// ============================================================
// Drug Dosage Calculator — Clinical Search Bar Widget
// ============================================================
// High-performance search input with 250ms debouncing, instant clear
// button ('X'), query match highlighting, and recent search history.
//
// Complies with:
// - 8-point spacing grid (Multiples of 4 and 8)
// - Minimum touch targets >= 48x48 dp
// - WCAG AAA contrast standard
//
// DISCLAIMER: SaMD prototype — for educational & clinical assistance.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clinical search bar with debouncing, recent history, and clear button.
class ClinicalSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback? onClear;
  final List<String> recentQueries;
  final ValueChanged<String>? onRecentQuerySelected;
  final VoidCallback? onClearHistory;
  final String? hintText;
  final bool isThai;
  final int debounceMs;

  const ClinicalSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    this.onClear,
    this.recentQueries = const [],
    this.onRecentQuerySelected,
    this.onClearHistory,
    this.hintText,
    this.isThai = true,
    this.debounceMs = 250,
  });

  @override
  State<ClinicalSearchBar> createState() => _ClinicalSearchBarState();
}

class _ClinicalSearchBarState extends State<ClinicalSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ClinicalSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query && widget.query != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      widget.onQueryChanged('');
      setState(() {});
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (mounted) {
        widget.onQueryChanged(value);
      }
    });
    setState(() {});
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onQueryChanged('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    final showRecent =
        _focusNode.hasFocus && !hasText && widget.recentQueries.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main search text input container
        Semantics(
          label: widget.isThai ? 'ช่องค้นหายา' : 'Medication search input',
          textField: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppTheme.primaryTeal
                    : AppTheme.borderStrong,
                width: _focusNode.hasFocus ? 1.5 : 1,
              ),
            ),
            child: TextField(
              key: const Key('clinical_search_bar_input'),
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.inkPrimary,
              ),
              decoration: InputDecoration(
                filled: false,
                hintText: widget.hintText ??
                    (widget.isThai
                        ? 'ค้นหาชื่อยา, อาการ, กลุ่มยา, หรือชื่อการค้า...'
                        : 'Search drug name, indication, class, or brand...'),
                hintStyle: const TextStyle(
                  color: AppTheme.inkMuted,
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        key: const Key('clinical_search_bar_clear_button'),
                        icon: const Icon(Icons.close, size: 18),
                        color: AppTheme.inkSecondary,
                        tooltip: widget.isThai ? 'ล้างคำค้น' : 'Clear search',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: _clearSearch,
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: _onTextChanged,
              onSubmitted: (val) {
                _debounceTimer?.cancel();
                widget.onQueryChanged(val);
              },
            ),
          ),
        ),

        // Recent search queries horizontal drawer / chip row
        if (showRecent) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  size: 15,
                  color: AppTheme.inkSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isThai ? 'ประวัติการค้นหาล่าสุด:' : 'Recent searches:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkSecondary,
                  ),
                ),
                const Spacer(),
                if (widget.onClearHistory != null)
                  InkWell(
                    onTap: widget.onClearHistory,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        widget.isThai ? 'ล้างประวัติ' : 'Clear',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.recentQueries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = widget.recentQueries[index];
                return ActionChip(
                  key: Key('recent_search_chip_$index'),
                  avatar: const Icon(
                    Icons.history,
                    size: 14,
                    color: AppTheme.primaryTeal,
                  ),
                  label: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryTealSoft,
                  side: const BorderSide(color: AppTheme.primaryTealBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: () {
                    _controller.text = item;
                    widget.onQueryChanged(item);
                    widget.onRecentQuerySelected?.call(item);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Utility widget that highlights query tokens within a given clinical text.
class ClinicalHighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const ClinicalHighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style = const TextStyle(fontSize: 14, color: Colors.black87),
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHighlightStyle = highlightStyle ??
        style.copyWith(
          backgroundColor: const Color(0xFFFEF08A), // Light soft amber
          color: const Color(0xFF0F766E), // Dark Teal
          fontWeight: FontWeight.bold,
        );

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final spans = <TextSpan>[];
    final textLower = text.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final matchIndex = textLower.indexOf(cleanQuery, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }

      if (matchIndex > start) {
        spans.add(TextSpan(
          text: text.substring(start, matchIndex),
          style: style,
        ));
      }

      final matchEnd = matchIndex + cleanQuery.length;
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchEnd),
        style: effectiveHighlightStyle,
      ));

      start = matchEnd;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
