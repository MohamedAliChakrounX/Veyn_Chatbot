import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../data/locations.dart';
import '../data/options.dart';
import '../l10n/translations.dart';
import '../models/chat_message.dart';
import '../models/trip.dart';
import '../providers/language_provider.dart';
import '../providers/trip_provider.dart';
import '../theme/colors.dart';
import 'stops_timeline.dart';

enum BookingPhase { confirm, payment, processing, done }

class BookingDialog extends StatefulWidget {
  final TripResult result;
  final Function(BookingSummary) onConfirm;

  const BookingDialog({
    super.key,
    required this.result,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required TripResult result,
    required Function(BookingSummary) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDialog(result: result, onConfirm: onConfirm),
    );
  }

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  BookingPhase _phase = BookingPhase.confirm;
  late TripStop _selectedBoarding;
  bool _stopsOpen = false;

  // Voyageurs éditables
  bool _travelersInitialized = false;
  int _adults = 1;
  int _children = 0;
  int _assisted = 0;

  // Mode de paiement
  String _paymentMethod = 'card'; // 'card', 'mobile', 'cash'
  String _cardBrand = 'visa'; // 'visa', 'mastercard', 'cib', 'edinar'

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cardNumber = TextEditingController(text: '4532 8492 1029 4242');
  final TextEditingController _cardExpiry = TextEditingController(text: '12/28');
  final TextEditingController _cardCvv = TextEditingController(text: '888');
  String _selectedProvider = 'flouci';

  BookingSummary? _finalSummary;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final stops = widget.result.stops;
    final boardingOptions = stops.where((s) => s.kind == StopKind.origin || s.kind == StopKind.stop).toList();
    _selectedBoarding = boardingOptions.isNotEmpty
        ? boardingOptions.first
        : (stops.isNotEmpty
            ? stops.first
            : TripStop(
                name: widget.result.departure,
                place: widget.result.operator,
                time: widget.result.departure,
                kind: StopKind.origin,
              ));
  }

  void _initTravelers(BuildContext context) {
    if (_travelersInitialized) return;
    _travelersInitialized = true;
    final t = context.read<TripProvider>().trip.travelers;
    if (t.total > 0) {
      _adults = max(1, t.adults);
      _children = max(0, t.children);
      _assisted = max(0, t.assisted);
    } else {
      _adults = 1;
      _children = 0;
      _assisted = 0;
    }
  }

  void _updateTravelers(BuildContext context, {int? adults, int? children, int? assisted}) {
    setState(() {
      if (adults != null) _adults = adults;
      if (children != null) _children = children;
      if (assisted != null) _assisted = assisted;
    });
    final newTravelers = Travelers(adults: _adults, children: _children, assisted: _assisted);
    context.read<TripProvider>().patchTrip({'travelers': newTravelers});
  }

  int get _totalTravelers => max(1, _adults + _children + _assisted);

  String _getTravelersText(BuildContext context) {
    final parts = <String>[];
    if (_adults > 0) {
      parts.add('$_adults ${_adults > 1 ? context.tr('adults') : context.tr('adult_singular')}');
    }
    if (_children > 0) {
      parts.add('$_children ${_children > 1 ? context.tr('children') : context.tr('child_singular')}');
    }
    if (_assisted > 0) {
      parts.add('$_assisted ${context.tr('assisted')}');
    }
    return parts.isNotEmpty ? parts.join(', ') : context.tr('default_traveler');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cardNumber.dispose();
    _cardExpiry.dispose();
    _cardCvv.dispose();
    super.dispose();
  }

  String _makeReference() {
    final rand = Random();
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final randomLetters = List.generate(3, (_) => letters[rand.nextInt(letters.length)]).join();
    final randomDigits = 1000 + rand.nextInt(9000);
    return 'VY-$randomLetters$randomDigits';
  }

  void _onCardNumberChanged(String val) {
    final raw = val.replaceAll(RegExp(r'\D'), '');
    final limited = raw.length > 16 ? raw.substring(0, 16) : raw;
    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    if (formatted != _cardNumber.text) {
      _cardNumber.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    // Détection automatique de la marque de carte
    if (limited.startsWith('4')) {
      if (_cardBrand != 'visa') setState(() => _cardBrand = 'visa');
    } else if (limited.startsWith('5') || limited.startsWith('2')) {
      if (_cardBrand != 'mastercard') setState(() => _cardBrand = 'mastercard');
    } else if (limited.startsWith('9')) {
      if (_cardBrand != 'edinar') setState(() => _cardBrand = 'edinar');
    }
    setState(() {});
  }

  String _formatDisplayCardNumber() {
    final clean = _cardNumber.text.replaceAll(RegExp(r'\s'), '');
    final sb = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) sb.write(' ');
      if (i < clean.length) {
        sb.write(clean[i]);
      } else {
        sb.write('•');
      }
    }
    return sb.toString();
  }

  Future<void> _processPayment() async {
    setState(() => _phase = BookingPhase.processing);
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final lang = context.read<LanguageProvider>().languageCode;
    final totalTravelers = _totalTravelers;
    final total = widget.result.price * totalTravelers;

    final rawCard = _cardNumber.text.replaceAll(' ', '');
    final last4 = rawCard.length >= 4 ? rawCard.substring(rawCard.length - 4) : '4242';

    final passenger = PassengerInfo(
      fullName: _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : context.tr('main_traveler'),
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : '+216 00 000 000',
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    final cardName = _cardBrand == 'visa'
        ? 'Visa'
        : _cardBrand == 'mastercard'
            ? 'Mastercard'
            : _cardBrand == 'cib'
                ? 'CIB'
                : 'e-Dinar';

    final selectedProviderObj = mobileProviders.firstWhere(
      (p) => p.id == _selectedProvider,
      orElse: () => mobileProviders.first,
    );

    final paymentMethodLabel = _paymentMethod == 'card'
        ? '${context.tr('payment_method_card')} ($cardName)'
        : _paymentMethod == 'cash'
            ? context.tr('payment_method_cash')
            : '${context.tr('payment_method_mobile')} (${selectedProviderObj.name})';

    final originName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.first.name : widget.result.departure,
      lang,
    );
    final destName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.last.name : widget.result.arrival,
      lang,
    );

    final summary = BookingSummary(
      reference: _makeReference(),
      result: widget.result,
      travelers: totalTravelers,
      travelersDetail: Travelers(adults: _adults, children: _children, assisted: _assisted),
      travelersLabel: _getTravelersText(context),
      total: total,
      currency: widget.result.currency,
      boardingStop: _selectedBoarding,
      routeLabel: '$originName → $destName',
      passenger: passenger,
      paymentMethod: paymentMethodLabel,
      cardType: _paymentMethod == 'card' ? cardName : null,
      cardLast4: _paymentMethod == 'card' ? last4 : null,
    );

    _finalSummary = summary;
    setState(() => _phase = BookingPhase.done);
  }

  void _finish() {
    if (_finalSummary != null) {
      widget.onConfirm(_finalSummary!);
    }
    Navigator.of(context).pop();
  }

  String _formatDate(String? dateStr, String lang) {
    if (dateStr == null || dateStr.isEmpty) return context.tr('today');
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final day = int.parse(parts[2]);
      final month = int.parse(parts[1]);
      if (month < 1 || month > 12) return dateStr;

      const monthsFr = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
      const monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      const monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

      final idx = month - 1;
      if (lang == 'ar') return '$day ${monthsAr[idx]}';
      if (lang == 'en') return '${monthsEn[idx]} $day';
      return '$day ${monthsFr[idx]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    _initTravelers(context);

    final isRtl = context.isRtl;
    final lang = context.watch<LanguageProvider>().languageCode;
    final trip = context.watch<TripProvider>().trip;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    final originName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.first.name : widget.result.departure,
      lang,
    );
    final destName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.last.name : widget.result.arrival,
      lang,
    );
    final routeText = '$originName → $destName';

    final totalTravelers = _totalTravelers;
    final total = widget.result.price * totalTravelers;
    final localizedCurrency = formatCurrency(widget.result.currency, lang);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: VeynColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
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
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeynColors.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // En-tête de la modale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    if (_phase == BookingPhase.payment) ...[
                      IconButton(
                        icon: Icon(isRtl ? LucideIcons.arrowRight : LucideIcons.arrowLeft, size: 20),
                        onPressed: () => setState(() => _phase = BookingPhase.confirm),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            _phase == BookingPhase.done
                                ? context.tr('step_confirmation')
                                : _phase == BookingPhase.payment
                                    ? context.tr('step_payment')
                                    : context.tr('step_details'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: VeynColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.result.operator} · $routeText',
                            style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () {
                        if (_phase == BookingPhase.done) {
                          _finish();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: VeynColors.line),

              // Corps défilable
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_phase == BookingPhase.confirm)
                        _buildConfirmPhase(context, isRtl, lang, trip),
                      if (_phase == BookingPhase.payment)
                        _buildPaymentPhase(context, isRtl, lang, trip),
                      if (_phase == BookingPhase.processing)
                        _buildProcessingPhase(context),
                      if (_phase == BookingPhase.done)
                        _buildDonePhase(context, isRtl, lang),
                    ],
                  ),
                ),
              ),

              // Pied de modale (Sticky bar pour actions et total)
              if (_phase != BookingPhase.processing)
                _buildStickyFooter(context, isRtl, total, localizedCurrency),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pied de modale sticky ──────────────────────────────────────────────────
  Widget _buildStickyFooter(
    BuildContext context,
    bool isRtl,
    double total,
    String localizedCurrency,
  ) {
    final totalTravelers = _totalTravelers;
    final totalFormatted = total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);

    return Container(
      decoration: const BoxDecoration(
        color: VeynColors.surfaceRaised,
        border: Border(top: BorderSide(color: VeynColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  // Total et nombre de places
                  Flexible(
                    flex: 2,
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${context.tr('total_place')} ($totalTravelers ${totalTravelers > 1 ? context.tr('seat_plural') : context.tr('seat_singular')})',
                          style: const TextStyle(fontSize: 10.5, color: VeynColors.inkFaint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                          child: Text(
                            '$totalFormatted $localizedCurrency',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: VeynColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Boutons d'actions selon la phase
                  if (_phase == BookingPhase.confirm) ...[
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: VeynColors.line),
                        foregroundColor: VeynColors.ink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      child: Text(
                        context.tr('cancel_btn'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _phase = BookingPhase.payment),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VeynColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.creditCard, size: 14),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                context.tr('proceed_to_payment'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_phase == BookingPhase.payment) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VeynColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.lock, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _paymentMethod == 'cash'
                                    ? context.tr('block_seat')
                                    : context.tr('pay_now'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_phase == BookingPhase.done) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: _finish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VeynColors.emeraldText,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.checkCircle2, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.tr('done_btn'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_phase == BookingPhase.confirm)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: VeynColors.line)),
                  color: VeynColors.surfaceSunken,
                ),
                child: Row(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    const Icon(LucideIcons.info, size: 13, color: VeynColors.inkFaint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('provisional_notice'),
                        style: const TextStyle(fontSize: 10.5, color: VeynColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Phase 1 : Confirmation des détails ─────────────────────────────────────
  Widget _buildConfirmPhase(BuildContext context, bool isRtl, String lang, TripQuery trip) {
    final bookingDate = widget.result.date ?? trip.date;
    final formattedDate = _formatDate(bookingDate, lang);
    final localizedCurrency = formatCurrency(widget.result.currency, lang);
    final stops = widget.result.stops;
    final boardingOptions = stops.where((s) => s.kind == StopKind.origin || s.kind == StopKind.stop).toList();

    // Arrêts localisés pour le timeline
    final localizedStops = stops.map((s) => TripStop(
      name: localizeCityName(s.name, lang),
      place: s.place,
      time: s.time,
      kind: s.kind,
      waitMinutes: s.waitMinutes,
    )).toList();

    return Column(
      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // 1. Résumé horaire & Opérateur
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VeynColors.surfaceSunken,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VeynColors.line),
          ),
          child: Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.result.departure} → ${widget.result.arrival}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: VeynColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.result.operator} · ${context.tr('duration_prefix')} ${widget.result.durationLabel}',
                      style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.result.price.toStringAsFixed(widget.result.price.truncateToDouble() == widget.result.price ? 0 : 2)} $localizedCurrency',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: VeynColors.accent),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Grille Date + Voyageurs (2 colonnes comme le web)
        Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            // Colonne Date
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VeynColors.line),
                ),
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(LucideIcons.calendar, size: 14, color: VeynColors.accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            context.tr('date_label'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeynColors.inkMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr('departure_at_time')} ${widget.result.departure}',
                      style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Colonne Voyageurs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VeynColors.surfaceSunken.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VeynColors.line),
                ),
                child: Column(
                  crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              const Icon(LucideIcons.users, size: 14, color: VeynColors.accent),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  context.tr('summary_travelers'),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeynColors.inkMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VeynColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_totalTravelers ${_totalTravelers > 1 ? context.tr('seat_plural') : context.tr('seat_singular')}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: VeynColors.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getTravelersText(context),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.result.price.toStringAsFixed(0)} $localizedCurrency ${context.tr('per_traveler')}',
                      style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 3. Compteurs voyageurs éditables (comme le web)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VeynColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VeynColors.line),
          ),
          child: Column(
            children: [
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('modify_travelers'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.ink),
                  ),
                  Text(
                    '$_totalTravelers ${context.tr('selected_count')}',
                    style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                  ),
                ],
              ),
              const Divider(height: 14, color: VeynColors.line),
              _buildTravelerCounterRow(
                label: context.tr('adults'),
                hint: context.tr('adults_hint'),
                count: _adults,
                min: 1,
                onMinus: () => _updateTravelers(context, adults: max(1, _adults - 1)),
                onPlus: () => _updateTravelers(context, adults: min(9, _adults + 1)),
                isRtl: isRtl,
              ),
              const Divider(height: 12, color: VeynColors.line),
              _buildTravelerCounterRow(
                label: context.tr('children'),
                hint: context.tr('children_hint'),
                count: _children,
                min: 0,
                onMinus: () => _updateTravelers(context, children: max(0, _children - 1)),
                onPlus: () => _updateTravelers(context, children: min(9, _children + 1)),
                isRtl: isRtl,
              ),
              const Divider(height: 12, color: VeynColors.line),
              _buildTravelerCounterRow(
                label: context.tr('assisted'),
                hint: context.tr('assisted_hint'),
                count: _assisted,
                min: 0,
                onMinus: () => _updateTravelers(context, assisted: max(0, _assisted - 1)),
                onPlus: () => _updateTravelers(context, assisted: min(9, _assisted + 1)),
                isRtl: isRtl,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 4. Point de montée (liste avec indicateurs de sélection radio)
        if (boardingOptions.length > 1) ...[
          Text(
            context.tr('boarding_point_legend'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.inkMuted),
          ),
          const SizedBox(height: 6),
          Column(
            children: boardingOptions.map((stop) {
              final active = stop.name == _selectedBoarding.name;
              final localizedName = localizeCityName(stop.name, lang);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedBoarding = stop),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? VeynColors.surfaceRaised : VeynColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? VeynColors.accent : VeynColors.line,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        // Radio circle
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: active ? VeynColors.accent : VeynColors.lineStrong,
                              width: 2,
                            ),
                          ),
                          child: active
                              ? Center(
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: VeynColors.accent,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizedName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VeynColors.ink),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (stop.place.isNotEmpty)
                                Text(
                                  stop.place,
                                  style: const TextStyle(fontSize: 11, color: VeynColors.inkFaint),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          stop.time,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],

        // 5. Points d'arrêt déroulants (Accordéon)
        if (stops.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: VeynColors.surfaceSunken.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VeynColors.line),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _stopsOpen = !_stopsOpen),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(LucideIcons.mapPin, size: 14, color: VeynColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${context.tr('stops_itinerary_title')} (${stops.length} ${context.tr('stops_count_parenthesis')})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeynColors.ink),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _stopsOpen ? 0.5 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(LucideIcons.chevronDown, size: 15, color: VeynColors.inkFaint),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_stopsOpen) ...[
                  const Divider(height: 1, color: VeynColors.line),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: StopsTimeline(stops: localizedStops),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 6. Décomposition du prix
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VeynColors.surfaceSunken,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.tr('standard_ticket')} ($_totalTravelers ${context.tr('travelers')})',
                    style: const TextStyle(fontSize: 12, color: VeynColors.ink),
                  ),
                  Text(
                    '${(widget.result.price * _totalTravelers).toStringAsFixed(0)} $localizedCurrency',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeynColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('service_fees'),
                    style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                  ),
                  Text(
                    context.tr('included'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: VeynColors.emeraldText),
                  ),
                ],
              ),
              const Divider(height: 16, color: VeynColors.line),
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('total_to_pay'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
                  ),
                  Text(
                    '${(widget.result.price * _totalTravelers).toStringAsFixed(0)} $localizedCurrency',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: VeynColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelerCounterRow({
    required String label,
    required String hint,
    required int count,
    required int min,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required bool isRtl,
  }) {
    return Row(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: VeynColors.ink)),
            Text(hint, style: const TextStyle(fontSize: 10, color: VeynColors.inkMuted)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: count <= min ? null : onMinus,
              icon: const Icon(LucideIcons.minus, size: 14),
              style: IconButton.styleFrom(
                side: const BorderSide(color: VeynColors.line),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(28, 28),
              ),
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: count >= 9 ? null : onPlus,
              icon: const Icon(LucideIcons.plus, size: 14),
              style: IconButton.styleFrom(
                side: const BorderSide(color: VeynColors.line),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(28, 28),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Phase 2 : Paiement ─────────────────────────────────────────────────────
  Widget _buildPaymentPhase(BuildContext context, bool isRtl, String lang, TripQuery trip) {
    final bookingDate = widget.result.date ?? trip.date;
    final formattedDate = _formatDate(bookingDate, lang);
    final localizedCurrency = formatCurrency(widget.result.currency, lang);
    final total = widget.result.price * _totalTravelers;
    final totalFormatted = total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2);

    final originName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.first.name : widget.result.departure,
      lang,
    );
    final destName = localizeCityName(
      widget.result.stops.isNotEmpty ? widget.result.stops.last.name : widget.result.arrival,
      lang,
    );

    return Column(
      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // 1. Résumé compact en haut (comme le web)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: VeynColors.surfaceSunken.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: VeynColors.line),
          ),
          child: Column(
            children: [
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$originName → $destName',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: VeynColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$totalFormatted $localizedCurrency',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: VeynColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  const Icon(LucideIcons.calendar, size: 12, color: VeynColors.inkMuted),
                  const SizedBox(width: 4),
                  Text(formattedDate, style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: TextStyle(color: VeynColors.inkFaint)),
                  ),
                  const Icon(LucideIcons.users, size: 12, color: VeynColors.inkMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getTravelersText(context),
                      style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Grille des méthodes de paiement (Carte / Mobile / Agence)
        Text(
          '${context.tr('payment_method')} :',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.inkMuted),
        ),
        const SizedBox(height: 8),
        _buildPaymentMethodTile(
          id: 'card',
          icon: LucideIcons.creditCard,
          iconColor: const Color(0xFF2563EB),
          title: context.tr('card'),
          subtitle: context.tr('card_payment_desc'),
          isSelected: _paymentMethod == 'card',
          isRtl: isRtl,
          onTap: () => setState(() => _paymentMethod = 'card'),
        ),
        const SizedBox(height: 6),
        _buildPaymentMethodTile(
          id: 'mobile',
          icon: LucideIcons.smartphone,
          iconColor: const Color(0xFFDC2626),
          title: context.tr('mobile_wallet'),
          subtitle: context.tr('mobile_wallet_desc'),
          isSelected: _paymentMethod == 'mobile',
          isRtl: isRtl,
          onTap: () => setState(() => _paymentMethod = 'mobile'),
        ),
        const SizedBox(height: 6),
        _buildPaymentMethodTile(
          id: 'cash',
          icon: LucideIcons.store,
          iconColor: const Color(0xFFD97706),
          title: context.tr('agency_payment'),
          subtitle: context.tr('cash_on_board_desc'),
          isSelected: _paymentMethod == 'cash',
          isRtl: isRtl,
          onTap: () => setState(() => _paymentMethod = 'cash'),
        ),

        const SizedBox(height: 14),

        // 3. Section spécifique selon la méthode choisie
        if (_paymentMethod == 'card') ...[
          // Choix de la marque de carte
          Text(
            context.tr('choose_card_brand'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBrandChip('visa', 'Visa', const Color(0xFF1A1F71)),
              const SizedBox(width: 6),
              _buildBrandChip('mastercard', 'Mastercard', const Color(0xFFEB001B)),
              const SizedBox(width: 6),
              _buildBrandChip('cib', 'CIB', const Color(0xFF00796B)),
              const SizedBox(width: 6),
              _buildBrandChip('edinar', 'e-Dinar', const Color(0xFFB26A00)),
            ],
          ),

          const SizedBox(height: 14),

          // Carte virtuelle interactive avec gradient selon la marque
          _buildVirtualCard(context, isRtl),

          const SizedBox(height: 14),

          // Formulaire de saisie de carte
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VeynColors.surfaceSunken.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VeynColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.lock, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('security_badge'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: VeynColors.inkMuted),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Titulaire de la carte
                TextField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: context.tr('full_name'),
                    hintText: 'MOHAMED BEN ALI',
                    prefixIcon: const Icon(LucideIcons.user, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                // Numéro de carte
                TextField(
                  controller: _cardNumber,
                  keyboardType: TextInputType.number,
                  onChanged: _onCardNumberChanged,
                  decoration: InputDecoration(
                    labelText: context.tr('card_number'),
                    hintText: '0000 0000 0000 0000',
                    prefixIcon: const Icon(LucideIcons.creditCard, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Date d'expiration & CVV
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cardExpiry,
                        keyboardType: TextInputType.datetime,
                        maxLength: 5,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: isRtl ? 'انتهاء (MM/AA)' : 'Exp. (MM/AA)',
                          hintText: 'MM/AA',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cardCvv,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: '•••',
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else if (_paymentMethod == 'mobile') ...[
          // Section Portefeuille mobile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 16, color: VeynColors.emeraldText),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('secure_mobile_title'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.emeraldText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: context.tr('phone_number_label'),
                    hintText: '+216 XX XXX XXX',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('sms_notice'),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('select_wallet'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: VeynColors.ink),
          ),
          const SizedBox(height: 8),
          Column(
            children: mobileProviders.map((provider) {
              final isSel = _selectedProvider == provider.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () => setState(() => _selectedProvider = provider.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? VeynColors.surfaceRaised : VeynColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel ? VeynColors.accent : VeynColors.line,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: provider.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            provider.name.substring(0, min(2, provider.name.length)).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(provider.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text(provider.getDescription(context), style: const TextStyle(fontSize: 10.5, color: VeynColors.inkMuted)),
                            ],
                          ),
                        ),
                        if (isSel) const Icon(LucideIcons.checkCircle2, size: 16, color: VeynColors.accent),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else if (_paymentMethod == 'cash') ...[
          // Section Agence
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              children: [
                const Icon(LucideIcons.info, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('agency_notice_title'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('agency_notice_text'),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? VeynColors.accent.withValues(alpha: 0.05) : VeynColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? VeynColors.accent : VeynColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: VeynColors.surfaceSunken,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VeynColors.ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: VeynColors.inkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle2, size: 18, color: VeynColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandChip(String brandId, String label, Color badgeColor) {
    final isSel = _cardBrand == brandId;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _cardBrand = brandId),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSel ? VeynColors.accent.withValues(alpha: 0.08) : VeynColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? VeynColors.accent : VeynColors.line,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSel ? VeynColors.accent : VeynColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVirtualCard(BuildContext context, bool isRtl) {
    LinearGradient cardGradient;
    Widget brandLogo;

    switch (_cardBrand) {
      case 'mastercard':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF1E1E24), Color(0xFF2B2D42), Color(0xFF1A1A1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        brandLogo = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEB001B))),
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF79E1B).withValues(alpha: 0.88)),
              ),
            ),
          ],
        );
        break;
      case 'cib':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        brandLogo = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
          child: const Text('CIB', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
        );
        break;
      case 'edinar':
        cardGradient = const LinearGradient(
          colors: [Color(0xFF0D2538), Color(0xFF103E65), Color(0xFFB26A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        brandLogo = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(4)),
          child: const Text('e-Dinar', style: TextStyle(color: Color(0xFF0D2538), fontSize: 10, fontWeight: FontWeight.w900)),
        );
        break;
      case 'visa':
      default:
        cardGradient = const LinearGradient(
          colors: [Color(0xFF1A1F71), Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        brandLogo = const Text(
          'VISA',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 1.5),
        );
        break;
    }

    final holderName = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim().toUpperCase()
        : 'MOHAMED BEN ALI';
    final expiryText = _cardExpiry.text.trim().isNotEmpty ? _cardExpiry.text.trim() : '12/28';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne 1 : Puce EMV & Logo Marque
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Puce EMV dorée
              Container(
                width: 34,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              brandLogo,
            ],
          ),

          const SizedBox(height: 18),

          // Ligne 2 : Numéro de carte monospace
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatDisplayCardNumber(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ligne 3 : Titulaire & Date d'expiration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TITULAIRE', style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 0.8)),
                    const SizedBox(height: 1),
                    Text(
                      holderName,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRATION', style: TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 0.8)),
                  const SizedBox(height: 1),
                  Text(
                    expiryText,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Phase 3 : Traitement ────────────────────────────────────────────────────
  Widget _buildProcessingPhase(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: VeynColors.accent),
            const SizedBox(height: 20),
            Text(
              context.tr('validating_payment'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: VeynColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('connecting_bank'),
              style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Phase 4 : Confirmation complète (comme le web) ──────────────────────────
  Widget _buildDonePhase(BuildContext context, bool isRtl, String lang) {
    final summary = _finalSummary!;
    final localizedCurrency = formatCurrency(widget.result.currency, lang);
    final bookingDate = widget.result.date;
    final formattedDate = _formatDate(bookingDate, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: VeynColors.successSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.checkCircle2, color: VeynColors.success, size: 34),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('payment_success_title'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: VeynColors.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('payment_success_sub'),
          style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),

        // Boîte Référence avec bouton copier (verte comme le web)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.badgeCheck, size: 18, color: VeynColors.emeraldText),
              const SizedBox(width: 8),
              Text(
                summary.reference,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF065F46),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _copied ? LucideIcons.check : LucideIcons.copy,
                  color: _copied ? VeynColors.success : const Color(0xFF059669),
                  size: 16,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: summary.reference));
                  setState(() => _copied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copied = false);
                  });
                },
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Tableau récapitulatif complet (identique au web)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VeynColors.surfaceSunken.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: VeynColors.line),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                context.tr('summary_route'),
                summary.routeLabel,
                isBold: true,
                isRtl: isRtl,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context.tr('summary_date_time'),
                '$formattedDate · ${widget.result.departure}',
                isRtl: isRtl,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context.tr('summary_travelers'),
                summary.travelersLabel ?? '${summary.travelers} ${context.tr('travelers')}',
                isRtl: isRtl,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                context.tr('summary_boarding'),
                localizeCityName(summary.boardingStop.name, lang),
                isRtl: isRtl,
              ),
              const Divider(height: 16, color: VeynColors.line),
              _buildSummaryRow(
                context.tr('summary_payment_mode'),
                summary.paymentMethod ?? '',
                isRtl: isRtl,
              ),
              const Divider(height: 16, color: VeynColors.line),
              _buildSummaryRow(
                context.tr('summary_total_amount'),
                '${summary.total.toStringAsFixed(0)} $localizedCurrency',
                isBold: true,
                valueColor: VeynColors.accent,
                valueFontSize: 16,
                isRtl: isRtl,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Notices d'information
        Text(
          '${context.tr('arrive_early_notice')}\n${context.tr('archive_chat_notice')}',
          style: const TextStyle(fontSize: 11, color: VeynColors.inkMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double valueFontSize = 12,
    required bool isRtl,
  }) {
    return Row(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: VeynColors.inkMuted)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? VeynColors.ink,
            ),
            textAlign: isRtl ? TextAlign.left : TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
