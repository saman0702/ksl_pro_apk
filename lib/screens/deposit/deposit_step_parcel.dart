import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/katian_theme_extension.dart';
import '../../core/theme.dart';
import '../../data/package_formats.dart';
import '../../models/models.dart';
import '../../utils/deposit_item_logic.dart';

class DepositStepParcel extends StatefulWidget {
  const DepositStepParcel({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final ExpeditionDraft draft;
  final VoidCallback onChanged;

  @override
  State<DepositStepParcel> createState() => _DepositStepParcelState();
}

class _DepositStepParcelState extends State<DepositStepParcel> {
  final _current = CurrentDraftItem();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _weightCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _valeurCtrl = TextEditingController();
  final _pourcentageCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _descriptionAutresCtrl = TextEditingController();

  bool _valeurChecked = false;
  bool _pourcentageChecked = false;
  bool _montantChecked = false;

  final _currency = NumberFormat('#,##0', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _syncAmountFieldsFromDraft();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _valeurCtrl.dispose();
    _pourcentageCtrl.dispose();
    _montantCtrl.dispose();
    _descriptionAutresCtrl.dispose();
    super.dispose();
  }

  void _syncAmountFieldsFromDraft() {
    final d = widget.draft;
    if (d.valeurDeclaree > 0) {
      _valeurCtrl.text = d.valeurDeclaree.toStringAsFixed(0);
    }
    if (d.pourcentageApplique > 0) {
      _pourcentageCtrl.text = d.pourcentageApplique.toStringAsFixed(1);
    }
    if (d.montant > 0) {
      _montantCtrl.text = d.montant.toStringAsFixed(0);
    }
    if (!ColisDescriptions.isPredefined(d.descriptionColis) &&
        d.descriptionColis.isNotEmpty &&
        d.descriptionColis != ColisDescriptions.autres) {
      _descriptionAutresCtrl.text = d.descriptionColis;
    }
  }

  void _notify() {
    widget.onChanged();
    setState(() {});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  PackageFormat? get _selectedFormat =>
      PackageFormats.byId(_current.packageFormat);

  bool get _showCustomDimensions => _selectedFormat?.isCustom == true;

  String get _descriptionDropdownValue {
    final d = widget.draft.descriptionColis;
    if (ColisDescriptions.predefined.contains(d)) return d;
    if (d.isNotEmpty) return ColisDescriptions.autres;
    return '';
  }

  bool get _showDescriptionAutres =>
      widget.draft.descriptionColis == ColisDescriptions.autres ||
      (!ColisDescriptions.isPredefined(widget.draft.descriptionColis) &&
          widget.draft.descriptionColis.isNotEmpty);

  void _addItem() {
    _current.name = _nameCtrl.text.trim();
    _current.quantity = int.tryParse(_qtyCtrl.text) ?? 1;
    if (_showCustomDimensions) {
      _current.weight = double.tryParse(_weightCtrl.text) ?? 0;
      _current.length = double.tryParse(_lengthCtrl.text) ?? 0;
      _current.width = double.tryParse(_widthCtrl.text) ?? 0;
      _current.height = double.tryParse(_heightCtrl.text) ?? 0;
    }

    final error = DepositItemLogic.validateAddItem(
      current: _current,
      existingItems: widget.draft.pickupItems,
    );
    if (error != null) {
      _snack(error);
      return;
    }

    widget.draft.pickupItems
        .add(DepositItemLogic.buildPickupItem(_current));
    _current.resetKeepCategory();
    _nameCtrl.clear();
    _qtyCtrl.text = '1';
    _weightCtrl.clear();
    _lengthCtrl.clear();
    _widthCtrl.clear();
    _heightCtrl.clear();
    _notify();
  }

  void _removeItem(int index) {
    widget.draft.pickupItems.removeAt(index);
    _notify();
  }

  void _onValeurChanged(String raw) {
    final d = widget.draft;
    final valeur = double.tryParse(raw) ?? 0;
    d.valeurDeclaree = valeur;
    if (_valeurChecked &&
        _pourcentageChecked &&
        !_montantChecked &&
        d.pourcentageApplique > 0 &&
        valeur > 0) {
      d.montant = ((valeur * d.pourcentageApplique) / 100).roundToDouble();
      _montantCtrl.text = d.montant.toStringAsFixed(0);
    } else if (_valeurChecked &&
        _montantChecked &&
        !_pourcentageChecked &&
        d.montant > 0 &&
        valeur > 0) {
      d.pourcentageApplique =
          ((d.montant / valeur) * 100 * 10).roundToDouble() / 10;
      _pourcentageCtrl.text = d.pourcentageApplique.toStringAsFixed(1);
    }
    _notify();
  }

  void _onPourcentageChanged(String raw) {
    final d = widget.draft;
    final pct = double.tryParse(raw) ?? 0;
    d.pourcentageApplique = pct;
    if (_pourcentageChecked &&
        _montantChecked &&
        !_valeurChecked &&
        d.montant > 0 &&
        pct > 0) {
      d.valeurDeclaree = ((d.montant * 100) / pct).roundToDouble();
      _valeurCtrl.text = d.valeurDeclaree.toStringAsFixed(0);
    } else if (_valeurChecked &&
        _pourcentageChecked &&
        !_montantChecked &&
        d.valeurDeclaree > 0 &&
        pct > 0) {
      d.montant = ((d.valeurDeclaree * pct) / 100).roundToDouble();
      _montantCtrl.text = d.montant.toStringAsFixed(0);
    }
    _notify();
  }

  void _onMontantChanged(String raw) {
    final d = widget.draft;
    final montant = double.tryParse(raw) ?? 0;
    d.montant = montant;
    if (_montantChecked &&
        _pourcentageChecked &&
        !_valeurChecked &&
        d.pourcentageApplique > 0 &&
        montant > 0) {
      d.valeurDeclaree =
          ((montant * 100) / d.pourcentageApplique).roundToDouble();
      _valeurCtrl.text = d.valeurDeclaree.toStringAsFixed(0);
    } else if (_valeurChecked &&
        _montantChecked &&
        !_pourcentageChecked &&
        d.valeurDeclaree > 0 &&
        montant > 0) {
      d.pourcentageApplique =
          ((montant / d.valeurDeclaree) * 100 * 10).roundToDouble() / 10;
      _pourcentageCtrl.text = d.pourcentageApplique.toStringAsFixed(1);
    }
    _notify();
  }

  String _calcHint() {
    final d = widget.draft;
    if (d.valeurDeclaree > 0 &&
        d.pourcentageApplique > 0 &&
        d.montant > 0) {
      return '${_currency.format(d.valeurDeclaree)} × ${d.pourcentageApplique}% = ${_currency.format(d.montant)} FCFA';
    }
    if (_valeurChecked &&
        _montantChecked &&
        !_pourcentageChecked &&
        d.valeurDeclaree > 0 &&
        d.montant > 0) {
      return 'Pourcentage calculé : ${((d.montant / d.valeurDeclaree) * 100).toStringAsFixed(1)}%';
    }
    if (_valeurChecked &&
        _pourcentageChecked &&
        !_montantChecked &&
        d.valeurDeclaree > 0 &&
        d.pourcentageApplique > 0) {
      return 'Montant calculé : ${_currency.format((d.valeurDeclaree * d.pourcentageApplique / 100).round())} FCFA';
    }
    if (_montantChecked &&
        _pourcentageChecked &&
        !_valeurChecked &&
        d.montant > 0 &&
        d.pourcentageApplique > 0) {
      return 'Valeur déclarée calculée : ${_currency.format((d.montant * 100 / d.pourcentageApplique).round())} FCFA';
    }
    return 'Cochez deux champs pour calculer automatiquement le troisième';
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    final d = widget.draft;
    final isIntl = d.isInternationalService;
    final formats = PackageFormats.formatsForTab(_current.selectedCategory);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: KatianColors.red),
            const SizedBox(width: 8),
            Text(
              'Articles à livrer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ext.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter un article',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ext.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Type de véhicule *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ext.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (isIntl)
                _VehicleTabs(
                  selected: _current.selectedCategory,
                  tabs: const [
                    (PackageFormats.carTab, '🚐 Car'),
                    (PackageFormats.camionTab, '🚛 Camions'),
                  ],
                  onSelected: (v) {
                    _current.selectedCategory = v;
                    _current.packageFormat = '';
                    _current.showFormats = false;
                    _notify();
                  },
                )
              else
                _VehicleTabs(
                  selected: _current.selectedCategory,
                  tabs: const [
                    ('moto', '🏍️ Moto'),
                    ('fourgon', '🚐 Fourgon ou Voiture'),
                    ('camion', '🚛 Camion'),
                  ],
                  onSelected: (v) {
                    _current.selectedCategory = v;
                    _current.packageFormat = '';
                    _current.showFormats = false;
                    _notify();
                  },
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'article *',
                  hintText: 'Ex: Ordinateur portable',
                ),
                onChanged: (_) => _notify(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _current.category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: ItemCategories.all
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          '${ItemCategories.iconFor(c)} $c',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => ItemCategories.all
                    .map(
                      (c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${ItemCategories.iconFor(c)} $c',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _current.category = v;
                    _notify();
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Format de colis *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ext.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  _current.showFormats = !_current.showFormats;
                  _notify();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: ext.border),
                    borderRadius: BorderRadius.circular(12),
                    color: ext.surface,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _current.packageFormat.isEmpty
                              ? 'Sélectionnez un format...'
                              : PackageFormats.getSimplifiedFormatName(
                                  _selectedFormat,
                                  _current.selectedCategory,
                                ),
                          style: TextStyle(color: ext.textPrimary),
                        ),
                      ),
                      Icon(
                        _current.showFormats
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: ext.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_current.showFormats) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    border: Border.all(color: ext.border),
                    borderRadius: BorderRadius.circular(12),
                    color: ext.surface,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: formats.length,
                    itemBuilder: (context, i) {
                      final format = formats[i];
                      final selected = _current.packageFormat == format.id;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor: KatianColors.redLight,
                        title: Text(
                          PackageFormats.getSimplifiedFormatName(
                            format,
                            _current.selectedCategory,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? KatianColors.red : ext.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          format.description,
                          style: TextStyle(fontSize: 12, color: ext.textSecondary),
                        ),
                        onTap: () {
                          DepositItemLogic.applyPackageFormat(_current, format.id);
                          _current.showFormats = false;
                          if (!format.isCustom) {
                            _weightCtrl.text = format.weightFixed.toString();
                            _lengthCtrl.text = format.dimensions.length.toString();
                            _widthCtrl.text = format.dimensions.width.toString();
                            _heightCtrl.text = format.dimensions.height.toString();
                          } else {
                            _weightCtrl.clear();
                            _lengthCtrl.clear();
                            _widthCtrl.clear();
                            _heightCtrl.clear();
                          }
                          _notify();
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _qtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                onChanged: (_) => _notify(),
              ),
              if (_showCustomDimensions) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _weightCtrl,
                  decoration: const InputDecoration(labelText: 'Poids (kg) *'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lengthCtrl,
                        decoration: const InputDecoration(labelText: 'Longueur (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _widthCtrl,
                        decoration: const InputDecoration(labelText: 'Largeur (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _heightCtrl,
                        decoration: const InputDecoration(labelText: 'Hauteur (cm)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
              if (_current.packageFormat.isNotEmpty &&
                  _current.packageFormat != 'xl') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: KatianColors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PackageFormats.getSimplifiedFormatName(
                          _selectedFormat,
                          _current.selectedCategory,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ext.textPrimary,
                        ),
                      ),
                      if (_selectedFormat != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedFormat!.description,
                          style: TextStyle(fontSize: 12, color: ext.textSecondary),
                        ),
                        Text(
                          'Exemples : ${_selectedFormat!.examples}',
                          style: TextStyle(fontSize: 11, color: ext.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter l\'article'),
                ),
              ),
            ],
          ),
        ),
        if (d.pickupItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Articles ajoutés (${d.pickupItems.length})',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: ext.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(d.pickupItems.length, (i) {
            final item = d.pickupItems[i];
            final fmt = PackageFormats.byId(item.packageFormat);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${ItemCategories.iconFor(item.category)} ${item.category} • ${item.quantity} unité(s)'
                  '${fmt != null ? ' • ${fmt.description}' : ''}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: KatianColors.red),
                  onPressed: () => _removeItem(i),
                ),
              ),
            );
          }),
          if (d.totalWeight > 40000)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KatianColors.redLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: KatianColors.red.withValues(alpha: 0.3)),
              ),
              child: const Text(
                '⚠️ Limite de poids dépassée — le poids total ne peut pas dépasser 40000 kg.',
                style: TextStyle(color: KatianColors.redDark, fontSize: 13),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KatianColors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Résumé : ${d.totalArticleCount} article(s)',
              style: TextStyle(fontSize: 13, color: ext.textPrimary),
            ),
          ),
        ],
        if (isIntl) ...[
          const SizedBox(height: 24),
          Text(
            'Description du colis *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: ext.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _descriptionDropdownValue.isEmpty
                ? null
                : _descriptionDropdownValue,
            decoration: const InputDecoration(
              hintText: 'Sélectionnez le type de colis...',
            ),
            items: [
              ...ColisDescriptions.predefined.map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
              ),
            ],
            onChanged: (v) {
              if (v == null) return;
              if (v == ColisDescriptions.autres) {
                d.descriptionColis = ColisDescriptions.autres;
                _descriptionAutresCtrl.clear();
              } else {
                d.descriptionColis = v;
              }
              _notify();
            },
          ),
          if (_showDescriptionAutres) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionAutresCtrl,
              decoration: const InputDecoration(
                labelText: 'Précisez la description',
                hintText: 'Ex: Palette, Sac de riz…',
              ),
              onChanged: (v) {
                d.descriptionColis = v.trim();
                _notify();
              },
            ),
          ],
          const SizedBox(height: 16),
          _AmountField(
            label: 'Valeur déclarée (FCFA) *',
            controller: _valeurCtrl,
            checked: _valeurChecked,
            onCheckChanged: (v) {
              setState(() {
                _valeurChecked = v;
                if (!v) {
                  d.valeurDeclaree = 0;
                  _valeurCtrl.clear();
                }
              });
              _notify();
            },
            onChanged: _onValeurChanged,
            hint: 'Valeur totale de la marchandise',
          ),
          const SizedBox(height: 12),
          _AmountField(
            label: 'Pourcentage appliqué (%) *',
            controller: _pourcentageCtrl,
            checked: _pourcentageChecked,
            onCheckChanged: (v) {
              setState(() {
                _pourcentageChecked = v;
                if (!v) {
                  d.pourcentageApplique = 0;
                  _pourcentageCtrl.clear();
                }
              });
              _notify();
            },
            onChanged: _onPourcentageChanged,
            hint: '% de la valeur déclarée',
          ),
          const SizedBox(height: 12),
          _AmountField(
            label: 'Montant de l\'expédition (FCFA) *',
            controller: _montantCtrl,
            checked: _montantChecked,
            onCheckChanged: (v) {
              setState(() {
                _montantChecked = v;
                if (!v) {
                  d.montant = 0;
                  _montantCtrl.clear();
                }
              });
              _notify();
            },
            onChanged: _onMontantChanged,
            hint: _calcHint(),
            hintBlue: true,
          ),
        ],
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ext.border),
      ),
      child: child,
    );
  }
}

class _VehicleTabs extends StatelessWidget {
  const _VehicleTabs({
    required this.selected,
    required this.tabs,
    required this.onSelected,
  });

  final String selected;
  final List<(String, String)> tabs;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ext.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: tabs.map((tab) {
          final active = selected == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(tab.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? ext.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? KatianColors.red : ext.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.controller,
    required this.checked,
    required this.onCheckChanged,
    required this.onChanged,
    required this.hint,
    this.hintBlue = false,
  });

  final String label;
  final TextEditingController controller;
  final bool checked;
  final ValueChanged<bool> onCheckChanged;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool hintBlue;

  @override
  Widget build(BuildContext context) {
    final ext = context.katian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ext.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            Checkbox(
              value: checked,
              activeColor: KatianColors.red,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => onCheckChanged(v ?? false),
            ),
            Text(
              'Saisir',
              style: TextStyle(fontSize: 12, color: ext.textSecondary),
            ),
          ],
        ),
        TextField(
          controller: controller,
          enabled: checked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: '0'),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: TextStyle(
            fontSize: 11,
            color: hintBlue ? KatianColors.blue : ext.textSecondary,
          ),
        ),
      ],
    );
  }
}
