import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../data/locations.dart';
import '../l10n/translations.dart';
import '../models/trip.dart';
import '../theme/colors.dart';

class LocationPickerSheet extends StatefulWidget {
  final bool isOrigin;
  final City? currentCity;
  final String? excludeCityId;
  final String lang;
  final Function(City) onSelectCity;

  const LocationPickerSheet({
    super.key,
    required this.isOrigin,
    required this.currentCity,
    this.excludeCityId,
    required this.lang,
    required this.onSelectCity,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isOrigin,
    required City? currentCity,
    String? excludeCityId,
    required String lang,
    required Function(City) onSelectCity,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerSheet(
        isOrigin: isOrigin,
        currentCity: currentCity,
        excludeCityId: excludeCityId,
        lang: lang,
        onSelectCity: onSelectCity,
      ),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  CountryCode? _selectedCountry;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si une ville est déjà sélectionnée, présélectionner son pays
    if (widget.currentCity != null) {
      _selectedCountry = widget.currentCity!.country;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.isRtl;
    final title = widget.isOrigin
        ? context.tr('choose_departure_point')
        : context.tr('choose_arrival_point');
    final icon = widget.isOrigin ? LucideIcons.mapPin : LucideIcons.navigation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: VeynColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée supérieure
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VeynColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: VeynColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: VeynColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: VeynColors.ink,
                          ),
                        ),
                        Row(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Text(
                              _selectedCountry == null
                                  ? context.tr('select_country')
                                  : '${context.tr('cities_in')} ${getCountryLocalizedName(_selectedCountry!, widget.lang)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: VeynColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Indicateur d'étape
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedCountry == null ? VeynColors.surfaceSunken : VeynColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCountry == null ? VeynColors.line : VeynColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _selectedCountry == null
                          ? context.tr('step_country')
                          : context.tr('step_city'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _selectedCountry == null ? VeynColors.inkSoft : VeynColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                    style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Contenu : Étape 1 (Choix Pays) ou Étape 2 (Choix Ville)
            Expanded(
              child: _selectedCountry == null
                  ? _buildCountrySelection(context, isRtl)
                  : _buildCitySelection(context, isRtl),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ÉTAPE 1 : CHOIX DU PAYS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCountrySelection(BuildContext context, bool isRtl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              context.tr('select_country'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: VeynColors.inkMuted,
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: countries.map((c) {
              final flag = getCountryFlag(c.code);
              final name = getCountryLocalizedName(c.code, widget.lang);
              final cityCount = getCitiesByCountry(c.code).length;
              final isSelected = widget.currentCity?.country == c.code;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCountry = c.code;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? VeynColors.accent : VeynColors.line,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? VeynColors.accent : VeynColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$cityCount ${context.tr('all_cities').toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: VeynColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ÉTAPE 2 : CHOIX DE LA VILLE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCitySelection(BuildContext context, bool isRtl) {
    final country = _selectedCountry!;
    final countryName = getCountryLocalizedName(country, widget.lang);
    final countryFlag = getCountryFlag(country);

    // Liste des villes du pays filtrée par recherche
    final filteredCities = searchCities(
      _searchQuery,
      country: country,
      excludeId: widget.excludeCityId,
    );

    // Villes populaires du pays
    final popularCities = getPopularCitiesByCountry(country)
        .where((c) => c.id != widget.excludeCityId)
        .toList();

    return Column(
      children: [
        // Barre de commutation rapide de pays
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          color: VeynColors.surfaceSunken,
          child: Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Bouton retour étape 1
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedCountry = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Icon(
                        isRtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                        size: 15,
                        color: VeynColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('change_country'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: VeynColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Puces rapides pour changer de pays en 1 clic
              ...countries.map((c) {
                final isCurrent = c.code == country;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCountry = c.code;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? VeynColors.accent : VeynColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? VeynColors.accent : VeynColors.line,
                        ),
                      ),
                      child: Text(
                        getCountryFlag(c.code),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Barre de recherche de ville
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: TextField(
            controller: _searchController,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: '${context.tr('search_placeholder_in_country')} ($countryFlag $countryName)',
              hintStyle: const TextStyle(fontSize: 13, color: VeynColors.inkMuted),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: VeynColors.inkMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: VeynColors.surfaceSunken,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VeynColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VeynColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VeynColors.accent, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),

        // Puces des villes phares (si la recherche est vide)
        if (_searchQuery.trim().isEmpty && popularCities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: VeynColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('popular_cities'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: VeynColors.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: popularCities.map((city) {
                    final isSelected = widget.currentCity?.id == city.id;
                    final cityName = localizeCityName(city.name, widget.lang);
                    return ActionChip(
                      label: Text(
                        cityName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : VeynColors.ink,
                        ),
                      ),
                      backgroundColor: isSelected ? VeynColors.accent : VeynColors.surfaceSunken,
                      side: BorderSide(
                        color: isSelected ? VeynColors.accent : VeynColors.line,
                      ),
                      onPressed: () {
                        widget.onSelectCity(city);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        const Divider(height: 8),

        // Liste des villes
        Expanded(
          child: filteredCities.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${context.tr('no_city_matches')} "$_searchQuery"',
                      style: const TextStyle(color: VeynColors.inkMuted, fontSize: 13),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: filteredCities.length,
                  separatorBuilder: (_, idx) => const Divider(height: 1, indent: 48),
                  itemBuilder: (context, index) {
                    final city = filteredCities[index];
                    final isSelected = widget.currentCity?.id == city.id;
                    final localizedName = localizeCityName(city.name, widget.lang);
                    final secondaryName = widget.lang == 'ar'
                        ? (city.nameFr ?? city.name)
                        : (city.nameAr ?? '');

                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? VeynColors.accentSoft : VeynColors.surfaceSunken,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isOrigin ? LucideIcons.mapPin : LucideIcons.navigation,
                          size: 16,
                          color: isSelected ? VeynColors.accent : VeynColors.inkMuted,
                        ),
                      ),
                      title: Text(
                        localizedName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? VeynColors.accent : VeynColors.ink,
                        ),
                      ),
                      subtitle: secondaryName.isNotEmpty
                          ? Text(
                              secondaryName,
                              style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(LucideIcons.check, size: 18, color: VeynColors.accent)
                          : null,
                      onTap: () {
                        widget.onSelectCity(city);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
