import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../core/logger.dart';
import '../../../providers/search_allergen_provider.dart';
import '../models/allergen_model.dart';
import '../../../core/supabase_client.dart';
import '../../../l10n/app_localizations.dart';

class AllergenPickerWidget extends ConsumerStatefulWidget {
  final List<AllergenModel> selectedAllergens;
  final ValueChanged<List<AllergenModel>> onChanged;

  const AllergenPickerWidget({
    super.key,
    required this.selectedAllergens,
    required this.onChanged,
  });

  @override
  ConsumerState<AllergenPickerWidget> createState() => _AllergenPickerWidgetState();
}

class _AllergenPickerWidgetState extends ConsumerState<AllergenPickerWidget> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addAllergy(AllergenModel a) {
    if (!widget.selectedAllergens.any((x) => x.id == a.id)) {
      widget.onChanged([...widget.selectedAllergens, a]);
    }
    _searchCtrl.clear();
    _focusNode.unfocus();
  }

  Future<void> _submitSuggestion() async {
    final txt = _query.trim();
    if (txt.isEmpty) return;

    _logger.userAction('Allergen suggested', screen: 'AllergenPicker', metadata: {'label': txt});
    _searchCtrl.clear();
    _focusNode.unfocus();

    final l10n = AppLocalizations.of(context);
    final client = ref.read(supabaseClientProvider);
    try {
      _logger.edge('submit-allergen-suggestion', 'BEFORE | label: $txt');
      await client.functions.invoke('submit-allergen-suggestion', body: {'label': txt});
      _logger.edge('submit-allergen-suggestion', 'AFTER | success');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allergenPickerSuggestionSent)),
        );
      }
    } catch (e, st) {
      _logger.edge('submit-allergen-suggestion', 'ERROR | $e', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchResultsAsync = ref.watch(searchAllergenProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                style: GoogleFonts.inter(fontSize: 14, color: AkeliColors.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.allergenPickerHint,
                  filled: true,
                  fillColor: AkeliColors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AkeliRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
                ),
                onSubmitted: (_) => _submitSuggestion(),
              ),
            ),
            const SizedBox(width: AkeliSpacing.sm),
            GestureDetector(
              onTap: _submitSuggestion,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AkeliColors.primary,
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        
        // Results Dropdown
        if (_query.isNotEmpty && _focusNode.hasFocus)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AkeliColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AkeliRadius.md),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: searchResultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return ListTile(
                    title: Text(l10n.allergenPickerAdd(_query), style: GoogleFonts.inter(fontSize: 14)),
                    leading: const Icon(Icons.add, size: 20),
                    onTap: _submitSuggestion,
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final a = results[i];
                    return ListTile(
                      title: Text(a.label, style: GoogleFonts.inter(fontSize: 14)),
                      onTap: () => _addAllergy(a),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.commonError, style: GoogleFonts.inter(color: Colors.red)),
              ),
            ),
          ),
          
        if (widget.selectedAllergens.isNotEmpty) ...[
          const SizedBox(height: AkeliSpacing.md),
          Wrap(
            spacing: AkeliSpacing.sm,
            runSpacing: AkeliSpacing.sm,
            children: widget.selectedAllergens.map((a) {
              return Chip(
                label: Text(a.label, style: GoogleFonts.inter(fontSize: 13, color: AkeliColors.onSurface)),
                backgroundColor: AkeliColors.surfaceContainerLow,
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () {
                  widget.onChanged(widget.selectedAllergens.where((x) => x.id != a.id).toList());
                },
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.pill)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
