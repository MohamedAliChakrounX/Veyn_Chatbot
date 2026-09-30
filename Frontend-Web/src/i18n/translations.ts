export type Language = 'fr' | 'ar' | 'en'

export interface TranslationSchema {
  common: {
    close: string
    cancel: string
    confirm: string
    save: string
    back: string
    next: string
    loading: string
    retry: string
    copied: string
    copy: string
  }
  header: {
    subtitle: string
    newSearch: string
    newSearchMobile: string
    history: string
    settingsTooltip: string
  }
  suggestions: {
    badge: string
    title: string
    q1: string
    q2: string
    q3: string
    q4: string
  }
  composer: {
    placeholder: string
    recording: string
    transcribing: string
    sendTooltip: string
    speechTooltip: string
    filtersTooltip: string
    openFilters: string
    activeFilters: string
  }
  trip: {
    departure: string
    arrival: string
    selectDeparture: string
    selectArrival: string
    searchCity: string
    date: string
    today: string
    tomorrow: string
    time: string
    morning: string
    morningRange: string
    afternoon: string
    afternoonRange: string
    evening: string
    eveningRange: string
    exactTime: string
    travelers: string
    travelerTotal: string
    adults: string
    adultsHint: string
    children: string
    childrenHint: string
    assisted: string
    assistedHint: string
    budget: string
    budgetMax: string
    currency: string
    modes: string
    allModes: string
    bus: string
    sharedTaxi: string
    train: string
    plane: string
    ferry: string
    other: string
    busStop: string
    taxiStop: string
    trainStop: string
    airportStop: string
    ferryStop: string
    meetingStop: string
    apply: string
    reset: string
  }
  tripPanel: {
    refineTrip: string
    allOptional: string
    reset: string
    optional: string
    departure: string
    destination: string
    travelers: string
    date: string
    time: string
    transport: string
    budgetMax: string
    departurePlaceholder: string
    arrivalPlaceholder: string
    noCityMatches: string
    departureTime: string
  }
  results: {
    title: string
    optionsFound: string
    bestOption: string
    bestRateReal: string
    direct: string
    directTrip: string
    transfersCount: string
    stopsCount: string
    departureAt: string
    arrivalAt: string
    duration: string
    durationPrefix: string
    perPerson: string
    bookNow: string
    viewDetails: string
    hideDetails: string
    stopsItinerary: string
    operator: string
    availableSeats: string
    availableDates: string
    datesCount: string
    availableSchedule: string
    selectSchedule: string
    departuresCount: string
    seatsRemaining: string
    stopPoints: string
    stopsInTotal: string
    waitMinutes: string
    waitHours: string
    yourBoarding: string
  }
  booking: {
    modalTitle: string
    stepSummary: string
    stepDetails: string
    stepPayment: string
    stepConfirmation: string
    itinerarySummary: string
    boardingPoint: string
    selectBoarding: string
    passengersDetails: string
    fullName: string
    fullNamePlaceholder: string
    phone: string
    phonePlaceholder: string
    email: string
    emailPlaceholder: string
    seatsToBook: string
    paymentMethod: string
    cardPayment: string
    cardPaymentDesc: string
    mobileWallet: string
    mobileWalletDesc: string
    cashOnBoard: string
    cashOnBoardDesc: string
    cardNumber: string
    expiry: string
    cvv: string
    selectWallet: string
    totalToPay: string
    payAndConfirm: string
    confirmReservation: string
    processingTitle: string
    processingDesc: string
    successTitle: string
    successDesc: string
    bookingRef: string
    ticketNotice: string
    finish: string
    seatSingular: string
    seatPlural: string
    totalPlace: string
    modifyTravelers: string
    selectedCount: string
    perTraveler: string
    departureAtTime: string
    boardingPointLegend: string
    stopsItineraryTitle: string
    stopsCountParenthesis: string
    payNow: string
    cancelBtn: string
    doneBtn: string
    provisionalNotice: string
    chooseCardBrand: string
    secureMobileTitle: string
    phoneNumberLabel: string
    smsNotice: string
    agencyNoticeTitle: string
    agencyNoticeText: string
    securityBadge: string
    validatingPayment: string
    connectingBank: string
    paymentSuccessTitle: string
    paymentSuccessSub: string
    copyRefTitle: string
    summaryRoute: string
    summaryDateTime: string
    summaryTravelers: string
    summaryBoarding: string
    summaryPaymentMode: string
    summaryTotalAmount: string
    arriveEarlyNotice: string
    archiveChatNotice: string
    retryWithCard: string
    visaCard: string
    mastercardCard: string
    cibCard: string
    edinarCard: string
  }
  bookingCard: {
    successHeader: string
    refPrefix: string
    travelDate: string
    travelers: string
    durationPrefix: string
    boardingAt: string
    atTime: string
    paymentMethodLabel: string
    directTrip: string
    stopsCount: string
    totalStops: string
    payCashAgency: string
  }
  history: {
    title: string
    searchPlaceholder: string
    empty: string
    emptyDesc: string
    newChat: string
    today: string
    yesterday: string
    thisMonth: string
    older: string
    deletePrompt: string
    conversationsCount: string
    clearAll: string
    noResultsFor: string
    tripsLabel: string
    bookedLabel: string
    clearHistoryConfirm: string
  }
  tripDashboard: {
    tripDashboard: string
    hideDashboard: string
    showDashboard: string
    precisionsCount: string
    noPrecisions: string
    searchTripsBtn: string
    chooseDeparturePoint: string
    chooseArrivalPoint: string
    clearFilters: string
    selectDate: string
    selectTime: string
    selectTravelers: string
    selectTransport: string
    allCities: string
    popularCities: string
    swapCities: string
    selectPrecisions: string
    stopsPreference: string
    directOnly: string
    allTrips: string
    budgetMax: string
  }
  serverConfig: {
    serverConfig: string
    serverConfigTooltip: string
    apiUrlLabel: string
    serverSet: string
    testConnection: string
    serverOnline: string
    serverOffline: string
    testing: string
    saved: string
    usbAdbPreset: string
    wifiPreset: string
    emulatorPreset: string
  }
  conflicts: {
    title: string
    detected: string
    keepCurrent: string
    updateTo: string
  }
  noResults: {
    tryTomorrow: string
    removeMode: string
    removeBudget: string
    tryTomorrowMsg: string
    removeAllModesMsg: string
    removeBudgetMsg: string
  }
  errorNotice: {
    message: string
    retry: string
  }
  travelers: {
    adult: string
    adults: string
    child: string
    children: string
    assisted: string
    assisteds: string
    defaultOne: string
  }
  paymentLabels: {
    card: string
    cardDesc: string
    mobileTn: string
    mobileTnDesc: string
    mobileLy: string
    mobileLyDesc: string
    mobileDz: string
    mobileDzDesc: string
    cash: string
    cashDesc: string
    paymentMethodCard: string
    paymentMethodCash: string
    paymentMethodMobile: string
    paymentError: string
    composerHint: string
  }
}

export const translations: Record<Language, TranslationSchema> = {
  fr: {
    common: {
      close: 'Fermer',
      cancel: 'Annuler',
      confirm: 'Confirmer',
      save: 'Enregistrer',
      back: 'Retour',
      next: 'Suivant',
      loading: 'Chargement en cours...',
      retry: 'Réessayer',
      copied: 'Copié !',
      copy: 'Copier',
    },
    header: {
      subtitle: 'Assistant transport · Tunisie · Algérie · Libye · Égypte',
      newSearch: 'Nouvelle recherche',
      newSearchMobile: 'Nouveau',
      history: 'Historique',
      settingsTooltip: 'Paramètres du serveur',
    },
    suggestions: {
      badge: 'Exemples de requêtes',
      title: 'Où souhaitez-vous voyager ?',
      q1: 'Je veux aller de Tripoli à Tunis demain matin avec 2 adultes.',
      q2: 'Je cherche les horaires pour Tunis vers Tripoli pour aujourd’hui.',
      q3: 'Quels sont les trajets de Misrata vers Tunis ?',
      q4: 'Donne-moi les prix entre Tripoli et Sfax.',
    },
    composer: {
      placeholder: 'Posez votre question (ex: Bus Tunis vers Sousse demain matin)...',
      recording: 'Enregistrement audio en cours...',
      transcribing: 'Transcription de votre message...',
      sendTooltip: 'Envoyer le message',
      speechTooltip: 'Enregistrement vocal',
      filtersTooltip: 'Critères de voyage',
      openFilters: 'Afficher les filtres',
      activeFilters: 'critères actifs',
    },
    trip: {
      departure: 'Départ',
      arrival: 'Arrivée',
      selectDeparture: 'Lieu de départ',
      selectArrival: 'Lieu d’arrivée',
      searchCity: 'Rechercher une ville...',
      date: 'Date',
      today: "Aujourd'hui",
      tomorrow: 'Demain',
      time: 'Horaire',
      morning: 'Matin',
      morningRange: '05h – 12h',
      afternoon: 'Après-midi',
      afternoonRange: '12h – 18h',
      evening: 'Soir',
      eveningRange: '18h – 23h',
      exactTime: 'Heure précise',
      travelers: 'Voyageurs',
      travelerTotal: 'voyageur(s)',
      adults: 'Adultes',
      adultsHint: '12 ans et plus',
      children: 'Enfants',
      childrenHint: 'Moins de 12 ans',
      assisted: 'PMR / Assistance',
      assistedHint: 'Mobilité réduite',
      budget: 'Budget',
      budgetMax: 'Budget maximum',
      currency: 'DT',
      modes: 'Mode de transport',
      allModes: 'Tous les modes',
      bus: 'Bus',
      sharedTaxi: 'Louage / Taxi collectif',
      train: 'Train',
      plane: 'Avion',
      ferry: 'Ferry',
      other: 'Autre',
      busStop: 'Gare routière',
      taxiStop: 'Station de louages',
      trainStop: 'Gare ferroviaire',
      airportStop: 'Aéroport',
      ferryStop: 'Port maritime',
      meetingStop: 'Point de rendez-vous',
      apply: 'Appliquer',
      reset: 'Réinitialiser',
    },
    tripPanel: {
      refineTrip: 'Préciser le voyage',
      allOptional: 'Tout est facultatif',
      reset: 'Réinitialiser',
      optional: 'Facultatif',
      departure: 'Départ',
      destination: 'Destination',
      travelers: 'Voyageurs',
      date: 'Date',
      time: 'Heure',
      transport: 'Transport',
      budgetMax: 'Budget max',
      departurePlaceholder: 'Rechercher une ville de départ…',
      arrivalPlaceholder: 'Rechercher une ville d’arrivée…',
      noCityMatches: 'Aucune ville ne correspond à',
      departureTime: 'Heure de départ',
    },
    results: {
      title: 'Itinéraires disponibles',
      optionsFound: 'options trouvées',
      bestOption: 'Recommandé',
      bestRateReal: 'Meilleur tarif réel',
      direct: 'direct',
      directTrip: 'Trajet direct',
      transfersCount: 'corr.',
      stopsCount: 'arrêt(s)',
      departureAt: 'Départ à',
      arrivalAt: 'Arrivée vers',
      duration: 'Durée estimée',
      durationPrefix: 'Durée :',
      perPerson: 'par pers.',
      bookNow: 'Réserver',
      viewDetails: 'Détails du trajet',
      hideDetails: 'Masquer détails',
      stopsItinerary: 'Arrêts & correspondances',
      operator: 'Opérateur',
      availableSeats: 'places disponibles',
      availableDates: 'Dates disponibles :',
      datesCount: 'dates',
      availableSchedule: 'Horaire disponible :',
      selectSchedule: 'Sélectionnez votre horaire :',
      departuresCount: 'départs',
      seatsRemaining: 'places restantes',
      stopPoints: 'points d’arrêt',
      stopsInTotal: 'arrêts au total',
      waitMinutes: 'min d’arrêt',
      waitHours: 'h d’arrêt',
      yourBoarding: 'Votre montée',
    },
    booking: {
      modalTitle: 'Réservation de votre voyage',
      stepSummary: 'Récapitulatif',
      stepDetails: 'Passagers',
      stepPayment: 'Paiement',
      stepConfirmation: 'Confirmation',
      itinerarySummary: 'Détails du voyage',
      boardingPoint: 'Point de montée',
      selectBoarding: 'Choisir votre point de montée',
      passengersDetails: 'Coordonnées du voyageur principal',
      fullName: 'Nom et prénom',
      fullNamePlaceholder: 'Ex: Mohamed Ben Salem',
      phone: 'Numéro de téléphone',
      phonePlaceholder: '+216 -- --- ---',
      email: 'Adresse e-mail',
      emailPlaceholder: 'exemple@domaine.com',
      seatsToBook: 'Nombre de places',
      paymentMethod: 'Mode de paiement',
      cardPayment: 'Carte bancaire',
      cardPaymentDesc: 'Visa, Mastercard, CIB, e-Dinar',
      mobileWallet: 'Portefeuille mobile',
      mobileWalletDesc: 'Flouci, D17, Sadad, Moamalat, BaridiMob',
      cashOnBoard: 'Paiement à bord',
      cashOnBoardDesc: 'Règlement en espèces au départ',
      cardNumber: 'Numéro de carte',
      expiry: 'Date d’expiration (MM/AA)',
      cvv: 'Cryptogramme (CVV)',
      selectWallet: 'Choisir votre opérateur mobile',
      totalToPay: 'Total à régler',
      payAndConfirm: 'Payer et confirmer le billet',
      confirmReservation: 'Confirmer la réservation',
      processingTitle: 'Paiement en cours de sécurisation...',
      processingDesc: 'Veuillez patienter pendant la validation auprès de l’opérateur.',
      successTitle: 'Réservation confirmée avec succès !',
      successDesc: 'Votre billet a été généré. Présentez ce reçu lors de l’embarquement.',
      bookingRef: 'Référence de réservation',
      ticketNotice: 'Un SMS de confirmation avec les détails a été envoyé à votre numéro.',
      finish: 'Terminer',
      seatSingular: 'place',
      seatPlural: 'places',
      totalPlace: 'Total',
      modifyTravelers: 'Modifier les voyageurs :',
      selectedCount: 'sélectionné(s)',
      perTraveler: '/ voyageur',
      departureAtTime: 'Départ à',
      boardingPointLegend: 'Point de montée',
      stopsItineraryTitle: 'Points d’arrêt de l’itinéraire',
      stopsCountParenthesis: 'arrêts',
      payNow: 'Payer maintenant',
      cancelBtn: 'Annuler',
      doneBtn: 'Terminer',
      provisionalNotice: 'La place est réservée provisoirement. Aucun débit avant la validation du paiement.',
      chooseCardBrand: 'Faire le choix de la carte :',
      secureMobileTitle: 'Paiement mobile instantané sécurisé',
      phoneNumberLabel: 'Numéro de téléphone mobile',
      smsNotice: 'Un SMS avec un code de confirmation vous sera envoyé sur ce numéro.',
      agencyNoticeTitle: 'Réservation avec règlement en agence',
      agencyNoticeText: 'Votre place sera bloquée pendant 2 heures. Rendez-vous au guichet de votre point de départ muni de votre référence pour régler.',
      securityBadge: 'Données bancaires 100% sécurisées et chiffrées de bout en bout',
      validatingPayment: 'Validation du paiement en cours…',
      connectingBank: 'Connexion sécurisée avec le serveur bancaire en cours.',
      paymentSuccessTitle: 'Paiement validé avec succès !',
      paymentSuccessSub: 'Votre billet est immédiatement émis et confirmé.',
      copyRefTitle: 'Copier la référence',
      summaryRoute: 'Trajet',
      summaryDateTime: 'Date & Heure',
      summaryTravelers: 'Voyageurs',
      summaryBoarding: 'Lieu d’embarquement',
      summaryPaymentMode: 'Mode de règlement',
      summaryTotalAmount: 'Montant total',
      arriveEarlyNotice: 'Présentez-vous 20 minutes avant l’heure de départ.',
      archiveChatNotice: 'Le récapitulatif sera archivé dans la discussion dès que vous cliquez sur « Terminer ».',
      retryWithCard: 'Réessayer avec une autre carte',
      visaCard: 'Carte Visa',
      mastercardCard: 'Carte Mastercard',
      cibCard: 'Carte CIB',
      edinarCard: 'Carte e-Dinar',
    },
    bookingCard: {
      successHeader: 'Réservation effectuée avec succès',
      refPrefix: 'Réf.',
      travelDate: 'Date du voyage',
      travelers: 'Voyageurs',
      durationPrefix: 'Durée :',
      boardingAt: 'Montée à',
      atTime: 'à',
      paymentMethodLabel: 'Moyen de paiement :',
      directTrip: 'Trajet direct',
      stopsCount: 'points d’arrêt',
      totalStops: 'arrêts au total',
      payCashAgency: 'Paiement en agence',
    },
    history: {
      title: 'Historique des recherches',
      searchPlaceholder: 'Rechercher une destination...',
      empty: 'Aucune recherche enregistrée',
      emptyDesc: 'Vos conversations et trajets planifiés apparaîtront ici.',
      newChat: 'Nouvelle conversation',
      today: "Aujourd'hui",
      yesterday: 'Hier',
      thisMonth: 'Ce mois-ci',
      older: 'Plus ancien',
      deletePrompt: 'Supprimer cette conversation ?',
      conversationsCount: 'conversations',
      clearAll: 'Effacer tout l\u2019historique',
      noResultsFor: 'Aucun r\u00e9sultat pour',
      tripsLabel: 'trajets',
      bookedLabel: 'r\u00e9serv\u00e9',
      clearHistoryConfirm: 'Voulez-vous vraiment effacer tout l\u2019historique des conversations ?',
    },
    tripDashboard: {
      tripDashboard: 'Pr\u00e9cisions du trajet',
      hideDashboard: 'Masquer le tableau de bord',
      showDashboard: 'Afficher le tableau de bord',
      precisionsCount: 'pr\u00e9cision(s)',
      noPrecisions: '0 pr\u00e9cision',
      searchTripsBtn: 'Rechercher les trajets',
      chooseDeparturePoint: 'Point de d\u00e9part',
      chooseArrivalPoint: 'Point d\u2019arriv\u00e9e',
      clearFilters: 'Effacer',
      selectDate: 'Date du trajet',
      selectTime: 'Cr\u00e9neau horaire',
      selectTravelers: 'Passagers',
      selectTransport: 'Transport',
      allCities: 'Toutes les villes',
      popularCities: 'Villes principales',
      swapCities: 'Permuter d\u00e9part et arriv\u00e9e',
      selectPrecisions: 'Points d’arrêt & Précisions',
      stopsPreference: 'Points d’arrêt & Itinéraire',
      directOnly: 'Trajets directs uniquement (sans arrêt)',
      allTrips: 'Tous les trajets (directs et avec arrêts)',
      budgetMax: 'Budget maximum',
    },
    serverConfig: {
      serverConfig: 'Connexion Backend',
      serverConfigTooltip: 'Configurer le serveur',
      apiUrlLabel: 'URL de l\u2019API FastAPI :',
      serverSet: 'Serveur configur\u00e9 :',
      testConnection: 'Tester la connexion',
      serverOnline: 'Serveur en ligne (200 OK)',
      serverOffline: 'Impossible de joindre le serveur',
      testing: 'V\u00e9rification...',
      saved: 'Enregistr\u00e9 !',
      usbAdbPreset: 'USB / ADB (127.0.0.1)',
      wifiPreset: 'Wi-Fi (192.168.100.15)',
      emulatorPreset: '\u00c9mulateur (10.0.2.2)',
    },
    conflicts: {
      title: 'Modification des critères détectée',
      detected: 'Vous aviez spécifié :',
      keepCurrent: "Conserver l'ancien",
      updateTo: 'Mettre à jour avec',
    },
    noResults: {
      tryTomorrow: 'Changer de date',
      removeMode: 'Tous les transports',
      removeBudget: 'Élargir le budget',
      tryTomorrowMsg: 'Chercher pour demain',
      removeAllModesMsg: 'Retire le filtre de transport, tous les moyens me conviennent.',
      removeBudgetMsg: 'Supprimer la limite de budget',
    },
    errorNotice: {
      message: 'Une erreur est survenue. Veuillez réessayer.',
      retry: 'Réessayer',
    },
    travelers: {
      adult: 'adulte',
      adults: 'adultes',
      child: 'enfant',
      children: 'enfants',
      assisted: 'assistance',
      assisteds: 'assistances',
      defaultOne: '1 adulte',
    },
    paymentLabels: {
      card: 'Carte bancaire',
      cardDesc: 'Visa, Mastercard, CIB, e-Dinar',
      mobileTn: 'Paiement mobile (Tunisie)',
      mobileTnDesc: 'D17, MyPos, Sobflous',
      mobileLy: 'Paiement mobile (Libye)',
      mobileLyDesc: 'Mobi Cash, Sadad',
      mobileDz: 'Paiement mobile (Algérie)',
      mobileDzDesc: 'BaridiMob, Dahabiya',
      cash: 'Paiement en agence',
      cashDesc: 'Réservez maintenant, payez sur place',
      paymentMethodCard: 'Carte bancaire',
      paymentMethodCash: 'Paiement en agence',
      paymentMethodMobile: 'Paiement mobile',
      paymentError: 'Paiement non abouti',
      composerHint: 'Écrivez ou dictez librement, utilisez le « + », ou combinez les deux. Données et horaires en direct.',
    },
  },
  ar: {
    common: {
      close: 'إغلاق',
      cancel: 'إلغاء',
      confirm: 'تأكيد',
      save: 'حفظ',
      back: 'رجوع',
      next: 'التالي',
      loading: 'جارٍ التحميل...',
      retry: 'إعادة المحاولة',
      copied: 'تم النسخ!',
      copy: 'نسخ',
    },
    header: {
      subtitle: 'مساعد النقل الذكي · تونس · الجزائر · ليبيا · مصر',
      newSearch: 'محادثة جديدة',
      newSearchMobile: 'جديد',
      history: 'السجل',
      settingsTooltip: 'إعدادات الخادم',
    },
    suggestions: {
      badge: 'استفسارات مقترحة',
      title: 'إلى أين ترغب في السفر اليوم؟',
      q1: 'أريد الذهاب من طرابلس إلى تونس صباح الغد لشخصين بالغين.',
      q2: 'أبحث عن مواعيد الرحلات من تونس إلى طرابلس اليوم.',
      q3: 'ما هي الرحلات المتوفرة من مصراتة إلى تونس؟',
      q4: 'كم تبلغ تكلفة السفر بين طرابلس وصفاقس؟',
    },
    composer: {
      placeholder: 'اطرح سؤالك هنا (مثال: حافلة من تونس إلى سوسة غداً صباحاً)...',
      recording: 'جارٍ التسجيل الصوتي...',
      transcribing: 'جارٍ تحويل الصوت إلى نص مكتوب...',
      sendTooltip: 'إرسال الرسالة',
      speechTooltip: 'تسجيل صوتي',
      filtersTooltip: 'تحديد خيارات السفر',
      openFilters: 'عرض الفلاتر',
      activeFilters: 'خيارات محددة',
    },
    trip: {
      departure: 'نقطة الانطلاق',
      arrival: 'وجهة الوصول',
      selectDeparture: 'حدد نقطة الانطلاق',
      selectArrival: 'حدد وجهة الوصول',
      searchCity: 'ابحث عن مدينة...',
      date: 'تاريخ السفر',
      today: 'اليوم',
      tomorrow: 'غداً',
      time: 'الوقت المفضل',
      morning: 'صباحاً',
      morningRange: '05:00 – 12:00',
      afternoon: 'ظهراً',
      afternoonRange: '12:00 – 18:00',
      evening: 'مساءً',
      eveningRange: '18:00 – 23:00',
      exactTime: 'وقت محدد',
      travelers: 'المسافرون',
      travelerTotal: 'مسافر(ين)',
      adults: 'بالغون',
      adultsHint: '12 سنة فما فوق',
      children: 'أطفال',
      childrenHint: 'أقل من 12 سنة',
      assisted: 'ذوو الاحتياجات الخاصة',
      assistedHint: 'مساعدة خاصة في التنقل',
      budget: 'الميزانية',
      budgetMax: 'أقصى ميزانية',
      currency: 'د.ت',
      modes: 'وسيلة النقل',
      allModes: 'جميع الوسائل',
      bus: 'حافلة',
      sharedTaxi: 'لواج / تاكسي جماعي',
      train: 'قطار',
      plane: 'طيران',
      ferry: 'عبّارة بحرية',
      other: 'وسيلة أخرى',
      busStop: 'محطة الحافلات',
      taxiStop: 'محطة اللواج',
      trainStop: 'محطة القطار',
      airportStop: 'المطار',
      ferryStop: 'الميناء البحري',
      meetingStop: 'نقطة الالتقاء',
      apply: 'تطبيق',
      reset: 'إعادة ضبط',
    },
    tripPanel: {
      refineTrip: 'تحديد خيارات السفر',
      allOptional: 'جميع الحقول اختيارية',
      reset: 'إعادة ضبط',
      optional: 'اختياري',
      departure: 'نقطة الانطلاق',
      destination: 'وجهة الوصول',
      travelers: 'المسافرون',
      date: 'تاريخ السفر',
      time: 'الوقت',
      transport: 'وسيلة النقل',
      budgetMax: 'أقصى ميزانية',
      departurePlaceholder: 'ابحث عن مدينة الانطلاق…',
      arrivalPlaceholder: 'ابحث عن مدينة الوصول…',
      noCityMatches: 'لا توجد مدينة مطابقة لـ',
      departureTime: 'وقت الانطلاق',
    },
    results: {
      title: 'الرحلات والخيارات المتاحة',
      optionsFound: 'رحلة متوفرة',
      bestOption: 'الخيار الأفضل',
      bestRateReal: 'أفضل سعر حقيقي',
      direct: 'مباشر',
      directTrip: 'رحلة مباشرة',
      transfersCount: 'تحويل(ات)',
      stopsCount: 'توقف(ات)',
      departureAt: 'الانطلاق في',
      arrivalAt: 'الوصول التقديري',
      duration: 'المدة المقدرة',
      durationPrefix: 'المدة :',
      perPerson: 'للشخص',
      bookNow: 'حجز التذكرة',
      viewDetails: 'تفاصيل الرحلة',
      hideDetails: 'إخفاء التفاصيل',
      stopsItinerary: 'المحطات ومسار الرحلة',
      operator: 'الناقل',
      availableSeats: 'مقاعد متوفرة',
      availableDates: 'التواريخ المتاحة :',
      datesCount: 'تواريخ متاحة',
      availableSchedule: 'المواعيد المتاحة :',
      selectSchedule: 'اختر الموعد المناسب :',
      departuresCount: 'مواعيد انطلاق',
      seatsRemaining: 'مقاعد متبقية',
      stopPoints: 'محطات توقف',
      stopsInTotal: 'محطات في المجمل',
      waitMinutes: 'دق توقف',
      waitHours: 'ساعة توقف',
      yourBoarding: 'نقطة ركوبك',
    },
    booking: {
      modalTitle: 'تأكيد حجز التذكرة',
      stepSummary: 'تفاصيل الرحلة',
      stepDetails: 'بيانات المسافر',
      stepPayment: 'الدفع',
      stepConfirmation: 'تأكيد الحجز',
      itinerarySummary: 'ملخص مسار الرحلة',
      boardingPoint: 'نقطة الركوب',
      selectBoarding: 'اختر نقطة الركوب المفضلة',
      passengersDetails: 'بيانات المسافر الرئيسي',
      fullName: 'الاسم الكامل',
      fullNamePlaceholder: 'مثال: محمد بن سالم',
      phone: 'رقم الهاتف الجوال',
      phonePlaceholder: '+216 -- --- ---',
      email: 'البريد الإلكتروني',
      emailPlaceholder: 'example@domain.com',
      seatsToBook: 'عدد المقاعد المطلوبة',
      paymentMethod: 'طريقة الدفع',
      cardPayment: 'البطاقة المصرفية',
      cardPaymentDesc: 'فيزا، ماستركارد، CIB، e-Dinar',
      mobileWallet: 'المحفظة الإلكترونية',
      mobileWalletDesc: 'فلوسي، D17، سداد، معاملات، بريدي موب',
      cashOnBoard: 'الدفع عند الانطلاق',
      cashOnBoardDesc: 'تسديد المبلغ نقداً في محطة الركوب',
      cardNumber: 'رقم البطاقة',
      expiry: 'تاريخ الانتهاء (شهر/سنة)',
      cvv: 'رمز الأمان (CVV)',
      selectWallet: 'اختر المحفظة الإلكترونية',
      totalToPay: 'المبلغ الإجمالي',
      payAndConfirm: 'إتمام الدفع وتأكيد الحجز',
      confirmReservation: 'تأكيد الحجز',
      processingTitle: 'جارٍ معالجة الدفع بأمان...',
      processingDesc: 'يرجى الانتظار أثناء تأكيد العملية مع مزود الخدمة.',
      successTitle: 'تم تأكيد حجزك بنجاح!',
      successDesc: 'تم إصدار تذكرتك بنجاح. يُرجى إظهار هذا الإيصال عند الصعود.',
      bookingRef: 'رقم مرجع الحجز',
      ticketNotice: 'تم إرسال رسالة نصية قصيرة تتضمن تفاصيل التذكرة إلى هاتفك.',
      finish: 'إنهاء',
      seatSingular: 'مقعد',
      seatPlural: 'مقاعد',
      totalPlace: 'المجموع',
      modifyTravelers: 'تعديل عدد المسافرين :',
      selectedCount: 'تم اختيار',
      perTraveler: '/ للمسافر',
      departureAtTime: 'الانطلاق في',
      boardingPointLegend: 'نقطة الركوب',
      stopsItineraryTitle: 'محطات مسار الرحلة',
      stopsCountParenthesis: 'محطات',
      payNow: 'الدفع الآن',
      cancelBtn: 'إلغاء',
      doneBtn: 'إنهاء',
      provisionalNotice: 'يتم حجز المقعد مؤقتًا. لا يتم خصم أي مبلغ مالي قبل تأكيد عملية الدفع.',
      chooseCardBrand: 'اختر نوع البطاقة المصرفية :',
      secureMobileTitle: 'دفع إلكتروني فوري وآمن',
      phoneNumberLabel: 'رقم الهاتف الجوال',
      smsNotice: 'سيتم إرسال رسالة نصية قصيرة تحتوي على رمز التأكيد إلى هذا الرقم.',
      agencyNoticeTitle: 'حجز مع إمكانية الدفع في مكتب الوكالة',
      agencyNoticeText: 'سيتم حجز مقعدك لمدة ساعتين. يرجى التوجه إلى شباك التذاكر في محطة الانطلاق مع مرجع الحجز لدفع المبلغ.',
      securityBadge: 'بيانات مصرفية آمنة 100% ومشفرة بالكامل من البداية إلى النهاية',
      validatingPayment: 'جارٍ التحقق من عملية الدفع...',
      connectingBank: 'جارٍ الاتصال الآمن مع الخادم المصرفي المعتمد.',
      paymentSuccessTitle: 'تم تأكيد الدفع بنجاح!',
      paymentSuccessSub: 'تم إصدار تذكرتك وتأكيد حجزك فوراً.',
      copyRefTitle: 'نسخ رقم الحجز',
      summaryRoute: 'مسار الرحلة',
      summaryDateTime: 'التاريخ والوقت',
      summaryTravelers: 'المسافرون',
      summaryBoarding: 'مكان الصعود',
      summaryPaymentMode: 'طريقة الدفع',
      summaryTotalAmount: 'المبلغ الإجمالي',
      arriveEarlyNotice: 'يرجى التواجد في المحطة قبل 20 دقيقة من موعد الانطلاق.',
      archiveChatNotice: 'سيتم حفظ ملخص الحجز في المحادثة بمجرد الضغط على « إنهاء ».',
      retryWithCard: 'إعادة المحاولة ببطاقة أخرى',
      visaCard: 'بطاقة فيزا',
      mastercardCard: 'بطاقة ماستركارد',
      cibCard: 'بطاقة CIB',
      edinarCard: 'بطاقة e-Dinar',
    },
    bookingCard: {
      successHeader: 'تم تأكيد الحجز بنجاح',
      refPrefix: 'مرجع الحجز:',
      travelDate: 'تاريخ الرحلة',
      travelers: 'المسافرون',
      durationPrefix: 'المدة :',
      boardingAt: 'الصعود في',
      atTime: 'عند',
      paymentMethodLabel: 'طريقة الدفع :',
      directTrip: 'رحلة مباشرة',
      stopsCount: 'محطات توقف',
      totalStops: 'محطات في المجمل',
      payCashAgency: 'دفع نقدي في الوكالة',
    },
    history: {
      title: 'سجل المحادثات والرحلات',
      searchPlaceholder: 'ابحث في السجل السابق...',
      empty: 'لا يوجد سجل سابق حتى الآن',
      emptyDesc: 'ستظهر هنا جميع رحلاتك وبحوثك السابقة.',
      newChat: 'محادثة جديدة',
      today: 'اليوم',
      yesterday: 'أمس',
      thisMonth: 'هذا الشهر',
      older: 'أقدم من ذلك',
      deletePrompt: 'هل ترغب في حذف هذه المحادثة؟',
      conversationsCount: 'محادثات',
      clearAll: 'مسح السجل بالكامل',
      noResultsFor: 'لا توجد نتائج لـ',
      tripsLabel: 'خيارات',
      bookedLabel: 'مؤكد',
      clearHistoryConfirm: 'هل أنت متأكد من رغبتك في حذف كامل سجل المحادثات؟',
    },
    tripDashboard: {
      tripDashboard: 'تفاصيل الرحلة',
      hideDashboard: 'إخفاء لوحة التحكم',
      showDashboard: 'إظهار لوحة التحكم',
      precisionsCount: 'معيار محدد',
      noPrecisions: '0 معيار',
      searchTripsBtn: 'البحث عن الرحلات',
      chooseDeparturePoint: 'نقطة الانطلاق',
      chooseArrivalPoint: 'نقطة الوصول',
      clearFilters: 'مسح',
      selectDate: 'تاريخ السفر',
      selectTime: 'التوقيت المفضل',
      selectTravelers: 'المسافرون',
      selectTransport: 'وسيلة النقل',
      allCities: 'جميع المدن',
      popularCities: 'المدن الرئيسية',
      swapCities: 'تبديل الانطلاق والوصول',
      selectPrecisions: 'محطات التوقف والميزانية',
      stopsPreference: 'محطات مسار الرحلة',
      directOnly: 'رحلات مباشرة فقط (بدون توقف)',
      allTrips: 'جميع الرحلات (مباشرة ومع توقف)',
      budgetMax: 'أقصى ميزانية',
    },
    serverConfig: {
      serverConfig: 'إعدادات الخادم',
      serverConfigTooltip: 'تكوين الخادم',
      apiUrlLabel: 'رابط خادم FastAPI :',
      serverSet: 'تم تحديد الخادم :',
      testConnection: 'اختبار الاتصال',
      serverOnline: 'تم الاتصال بالخادم بنجاح (200 OK)',
      serverOffline: 'تعذر الاتصال بالخادم',
      testing: 'جارٍ الفحص...',
      saved: 'تم الحفظ!',
      usbAdbPreset: 'USB / ADB (127.0.0.1)',
      wifiPreset: 'Wi-Fi (192.168.100.15)',
      emulatorPreset: 'محاكي (10.0.2.2)',
    },
    conflicts: {
      title: 'تم رصد تغيير في خيارات السفر',
      detected: 'المعطى السابق المسجل :',
      keepCurrent: 'الإبقاء على الحالي',
      updateTo: 'تحديث إلى الجديد',
    },
    noResults: {
      tryTomorrow: 'تغيير التاريخ',
      removeMode: 'جميع وسائل النقل',
      removeBudget: 'توسيع الميزانية',
      tryTomorrowMsg: 'ابحث عن رحلات ليوم غد',
      removeAllModesMsg: 'أزل فلتر وسيلة النقل، أي وسيلة تناسبني.',
      removeBudgetMsg: 'إزالة حد الميزانية',
    },
    errorNotice: {
      message: 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة مجدداً.',
      retry: 'إعادة المحاولة',
    },
    travelers: {
      adult: 'بالغ',
      adults: 'بالغون',
      child: 'طفل',
      children: 'أطفال',
      assisted: 'من ذوي الاحتياجات',
      assisteds: 'من ذوي الاحتياجات',
      defaultOne: 'بالغ واحد',
    },
    paymentLabels: {
      card: 'البطاقة المصرفية',
      cardDesc: 'فيزا، ماستركارد، CIB، e-Dinar',
      mobileTn: 'الدفع الإلكتروني (تونس)',
      mobileTnDesc: 'D17، MyPos، Sobflous',
      mobileLy: 'الدفع الإلكتروني (ليبيا)',
      mobileLyDesc: 'Mobi Cash، سداد',
      mobileDz: 'الدفع الإلكتروني (الجزائر)',
      mobileDzDesc: 'بريدي موب، ذهبية',
      cash: 'الدفع في مكتب الوكالة',
      cashDesc: 'احجز الآن وادفع عند الحضور',
      paymentMethodCard: 'بطاقة مصرفية',
      paymentMethodCash: 'دفع نقدي في الوكالة',
      paymentMethodMobile: 'محفظة إلكترونية',
      paymentError: 'فشلت عملية الدفع',
      composerHint: 'اكتب استفسارك بحرية أو استخدم التسجيل الصوتي، يمكنك أيضاً النقر على « + » لتحديد خيارات الرحلة مباشرة.',
    },
  },
  en: {
    common: {
      close: 'Close',
      cancel: 'Cancel',
      confirm: 'Confirm',
      save: 'Save',
      back: 'Back',
      next: 'Next',
      loading: 'Loading...',
      retry: 'Retry',
      copied: 'Copied!',
      copy: 'Copy',
    },
    header: {
      subtitle: 'Transport Assistant · Tunisia · Algeria · Libya · Egypt',
      newSearch: 'New Search',
      newSearchMobile: 'New',
      history: 'History',
      settingsTooltip: 'Server Settings',
    },
    suggestions: {
      badge: 'Suggested Queries',
      title: 'Where would you like to travel?',
      q1: 'I want to travel from Tripoli to Tunis tomorrow morning with 2 adults.',
      q2: 'Check schedules from Tunis to Tripoli for today.',
      q3: 'What travel options are available from Misrata to Tunis?',
      q4: 'Show me ticket prices between Tripoli and Sfax.',
    },
    composer: {
      placeholder: 'Ask your question (e.g., Bus from Tunis to Sousse tomorrow morning)...',
      recording: 'Recording audio...',
      transcribing: 'Transcribing your voice...',
      sendTooltip: 'Send message',
      speechTooltip: 'Voice input',
      filtersTooltip: 'Trip criteria',
      openFilters: 'Show filters',
      activeFilters: 'active filters',
    },
    trip: {
      departure: 'Departure',
      arrival: 'Destination',
      selectDeparture: 'Select origin',
      selectArrival: 'Select destination',
      searchCity: 'Search for a city...',
      date: 'Date',
      today: 'Today',
      tomorrow: 'Tomorrow',
      time: 'Time',
      morning: 'Morning',
      morningRange: '05:00 – 12:00',
      afternoon: 'Afternoon',
      afternoonRange: '12:00 – 18:00',
      evening: 'Evening',
      eveningRange: '18:00 – 23:00',
      exactTime: 'Exact time',
      travelers: 'Travelers',
      travelerTotal: 'traveler(s)',
      adults: 'Adults',
      adultsHint: '12 years & older',
      children: 'Children',
      childrenHint: 'Under 12 years',
      assisted: 'PRM / Assistance',
      assistedHint: 'Reduced mobility',
      budget: 'Budget',
      budgetMax: 'Max budget',
      currency: 'TND',
      modes: 'Transport Mode',
      allModes: 'All modes',
      bus: 'Bus',
      sharedTaxi: 'Shared Taxi / Louage',
      train: 'Train',
      plane: 'Flight',
      ferry: 'Ferry',
      other: 'Other',
      busStop: 'Bus Terminal',
      taxiStop: 'Louage Station',
      trainStop: 'Railway Station',
      airportStop: 'Airport',
      ferryStop: 'Seaport',
      meetingStop: 'Meeting point',
      apply: 'Apply',
      reset: 'Reset',
    },
    tripPanel: {
      refineTrip: 'Refine your trip',
      allOptional: 'All optional',
      reset: 'Reset',
      optional: 'Optional',
      departure: 'Departure',
      destination: 'Destination',
      travelers: 'Travelers',
      date: 'Date',
      time: 'Time',
      transport: 'Transport',
      budgetMax: 'Max budget',
      departurePlaceholder: 'Search departure city…',
      arrivalPlaceholder: 'Search destination city…',
      noCityMatches: 'No city matches',
      departureTime: 'Departure time',
    },
    results: {
      title: 'Available Itineraries',
      optionsFound: 'options found',
      bestOption: 'Best Option',
      bestRateReal: 'Best real rate',
      direct: 'direct',
      directTrip: 'Direct trip',
      transfersCount: 'transfer(s)',
      stopsCount: 'stop(s)',
      departureAt: 'Departure at',
      arrivalAt: 'Est. arrival',
      duration: 'Duration',
      durationPrefix: 'Duration:',
      perPerson: 'per person',
      bookNow: 'Book Now',
      viewDetails: 'Trip details',
      hideDetails: 'Hide details',
      stopsItinerary: 'Stops & Connections',
      operator: 'Carrier',
      availableSeats: 'seats available',
      availableDates: 'Available dates:',
      datesCount: 'dates',
      availableSchedule: 'Available schedule:',
      selectSchedule: 'Select your schedule:',
      departuresCount: 'departures',
      seatsRemaining: 'seats left',
      stopPoints: 'stops',
      stopsInTotal: 'total stops',
      waitMinutes: 'min stop',
      waitHours: 'h stop',
      yourBoarding: 'Your boarding',
    },
    booking: {
      modalTitle: 'Trip Booking',
      stepSummary: 'Summary',
      stepDetails: 'Passengers',
      stepPayment: 'Payment',
      stepConfirmation: 'Confirmation',
      itinerarySummary: 'Itinerary details',
      boardingPoint: 'Boarding point',
      selectBoarding: 'Select your boarding point',
      passengersDetails: 'Lead passenger details',
      fullName: 'Full Name',
      fullNamePlaceholder: 'e.g. Mohamed Ben Salem',
      phone: 'Phone Number',
      phonePlaceholder: '+216 -- --- ---',
      email: 'Email Address',
      emailPlaceholder: 'example@domain.com',
      seatsToBook: 'Number of seats',
      paymentMethod: 'Payment method',
      cardPayment: 'Credit / Debit Card',
      cardPaymentDesc: 'Visa, Mastercard, CIB, e-Dinar',
      mobileWallet: 'Mobile Wallet',
      mobileWalletDesc: 'Flouci, D17, Sadad, Moamalat, BaridiMob',
      cashOnBoard: 'Pay on departure',
      cashOnBoardDesc: 'Pay cash when boarding',
      cardNumber: 'Card number',
      expiry: 'Expiration date (MM/YY)',
      cvv: 'CVV security code',
      selectWallet: 'Select mobile wallet provider',
      totalToPay: 'Total to pay',
      payAndConfirm: 'Pay & confirm booking',
      confirmReservation: 'Confirm reservation',
      processingTitle: 'Securing your payment...',
      processingDesc: 'Please wait while we verify your transaction.',
      successTitle: 'Booking confirmed successfully!',
      successDesc: 'Your electronic ticket is ready. Show this receipt when boarding.',
      bookingRef: 'Booking Reference',
      ticketNotice: 'A confirmation SMS with your trip details has been sent to your phone.',
      finish: 'Done',
      seatSingular: 'seat',
      seatPlural: 'seats',
      totalPlace: 'Total',
      modifyTravelers: 'Modify travelers:',
      selectedCount: 'selected',
      perTraveler: '/ traveler',
      departureAtTime: 'Departure at',
      boardingPointLegend: 'Boarding point',
      stopsItineraryTitle: 'Itinerary stops',
      stopsCountParenthesis: 'stops',
      payNow: 'Pay now',
      cancelBtn: 'Cancel',
      doneBtn: 'Done',
      provisionalNotice: 'Seat reserved temporarily. No charges applied until payment is confirmed.',
      chooseCardBrand: 'Choose card type:',
      secureMobileTitle: 'Instant secure mobile payment',
      phoneNumberLabel: 'Mobile phone number',
      smsNotice: 'An SMS with confirmation code will be sent to this number.',
      agencyNoticeTitle: 'Reservation with in-agency payment',
      agencyNoticeText: 'Your seat will be held for 2 hours. Please visit the ticket counter at departure point with your reference to pay.',
      securityBadge: '100% secure end-to-end encrypted banking data',
      validatingPayment: 'Validating payment…',
      connectingBank: 'Secure connection with the banking server in progress.',
      paymentSuccessTitle: 'Payment confirmed successfully!',
      paymentSuccessSub: 'Your ticket is immediately issued and confirmed.',
      copyRefTitle: 'Copy booking reference',
      summaryRoute: 'Route',
      summaryDateTime: 'Date & Time',
      summaryTravelers: 'Travelers',
      summaryBoarding: 'Boarding place',
      summaryPaymentMode: 'Payment method',
      summaryTotalAmount: 'Total amount',
      arriveEarlyNotice: 'Please arrive 20 minutes before departure time.',
      archiveChatNotice: 'The booking summary will be archived in chat once you click "Done".',
      retryWithCard: 'Retry with another card',
      visaCard: 'Visa Card',
      mastercardCard: 'Mastercard',
      cibCard: 'CIB Card',
      edinarCard: 'e-Dinar Card',
    },
    bookingCard: {
      successHeader: 'Booking confirmed successfully',
      refPrefix: 'Ref.',
      travelDate: 'Travel date',
      travelers: 'Travelers',
      durationPrefix: 'Duration:',
      boardingAt: 'Boarding at',
      atTime: 'at',
      paymentMethodLabel: 'Payment method:',
      directTrip: 'Direct trip',
      stopsCount: 'stops',
      totalStops: 'total stops',
      payCashAgency: 'Pay at agency',
    },
    history: {
      title: 'Search History',
      searchPlaceholder: 'Search past trips...',
      empty: 'No search history yet',
      emptyDesc: 'Your conversations and itineraries will be saved here.',
      newChat: 'New conversation',
      today: 'Today',
      yesterday: 'Yesterday',
      thisMonth: 'This month',
      older: 'Older',
      deletePrompt: 'Delete this conversation?',
      conversationsCount: 'conversations',
      clearAll: 'Clear all history',
      noResultsFor: 'No results for',
      tripsLabel: 'trips',
      bookedLabel: 'booked',
      clearHistoryConfirm: 'Are you sure you want to clear all conversation history?',
    },
    tripDashboard: {
      tripDashboard: 'Trip criteria',
      hideDashboard: 'Hide dashboard',
      showDashboard: 'Show dashboard',
      precisionsCount: 'criteria',
      noPrecisions: '0 criteria',
      searchTripsBtn: 'Search trips',
      chooseDeparturePoint: 'Departure point',
      chooseArrivalPoint: 'Arrival point',
      clearFilters: 'Clear',
      selectDate: 'Trip date',
      selectTime: 'Time slot',
      selectTravelers: 'Passengers',
      selectTransport: 'Transport',
      allCities: 'All cities',
      popularCities: 'Main cities',
      swapCities: 'Swap departure and arrival',
      selectPrecisions: 'Stops & Preferences',
      stopsPreference: 'Stops & Itinerary',
      directOnly: 'Direct trips only (no stops)',
      allTrips: 'All trips (direct and with stops)',
      budgetMax: 'Maximum budget',
    },
    serverConfig: {
      serverConfig: 'Backend Connection',
      serverConfigTooltip: 'Configure server',
      apiUrlLabel: 'FastAPI API URL:',
      serverSet: 'Server configured:',
      testConnection: 'Test connection',
      serverOnline: 'Server online (200 OK)',
      serverOffline: 'Unable to reach server',
      testing: 'Testing...',
      saved: 'Saved!',
      usbAdbPreset: 'USB / ADB (127.0.0.1)',
      wifiPreset: 'Wi-Fi (192.168.100.15)',
      emulatorPreset: 'Emulator (10.0.2.2)',
    },
    conflicts: {
      title: 'Change in criteria detected',
      detected: 'You previously specified:',
      keepCurrent: 'Keep current',
      updateTo: 'Update to',
    },
    noResults: {
      tryTomorrow: 'Change date',
      removeMode: 'All transport modes',
      removeBudget: 'Expand budget',
      tryTomorrowMsg: 'Search trips for tomorrow',
      removeAllModesMsg: 'Remove transport filter, any mode is fine.',
      removeBudgetMsg: 'Remove budget limit',
    },
    errorNotice: {
      message: 'An error occurred. Please try again.',
      retry: 'Retry',
    },
    travelers: {
      adult: 'adult',
      adults: 'adults',
      child: 'child',
      children: 'children',
      assisted: 'assisted',
      assisteds: 'assisted',
      defaultOne: '1 adult',
    },
    paymentLabels: {
      card: 'Credit / Debit Card',
      cardDesc: 'Visa, Mastercard, CIB, e-Dinar',
      mobileTn: 'Mobile Payment (Tunisia)',
      mobileTnDesc: 'D17, MyPos, Sobflous',
      mobileLy: 'Mobile Payment (Libya)',
      mobileLyDesc: 'Mobi Cash, Sadad',
      mobileDz: 'Mobile Payment (Algeria)',
      mobileDzDesc: 'BaridiMob, Dahabiya',
      cash: 'Pay at Agency',
      cashDesc: 'Book now, pay on-site',
      paymentMethodCard: 'Credit/Debit Card',
      paymentMethodCash: 'Pay at Agency',
      paymentMethodMobile: 'Mobile Wallet',
      paymentError: 'Payment failed',
      composerHint: 'Type or speak freely, use "+" to set trip options, or combine both. Live data & schedules.',
    },
  },
}
