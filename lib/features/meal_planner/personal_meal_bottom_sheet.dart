import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';

class PersonalMealCreatedResult {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  const PersonalMealCreatedResult({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class PersonalMealBottomSheet extends ConsumerStatefulWidget {
  final String? entryId; // null = create mode

  const PersonalMealBottomSheet({super.key, this.entryId});

  @override
  ConsumerState<PersonalMealBottomSheet> createState() => _PersonalMealBottomSheetState();
}

class _PersonalMealBottomSheetState extends ConsumerState<PersonalMealBottomSheet> with SingleTickerProviderStateMixin {
  final _logger = appLogger;
  late TabController _tabController;
  final TextEditingController _descriptionController = TextEditingController();
  
  // Controllers for editable results
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calController = TextEditingController();
  final TextEditingController _protController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String? _imageBase64;
  String? _mimeType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _calController.dispose();
    _protController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    _logger.userAction('Pick image tapped', screen: 'PersonalMealBottomSheet', metadata: {'source': source.name});
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 70);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBase64 = base64Encode(bytes);
          _mimeType = 'image/jpeg';
        });
      }
    } catch (e, st) {
      _logger.e('🚫 Permission: pickImage denied or failed | source: ${source.name} | $e', error: e, stackTrace: st);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealPlannerError(e.toString()))),
        );
      }
    }
  }

  void _analyze() {
    _logger.userAction('Analyser avec l\'IA tapped', screen: 'PersonalMealBottomSheet');
    ref.read(personalMealSwapProvider.notifier).analyze(
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
      imageBase64: _imageBase64,
      mimeType: _mimeType,
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    _logger.userAction(
      widget.entryId == null ? 'Ajouter la collation tapped' : 'Confirmer ce repas tapped',
      screen: 'PersonalMealBottomSheet',
      metadata: {'entryId': widget.entryId},
    );
    if (widget.entryId == null) {
      if (_nameController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le nom du repas ne peut pas être vide.')),
          );
        }
        return;
      }
      _logger.provider('PersonalMealBottomSheet → create mode pop | name: ${_nameController.text.trim()} | kcal: ${_calController.text.trim()}');
      // create mode — return data to caller, no DB write
      if (mounted) {
        Navigator.of(context).pop(PersonalMealCreatedResult(
          name: _nameController.text.trim(),
          calories: double.tryParse(_calController.text.trim()) ?? 0,
          proteinG: double.tryParse(_protController.text.trim()) ?? 0,
          carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
          fatG: double.tryParse(_fatController.text.trim()) ?? 0,
        ));
      }
      return;
    }
    // swap mode — save via RPC then dismiss
    setState(() => _isSaving = true);
    try {
      await ref.read(personalMealSwapProvider.notifier).save(
        entryId: widget.entryId!,
        mealName: _nameController.text.trim(),
        calories: double.tryParse(_calController.text.trim()) ?? 0,
        proteinG: double.tryParse(_protController.text.trim()) ?? 0,
        carbsG: double.tryParse(_carbsController.text.trim()) ?? 0,
        fatG: double.tryParse(_fatController.text.trim()) ?? 0,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mealPlannerError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('PersonalMealBottomSheet build() | entryId: ${widget.entryId}');
    final analysisState = ref.watch(personalMealSwapProvider);

    // Sync controllers when analysis succeeds — mounted guard prevents writes to disposed controllers.
    ref.listen<AsyncValue<PersonalMealAnalysisResult?>>(personalMealSwapProvider, (prev, next) {
      if (!mounted) return;
      final data = next.valueOrNull;
      if (data != null && prev?.valueOrNull != data) {
        _nameController.text = data.mealName;
        _calController.text = data.calories.toString();
        _protController.text = data.proteinG.toString();
        _carbsController.text = data.carbsG.toString();
        _fatController.text = data.fatG.toString();
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AkeliColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AkeliColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.entryId == null ? 'Ajouter une collation personnelle' : 'Saisir un repas personnel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (analysisState.valueOrNull == null) ...[
              TabBar(
                controller: _tabController,
                indicatorColor: AkeliColors.primary,
                labelColor: AkeliColors.primary,
                unselectedLabelColor: AkeliColors.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Description'),
                  Tab(text: 'Photo'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Description Tab
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Poulet yassa maison avec riz blanc, portion normale',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    // Photo Tab
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Caméra'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.image),
                                label: const Text('Galerie'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_imageBase64 != null)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(_imageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            const Expanded(
                              child: Center(
                                child: Text('Aucune photo sélectionnée', style: TextStyle(color: AkeliColors.onSurfaceVariant)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_descriptionController.text.isNotEmpty || _imageBase64 != null) && !analysisState.isLoading
                        ? _analyze
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: analysisState.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Analyser avec l\'IA'),
                  ),
                ),
              ),
            ] else ...[
              // Analysis Result
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildConfidenceChip(analysisState.valueOrNull!.confidence),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nom du repas', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Kcal', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _protController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prot (g)', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Glucides (g)', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: _fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Lipides (g)', border: OutlineInputBorder()))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Vous pouvez modifier manuellement les valeurs ci-dessus si nécessaire.',
                      style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.entryId == null ? 'Ajouter la collation' : 'Confirmer ce repas'),
                  ),
                ),
              ),
            ],
            if (analysisState.hasError)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.mealPlannerError(analysisState.error.toString()), style: const TextStyle(color: AkeliColors.error)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceChip(String confidence) {
    Color bg;
    Color fg;
    String text;
    if (confidence == 'high') {
      bg = AkeliColors.primary.withValues(alpha: 0.15);
      fg = AkeliColors.primary;
      text = '✓ Confiance élevée';
    } else if (confidence == 'medium') {
      bg = AkeliColors.accentAmber.withValues(alpha: 0.15);
      fg = AkeliColors.accentAmber;
      text = '~ Estimation moyenne';
    } else {
      bg = AkeliColors.error.withValues(alpha: 0.15);
      fg = AkeliColors.error;
      text = '? Confiance faible';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
