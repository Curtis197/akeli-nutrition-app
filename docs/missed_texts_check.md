# Missed Texts Check
This file contains potentially user-facing strings that might have been missed by the first extraction script.

## File: `lib/core/logger.dart`
- [L22] `🔄 Provider: MyProvider initialized`
- [L83, L85] `🔐 Auth: $message`
- [L94, L96] `📡 DB: $message`
- [L105] `🚫 RLS: $message`
- [L107] `🔍 RLS: $message`
- [L116, L118] `🔄 Provider: $message`
- [L127, L129] `⚡ Function: $functionName - $message`
- [L137] ` [screen: $screen]`
- [L138] ` | metadata: $metadata`
- [L139] `🎯 UI: $action$screenContext$metaStr`
- [L146] ` [reason: $reason]`
- [L147] `🧭 Navigation: $from → $to$reasonStr`
- [L154] ` | $context`
- [L156, L158] `⏱️ Perf: $operation took ${duration.inMilliseconds}ms$contextStr`
- [L176] `${localPart.substring(0, 3)}***`
- [L180] `${domainPart.substring(0, 3)}***`
- [L193] `${uuid.substring(0, 4)}***${uuid.substring(uuid.length - 4)}`
- [L199] `${token.substring(0, 10)}...${token.substring(token.length - 10)}`
- [L239] `🔍 RLS DEBUG: Querying "$tableName" table`
- [L240] `  userId: ${userId ?? "null (not authenticated)"}`
- [L241] `  filters: ${filters ?? "none"}`
- [L242] `  rows returned: $rowCount`
- [L245] `⚠️ RLS DEBUG: Possible RLS policy blocking userId: $userId`
- [L246] `  Check policies on "$tableName" table for auth_uid() match`
- [L258] `✅ RLS: Policy "$policyName" on "$tableName" allowed for userId: $userId`
- [L260] `🚫 RLS: Policy "$policyName" on "$tableName" blocked for userId: $userId`

## File: `lib/core/notification_handler.dart`
- [L12] `FCM background message | type: ${message.data[`
- [L12] `]} | id: ${message.messageId}`
- [L17] `Notification tapped | type: $type`

## File: `lib/core/nutrition_calculator.dart`
- [L73] `snack_${i - 2}`

## File: `lib/core/quantity_formatter.dart`
- [L32] ` $unit`
- [L44] `$whole $fractionStr$suffix`

## File: `lib/core/router.dart`
- [L132] `redirect check | isAuth: $isAuth | hasProfile: ${profile != null}`
- [L136] `unauthenticated → redirect to auth`
- [L141] `ll redirect to onboarding if needed.\n        appLogger.navigation(state.uri.path, AkeliRoutes.home, reason: `
- [L142] `);\n        return AkeliRoutes.home;\n      }\n\n      if (isAuth) {\n        if (profile != null) {\n          if (!profile.onboardingDone && !isOnOnboarding) {\n            final path = state.uri.path;\n            if (path == AkeliRoutes.privacyPolicy || path == AkeliRoutes.termsOfService) {\n              return null;\n            }\n            appLogger.navigation(state.uri.path, AkeliRoutes.onboarding, reason: `
- [L153] `);\n            return AkeliRoutes.onboarding;\n          }\n          if (profile.onboardingDone && isOnOnboarding) {\n            appLogger.navigation(state.uri.path, AkeliRoutes.home, reason: `
- [L157] `);\n            return AkeliRoutes.home;\n          }\n        }\n      }\n      \n      return null;\n    },\n    routes: [\n      GoRoute(\n        path: AkeliRoutes.auth,\n        builder: (context, state) => const AuthPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.onboarding,\n        builder: (context, state) => const OnboardingPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.recipeDetail,\n        builder: (context, state) {\n          final recipeId = state.pathParameters[`
- [L177] `]!;\n          final source = state.extra as TrackingSource? ?? TrackingSource.feed;\n          return RecipeDetailPage(recipeId: recipeId, source: source);\n        },\n        routes: [\n          GoRoute(\n            path: `
- [L183] `,\n            builder: (context, state) {\n              final extra = state.extra as Map<String, dynamic>?;\n              if (extra == null || extra[`
- [L186] `] == null) {\n                final recipeId = state.pathParameters[`
- [L187] `]!;\n                appLogger.navigation(\n                  `
- [L190] `,\n                  reason: `
- [L191] `,\n                );\n                return RecipeDetailPage(recipeId: recipeId, source: TrackingSource.feed);\n              }\n              appLogger.userAction(\n                `
- [L196] `,\n                screen: `
- [L197] `,\n                metadata: {`
- [L198] `: state.pathParameters[`
- [L198] `]},\n              );\n              return CookingModePage(\n                recipe: extra[`
- [L201] `] as Recipe,\n                initialStepIndex: (extra[`
- [L202] `] as int?) ?? 0,\n              );\n            },\n          ),\n        ],\n      ),\n      GoRoute(\n        path: AkeliRoutes.shoppingList,\n        builder: (context, state) => const ShoppingListPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.nutrition,\n        builder: (context, state) => const NutritionPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.fanMode,\n        builder: (context, state) => const FanModePage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.subscription,\n        builder: (context, state) => const SubscriptionPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.aiChat,\n        builder: (context, state) => const AiChatPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.profile,\n        builder: (context, state) => const ProfilePage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.settings,\n        builder: (context, state) => const SettingsPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.dietPlan,\n        builder: (context, state) => const DietPlanPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.notifications,\n        builder: (context, state) => const NotificationsPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.notificationSettings,\n        builder: (context, state) => const NotificationSettingsPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.account,\n        builder: (context, state) => const AccountPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.mealDetail,\n        builder: (context, state) {\n          final id = state.pathParameters["id"]!;\n          return MealDetailPage(mealId: id);\n        },\n        routes: [\n          GoRoute(\n            path: `
- [L260] `,\n            builder: (context, state) {\n              final id = state.pathParameters["id"]!;\n              return FeedPage(swapEntryId: id);\n            },\n          ),\n        ],\n      ),\n      GoRoute(\n        path: AkeliRoutes.batchCooking,\n        builder: (context, state) => const BatchCookingPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.batchCookingDetail,\n        builder: (context, state) {\n          final sessionId = state.pathParameters[`
- [L275] `]!;\n          final extra = state.extra as Map<String, dynamic>?;\n          final initialSession = extra?[`
- [L277] `] as CookingSession?;\n          return BatchCookingDetailPage(\n            sessionId: sessionId,\n            initialSession: initialSession,\n          );\n        },\n      ),\n      GoRoute(\n        path: AkeliRoutes.nutritionPlan,\n        builder: (context, state) => const NutritionPlanPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.groupChat,\n        builder: (context, state) {\n          final id = state.pathParameters["id"]!;\n          return GroupChatPage(groupId: id);\n        },\n        routes: [\n          GoRoute(\n            path: `
- [L296] `,\n            builder: (context, state) {\n              final id = state.pathParameters["id"]!;\n              return GroupDetailPage(groupId: id);\n            },\n          ),\n        ],\n      ),\n      GoRoute(\n        path: AkeliRoutes.browseGroups,\n        builder: (context, state) => const BrowseGroupsPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.support,\n        builder: (context, state) => const SupportPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.privacyPolicy,\n        builder: (context, state) => const PrivacyPolicyPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.termsOfService,\n        builder: (context, state) => const TermsOfServicePage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.referral,\n        builder: (context, state) => const ReferralPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.preferences,\n        builder: (context, state) => const PreferencesPage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.healthProfile,\n        builder: (context, state) => const HealthProfilePage(),\n      ),\n      GoRoute(\n        path: AkeliRoutes.creatorDetail,\n        builder: (context, state) {\n          final creatorId = state.pathParameters[`
- [L335] `]!;\n          return CreatorDetailPage(creatorId: creatorId);\n        },\n      ),\n      GoRoute(\n        path: AkeliRoutes.userProfile,\n        builder: (context, state) {\n          final userId = state.pathParameters[`
- [L350] `]!;\n          final title = state.extra as String? ?? `

## File: `lib/core/supabase_client.dart`
- [L9] `📡 Supabase: initializing | url: $_supabaseUrl`
- [L14] `✅ Supabase: client ready`
- [L19] `🔄 Provider: supabaseClientProvider created (keepAlive)`

## File: `lib/core/theme.dart`
- [L19] `The Organic Layer`

## File: `lib/features/ai_assistant/ai_chat_page.dart`
- [L37] `AiChatNotifier build()`
- [L38] `AiChatNotifier disposed`
- [L43] `AiChatNotifier sendMessage | content length: ${content.trim().length}`
- [L61] `AiChatNotifier → loading (sending)`
- [L70] `BEFORE | conversationId: ${_conversationId ?? "new"} | messageLength: ${content.trim().length}`
- [L82] `AFTER | conversationId: $_conversationId | pathType: ${data[`
- [L82] `]} | tokens: ${data[`
- [L93] `AiChatNotifier → data | messages: ${state.length}`
- [L95] `ERROR | $e`
- [L96] `AiChatNotifier → error | $e`
- [L102] `Désolé, une erreur est survenue. Réessayez dans un moment.`
- [L110] `AiChatNotifier clear()`
- [L138] `AiChatPage disposed`
- [L158] `Send message tapped`
- [L169] `AiChatPage build() | messageCount: ${messages.length} | hasLoading: $hasLoading`
- [L225] `Clear conversation tapped`
- [L321] `Message submitted via keyboard`
- [L364] `Send button tapped`
- [L387] `Quels aliments riches en protéines pour ma culture ?`
- [L388] `Quel est mon apport calorique recommandé ?`
- [L389] `Comment perdre du poids avec la cuisine africaine ?`
- [L390] `Donne-moi une recette pour ce soir.`
- [L395] `WelcomeView build()`
- [L439] `Suggestion tapped`
- [L479] `${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}`
- [L573] `TypingIndicator initState()`
- [L599] `TypingIndicator disposed`

## File: `lib/features/auth/auth_page.dart`
- [L41] `_AuthPageState disposed`
- [L51] `Sign-up form submitted`
- [L53] `signUp triggered from AuthPage | email: ${LogHelper.maskEmail(_signUpEmail.text.trim())}`
- [L55] `AuthPage: sign-up form validation passed`
- [L64] `signUp ERROR displayed to user | error: ${s.error}`
- [L67] `signUp SUCCESS | navigating to onboarding`
- [L73] `Login form submitted`
- [L75] `signIn triggered from AuthPage | email: ${LogHelper.maskEmail(_loginEmail.text.trim())}`
- [L85] `signIn ERROR displayed to user | error: ${s.error}`
- [L88] `signIn SUCCESS | router redirect will handle navigation`
- [L93] `Invalid login credentials`
- [L93] `Email ou mot de passe incorrect.`
- [L94] `User already registered`
- [L94] `Cet email est déjà utilisé.`
- [L95] `Password should be`
- [L95] `Le mot de passe doit contenir au moins 6 caractères.`
- [L97] `email not confirmed`
- [L98] `Veuillez confirmer votre adresse email avant de vous connecter.`
- [L100] `Une erreur est survenue. Réessayez.`
- [L105] `_AuthPageState build() | tab: ${_isLogin ? "login" : "signup"}`
- [L169] `Auth tab toggled`
- [L378] `Entrez votre email`
- [L382, L477] `Email requis`
- [L383] `Email invalide`
- [L390] `Créez un mot de passe`
- [L396, L490] `Mot de passe requis`
- [L397] `Minimum 8 caractères`
- [L404] `Confirmez le mot de passe`
- [L411] `Les mots de passe ne correspondent pas`
- [L484] `Mot de passe`

## File: `lib/features/auth/onboarding_data.dart`
- [L113] `OnboardingNotifier build()`
- [L118] `OnboardingNotifier → updateLanguage | $v`
- [L123] `OnboardingNotifier → updateConsent | privacy: $privacy | cgu: $cgu`
- [L135] `OnboardingNotifier → updateProfile | name: $name | sex: $sex`
- [L155] `OnboardingNotifier → updateGoals | cookingTime: $cookingTime | batchEnabled: $batchCookingEnabled | batchMax: $batchMaxPortions`
- [L175] `OnboardingNotifier → updatePreferences | noPork: $noPork | noMeat: $noMeat | noGluten: $noGluten | noLactose: $noLactose`
- [L187] `OnboardingNotifier → updateCuisineRegion | code: $code`

## File: `lib/features/auth/onboarding_page.dart`
- [L36] `_OnboardingPageState disposed`
- [L42] `Onboarding next tapped`
- [L46] `Veuillez accepter les deux conditions pour continuer.`
- [L47] `Veuillez entrer votre prénom pour continuer.`
- [L48] `Veuillez entrer votre poids cible pour continuer.`
- [L67] `Onboarding back tapped`
- [L86] `Onboarding submitted`
- [L97] `${DateTime.now().year - d.age!}-01-01`
- [L109] `};\n    if (d.weightGoal == `
- [L110, L111, L112, L113, L114, L115] `) goalSet.add(`
- [L110, L111] `);\n    if (d.weightGoal == `
- [L112, L113, L114] `);\n    if (d.muscleGoal == `
- [L115] `);\n    final inferredGoals = goalSet.toList();\n\n    final body = <String, dynamic>{\n      `
- [L119] `: d.name,\n      if (d.sex != null) `
- [L120] `: d.sex,\n      if (birthDate != null) `
- [L121] `: birthDate,\n      if (d.height != null) `
- [L122] `: d.height,\n      if (d.weight != null) `
- [L123] `: d.weight,\n      if (d.targetWeight != null) `
- [L124] `: d.targetWeight,\n      if (d.activityLevel != null) `
- [L125] `: d.activityLevel,\n      `
- [L126] `: inferredGoals,\n      if (d.weightGoal != null) `
- [L127] `: d.weightGoal,\n      if (d.muscleGoal != null) `
- [L128] `: d.muscleGoal,\n      if (d.cookingTime != null) `
- [L129] `: d.cookingTime,\n      `
- [L130] `: d.batchCookingEnabled,\n      `
- [L131] `: d.batchMaxPortions,\n      `
- [L132] `: restrictions,\n      `
- [L133] `: d.allergens.map((a) => a.id).toList(),\n      `
- [L134] `: d.cuisinePreferences,\n      if (d.consentPrivacy) `
- [L135] `: now,\n      if (d.consentCgu) `
- [L136] `: now,\n    };\n\n    try {\n      _logger.edge(`
- [L140] `);\n      await client.functions.invoke(`
- [L141] `, body: body);\n      _logger.edge(`
- [L146] `);\n      client.functions.invoke(`
- [L147] `, body: {\n        `
- [L149] `: 3,\n      }).then((_) {\n        _logger.edge(`
- [L151] `);\n      }).catchError((Object e) {\n        _logger.edge(`
- [L153] `);\n      });\n      if (mounted) context.go(AkeliRoutes.home);\n    } catch (e, st) {\n      _logger.edge(`
- [L157] `, error: e, stackTrace: st);\n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          const SnackBar(\n            content: Text(\n              `
- [L162] `,\n            ),\n          ),\n        );\n        context.go(AkeliRoutes.home);\n      }\n    } finally {\n      if (mounted) setState(() => _isSubmitting = false);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    _logger.provider(`
- [L175] `);\n    return Scaffold(\n      backgroundColor: AkeliColors.surfaceContainerLow,\n      body: SafeArea(\n        child: Column(\n          children: [\n            _OnboardingHeader(\n              step: _currentStep,\n              totalSteps: _totalSteps,\n              onBack: _currentStep > 0 ? _back : null,\n              onSkip: () {\n                _logger.userAction(`
- [L186, L503, L983, L1162, L1169] `, screen: `
- [L186, L503, L983, L1162, L1169, L1301, L1312, L1323, L1352, L1363, L1374] `, metadata: {`
- [L186] `: _currentStep});\n                context.go(AkeliRoutes.home);\n              },\n            ),\n            Expanded(\n              child: PageView(\n                controller: _pageController,\n                physics: const NeverScrollableScrollPhysics(),\n                onPageChanged: (i) {\n                  _logger.provider(`
- [L262] `,\n                  textAlign: TextAlign.center,\n                  style: GoogleFonts.plusJakartaSans(\n                    fontSize: 22,\n                    fontWeight: FontWeight.w800,\n                    color: AkeliColors.primary,\n                  ),\n                ),\n              ),\n              TextButton(\n                onPressed: onSkip,\n                child: Text(\n                  `
- [L274] `,\n                  style: GoogleFonts.inter(\n                    fontSize: 13,\n                    fontWeight: FontWeight.w600,\n                    color: AkeliColors.primary,\n                    letterSpacing: 0.05,\n                  ),\n                ),\n              ),\n            ],\n          ),\n        ),\n        Padding(\n          padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.lg),\n          child: Column(\n            children: [\n              Row(\n                mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                children: [\n                  Text(\n                    `
- [L294] `,\n                    style: GoogleFonts.inter(\n                        fontSize: 11,\n                        fontWeight: FontWeight.w600,\n                        color: AkeliColors.onSurfaceVariant,\n                        letterSpacing: 0.08),\n                  ),\n                  Text(\n                    `
- [L375] `,\n                      style: GoogleFonts.plusJakartaSans(\n                        fontSize: 15,\n                        fontWeight: FontWeight.w600,\n                        color: AkeliColors.primaryContainer,\n                      ),\n                    ),\n                  ),\n                ),\n              ),\n            ),\n            const SizedBox(width: AkeliSpacing.md),\n          ],\n          Expanded(\n            flex: onBack != null ? 2 : 1,\n            child: AkeliGradientButton(\n              label: isLast ? "Commencer l`
- [L462] `interface.",\n            style: Theme.of(context).textTheme.bodyLarge,\n          ),\n          const SizedBox(height: AkeliSpacing.xl),\n          _StepCard(\n            child: Column(\n              crossAxisAlignment: CrossAxisAlignment.start,\n              children: [\n                Text(\n                  `
- [L471] `,\n                  style: GoogleFonts.inter(\n                    fontSize: 11,\n                    fontWeight: FontWeight.w600,\n                    color: AkeliColors.onSurfaceVariant,\n                    letterSpacing: 0.1,\n                  ),\n                ),\n                const SizedBox(height: AkeliSpacing.sm),\n                Container(\n                  decoration: BoxDecoration(\n                    color: AkeliColors.surfaceContainerHighest,\n                    borderRadius: BorderRadius.circular(AkeliRadius.md),\n                  ),\n                  padding: const EdgeInsets.symmetric(\n                      horizontal: AkeliSpacing.md),\n                  child: DropdownButtonHideUnderline(\n                    child: DropdownButton<String>(\n                      value: data.language,\n                      isExpanded: true,\n                      style: GoogleFonts.inter(\n                          fontSize: 16, color: AkeliColors.onSurface),\n                      dropdownColor: AkeliColors.surfaceContainerLowest,\n                      borderRadius: BorderRadius.circular(AkeliRadius.md),\n                      items: const [\n                        DropdownMenuItem(value: `
- [L496, L497, L498, L499] `, child: Text(`
- [L496, L497, L498] `)),\n                        DropdownMenuItem(value: `
- [L499] `)),\n                      ],\n                      onChanged: (v) {\n                        if (v != null) {\n                          appLogger.userAction(`
- [L537] `);\n    _privacyRecognizer = TapGestureRecognizer()\n      ..onTap = () => context.push(AkeliRoutes.privacyPolicy);\n    _cguRecognizer = TapGestureRecognizer()\n      ..onTap = () => context.push(AkeliRoutes.termsOfService);\n  }\n\n  @override\n  void dispose() {\n    _logger.provider(`
- [L546] `);\n    _privacyRecognizer.dispose();\n    _cguRecognizer.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final data = ref.watch(onboardingProvider);\n    final notifier = ref.read(onboardingProvider.notifier);\n\n    return SingleChildScrollView(\n      padding: const EdgeInsets.all(AkeliSpacing.lg),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Text(\n            `
- [L563] `,\n            style: GoogleFonts.plusJakartaSans(\n              fontSize: 36,\n              fontWeight: FontWeight.w800,\n              color: AkeliColors.primary,\n              letterSpacing: -0.02,\n            ),\n          ),\n          const SizedBox(height: AkeliSpacing.sm),\n          Text(\n            "Avant de plonger dans l`
- [L573] `,\n            style: Theme.of(context).textTheme.bodyLarge,\n          ),\n          const SizedBox(height: AkeliSpacing.xl),\n          _StepCard(\n            padding: EdgeInsets.zero,\n            child: Column(\n              children: [\n                const Padding(\n                  padding: EdgeInsets.fromLTRB(AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, 0),\n                  child: Column(\n                    children: [\n                      _ConsentSection(\n                        title: 'Données collectées',\n                        items: [\n                          ('Identité et contact :', `
- [L589] `application :", "Statistiques anonymes pour améliorer votre expérience quotidienne."),\n                        ],\n                      ),\n                      SizedBox(height: AkeliSpacing.lg),\n                      _ConsentSection(\n                        title: `
- [L594] `,\n                        items: [\n                          (`
- [L596] `, "Consultez, modifiez ou exportez vos données à tout moment depuis les paramètres."),\n                          ("Droit à l`
- [L597] `),\n                        ],\n                      ),\n                    ],\n                  ),\n                ),\n                const SizedBox(height: AkeliSpacing.lg),\n                Container(\n                  padding: const EdgeInsets.all(AkeliSpacing.lg),\n                  decoration: const BoxDecoration(\n                    color: AkeliColors.surfaceContainerLow,\n                    borderRadius: BorderRadius.only(\n                      bottomLeft: Radius.circular(AkeliRadius.xl),\n                      bottomRight: Radius.circular(AkeliRadius.xl),\n                    ),\n                  ),\n                  child: Column(\n                    children: [\n                      _ConsentCheckbox(\n                        value: data.consentPrivacy,\n                        onChanged: (v) =>\n                            notifier.updateConsent(privacy: v),\n                        label: RichText(\n                          text: TextSpan(\n                            style: GoogleFonts.inter(\n                              fontSize: 13,\n                              color: AkeliColors.onSurfaceVariant,\n                              height: 1.5,\n                            ),\n                            children: [\n                              const TextSpan(text: `
- [L627] `accepte la "),\n                              TextSpan(\n                                text: "Politique de Confidentialité",\n                                style: const TextStyle(\n                                  color: AkeliColors.primary,\n                                  decoration: TextDecoration.underline,\n                                ),\n                                recognizer: _privacyRecognizer,\n                              ),\n                              const TextSpan(text: " et confirme avoir lu les informations concernant le traitement de mes données personnelles (RGPD)."),\n                            ],\n                          ),\n                        ),\n                      ),\n                      const SizedBox(height: AkeliSpacing.md),\n                      _ConsentCheckbox(\n                        value: data.consentCgu,\n                        onChanged: (v) =>\n                            notifier.updateConsent(cgu: v),\n                        label: RichText(\n                          text: TextSpan(\n                            style: GoogleFonts.inter(\n                              fontSize: 13,\n                              color: AkeliColors.onSurfaceVariant,\n                              height: 1.5,\n                            ),\n                            children: [\n                              const TextSpan(text: "J`
- [L654] `),\n                              TextSpan(\n                                text: `
- [L656] `Utilisation (CGU)",\n                                style: const TextStyle(\n                                  color: AkeliColors.primary,\n                                  decoration: TextDecoration.underline,\n                                ),\n                                recognizer: _cguRecognizer,\n                              ),\n                              const TextSpan(text: " d`
- [L813] `exercice quotidien.", Icons.weekend_rounded),\n    (`
- [L966] `activité physique",\n                    style: GoogleFonts.inter(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w500,\n                        color: AkeliColors.onSurface)),\n                const SizedBox(height: AkeliSpacing.md),\n                GridView.count(\n                  crossAxisCount: 2,\n                  shrinkWrap: true,\n                  physics: const NeverScrollableScrollPhysics(),\n                  crossAxisSpacing: AkeliSpacing.sm,\n                  mainAxisSpacing: AkeliSpacing.sm,\n                  childAspectRatio: 1.2,\n                  children: _activities.map((a) {\n                    final selected = data.activityLevel == a.$1;\n                    return GestureDetector(\n                      onTap: () {\n                        _logger.userAction(`
- [L983] `: a.$1});\n                        notifier.updateProfile(activityLevel: a.$1);\n                      },\n                      child: AnimatedContainer(\n                        duration: const Duration(milliseconds: 150),\n                        padding: const EdgeInsets.all(AkeliSpacing.md),\n                        decoration: BoxDecoration(\n                          color: selected\n                              ? AkeliColors.secondaryContainer.withValues(alpha: 0.4)\n                              : AkeliColors.surface,\n                          borderRadius: BorderRadius.circular(AkeliRadius.xl),\n                          border: Border.all(\n                            color: selected\n                                ? AkeliColors.secondaryContainer\n                                : Colors.transparent,\n                            width: 1.5,\n                          ),\n                        ),\n                        child: Column(\n                          crossAxisAlignment: CrossAxisAlignment.start,\n                          children: [\n                            Row(\n                              mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                              children: [\n                                Icon(a.$4,\n                                    color: selected\n                                        ? AkeliColors.primary\n                                        : AkeliColors.onSurfaceVariant,\n                                    size: 28),\n                                Container(\n                                  width: 20,\n                                  height: 20,\n                                  decoration: BoxDecoration(\n                                    shape: BoxShape.circle,\n                                    color: selected\n                                        ? AkeliColors.primary\n                                        : Colors.transparent,\n                                    border: Border.all(\n                                      color: selected\n                                          ? AkeliColors.primary\n                                          : AkeliColors.outlineVariant,\n                                      width: 1.5,\n                                    ),\n                                  ),\n                                  child: selected\n                                      ? const Icon(Icons.check,\n                                          color: Colors.white, size: 12)\n                                      : null,\n                                ),\n                              ],\n                            ),\n                            const SizedBox(height: AkeliSpacing.sm),\n                            Text(a.$2,\n                                style: GoogleFonts.inter(\n                                    fontSize: 14,\n                                    fontWeight: FontWeight.w600,\n                                    color: AkeliColors.onSurface)),\n                            Text(a.$3,\n                                style: GoogleFonts.inter(\n                                    fontSize: 11,\n                                    color: AkeliColors.onSurfaceVariant),\n                                maxLines: 2,\n                                overflow: TextOverflow.ellipsis),\n                          ],\n                        ),\n                      ),\n                    );\n                  }).toList(),\n                ),\n              ],\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _MetricField extends StatefulWidget {\n  final String value;\n  final String suffix;\n  final ValueChanged<String> onChanged;\n\n  const _MetricField({\n    required this.value,\n    required this.suffix,\n    required this.onChanged,\n  });\n\n  @override\n  State<_MetricField> createState() => _MetricFieldState();\n}\n\nclass _MetricFieldState extends State<_MetricField> {\n  late final TextEditingController _ctrl;\n\n  @override\n  void initState() {\n    super.initState();\n    _ctrl = TextEditingController(text: widget.value);\n  }\n\n  @override\n  void dispose() {\n    _ctrl.dispose();\n    super.dispose();\n  }\n\n  @override\n  void didUpdateWidget(_MetricField old) {\n    super.didUpdateWidget(old);\n    if (widget.value != _ctrl.text) {\n      _ctrl.text = widget.value;\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      decoration: BoxDecoration(\n        color: AkeliColors.surfaceContainerHighest,\n        borderRadius: BorderRadius.circular(AkeliRadius.sm),\n      ),\n      child: Row(\n        children: [\n          Expanded(\n            child: TextField(\n              controller: _ctrl,\n              onChanged: widget.onChanged,\n              keyboardType: const TextInputType.numberWithOptions(decimal: true),\n              textAlign: TextAlign.center,\n              style: GoogleFonts.inter(\n                  fontSize: 18,\n                  fontWeight: FontWeight.w600,\n                  color: AkeliColors.onSurface),\n              decoration: const InputDecoration(\n                border: InputBorder.none,\n                filled: false,\n                contentPadding: EdgeInsets.symmetric(vertical: 16),\n              ),\n            ),\n          ),\n          Padding(\n            padding: const EdgeInsets.only(right: 12),\n            child: Text(\n              widget.suffix,\n              style: GoogleFonts.inter(\n                  fontSize: 11,\n                  fontWeight: FontWeight.w600,\n                  color: AkeliColors.onSurfaceVariant,\n                  letterSpacing: 0.1),\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _SexSegment extends StatelessWidget {\n  final String? value;\n  final ValueChanged<String> onChanged;\n  const _SexSegment({this.value, required this.onChanged});\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      height: 54,\n      padding: const EdgeInsets.all(6),\n      decoration: BoxDecoration(\n        color: AkeliColors.surfaceContainerHighest,\n        borderRadius: BorderRadius.circular(AkeliRadius.xl),\n      ),\n      child: Row(\n        children: [\n          _SexOption(\n              label: `
- [L1159, L1166] `,\n              selected: value == `
- [L1160, L1167] `,\n              onTap: () {\n                appLogger.userAction(`
- [L1162, L1169] `});\n                onChanged(`
- [L1163] `);\n              }),\n          _SexOption(\n              label: `
- [L1261] `);\n    final data = ref.watch(onboardingProvider);\n    final notifier = ref.read(onboardingProvider.notifier);\n\n    return SingleChildScrollView(\n      padding: const EdgeInsets.all(AkeliSpacing.lg),\n      child: Column(\n        crossAxisAlignment: CrossAxisAlignment.start,\n        children: [\n          Text(`
- [L1270] `,\n              style: GoogleFonts.plusJakartaSans(\n                  fontSize: 36,\n                  fontWeight: FontWeight.w800,\n                  color: AkeliColors.onSurface,\n                  letterSpacing: -0.02)),\n          const SizedBox(height: AkeliSpacing.sm),\n          Text(\n              `
- [L1287, L1338] `,\n                    style: GoogleFonts.inter(\n                        fontSize: 11,\n                        fontWeight: FontWeight.w600,\n                        color: AkeliColors.onSurfaceVariant,\n                        letterSpacing: 0.1)),\n                const SizedBox(height: AkeliSpacing.md),\n                _GoalRadioOption(\n                  value: `
- [L1295, L1306, L1317] `,\n                  groupValue: data.weightGoal,\n                  label: `
- [L1297] `,\n                  icon: Icons.trending_down_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1300, L1311, L1322, L1351, L1362, L1373, L1400] `,\n                        screen: `
- [L1301, L1312] `: v});\n                    notifier.updateGoals(weightGoal: v);\n                  },\n                ),\n                _GoalRadioOption(\n                  value: `
- [L1308] `,\n                  icon: Icons.balance_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1319] `,\n                  icon: Icons.trending_up_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1346, L1357, L1368] `,\n                  groupValue: data.muscleGoal,\n                  label: `
- [L1348] `,\n                  icon: Icons.remove_circle_outline_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1352, L1363] `: v});\n                    notifier.updateGoals(muscleGoal: v);\n                  },\n                ),\n                _GoalRadioOption(\n                  value: `
- [L1359] `,\n                  icon: Icons.fitness_center_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1370] `,\n                  icon: Icons.add_circle_outline_rounded,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1389] `,\n                    style: GoogleFonts.inter(\n                        fontSize: 11,\n                        fontWeight: FontWeight.w600,\n                        color: AkeliColors.onSurfaceVariant,\n                        letterSpacing: 0.1)),\n                const SizedBox(height: AkeliSpacing.md),\n                _MetricField(\n                  value: data.targetWeight?.toString() ?? `
- [L1397] `,\n                  suffix: `
- [L1398] `,\n                  onChanged: (v) {\n                    _logger.userAction(`
- [L1401] `,\n                        metadata: {`
- [L1402] `: v});\n                    if (v.isEmpty) {\n                      notifier.clearTargetWeight();\n                    } else {\n                      notifier.updateGoals(targetWeight: double.tryParse(v));\n                    }\n                  },\n                ),\n                const SizedBox(height: AkeliSpacing.xl),\n                Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(`
- [L1414] `,\n                        style: GoogleFonts.inter(\n                            fontSize: 11,\n                            fontWeight: FontWeight.w600,\n                            color: AkeliColors.onSurfaceVariant,\n                            letterSpacing: 0.1)),\n                    IntensityBadge(\n                      currentKg: data.weight,\n                      targetKg: data.targetWeight,\n                      months: data.timelineMonths.toDouble(),\n                    ),\n                  ],\n                ),\n                const SizedBox(height: AkeliSpacing.md),\n                Center(\n                  child: RichText(\n                    text: TextSpan(\n                      children: [\n                        TextSpan(\n                          text: `
- [L1433] `,\n                          style: GoogleFonts.plusJakartaSans(\n                              fontSize: 56,\n                              fontWeight: FontWeight.w800,\n                              color: AkeliColors.primary,\n                              height: 1),\n                        ),\n                        TextSpan(\n                          text: `
- [L1441] `,\n                          style: GoogleFonts.inter(\n                              fontSize: 20,\n                              color: AkeliColors.onSurfaceVariant),\n                        ),\n                      ],\n                    ),\n                  ),\n                ),\n                SliderTheme(\n                  data: SliderThemeData(\n                    activeTrackColor: AkeliColors.secondaryContainer,\n                    inactiveTrackColor: AkeliColors.surfaceContainerHighest,\n                    thumbColor: AkeliColors.surfaceContainerLowest,\n                    overlayColor:\n                        AkeliColors.primary.withValues(alpha: 0.1),\n                    thumbShape:\n                        const RoundSliderThumbShape(enabledThumbRadius: 14),\n                    trackHeight: 10,\n                  ),\n                  child: Slider(\n                    value: data.timelineMonths.toDouble(),\n                    min: 1,\n                    max: 12,\n                    divisions: 11,\n                    onChanged: (v) {\n                      _logger.userAction(`
- [L1467, L1506] `,\n                          screen: `
- [L1468] `,\n                          metadata: {`
- [L1469] `: v.round()});\n                      notifier.updateGoals(timelineMonths: v.round());\n                    },\n                  ),\n                ),\n                Row(\n                  mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                  children: [\n                    Text(`
- [L1477] `,\n                        style: GoogleFonts.inter(\n                            fontSize: 10,\n                            color: AkeliColors.onSurfaceVariant,\n                            letterSpacing: 0.1)),\n                    Text(`
- [L1482] `,\n                        style: GoogleFonts.inter(\n                            fontSize: 10,\n                            color: AkeliColors.onSurfaceVariant,\n                            letterSpacing: 0.1)),\n                  ],\n                ),\n                const SizedBox(height: AkeliSpacing.xl),\n                Text(`
- [L1490] `,\n                    style: GoogleFonts.inter(\n                        fontSize: 11,\n                        fontWeight: FontWeight.w600,\n                        color: AkeliColors.onSurfaceVariant,\n                        letterSpacing: 0.1)),\n                const SizedBox(height: AkeliSpacing.md),\n                Container(\n                  decoration: BoxDecoration(\n                    color: AkeliColors.surfaceContainerHighest,\n                    borderRadius: BorderRadius.circular(AkeliRadius.sm),\n                  ),\n                  child: TextField(\n                    controller: _motivationsCtrl,\n                    maxLines: 3,\n                    onChanged: (v) {\n                      _logger.userAction(`
- [L1507] `);\n                      notifier.updateGoals(motivations: v);\n                    },\n                    style: GoogleFonts.inter(\n                        fontSize: 15, color: AkeliColors.onSurface),\n                    decoration: InputDecoration(\n                      hintText: `
- [L1513] `est-ce qui vous motive ?`
- [L1547, L1558, L1569] `Cooking time selected`
- [L1619] `Batch cooking toggled`
- [L1657] `Batch max portions selected`
- [L1756] `Afrique de l\'Ouest`
- [L1757] `Afrique de l\'Est`
- [L1758] `Afrique du Nord`
- [L1759] `Afrique Centrale`
- [L1760] `Afrique Australe`
- [L1772] `_StepPreferencesState build()`
- [L1804] `Exclure tous les plats contenant du porc`
- [L1812] `Options végétariennes uniquement`
- [L1820] `Exclure le gluten de votre alimentation`
- [L1828] `Exclure les produits laitiers`
- [L1888] `Region selected`
- [L2044] `Votre nom`
- [L2055] `${data.age} ans`
- [L2057] `${data.height?.toInt()} cm`
- [L2059] `${data.weight?.toInt()} kg`
- [L2078] `Niveau d'activité`
- [L2079, L2086] `Non défini`
- [L2083] `Objectif poids`
- [L2085] `${data.targetWeight?.toInt()} kg`

## File: `lib/features/community/browse_groups_page.dart`
- [L32] `Cuisine Africaine`
- [L32] `Session de cuisine`
- [L33] `Sport & Forme`
- [L34] `Perte de poids`
- [L57] `ve already joined\n    final myGroups = ref.watch(communityGroupsProvider).valueOrNull ?? [];\n    final myGroupIds = myGroups.map((g) => g[`
- [L59] `] as String).toSet();\n\n    return Scaffold(\n      backgroundColor: AkeliColors.background,\n      appBar: AppBar(\n        title: const Text(`
- [L64] `),\n        backgroundColor: AkeliColors.background,\n        elevation: 0,\n        actions: [\n          if (_regionId != null || _language != null || _topic != null)\n            IconButton(\n              icon: const Icon(Icons.filter_alt_off),\n              tooltip: `
- [L92] `),\n                        items: [\n                          const DropdownMenuItem(value: null, child: Text(`
- [L94] `)),\n                          ...regions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),\n                        ],\n                        onChanged: (v) => setState(() => _regionId = v),\n                      ),\n                    ),\n                    loading: () => const SizedBox(width: 80, child: LinearProgressIndicator()),\n                    error: (_, __) => const Text(`
- [L108, L121] `),\n                      items: [\n                        const DropdownMenuItem(value: null, child: Text(`
- [L137] `)),\n              data: (groups) {\n                if (groups.isEmpty) {\n                  return const Center(child: Text(`
- [L140] `));\n                }\n                return ListView.builder(\n                  padding: const EdgeInsets.all(AkeliSpacing.md),\n                  itemCount: groups.length,\n                  itemBuilder: (context, index) {\n                    final group = groups[index];\n                    final groupId = group[`
- [L147] `] as String;\n                    final isMember = myGroupIds.contains(groupId);\n                    return _GroupBrowseCard(\n                      group: group,\n                      isMember: isMember,\n                      regionsMap: regionsAsync.valueOrNull ?? {},\n                    );\n                  },\n                );\n              },\n            ),\n          ),\n        ],\n      ),\n    );\n  }\n}\n\nclass _GroupBrowseCard extends ConsumerStatefulWidget {\n  final Map<String, dynamic> group;\n  final bool isMember;\n  final Map<String, String> regionsMap;\n\n  const _GroupBrowseCard({\n    required this.group,\n    required this.isMember,\n    required this.regionsMap,\n  });\n\n  @override\n  ConsumerState<_GroupBrowseCard> createState() => _GroupBrowseCardState();\n}\n\nclass _GroupBrowseCardState extends ConsumerState<_GroupBrowseCard> {\n  bool _isJoining = false;\n\n  Future<void> _joinGroup() async {\n    final groupId = widget.group[`
- [L184] `] as String;\n    appLogger.userAction(`
- [L185] `, screen: `
- [L185] `, metadata: {`
- [L195] `);\n      await client.from(`
- [L196] `).insert({\n        `
- [L197] `: groupId,\n        `
- [L198] `: userId,\n        `
- [L199] `\n      });\n      appLogger.db(`
- [L204] `, groupId).maybeSingle();\n      if (conv != null) {\n        await client.from(`
- [L206] `).insert({\n          `
- [L207] `: conv[`
- [L208] `: userId,\n        });\n      }\n\n      ref.invalidate(communityGroupsProvider);\n      ref.invalidate(browseGroupsProvider);\n      \n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(`
- [L216] `)));\n        context.push(AkeliRoutes.groupChatPath(groupId));\n      }\n    } catch (e) {\n      appLogger.db(`
- [L220] `);\n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(`

## File: `lib/features/community/community_page.dart`
- [L22] `communityGroupsProvider build()`
- [L23] `communityGroupsProvider disposed`
- [L50] `AFTER | table: v_community_group | rows: ${groups.length}`
- [L76] `Cuisine Africaine`
- [L76] `Session de cuisine`
- [L77] `Sport & Forme`
- [L78] `Perte de poids`
- [L85] `CommunityPage initState()`
- [L91] `CommunityPage disposed`
- [L97] `CommunityPage build()`
- [L112] `Browse groups tapped`
- [L167] `Create group FAB tapped`
- [L257] `Erreur lors de la création du groupe.`
- [L331] `Le nom est requis`
- [L396] `_GroupesTab build()`
- [L416] `Group card tapped`
- [L536] `_ToutTab build()`
- [L550] `Aucune conversation`
- [L551] `Rejoignez un groupe ou envoyez un message privé.`
- [L593] `] as int?) ?? 0} membres`
- [L595] `Group tile tapped`
- [L632, L830] `DM tile tapped`
- [L653] `_PrivesTab build()`
- [L667] `Aucune conversation privée`
- [L668] `Rejoignez un groupe pour commencer.`
- [L753] `DM request rejected`
- [L772] `DM request accepted`

## File: `lib/features/community/group_chat_page.dart`
- [L49] `Exactly one of groupId or conversationId must be provided`
- [L67] `GroupChatPage initState() | groupId: ${widget.groupId} | conversationId: ${widget.conversationId}`
- [L76] `GroupChatPage disposed`
- [L84] `ERROR | markConversationRead | $e`
- [L94] `Message sent`
- [L115] `🍽️ ${attachment.recipe.title}`
- [L129] `📷 Photo`
- [L138] `ERROR | _sendMessage | $e`
- [L151] `BEFORE | groupId: $groupId`
- [L157] `AFTER | success`
- [L159] `ERROR | $e`
- [L164] `Attach button tapped`
- [L217] `Image staged in composer`
- [L224] `Recipe picker opened`
- [L235] `Recipe staged in composer`
- [L271, L315] `Discussion du groupe`
- [L271] `Message privé`
- [L273] `GroupChatPage build() | conversationId: $convId`
- [L321] `$count membre${count > 1 ? `
- [L367] `Edit group tapped`
- [L393] `Group info tapped`
- [L482] `Message submitted via keyboard`
- [L504] `Send button tapped`
- [L585] `Attachment preview dismissed`
- [L599] `${dt.hour.toString().padLeft(2, `
- [L599] `)}:${dt.minute.toString().padLeft(2, `
- [L626] `RecipePickerSheet initState()`
- [L636] `RecipePickerSheet disposed`
- [L643] `RecipePickerSheet build() | query: "$_query"`
- [L688] `RecipePickerSheet → error | $e`
- [L692] `RecipePickerSheet → data | count: ${recipes.length}`
- [L696] `Aucune recette disponible`
- [L696] `Aucun résultat pour "$_query"`
- [L737] `Recipe selected in picker`
- [L826] `Cuisine Africaine`
- [L826] `Session de cuisine`
- [L827] `Sport & Forme`
- [L828] `Perte de poids`
- [L876] `Erreur lors de la mise à jour`
- [L946] `Le nom est requis`

## File: `lib/features/community/group_detail_page.dart`
- [L33] `GroupDetailPage initState() | groupId: ${widget.groupId}`
- [L39] `GroupDetailPage disposed`
- [L46] `GroupDetailPage build() | groupId: ${widget.groupId}`
- [L79] `Groupe inconnu`
- [L192] `DM button tapped`
- [L221] `ERROR | _onDmTap | ${e.toString()}`
- [L231] `Exclude member tapped`
- [L260] `BEFORE | groupId: ${widget.groupId} | target: ${member.userId}`
- [L270] `AFTER | success`
- [L278] `ERROR | status: ${e.status} | ${e.reasonPhrase}`
- [L299] `ERROR | $e`
- [L338] `Invite tapped`
- [L351] `Aucun membre`
- [L352] `Les membres apparaîtront ici.`
- [L363] `Profile tapped`
- [L388] `_ImagesTab build() | groupId: $groupId`
- [L394] `_ImagesTab → error | $e`
- [L398] `_ImagesTab → data | count: ${urls.length}`
- [L402] `Aucune photo partagée`
- [L403] `Les photos envoyées dans le chat apparaîtront ici.`
- [L429] `Photo tapped`
- [L480] `_RecipesTab build() | groupId: $groupId`
- [L486] `_RecipesTab → error | $e`
- [L490] `_RecipesTab → data | count: ${ids.length}`
- [L494] `Aucune recette partagée`
- [L495] `Les recettes partagées dans le chat apparaîtront ici.`
- [L532] `Shared recipe tapped`
- [L657] `Submit group invites`
- [L680] `ERROR | invoke invite-to-group | $e`
- [L732] `Aucun contact éligible`
- [L734] `Vous n'avez pas encore de conversations privées avec des utilisateurs à inviter.`

## File: `lib/features/cooking/cooking_mode_page.dart`
- [L58] `CookingModePage initState() | recipeId: ${widget.recipe.id} | no steps`
- [L66] `CookingModePage initState() | recipeId: ${widget.recipe.id} | initialStep: $_currentStepIndex`
- [L78] `Timer paused`
- [L82] `Timer started`
- [L118] `Step navigation`
- [L132] `CookingModePage disposed | recipeId: ${widget.recipe.id}`
- [L178] `Step page changed (landscape)`
- [L193, L233] `Cooking mode closed`
- [L202, L355] `Cooking mode completed`
- [L212, L326] `Ingredient checked`
- [L245] `Step swiped`
- [L265] `CookingModePage | section slide | index: $index | title: "${s.sectionTitle}"`
- [L499, L683] `)}:${seconds.toString().padLeft(2, `
- [L753] `CookingModePage | ingredient section header | title: "${ing.sectionTitle}"`

## File: `lib/features/cooking/cooking_session_bottom_sheet.dart`
- [L14] `Cooking session sheet opened`
- [L139] `Cooking session sheet dismissed`

## File: `lib/features/diet_plan/diet_plan_page.dart`
- [L33] `DietPlanPage build() | planAsync.isLoading: ${planAsync.isLoading}`
- [L216] `${startingWeight.toStringAsFixed(1)} kg`
- [L226] `${targetWeight.toStringAsFixed(1)} kg`
- [L260] `${currentWeight.toStringAsFixed(1)} kg actuel`
- [L260] `-- actuel`
- [L331] `EEEE d MMMM`
- [L369] `Meal item tapped`
- [L431] `Regenerate plan tapped`
- [L449] `Shopping list button tapped`

## File: `lib/features/fan_mode/fan_mode_page.dart`
- [L16] `FanModePage build() | isLoading: ${fanSubAsync.isLoading}`
- [L30] `FanModePage → isFan: $isFan | status: ${sub?.status}`
- [L50] `_NoFanUserView build()`
- [L57] `_NoFanUserView consumptionAsync → loading`
- [L61] `_NoFanUserView consumptionAsync → error | $e`
- [L65] `_NoFanUserView consumptionAsync → data | count: ${consumption.length}`
- [L93] `_NoFanUserView creatorsAsync → loading`
- [L98] `_NoFanUserView creatorsAsync → error | $err`
- [L102] `_NoFanUserView creatorsAsync → data | count: ${creators.length}`
- [L107] `Aucun créateur éligible`
- [L109] `Les créateurs doivent publier 30 recettes pour être éligibles.`
- [L136] `Activate fan mode button tapped`
- [L145] `inclus dans votre abonnement Akeli.\n\n`
- [L147] `(max 9 recettes externes par mois).\n\n`
- [L148] `Actif à partir du 1er du mois prochain.`
- [L162] `Activate fan mode confirmed`
- [L325] `_EligibleCreatorCard build() | creatorId: ${creator.id} | isDominant: $isDominant`
- [L417] `_FanUserView build() | status: ${sub.status}`
- [L455] `Cancel fan mode button tapped`
- [L477] `Cancel fan mode confirmed`
- [L550] `⏳ Actif le 1er du mois prochain`
- [L551] `❤️ Mode Fan actif`
- [L651] `votre créateur`

## File: `lib/features/home/home_creator_chip.dart`
- [L25] `HomeCreatorChip tapped`

## File: `lib/features/home/home_page.dart`
- [L39] `_HomePageState initState | _currentWeight default: $_currentWeight kg (hardcoded)`
- [L44] `_HomePageState disposed`
- [L61] `ERROR: $e`
- [L80] `weightLogProvider listener | entries: ${entries.length}`
- [L82] `weightLogProvider listener | updating stepper: $_currentWeight → ${entries.first.weightKg} kg (from weight_log row[0])`
- [L87] `weightLogProvider listener | 0 entries → falling back to health profile weightKg: $healthWeight kg`
- [L90] `weightLogProvider listener | 0 entries, no health profile weight → keeping default: $_currentWeight kg`
- [L94] `weightLogProvider listener | loading`
- [L95] `weightLogProvider listener | error: $e`
- [L106] `healthProfileProvider listener | no weight_log entries → seeding stepper from health profile: ${health!.weightKg} kg`
- [L121] `HomePage build() | seeding weight from current data (listener missed): $seedWeight kg`
- [L128] `HomePage build() ── provider states ──────────────────`
- [L129] `  [profile]      ${_ps(profileAsync)}`
- [L130] `  [health]       ${_ps(healthAsync)}`
- [L131] `  [nutrition]    ${_ps(nutritionAsync)}`
- [L132] `  [plan]         ${_ps(nutritionPlanAsync)}`
- [L133] `  [mealPlan]     ${_ps(mealPlanAsync)}`
- [L134] `  [shopping]     ${_ps(shoppingAsync)}`
- [L135] `  [weight]       ${_ps(weightAsync)}`
- [L136] `  [recipes]      ${_ps(recipesAsync)}`
- [L137] `  [creators]     ${_ps(creatorsAsync)}`
- [L150] `[profile] data | displayName: "${profile?.displayName}" | onboarding: ${profile?.onboardingDone}`
- [L177] `[profile] loading`
- [L181] `[profile] ERROR: $e`
- [L204] `Nutrition card tapped`
- [L220] `[weight-ring] data | entries: ${entries.length} | health: ${health == null ? "null" : "loaded"} | weightKg: ${health?.weightKg} | targetWeightKg: ${health?.targetWeightKg}`
- [L222] `  weight entry[$i] | date: ${entries[i].date} | weightKg: ${entries[i].weightKg}`
- [L228] `Weight graph → data (no entries) | health.weightKg: $profileWeight | health.targetWeightKg: $profileTarget`
- [L232] `${profileWeight.toStringAsFixed(1)}kg → ${profileTarget?.toStringAsFixed(1) ?? `
- [L233, L269] `--kg → --kg`
- [L254] `Weight graph → data | current: ${currentWeight}kg | starting: ${startingWeight.toStringAsFixed(1)}kg (health profile) | target: ${targetWeight?.toStringAsFixed(1) ?? "--"}kg | progress: ${(progress * 100).toInt()}%`
- [L258] `${currentWeight.toStringAsFixed(1)}kg → ${targetWeight?.toStringAsFixed(1) ?? `
- [L259, L297] `${(progress * 100).toInt()}`
- [L266] `[weight-ring] orElse (loading or error) | weightAsync: ${_ps(weightAsync)}`
- [L292] `[calorie-ring] data | consumed: $consumed kcal | target: ${target.toInt()} kcal | plan: ${nutritionPlanAsync.valueOrNull?.calorieGoal ?? "null(using 2000)"} | progress: ${(progress * 100).toInt()}%`
- [L296] `$consumed → ${target.toInt()} kcal`
- [L304] `[calorie-ring] loading`
- [L308] `[calorie-ring] ERROR: $e`
- [L345] `Weight stepper changed`
- [L358] `Vos repas du jour`
- [L370] `[meals] data | plan: ${plan == null ? "null" : plan.id} | todayEntries: ${todayEntries.length}`
- [L399] `Meal consumed toggled`
- [L414] `Meal card tapped`
- [L424] `[meals] loading`
- [L428] `[meals] ERROR: $error`
- [L445] `Liste de courses`
- [L446] `Voir tout`
- [L448] `View all shopping tapped`
- [L466, L477, L488] `Shopping filter changed`
- [L503] `[shopping] data | total: ${items.length} | filter: $_activeFilter`
- [L540] `Shopping item toggled`
- [L554] `[shopping] loading`
- [L558] `[shopping] ERROR: $e`
- [L568] `Recettes recommandées`
- [L578] `[recipes] data | count: ${recipes.length}`
- [L615] `Recipe card tapped`
- [L627] `[recipes] loading`
- [L631] `[recipes] ERROR: $error`
- [L653] `[home-creators] data | total rpc: ${creators.length} | after fan filter + take5: ${shown.length}`
- [L659] `Créateurs pour vous`
- [L679] `Creator chip tapped`
- [L693] `[home-creators] loading`
- [L702] `[home-creators] ERROR: $e`
- [L729] `HomePage: filtering shopping items | filter: $_activeFilter | total: ${allItems.length} | filtered: ${filtered.length}`

## File: `lib/features/journaling/journaling_bottom_sheet.dart`
- [L19] `Journaling sheet opened`
- [L45] `JournalingBottomSheet build()`
- [L51] `JournalingBottomSheet disposed`
- [L57] `JournalingBottomSheet | save blocked | empty description`
- [L71] `Save journal entry tapped`
- [L78] `BEFORE | table: journal_entry | op: INSERT | userId: ${user?.id}`
- [L85] `AFTER | table: journal_entry | rows: 1`
- [L86] `JournalingBottomSheet | entry saved`
- [L102] `ERROR | table: journal_entry | code: ${e.code}`
- [L117] `ERROR | journal_entry | unexpected | $e`
- [L125] `Add photo tapped`
- [L291] `Meal type selected: $type`
- [L352] `Enregistrer l\'entrée`

## File: `lib/features/legal/privacy_policy_page.dart`
- [L16] `PrivacyPolicyPage build()`
- [L38] `Back tapped`
- [L94] `En bref`
- [L98] `Collecte minimale`
- [L99] `Seules les données nécessaires au fonctionnement de l\'application`
- [L104] `Sécurité maximale`
- [L105] `Chiffrement de bout en bout et stockage sécurisé`
- [L110] `Contrôle total`
- [L111] `Vous pouvez accéder, modifier ou supprimer vos données à tout moment`
- [L116] `1. Collecte de données`
- [L119] `Nous collectons uniquement les données nécessaires pour vous offrir la meilleure expérience :\n\n• Informations de profil (nom, email, préférences alimentaires)\n• Historique de navigation dans l`
- [L129, L176, L189] `),\n            const SizedBox(height: 12),\n            _buildContentCard(\n              content: `
- [L142] `),\n            const SizedBox(height: 12),\n            GridView.count(\n              shrinkWrap: true,\n              physics: const NeverScrollableScrollPhysics(),\n              crossAxisCount: 2,\n              mainAxisSpacing: 12,\n              crossAxisSpacing: 12,\n              children: [\n                _buildRightsCard(\n                  icon: Icons.visibility_outlined,\n                  title: `
- [L153, L158, L163, L168] `,\n                  description: `
- [L154] `,\n                ),\n                _buildRightsCard(\n                  icon: Icons.edit_outlined,\n                  title: `
- [L159] `,\n                ),\n                _buildRightsCard(\n                  icon: Icons.delete_outline,\n                  title: `
- [L164] `,\n                ),\n                _buildRightsCard(\n                  icon: Icons.download_outlined,\n                  title: `
- [L194] `à 3 ans après votre dernière connexion\n• Immédiatement supprimées après demande de suppression de compte`
- [L200] `Contact DPO`

## File: `lib/features/legal/terms_of_service_page.dart`
- [L16] `TermsOfServicePage build()`
- [L38] `Back tapped`
- [L96] `Accès au service`
- [L97] `Akeli est une application mobile gratuite dédiée à la nutrition africaine et aux recettes traditionnelles.\n\nL`
- [L102] `un compte utilisateur\n\nCertaines fonctionnalités premium (Fan Mode, plans personnalisés) sont accessibles via abonnement.`
- [L111] `Compte utilisateur`
- [L112] `Vous êtes responsable de :\n• La confidentialité de vos identifiants\n• L`
- [L123, L167] `,\n              title: `
- [L124, L168] `,\n              content: `
- [L125] `Akeli ou de ses partenaires.\n\nInterdictions :\n• Reproduction sans autorisation\n• Utilisation commerciale non autorisée\n• Modification ou altération des contenus\n\nLes créateurs conservent les droits sur leurs recettes publiées.`
- [L140] `Akeli fournit des informations nutritionnelles à titre indicatif uniquement.\n\nNous ne pouvons être tenus responsables :\n• Des erreurs dans les informations nutritionnelles\n• Des réactions allergiques ou problèmes de santé liés aux recettes\n• Des interruptions temporaires du service pour maintenance\n\nConsultez toujours un professionnel de santé pour des conseils médicaux.`
- [L154] `Abonnements et paiements`
- [L175] `utilisation vaut acceptation des nouvelles conditions.`

## File: `lib/features/meal_planner/batch_cooking_detail_page.dart`
- [L37] `BatchCookingDetailPage build() | sessionId: ${widget.sessionId}`
- [L72] `Start cooking tapped`
- [L82] `BatchCookingDetailPage _startCooking ERROR | $e`
- [L422] `Step tapped`
- [L547] `Commencer la cuisson`
- [L649] `Ingredient tapped`

## File: `lib/features/meal_planner/batch_cooking_page.dart`
- [L17] `BatchCookingPage build() | sessionsAsync.isLoading: ${sessionsAsync.isLoading}`
- [L116] `BatchCookingEmptyState build()`
- [L160] `${date.day} ${months[date.month - 1]}.`
- [L165] `CookingSessionCard build() | sessionId: ${session.id}`

## File: `lib/features/meal_planner/meal_detail_page.dart`
- [L37] `MealDetailPage build() | mealId: ${widget.mealId}`
- [L83] `Mark consumed tapped | isConsumed: ${entry.isConsumed}`
- [L93] `Meal like tapped`
- [L128] `MealDetailBody build() | mealId: ${entry.id}`
- [L131] `MealDetailBody | future meal guard | mealId: ${entry.id} | scheduledDate: ${entry.scheduledDate}`
- [L253] `${entry.totalTimeMin} min`
- [L304] `Repas consommé`
- [L304] `Marquer comme consommé`
- [L399] `Ingredient tapped`
- [L472] `Batch session card tapped`
- [L522] `MealDetailPage | section header | title: "${step.sectionTitle}"`
- [L583] `Step tapped`
- [L615] `Swap recipe tapped`
- [L626] `Personal meal tapped`
- [L643] `Consommez d\'abord ce repas`
- [L645] `Modifier votre avis`
- [L646] `Laisser un avis`
- [L650] `Rating tapped`
- [L668] `View recipe tapped`
- [L833] `Session de cuisine batch`

## File: `lib/features/meal_planner/meal_planner_page.dart`
- [L55] `MealPlannerPage build() | days: ${dayKeys.length}`
- [L83] `Voir mon plan diététique`
- [L85] `Diet plan card tapped`
- [L93] `Voir ma liste de course`
- [L95] `Shopping list card tapped`
- [L103] `Session de cuisine`
- [L105] `Batch cooking card tapped`
- [L130] `Meal plan entry tapped`
- [L134] `Meal consumed toggle`
- [L158] `Generate plan button tapped`
- [L178] `Add snack tapped`
- [L218, L327] `ERROR | $e`
- [L249] `Generate plan FAB tapped from empty state`

## File: `lib/features/meal_planner/personal_meal_bottom_sheet.dart`
- [L68] `Pick image tapped`
- [L81] `Analyser avec l\'IA tapped`
- [L91] `Ajouter la collation tapped`
- [L91] `Confirmer ce repas tapped`
- [L104] `PersonalMealBottomSheet → create mode pop | name: ${_nameController.text.trim()} | kcal: ${_calController.text.trim()}`
- [L142] `PersonalMealBottomSheet build() | entryId: ${widget.entryId}`
- [L182] `Ajouter une collation personnelle`
- [L182] `Saisir un repas personnel`
- [L329] `Ajouter la collation`
- [L329] `Confirmer ce repas`
- [L352] `✓ Confiance élevée`
- [L356] `~ Estimation moyenne`
- [L360] `? Confiance faible`

## File: `lib/features/meal_planner/rating_bottom_sheet.dart`
- [L35] `Rating submit tapped`
- [L156] `Rating skipped`

## File: `lib/features/meal_planner/shopping_list_page.dart`
- [L29] `ShoppingListPage build() | listAsync.isLoading: ${listAsync.isLoading}`
- [L72] `Liste vide`
- [L73] `Votre liste de courses apparaîtra ici une fois votre plan alimentaire généré.`
- [L109, L118, L127] `Filter selected`

## File: `lib/features/meal_planner/widgets/meal_planner_day_row.dart`
- [L34] `${_dayNames[date.weekday - 1]} ${date.day} ${_monthNames[date.month]}`
- [L43] `MealPlannerDayRow build() | date: $_formattedDate | entries: ${entries.length}`
- [L90] `Ajouter une autre collation`
- [L90] `Ajouter une collation`
- [L116] `MealPlannerDayRow | future date guard | entryId: ${entry.id} | scheduledDate: ${entry.scheduledDate}`
- [L127] `Meal plan entry tapped`
- [L133] `Meal card consumed toggle`

## File: `lib/features/meal_planner/widgets/snack_picker_sheet.dart`
- [L46] `SnackPickerSheet initState()`
- [L52] `SnackPickerSheet dispose()`
- [L57] `Collation personnelle tapped`
- [L65] `Personal snack created`
- [L75] `Personal snack dismissed`
- [L81] `SnackPickerSheet build() | query: $_query`
- [L120] `SnackPickerSheet close`
- [L133] `SnackPickerSheet search changed`
- [L210] `Recipe picked for snack`

## File: `lib/features/notifications/notifications_page.dart`
- [L27] `NotificationsPage initState()`
- [L35] `NotificationsPage build()`
- [L58] `NotificationsPage → error | $e`
- [L61] `Erreur de chargement`
- [L62] `Impossible de charger les notifications. Réessayez.`
- [L67] `NotificationsPage → data | count: ${notifications.length}`
- [L71] `Aucune notification`
- [L72] `Vous recevrez ici vos rappels de repas et messages.`
- [L122] `Message notification tapped`
- [L140] `DM request notification tapped`
- [L148] `Accept DM request tapped`
- [L154] `ERROR | acceptDmRequest | $e`
- [L160] `Decline DM request tapped`
- [L166] `ERROR | rejectDmRequest | $e`
- [L182] `Group invite notification tapped`
- [L190] `Accept group invite tapped`
- [L212] `ERROR | accept_group_invite | $e`
- [L223] `Decline group invite tapped`
- [L236] `ERROR | decline group invite | $e`
- [L251] `Meal reminder notification tapped`
- [L270] `Generic notification tapped`
- [L291] `CETTE SEMAINE`
- [L292] `PLUS TÔT`
- [L315] `À l'instant`
- [L316] `Il y a ${diff.inMinutes} min`
- [L317] `Il y a ${diff.inHours} h`
- [L319] `Il y a ${diff.inDays} j`

## File: `lib/features/nutrition/nutrition_page.dart`
- [L31] `NutritionPage initState()`
- [L37] `NutritionPage disposed`
- [L44] `NutritionPage build()`
- [L145] `${_selected.year}-${_selected.month.toString().padLeft(2, `
- [L145] `)}-${_selected.day.toString().padLeft(2, `
- [L155] `${weekdays[d.weekday - 1]} ${d.day} ${months[d.month - 1]}`
- [L162] `TodayTab build() | date: $_dateStr | nutritionAsync.isLoading: ${nutritionAsync.isLoading} | plan: ${plan != null}`
- [L171] `NutritionPage today nav prev`
- [L177] `NutritionPage today nav next`
- [L190] `Aucune donnée`
- [L191] `Aucune consommation enregistrée pour cette journée.`
- [L237] `Add water glass tapped`
- [L274] `${d.year}-${d.month.toString().padLeft(2, `
- [L274] `)}-${d.day.toString().padLeft(2, `
- [L284] `${s.day} – ${u.day} ${months[u.month - 1]}`
- [L285] `${s.day} ${months[s.month - 1]} – ${u.day} ${months[u.month - 1]}`
- [L291] `WeeklyTab build() | weekAsync.isLoading: ${weekAsync.isLoading} | offset: $_weekOffset`
- [L300] `NutritionPage week nav prev`
- [L306] `NutritionPage week nav next`
- [L319] `Pas encore de données`
- [L320] `Aucune consommation enregistrée pour cette semaine.`
- [L437] `MacroDonutChart build()`
- [L522] `Legend build() | label: $label`
- [L624] `WaterTracker build() | waterMl: $waterMl`
- [L715] `WeightTrendChart build() | weightAsync.isLoading: ${weightAsync.isLoading} | healthAsync.isLoading: ${healthAsync.isLoading}`
- [L743] `Add weight button tapped`
- [L833] `${spot.y} kg`
- [L853] `Cible: ${line.y}kg`
- [L962] `Weight dialog cancelled`
- [L975] `Weight dialog saved`
- [L996] `WeeklyCaloriesChart build()`
- [L1079] `AverageStats build()`
- [L1109] `_ConsumedRecipesList build() | date: $dateStr | recipesAsync.isLoading: ${recipesAsync.isLoading}`
- [L1154] `${recipe.consumedAt.hour.toString().padLeft(2, `
- [L1154] `)}:${recipe.consumedAt.minute.toString().padLeft(2, `
- [L1158] `Consumed recipe tapped`

## File: `lib/features/nutrition/widgets/journey/journey_calendar.dart`
- [L32] `JourneyCalendar build() | $year-$month`

## File: `lib/features/nutrition/widgets/journey/journey_goals_card.dart`
- [L13] `JourneyGoalsCard build()`
- [L27] `${stats.weightCurrentKg?.toStringAsFixed(1)} kg → ${stats.weightTargetKg?.toStringAsFixed(1)} kg`
- [L37] `${stats.calorieHitPct}% des jours logués`

## File: `lib/features/nutrition/widgets/journey/journey_streak_pill.dart`
- [L15] `JourneyStreakPill build()`

## File: `lib/features/nutrition/widgets/journey/journey_summary_row.dart`
- [L15] `JourneySummaryRow build()`

## File: `lib/features/nutrition/widgets/journey/journey_tab.dart`
- [L26] `JourneyTab initState()`
- [L34] `JourneyTab disposed`
- [L47] `Journey prev month`
- [L62] `Journey next month`
- [L73] `JourneyTab build() | $_year-$_month`
- [L82] `JourneyTab → error | $e`
- [L109] `JourneyTab → data | streak: ${stats.currentStreak}`

## File: `lib/features/nutrition_plan/nutrition_plan_page.dart`
- [L20] `Collation 1`
- [L21] `Collation 2`
- [L22] `Collation 3`
- [L66] `NutritionPlanPage initState | isOnboarding: ${widget.isOnboarding}`
- [L71] `NutritionPlanPage _loadInitialData`
- [L110] `NutritionPlanPage → loaded existing plan | calorieGoal: ${activePlan.calorieGoal}`
- [L131] `Calculate button tapped`
- [L152] `NutritionPlanPage → calculated | bmr: ${bmr.toStringAsFixed(0)} tdee: ${tdee.toStringAsFixed(0)} goal: $calorieGoal`
- [L167] `Add meal slot tapped`
- [L171] `snack_${nextIndex - 2}`
- [L186] `Remove meal slot tapped | index: $index`
- [L204] `Save plan button tapped`
- [L240] `NutritionPlanPage → save success`
- [L256] `NutritionPlanPage → save error | $e`
- [L297] `Poids (kg)`
- [L299] `Taille (cm)`

## File: `lib/features/profile/profile_page.dart`
- [L51] `s\n    final displayProfile = isCurrentUser\n        ? profileAsync.valueOrNull\n        : targetProfileAsync?.valueOrNull;\n    final isPrivate = !isCurrentUser && (displayProfile?.isPrivate ?? false);\n\n    final userSavedRecipesAsync = ref.watch(userSavedRecipesProvider(targetUserId));\n    final userCommentsAsync = ref.watch(userCommentsProvider(targetUserId));\n    final userGroupsAsync = ref.watch(userGroupsProvider(targetUserId));\n    \n    return Scaffold(\n      backgroundColor: AkeliColors.background,\n      extendBodyBehindAppBar: true,\n      appBar: PreferredSize(\n        preferredSize: const Size.fromHeight(kToolbarHeight + 16),\n        child: ClipRect(\n          child: BackdropFilter(\n            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),\n            child: Container(\n              color: AkeliColors.surface.withValues(alpha: 0.8),\n              padding: EdgeInsets.only(\n                top: MediaQuery.of(context).padding.top + 8,\n                bottom: 8,\n                left: 16,\n                right: 16,\n              ),\n              child: Row(\n                mainAxisAlignment: MainAxisAlignment.spaceBetween,\n                children: [\n                  Container(\n                    decoration: const BoxDecoration(\n                      color: AkeliColors.surfaceContainerHighest,\n                      shape: BoxShape.circle,\n                    ),\n                    child: IconButton(\n                      padding: EdgeInsets.zero,\n                      icon: const Icon(Icons.arrow_back, color: AkeliColors.onSurfaceVariant),\n                      onPressed: () {\n                        if (context.canPop()) {\n                          context.pop();\n                        } else {\n                          context.go(AkeliRoutes.home);\n                        }\n                      },\n                    ),\n                  ),\n                  Text(\n                    displayProfile?.displayName ?? `
- [L98] `,\n                    style: GoogleFonts.plusJakartaSans(\n                      fontSize: 20,\n                      fontWeight: FontWeight.bold,\n                      color: AkeliColors.onSurface,\n                      letterSpacing: -0.5,\n                    ),\n                  ),\n                  if (isCurrentUser)\n                    Container(\n                      decoration: const BoxDecoration(\n                        color: AkeliColors.surfaceContainerHighest,\n                        shape: BoxShape.circle,\n                      ),\n                      child: IconButton(\n                        padding: EdgeInsets.zero,\n                        icon: const Icon(Icons.settings_outlined, color: AkeliColors.onSurfaceVariant),\n                        onPressed: () {\n                          appLogger.userAction(`
- [L116, L261] `, screen: `
- [L116] `);\n                          context.push(AkeliRoutes.settings);\n                        },\n                      ),\n                    )\n                  else\n                    const SizedBox(width: 48),\n                ],\n              ),\n            ),\n          ),\n        ),\n      ),\n      body: (isCurrentUser\n              ? profileAsync\n              : targetProfileAsync ?? const AsyncValue.loading())\n          .when(\n        loading: () => const Center(child: CircularProgressIndicator()),\n        error: (err, _) => Center(child: Text(`
- [L261] `);\n                                              try {\n                                                await sendDmRequest(ref, widget.userId!);\n                                                ref.invalidate(conversationStateProvider(widget.userId!));\n                                                if (context.mounted) {\n                                                  ScaffoldMessenger.of(context).showSnackBar(\n                                                    const SnackBar(content: Text(`
- [L267] `)),\n                                                  );\n                                                }\n                                              } catch (e) {\n                                                if (context.mounted) {\n                                                  ScaffoldMessenger.of(context).showSnackBar(\n                                                    const SnackBar(content: Text(`
- [L273] `envoi de la demande`
- [L322] `Message button tapped`
- [L339] `Close conversation tapped`
- [L505] `${r.totalTimeMin} min • ${r.difficulty}`
- [L533] `Recette inconnue`
- [L767] `Group card tapped`

## File: `lib/features/recipes/creator_detail_page.dart`
- [L34] `CreatorDetailPage initState() | creatorId: ${widget.creatorId}`
- [L39] `CreatorDetailPage disposed`
- [L47] `Become fan tapped`
- [L56] `ERROR | $e`
- [L74] `CreatorDetailPage build() | detailAsync.isLoading: ${detailAsync.isLoading}`
- [L132] `Aucune recette publiée`
- [L133] `Ce créateur n\'a pas encore publié de recettes.`
- [L162] `Recipe tapped from creator page`
- [L396] `En cours...`
- [L396] `Devenir fan`

## File: `lib/features/recipes/domain/repositories/i_recipe_tracking_repository.dart`
- [L11] `ouverture d`

## File: `lib/features/recipes/feed_page.dart`
- [L118] `FeedPage initState()`
- [L125] `FeedPage disposed`
- [L149] `Load more recipes triggered`
- [L166] `AFTER rpc | fn: generate_feed_personalized | page rows: ${page.length}`
- [L177] `ERROR | _loadMoreRecipes | $e`
- [L187] `Load more search triggered`
- [L205] `AFTER | searchRecipesProvider | page rows: ${page.length} | offset: $_searchOffset`
- [L216] `ERROR | _loadMoreSearch | $e`
- [L229] `Load more creators triggered`
- [L235] `BEFORE rpc | fn: generate_creators_personalized | p_exclude: ${_seenCreatorIds.length}`
- [L241] `AFTER rpc | fn: generate_creators_personalized | rows: ${rpcRows.length}`
- [L244] `Zero rows | table: generate_creators_personalized | userId: ${user.id} | possible RLS block`
- [L258] `id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region`
- [L260] `AFTER | table: creator | rows: ${rows.length}`
- [L263] `Zero rows | table: creator | userId: ${user.id} | possible RLS block`
- [L286] `Permission denied | table: creator | userId: ${user.id}`
- [L288] `ERROR | table: creator | code: ${e.code} | ${e.message}`
- [L291] `ERROR | _loadMoreCreators | $e`
- [L300] `Région ▾`
- [L309] `Difficulté ▾`
- [L316] `Temps ▾`
- [L320, L530] `Mieux noté`
- [L322, L532] `Plus récent`
- [L323] `Trier ▾`
- [L335, L666] `Mieux notés`
- [L336, L667] `Plus de fans`
- [L337, L668] `Plus de recettes`
- [L342] `Combined filter sheet opened`
- [L473] `${tempMaxCal ?? `
- [L473, L888] `} kcal`
- [L489] `2000+ kcal`
- [L489] `$tempMaxCal kcal`
- [L522] `Sort sheet opened`
- [L527, L663] `Trier par`
- [L531] `Plus populaire`
- [L536] `Sort selected`
- [L548] `Cuisine traditionnelle`
- [L549] `Cuisine fusion`
- [L550] `Cuisine végétarienne`
- [L552] `Street food`
- [L556] `Creator filter sheet opened`
- [L635] `Creator filter applied`
- [L658] `Creator sort sheet opened`
- [L672] `Creator sort changed`
- [L707] `FeedPage build() | isSearching: $isSearching | feedAsync.isLoading: ${feedAsync.isLoading}`
- [L755] `Feed tab selected`
- [L786] `Search cleared`
- [L977] `Aucune recette trouvée`
- [L978] `Pas encore de recettes`
- [L980] `Essayez d\'autres termes de recherche.`
- [L981] `Explorez et découvrez des recettes africaines.`
- [L1011] `Recipe card tapped`
- [L1084] `_buildCreateursSliver | creatorsAsync.isLoading: ${creatorsAsync.isLoading}`
- [L1120] `Aucun créateur trouvé`
- [L1121] `Aucun créateur disponible`
- [L1123] `Essayez d\'autres termes ou réinitialisez les filtres.`
- [L1124] `Les créateurs apparaîtront ici.`
- [L1140] `Creator card tapped`
- [L1181] `Creators search query changed`

## File: `lib/features/recipes/presentation/providers/recipe_tracking_provider.dart`
- [L11] `BEFORE | op: trackImpression | recipeId: $recipeId | source: $source`
- [L13] `AFTER | op: trackImpression | recipeId: $recipeId (mock)`
- [L15] `ERROR | op: trackImpression | recipeId: $recipeId`
- [L21] `BEFORE | op: trackOpen | recipeId: $recipeId | source: $source`
- [L23] `AFTER | op: trackOpen | recipeId: $recipeId | result: null (mock)`
- [L26] `ERROR | op: trackOpen | recipeId: $recipeId`
- [L33] `BEFORE | op: trackClose | openId: $openId`
- [L35] `AFTER | op: trackClose | openId: $openId (mock)`
- [L37] `ERROR | op: trackClose | openId: $openId`
- [L44] `recipeTrackingRepositoryProvider created (mock)`

## File: `lib/features/recipes/recipe_detail_page.dart`
- [L55] `RecipeDetailPage initState() | recipeId: ${widget.recipeId} | source: ${widget.source}`
- [L62] `BEFORE | op: trackOpen | recipeId: ${widget.recipeId} | source: ${widget.source}`
- [L67] `AFTER | op: trackOpen | openId: ${_currentOpen?.id}`
- [L69] `ERROR | op: trackOpen | recipeId: ${widget.recipeId}`
- [L77] `RecipeDetailPage disposed | recipeId: ${widget.recipeId}`
- [L87] `FIRE | op: trackClose | openId: ${open.id} | fire-and-forget from dispose`
- [L99] `RecipeDetailPage build() | recipeId: ${widget.recipeId} | recipeAsync.isLoading: ${recipeAsync.isLoading}`
- [L112] `Recette introuvable.`
- [L123] `Recipe image swiped`
- [L128] `Save button tapped`
- [L220] `Sans recette`
- [L268] `RecipeContent build() | recipeId: ${recipe.id}`
- [L465] `Start Cooking tapped`
- [L577] `RecipeDetailPage | ingredient section header | title: "${ing.sectionTitle}"`
- [L610] ` (opt.)`
- [L631] `Ingredient tapped`
- [L679] `RecipeDetailPage | section header | step: ${step.stepNumber} | title: "${step.sectionTitle}"`
- [L724] `Step tapped`
- [L840] `POUR 100G`
- [L850] `RECETTE TOTALE`
- [L850] `PAR PORTION`
- [L1012] `_CreatorCardSection build() | creatorId: $creatorId`
- [L1046] `Creator card tapped from recipe detail`
- [L1246] `Il y a ${diff.inDays} j`
- [L1247] `Il y a ${diff.inHours} h`
- [L1248] `À l'instant`

## File: `lib/features/recipes/widgets/ingredient_detail_sheet.dart`
- [L22] `IngredientDetailSheet opened`
- [L45] `IngredientDetailSheet build() | ingredientId: ${ingredient.ingredientId}`
- [L209] `Riche en protéines`
- [L210] `Pauvre en graisses`
- [L211] `Sans gluten`
- [L212] `Aliment de base`
- [L213] `Difficile à trouver en Europe`
- [L285] `${detail.caloriesPer100g!.toStringAsFixed(0)} kcal`
- [L291] `${detail.proteinPer100g!.toStringAsFixed(1)} g`
- [L298] `${detail.carbsPer100g!.toStringAsFixed(1)} g`
- [L309] `${detail.fatPer100g!.toStringAsFixed(1)} g`

## File: `lib/features/recipes/widgets/recipe_comments_sheet.dart`
- [L76] `Plus Jakarta Sans`

## File: `lib/features/referral/referral_page.dart`
- [L12] `s referral code, stats, and allows code customization\nclass ReferralPage extends ConsumerStatefulWidget {\n  const ReferralPage({super.key});\n\n  @override\n  ConsumerState<ReferralPage> createState() => _ReferralPageState();\n}\n\nclass _ReferralPageState extends ConsumerState<ReferralPage> {\n  final _logger = appLogger;\n  final _codeController = TextEditingController();\n  int _referralCount = 0;\n  bool _isEditing = false;\n  bool _isSaving = false;\n  bool _isLoading = true;\n\n  @override\n  void initState() {\n    super.initState();\n    _logger.provider(`
- [L31] `);\n    _loadData();\n  }\n\n  @override\n  void dispose() {\n    _codeController.dispose();\n    _logger.provider(`
- [L38] `);\n    super.dispose();\n  }\n\n  Future<void> _loadData() async {\n    final user = ref.read(currentUserProvider);\n    if (user == null) return;\n    final client = ref.read(supabaseClientProvider);\n\n    try {\n      _logger.db(`
- [L48] `);\n      final profile = await client\n          .from(`
- [L50, L58] `)\n          .select(`
- [L51, L59] `)\n          .eq(`
- [L52] `, user.id)\n          .maybeSingle();\n      _logger.db(`
- [L54] `);\n\n      _logger.db(`
- [L56] `);\n      final referrals = await client\n          .from(`
- [L60, L92] `, user.id);\n      _logger.db(`
- [L61] `);\n\n      if (mounted) {\n        setState(() {\n          _codeController.text = (profile?[`
- [L65] `] as String?) ??\n              `
- [L66] `;\n          _referralCount = referrals.length;\n          _isLoading = false;\n        });\n      }\n    } on PostgrestException catch (e, st) {\n      _logger.db(`
- [L72] `, error: e, stackTrace: st);\n      if (mounted) setState(() => _isLoading = false);\n    } catch (e, st) {\n      _logger.db(`
- [L75] `, error: e, stackTrace: st);\n      if (mounted) setState(() => _isLoading = false);\n    }\n  }\n\n  Future<void> _saveCode() async {\n    _logger.userAction(`
- [L81] `, screen: `
- [L81] `);\n    final user = ref.read(currentUserProvider);\n    if (user == null) return;\n    final client = ref.read(supabaseClientProvider);\n\n    setState(() => _isSaving = true);\n    try {\n      _logger.db(`
- [L88] `);\n      await client\n          .from(`
- [L90] `)\n          .update({`
- [L91] `: _codeController.text.trim().toUpperCase()})\n          .eq(`
- [L93] `);\n\n      if (mounted) {\n        setState(() {\n          _isSaving = false;\n          _isEditing = false;\n        });\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(\n            content: const Text(`
- [L102] `),\n            backgroundColor: AkeliColors.success,\n            behavior: SnackBarBehavior.floating,\n            shape: RoundedRectangleBorder(\n              borderRadius: BorderRadius.circular(AkeliRadius.lg),\n            ),\n          ),\n        );\n      }\n    } on PostgrestException catch (e, st) {\n      _logger.db(`
- [L112] `, error: e, stackTrace: st);\n      if (mounted) setState(() => _isSaving = false);\n    } catch (e, st) {\n      _logger.db(`
- [L115] `, error: e, stackTrace: st);\n      if (mounted) setState(() => _isSaving = false);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    if (_isLoading) {\n      return const Scaffold(\n        backgroundColor: AkeliColors.surface,\n        body: Center(child: CircularProgressIndicator()),\n      );\n    }\n\n    return Scaffold(\n      backgroundColor: AkeliColors.surface,\n      appBar: AppBar(\n        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),\n        elevation: 0,\n        scrolledUnderElevation: 0,\n        leading: IconButton(\n          icon: const Icon(Icons.arrow_back, color: AkeliColors.onSurfaceVariant),\n          onPressed: () => context.pop(),\n        ),\n        title: Text(\n          `
- [L189] `,\n                    style: GoogleFonts.inter(\n                      fontSize: 10,\n                      fontWeight: FontWeight.w500,\n                      color: AkeliColors.onSurfaceVariant,\n                      letterSpacing: 1,\n                    ),\n                  ),\n                  const SizedBox(height: AkeliSpacing.sm),\n                  if (!_isEditing)\n                    Text(\n                      _codeController.text,\n                      style: GoogleFonts.plusJakartaSans(\n                        fontSize: 36,\n                        fontWeight: FontWeight.w800,\n                        color: AkeliColors.primary,\n                        letterSpacing: 2,\n                      ),\n                    ),\n                  if (_isEditing) ...[\n                    const SizedBox(height: AkeliSpacing.sm),\n                    TextField(\n                      controller: _codeController,\n                      textAlign: TextAlign.center,\n                      style: GoogleFonts.plusJakartaSans(\n                        fontSize: 24,\n                        fontWeight: FontWeight.w700,\n                        color: AkeliColors.primary,\n                        letterSpacing: 2,\n                      ),\n                      decoration: InputDecoration(\n                        border: OutlineInputBorder(\n                          borderRadius: BorderRadius.circular(12),\n                          borderSide: BorderSide.none,\n                        ),\n                        fillColor: AkeliColors.surfaceContainerHigh,\n                        filled: true,\n                        contentPadding: const EdgeInsets.symmetric(\n                          horizontal: AkeliSpacing.md,\n                          vertical: AkeliSpacing.sm,\n                        ),\n                      ),\n                      autofocus: true,\n                    ),\n                  ],\n                  const SizedBox(height: AkeliSpacing.md),\n                  Container(\n                    padding: const EdgeInsets.symmetric(\n                      horizontal: AkeliSpacing.md,\n                      vertical: AkeliSpacing.sm,\n                    ),\n                    decoration: BoxDecoration(\n                      color: const Color(0xFFFF9F1C).withValues(alpha: 0.1),\n                      borderRadius: BorderRadius.circular(50),\n                    ),\n                    child: Row(\n                      mainAxisSize: MainAxisSize.min,\n                      children: [\n                        const Icon(\n                          Icons.people_outline,\n                          color: Color(0xFFFF9F1C),\n                          size: 16,\n                        ),\n                        const SizedBox(width: AkeliSpacing.xs),\n                        Text(\n                          `
- [L331] `Edit referral code tapped`

## File: `lib/features/settings/account_page.dart`
- [L36] `AccountPage initState()`
- [L41] `AccountPage disposed`
- [L52] `AccountPage build() | email: ${LogHelper.maskEmail(email)}`
- [L93] `Plus Jakarta Sans`
- [L131] `Mot de passe`
- [L187] `Zone dangereuse`
- [L227] `Update password button tapped`
- [L235] `Veuillez remplir tous les champs.`
- [L239] `Le mot de passe doit contenir au moins 8 caractères.`
- [L243] `Les mots de passe ne correspondent pas.`
- [L253] `Password updated successfully`
- [L266] `updatePassword ERROR | $e`
- [L276] `Delete account button tapped`
- [L291] `Delete account cancelled`
- [L307] `Delete account confirmed`
- [L312] `deleteAccount ERROR | $e`
- [L323] `Invalid login credentials`
- [L324] `Mot de passe actuel incorrect.`
- [L327] `Trop de tentatives. Veuillez patienter.`
- [L329] `Une erreur est survenue. Veuillez réessayer.`

## File: `lib/features/settings/health_profile_page.dart`
- [L35] `Légèrement actif`
- [L36] `Modérément actif`
- [L38] `Très actif`
- [L42] `Perte de poids`
- [L43] `Prise de muscle`
- [L69] `HealthProfilePage disposed`
- [L90] `HealthProfilePage build()`
- [L135] `HealthProfilePage back tapped`
- [L144] `Plus Jakarta Sans`
- [L169] `PARAMÈTRES DE SANTÉ`
- [L182] `Sex selected`
- [L188] `Sex cleared`
- [L197] `Date de naissance`
- [L201] `Birth date tapped`
- [L210] `Birth date picked`
- [L229] `d MMMM yyyy`
- [L231] `Non renseignée`
- [L256] `Height changed`
- [L269] `Poids actuel`
- [L275] `Weight changed`
- [L288] `Poids cible`
- [L294] `Target weight changed`
- [L306] `activité\n                      const SettingsLabel("Niveau d`
- [L338] `objectif"),\n                      const SizedBox(height: 12),\n                      Wrap(\n                        spacing: 8,\n                        runSpacing: 8,\n                        children: _goalTypeOptions.map((opt) {\n                          final (code, name) = opt;\n                          final selected = local.goalType == code;\n                          return FilterChip(\n                            label: Text(name),\n                            selected: selected,\n                            onSelected: (_) {\n                              _logger.userAction(`
- [L350] `,\n                                  screen: `
- [L351] `,\n                                  metadata: {`
- [L376] `),\n                      const SizedBox(height: 12),\n                      _ChipSelector(\n                        options: _weightGoalOptions,\n                        selected: local.weightGoal,\n                        onSelected: (v) {\n                          _logger.userAction(`
- [L382, L388, L404, L410] `,\n                              screen: `
- [L383, L405] `,\n                              metadata: {`
- [L384] `: v});\n                          setState(() => _local = local.copyWith(weightGoal: v));\n                        },\n                        onCleared: () {\n                          _logger.userAction(`
- [L398] `),\n                      const SizedBox(height: 12),\n                      _ChipSelector(\n                        options: _muscleGoalOptions,\n                        selected: local.muscleGoal,\n                        onSelected: (v) {\n                          _logger.userAction(`
- [L406] `: v});\n                          setState(() => _local = local.copyWith(muscleGoal: v));\n                        },\n                        onCleared: () {\n                          _logger.userAction(`
- [L442] `,\n                              onChanged: (v) {\n                                _logger.userAction(`
- [L444] `,\n                                    screen: `
- [L445] `,\n                                    metadata: {`
- [L446] `: v.round()});\n                                setState(() => _local = local.copyWith(\n                                    targetTimeWeeks: v.round()));\n                              },\n                            ),\n                          ),\n                          SizedBox(\n                            width: 72,\n                            child: Text(\n                              `
- [L491] `,\n                            style: TextStyle(\n                                fontSize: 17,\n                                fontWeight: FontWeight.bold,\n                                color: Colors.white),\n                          ),\n                  ),\n                ),\n              ],\n            ),\n          ),\n        );\n      },\n    );\n  }\n\n  Future<void> _save() async {\n    if (_local == null) return;\n    _logger.userAction(`
- [L509] `,\n        screen: `
- [L510] `);\n    final saved = _local!;\n    setState(() => _saving = true);\n    try {\n      await ref.read(healthProfileProvider.notifier).save(saved);\n      _local = null;\n      if (mounted) {\n        final kcal = computeCalorieGoal(saved);\n        final msg = kcal != null\n            ? `
- [L520] `;\n        rootScaffoldMessengerKey.currentState?.showSnackBar(\n          SnackBar(content: Text(msg)),\n        );\n        context.pop();\n      }\n    } catch (e, st) {\n      _logger.provider(`
- [L527] `,\n          error: e, stackTrace: st);\n      if (mounted) {\n        ScaffoldMessenger.of(context).showSnackBar(\n          SnackBar(content: Text(`

## File: `lib/features/settings/notification_settings_page.dart`
- [L15] `NotificationSettingsPage build()`
- [L49] `Back button tapped`
- [L62, L198, L302] `Plus Jakarta Sans`
- [L79] `NotificationSettingsPage → error | $e`
- [L121] `Recevez vos notifications sur votre appareil`
- [L128] `Messages et conversations`
- [L135] `Heures de repas planifiés`
- [L142] `Nouvelles demandes de connexion`
- [L314] `Save notification prefs tapped`
- [L328] `ERROR | save notification prefs | $e`

## File: `lib/features/settings/preferences_page.dart`
- [L27] `Rapide (< 30 min)`
- [L28] `Moyen (30–60 min)`
- [L29] `Peu importe`
- [L33] `Afrique de l\'Ouest`
- [L34] `Afrique de l\'Est`
- [L35] `Afrique du Nord`
- [L36] `Afrique Centrale`
- [L37] `Afrique du Sud`
- [L44] `PreferencesPage build()`
- [L86] `PreferencesPage back tapped`
- [L95] `Plus Jakarta Sans`
- [L126] `Temps de préparation`
- [L135] `Cooking time selected`
- [L145] `Cuisson en batch`
- [L176] `Batch cooking toggled`
- [L221] `Batch max portions changed`
- [L242] `RÉGION CULINAIRE`
- [L255] `Region selected`
- [L283] `RESTRICTIONS ALIMENTAIRES`
- [L293] `noPork toggled`
- [L306] `noMeat toggled`
- [L319] `noGluten toggled`
- [L332] `noLactose toggled`
- [L409] `PreferencesPage save tapped`
- [L421] `PreferencesPage save error | $e`

## File: `lib/features/settings/settings_page.dart`
- [L21] `SettingsPage build() | isPremium: $isPremium`
- [L62, L156] `Plus Jakarta Sans`
- [L200] `Edit profile button tapped`
- [L243] `Nutrition tracking menu tapped`
- [L251] `Account menu tapped`
- [L259] `Fan mode menu tapped`
- [L267] `Preferences menu tapped`
- [L275] `Health profile menu tapped`
- [L289] `Notifications menu tapped`
- [L298] `Language menu tapped`
- [L312] `Private profile toggled`
- [L329] `Help FAQ menu tapped`
- [L340] `Privacy policy link tapped`
- [L355] `Terms link tapped`
- [L378] `Sign out button tapped`
- [L416] `Sign out cancelled`
- [L431] `Sign out confirmed`
- [L456] `ProfileSection build() | title: $title`
- [L542] `ProfileMenuItem build() | label: $label`
- [L592] `Avatar upload started`
- [L595] `Avatar upload success`
- [L597] `ERROR | avatar upload | $e`
- [L610] `EditProfileSheet initState()`
- [L620] `EditProfileSheet disposed`
- [L628] `EditProfileSheet build()`
- [L660] `Edit profile sheet closed`
- [L782] `Save profile button tapped`
- [L807] `Profile save executed`

## File: `lib/features/settings/widgets/allergen_picker_widget.dart`
- [L59] `Allergen suggested`
- [L65] `BEFORE | label: $txt`
- [L67] `AFTER | success`
- [L74] `ERROR | $e`

## File: `lib/features/settings/widgets/settings_widgets.dart`
- [L76] `SettingsRadioRow tapped`

## File: `lib/features/subscription/subscription_page.dart`
- [L15] `SubscriptionPage build() | isPremium: $isPremium`
- [L45] `Abonnement actif`
- [L45] `Akeli Premium`
- [L55] `Merci de faire partie de la communauté Akeli.`
- [L56] `Nutrition africaine personnalisée`
- [L131] `Subscribe button tapped`
- [L150] `Recettes africaines personnalisées avec IA`
- [L151] `Plan alimentaire hebdomadaire adapté`
- [L152] `Suivi nutritionnel détaillé`
- [L153] `Assistant IA nutritionnel`
- [L154] `Mode Fan — soutenez vos créateurs`
- [L155] `Communauté et groupes de discussion`
- [L156] `Liste de courses automatique`
- [L167] `ActiveSubCard build()`
- [L215] `${date.day.toString().padLeft(2, `

## File: `lib/features/support/support_page.dart`
- [L32] `SupportPage initState()`
- [L44] `SupportPage disposed`
- [L49] `Add screenshot tapped`
- [L58] `Screenshot selected`
- [L70] `BEFORE | bucket: support-screenshots | path: $fileName`
- [L81] `AFTER | url: $url`
- [L84] `ERROR | $e`
- [L91] `SupportPage | form validation failed`
- [L95] `Submit support ticket tapped`
- [L108] `BEFORE | table: support_message | op: INSERT | userId: ${user?.id}`
- [L116] `AFTER | table: support_message | rows: 1`
- [L134] `ERROR | table: support_message | code: ${e.code}`
- [L142] `ERROR | support submit | unexpected | $e`
- [L243] `Ex: Problème de connexion...`
- [L246] `Veuillez entrer un sujet`
- [L269] `Veuillez entrer votre email`
- [L272] `Veuillez entrer un email valide`
- [L292] `Décrivez votre problème...`
- [L295] `Veuillez entrer votre message`
- [L298] `Le message doit contenir au moins 10 caractères`
- [L329] `Screenshot removed`
- [L458] `Plus Jakarta Sans`

## File: `lib/firebase_options.dart`
- [L21] `DefaultFirebaseOptions have not been configured for web - `
- [L22, L33, L38, L43] `you can reconfigure this by running the FlutterFire CLI again.`
- [L32] `DefaultFirebaseOptions have not been configured for macos - `
- [L37] `DefaultFirebaseOptions have not been configured for windows - `
- [L42] `DefaultFirebaseOptions have not been configured for linux - `
- [L47] `DefaultFirebaseOptions are not supported for this platform.`

## File: `lib/main.dart`
- [L16] `🚀 Akeli app starting | initializing Supabase & Firebase`
- [L26] `✅ Firebase initialized`
- [L34] `FCM terminated-state message | type: ${initialMessage.data[`
- [L39] `FCM Foreground Message received: ${message.notification?.title}`
- [L41] `Nouvelle notification`
- [L66] `⚠️ Firebase init failed (Please run flutterfire configure): $e`
- [L70] `✅ Supabase initialized | launching ProviderScope`
- [L86] `FCM background tap | type: ${message.data[`
- [L103] `🔄 AkeliApp.build() | evaluating router`

## File: `lib/providers/auth_provider.dart`
- [L12] `authStreamProvider build() | subscribing to onAuthStateChange`
- [L13] `authStreamProvider disposed`
- [L18] `Auth state changed | event: ${state.event} | userId: ${state.session?.user.id ?? "null"}`
- [L26] `currentUserProvider evaluated | userId: ${user?.id ?? "null"}`
- [L32] `isAuthenticatedProvider evaluated | isAuth: $isAuth`
- [L45] `AuthNotifier build()`
- [L46] `AuthNotifier disposed`
- [L53] `signUp BEFORE | email: ${LogHelper.maskEmail(email)}`
- [L54] `AuthNotifier → loading (signUp)`
- [L59] `BEFORE | op: signUp | supabase.auth.signUp`
- [L65] `signUp ERROR | no user returned`
- [L66] `Sign-up returned no user`
- [L68] `signUp SUCCESS | userId: ${response.user!.id}`
- [L69] `AuthNotifier → data (signUp success)`
- [L71] `signUp ERROR | AuthException: ${e.message}`
- [L72] `AuthNotifier → error (signUp failed)`
- [L75] `signUp ERROR | unexpected: $e`
- [L76] `AuthNotifier → error (signUp unexpected)`
- [L86] `signIn BEFORE | email: ${LogHelper.maskEmail(email)}`
- [L87] `AuthNotifier → loading (signIn)`
- [L92] `BEFORE | op: signInWithPassword | supabase.auth`
- [L97] `signIn SUCCESS | userId: ${response.user?.id ?? "null"}`
- [L98] `AuthNotifier → data (signIn success)`
- [L100] `signIn ERROR | AuthException: ${e.message}`
- [L101] `AuthNotifier → error (signIn AuthException)`
- [L104] `signIn ERROR | unexpected: $e`
- [L105] `AuthNotifier → error (signIn unexpected)`
- [L112] `signOut BEFORE`
- [L113] `AuthNotifier → loading (signOut)`
- [L118] `BEFORE | op: signOut | supabase.auth`
- [L120] `signOut SUCCESS`
- [L121] `AuthNotifier → data (signOut success)`
- [L123] `signOut ERROR | $e`
- [L124] `AuthNotifier → error (signOut failed)`
- [L131] `resetPassword BEFORE | email: ${LogHelper.maskEmail(email)}`
- [L132] `AuthNotifier → loading (resetPassword)`
- [L137] `BEFORE | op: resetPasswordForEmail | supabase.auth`
- [L139] `resetPassword SUCCESS | email: ${LogHelper.maskEmail(email)}`
- [L140] `AuthNotifier → data (resetPassword success)`
- [L142] `resetPassword ERROR | AuthException: ${e.message}`
- [L143] `AuthNotifier → error (resetPassword failed)`
- [L146] `resetPassword ERROR | unexpected: $e`
- [L147] `AuthNotifier → error (resetPassword unexpected)`
- [L157] `updatePassword BEFORE`
- [L158] `AuthNotifier → loading (updatePassword)`
- [L164] `No authenticated user`
- [L166] `BEFORE | op: signInWithPassword | verify current password`
- [L168] `updatePassword | current password verified`
- [L170] `BEFORE | op: updateUser | new password`
- [L172] `updatePassword SUCCESS`
- [L173] `AuthNotifier → data (updatePassword success)`
- [L175] `updatePassword ERROR | AuthException: ${e.message}`
- [L176] `AuthNotifier → error (updatePassword failed)`
- [L179] `updatePassword ERROR | unexpected: $e`
- [L180] `AuthNotifier → error (updatePassword unexpected)`
- [L187] `deleteAccount BEFORE`
- [L188] `AuthNotifier → loading (deleteAccount)`
- [L193] `BEFORE | invoking edge function`
- [L195] `AFTER | status: ${response.status}`
- [L198] `delete-account returned status ${response.status}`
- [L201] `BEFORE | op: signOut | after account deletion`
- [L203] `deleteAccount SUCCESS | user signed out`
- [L204] `AuthNotifier → data (deleteAccount success)`
- [L206] `ERROR | $e`
- [L207] `AuthNotifier → error (deleteAccount failed)`

## File: `lib/providers/creator_provider.dart`
- [L18] `creatorsListProvider build()`
- [L19] `creatorsListProvider disposed`
- [L23] `creatorsListProvider EARLY RETURN | reason: no authenticated user`
- [L31] `BEFORE rpc | fn: generate_creators_personalized | userId: ${user.id}`
- [L36] `AFTER rpc | fn: generate_creators_personalized | rows: ${rpcRows.length}`
- [L39] `creatorsListProvider → data | count: 0`
- [L51, L220] `id, user_id, display_name, profile_image_url, bio, specialties, recipe_count, fan_count, average_rating, heritage_region`
- [L53] `AFTER | table: creator | rows: ${rows.length}`
- [L65] `AFTER | table: fan_subscription | rows: ${fanRows.length}`
- [L71] `Permission denied | table: fan_subscription | userId: ${user.id}`
- [L73] `ERROR | table: fan_subscription | code: ${e.code} | ${e.message}`
- [L78] `t preserve order)\n    final creatorMap = <String, Creator>{};\n    for (final r in rows) {\n      final row = r as Map<String, dynamic>;\n      final id = row[`
- [L82] `] as String;\n      creatorMap[id] = Creator.fromJson({\n        ...row,\n        `
- [L85] `: fanIds.contains(id),\n      });\n    }\n\n    final list = orderedIds\n        .where((id) => creatorMap.containsKey(id))\n        .map((id) => creatorMap[id]!)\n        .toList();\n\n    if (list.isEmpty) {\n      _logger.rls(`
- [L95] `);\n    }\n    _logger.provider(`
- [L97] `);\n    return list;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L100, L140, L249, L306] `) {\n      _logger.rls(`
- [L101, L141, L250, L307] `, error: e, stackTrace: st);\n    } else {\n      _logger.db(`
- [L103, L143, L252] `, error: e, stackTrace: st);\n    }\n    _logger.provider(`
- [L116] `);\n  ref.onDispose(() => _logger.provider(`
- [L117] `));\n\n  final client = ref.watch(supabaseClientProvider);\n  _logger.db(`
- [L120] `);\n\n  try {\n    final row = await client\n        .from(`
- [L124] `)\n        .select(`
- [L125] `)\n        .eq(`
- [L126] `, creatorId)\n        .maybeSingle();\n\n    _logger.db(`
- [L129] `);\n\n    if (row == null) {\n      _logger.rls(`
- [L132] `);\n      _logger.provider(`
- [L133] `);\n      return null;\n    }\n\n    _logger.provider(`
- [L137] `);\n    return Creator.fromJson(row);\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L156] `creatorRecipesProvider build() | creatorId: $creatorId`
- [L157] `creatorRecipesProvider disposed`
- [L165] `id, creator_id, title, cover_image_url, region, average_rating, like_count, difficulty, prep_time_min, cook_time_min, servings, is_published, rating_count, created_at`
- [L170] `AFTER | table: recipe | rows: ${rows.length}`
- [L173] `Zero rows | table: recipe | creatorId: $creatorId | possible RLS block`
- [L179] `creatorRecipesProvider → data | count: ${list.length}`
- [L183] `Permission denied | table: recipe | creatorId: $creatorId`
- [L185] `ERROR | table: recipe | code: ${e.code} | ${e.message}`
- [L187] `creatorRecipesProvider → error | ${e.message}`
- [L198] `creatorDetailProvider build() | creatorId: $creatorId`
- [L199] `creatorDetailProvider disposed`
- [L203] `creatorDetailProvider EARLY RETURN | reason: no authenticated user`
- [L204] `Not authenticated`
- [L209] `[STEP 1] Fetching creator + recipes + fan status in parallel | creatorId: $creatorId`
- [L223] `s published recipes (for totalLikes + recipeIds)\n      client\n          .from(`
- [L225, L231, L266] `)\n          .select(`
- [L226, L232] `)\n          .eq(`
- [L227, L233] `, creatorId)\n          .eq(`
- [L234] `, user.id)\n          .eq(`
- [L235] `)\n          .limit(1),\n    ]);\n\n    final creatorRow = results[0] as Map<String, dynamic>;\n    final recipeRows = results[1] as List<dynamic>;\n    final fanRows = results[2] as List<dynamic>;\n\n    _logger.db(`
- [L243] `);\n\n    creator = Creator.fromJson(creatorRow);\n    recipes = recipeRows.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();\n    isFan = fanRows.isNotEmpty;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L254] `);\n    rethrow;\n  }\n\n  final totalLikes = recipes.fold<int>(0, (sum, r) => sum + r.likeCount);\n  final recipeIds = recipes.map((r) => r.id).toList();\n\n  int userConsumptionCount = 0;\n  if (recipeIds.isNotEmpty) {\n    _logger.db(`
- [L263] `);\n    try {\n      final consumptionRows = await client\n          .from(`
- [L267] `)\n          .inFilter(`
- [L272] `] as String)\n          .toSet()\n          .length;\n\n      _logger.db(`
- [L276] `);\n    } on PostgrestException catch (e, st) {\n      _logger.db(`
- [L297] `);\n  try {\n    await client.from(`
- [L299] `).insert({\n      `
- [L300] `: creatorId,\n      `
- [L301] `: userId,\n      `
- [L302] `,\n    });\n    _logger.db(`
- [L304] `);\n  } on PostgrestException catch (e, st) {\n    if (e.code == `

## File: `lib/providers/dm_provider.dart`
- [L183] `conversationStateProvider build() | otherUserId: $otherUserId`
- [L184] `conversationStateProvider disposed`
- [L189] `BEFORE | conversationStateProvider | checkExistingDm | otherUserId: $otherUserId`
- [L199] `conversation_id, conversation:conversation_id(type)`
- [L207] `AFTER | conversationStateProvider | found active DM | conversationId: $id`
- [L214] `BEFORE | conversationStateProvider | checkPendingRequest | otherUserId: $otherUserId`
- [L224] `AFTER | conversationStateProvider | pending request exists`
- [L228] `AFTER | conversationStateProvider | no relationship`
- [L240] `myPrivateConversationsProvider build() | userId: ${user?.id}`
- [L241] `myPrivateConversationsProvider disposed`
- [L251] `conversation_id, last_read_at`
- [L253] `AFTER | table: conversation_participant | rows: ${participations.length}`
- [L270] `id, updated_at`
- [L274] `AFTER | table: conversation | rows: ${conversations.length}`
- [L287] `conversation_id, user_id, user_profile:user_id(first_name, avatar_url)`
- [L290] `AFTER | table: conversation_participant | others rows: ${allOthers.length}`
- [L301] `conversation_id, content, sent_at`
- [L305] `AFTER | table: chat_message | rows: ${allMessages.length}`
- [L345] `myPrivateConversationsProvider → data | count: ${result.length}`
- [L354] `pendingDmRequestsProvider build() | userId: ${user?.id}`
- [L355] `pendingDmRequestsProvider disposed`
- [L367] `id, requester_id, message, created_at, user_profile:requester_id(first_name, avatar_url)`
- [L372] `AFTER | table: conversation_request | rows: ${rows.length}`
- [L374] `pendingDmRequestsProvider → data (empty)`
- [L381] `pendingDmRequestsProvider → data | count: ${requests.length}`
- [L386] `Permission denied | table: conversation_request | userId: ${user.id}`
- [L391] `ERROR | table: conversation_request | code: ${e.code}`
- [L404] `groupMembersProvider build() | groupId: $groupId`
- [L406] `groupMembersProvider disposed | groupId: $groupId`
- [L416] `user_id, role, joined_at, user_profile:user_id(first_name, username, avatar_url)`
- [L420] `AFTER | table: group_member | rows: ${rows.length}`
- [L423] `Zero rows | table: group_member | groupId: $groupId | possible RLS block`
- [L428] `groupMembersProvider → data | count: ${members.length}`
- [L433] `Permission denied | table: group_member | groupId: $groupId`
- [L438] `ERROR | table: group_member | code: ${e.code}`
- [L446] `s chat.\nfinal resolveConversationIdProvider =\n    FutureProvider.autoDispose.family<String?, String>((ref, groupId) async {\n  final logger = appLogger;\n  logger.provider(\n      `
- [L451] `);\n  ref.onDispose(() => logger\n      .provider(`
- [L453] `));\n\n  final client = ref.watch(supabaseClientProvider);\n  logger.db(\n      `
- [L457, L1075] `);\n\n  try {\n    final data = await client\n        .from(`
- [L461, L500, L572, L587, L624, L1079] `)\n        .select(`
- [L462, L501, L573, L625, L1080] `)\n        .eq(`
- [L463] `, groupId)\n        .maybeSingle();\n\n    final convId = data?[`
- [L466] `] as String?;\n    logger.db(\n        `
- [L468] `);\n    logger.provider(\n        `
- [L470] `);\n    return convId;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L473, L662, L806, L843] `) {\n      logger.rls(\n          `
- [L475, L664, L808, L845] `,\n          error: e,\n          stackTrace: st);\n    } else {\n      logger.db(\n          `
- [L492] `);\n  ref.onDispose(() => logger.provider(`
- [L493] `));\n\n  final client = ref.watch(supabaseClientProvider);\n  logger.db(`
- [L496] `);\n\n  try {\n    final rows = await client\n        .from(`
- [L502] `, conversationId) as List<dynamic>;\n\n    logger.db(`
- [L504] `);\n\n    final map = <String, String>{};\n    for (final row in rows.cast<Map<String, dynamic>>()) {\n      final userId = row[`
- [L508] `] as String;\n      final profile = row[`
- [L509] `] as Map<String, dynamic>?;\n      final firstName = (profile?[`
- [L510, L511] `] as String? ?? `
- [L510] `).trim();\n      final username = (profile?[`
- [L511] `).trim();\n      final name = firstName.isNotEmpty ? firstName : username;\n      if (name.isNotEmpty) {\n        map[userId] = name;\n      }\n    }\n    return map;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L519, L604, L635, L703, L726] `) {\n      logger.rls(`
- [L520, L605, L636, L704, L727] `, error: e, stackTrace: st);\n    } else {\n      logger.db(`
- [L534] `);\n  ref.onDispose(() => logger.provider(\n      `
- [L536] `));\n\n  final client = ref.watch(supabaseClientProvider);\n  final userId = ref.watch(currentUserProvider)?.id ?? `
- [L539] `;\n\n  logger.db(\n      `
- [L542] `);\n\n  return client\n      .from(`
- [L545] `)\n      .stream(primaryKey: [`
- [L546] `])\n      .eq(`
- [L547] `, conversationId)\n      .order(`
- [L548] `, ascending: false)\n      .map((rows) {\n        logger.db(\n            `
- [L568] `);\n\n  try {\n    final mine = await client\n        .from(`
- [L574] `, userId) as List<dynamic>;\n\n    if (mine.isEmpty) {\n      logger.db(`
- [L577] `);\n      return null;\n    }\n\n    final myIds = mine\n        .cast<Map<String, dynamic>>()\n        .map((r) => r[`
- [L583] `] as String)\n        .toList();\n\n    final shared = await client\n        .from(`
- [L588] `)\n        .inFilter(`
- [L589] `, myIds)\n        .eq(`
- [L590] `, otherUserId) as List<dynamic>;\n\n    for (final row in shared.cast<Map<String, dynamic>>()) {\n      final conv = row[`
- [L593] `] as Map<String, dynamic>?;\n      if (conv?[`
- [L594] `) {\n        final id = row[`
- [L595] `] as String;\n        logger.db(`
- [L596] `);\n        return id;\n      }\n    }\n\n    logger.db(`
- [L601] `);\n    return null;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L620] `);\n\n  try {\n    final result = await client\n        .from(`
- [L626] `, userId)\n        .eq(`
- [L627] `, recipientId)\n        .eq(`
- [L628] `)\n        .maybeSingle();\n\n    final exists = result != null;\n    logger.db(`
- [L632] `);\n    return exists;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L652, L788] `);\n  try {\n    await client.from(`
- [L654, L790] `).insert({\n      `
- [L655, L792] `: userId,\n      `
- [L656] `: recipientId,\n      `
- [L657] `,\n    });\n    logger.db(\n        `
- [L660, L724, L804, L841] `);\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L687] `);\n\n  try {\n    final result = await client.rpc(`
- [L690, L720] `, params: {\n      `
- [L691, L721] `: requestId,\n      `
- [L692] `,\n    }) as Map<String, dynamic>;\n\n    final conversationId = result[`
- [L695] `] as String;\n    logger.db(`
- [L696] `);\n\n    ref.invalidate(myPrivateConversationsProvider);\n    ref.invalidate(pendingDmRequestsProvider);\n\n    return conversationId;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L717] `);\n\n  try {\n    await client.rpc(`
- [L722] `,\n    });\n    logger.db(`
- [L749] ` is not a valid MIME subtype.\n  const extToMime = {\n    `
- [L757] `;\n  logger.db(`
- [L758] `);\n  try {\n    await client.storage.from(`
- [L760] `).uploadBinary(\n      path,\n      bytes,\n      fileOptions: FileOptions(upsert: false, contentType: `
- [L763] `),\n    );\n    final url = client.storage.from(`
- [L765] `).getPublicUrl(path);\n    logger.db(`
- [L766] `);\n    return url;\n  } on StorageException catch (e, st) {\n    logger.db(`
- [L769] `, error: e, stackTrace: st);\n    rethrow;\n  }\n}\n\nFuture<void> sendMessage(\n  WidgetRef ref,\n  String conversationId,\n  String content, {\n  String messageType = `
- [L778] `,\n  String? recipeId,\n  String? caption,\n}) async {\n  final logger = appLogger;\n  final client = ref.read(supabaseClientProvider);\n  final userId = ref.read(currentUserProvider)?.id;\n  if (userId == null) return;\n\n  logger.db(\n      `
- [L791] `: conversationId,\n      `
- [L793] `: content,\n      `
- [L794] `: messageType,\n      if (recipeId != null) `
- [L795] `: recipeId,\n      if (caption != null && caption.isNotEmpty) `
- [L796] `: caption,\n    });\n    logger.db(`
- [L798] `);\n\n    await client\n        .from(`
- [L801, L836] `)\n        .update({`
- [L802, L837] `: DateTime.now().toIso8601String()})\n        .eq(`
- [L803] `, conversationId);\n    logger.db(`
- [L833] `);\n  try {\n    await client\n        .from(`
- [L838, L1081] `, conversationId)\n        .eq(`
- [L839] `, userId);\n    logger.db(\n        `
- [L868] `BEFORE | table: conversation_participant | op: DELETE | conversationId: $conversationId`
- [L875] `AFTER | table: conversation_participant | deleted for current user`
- [L879] `Permission denied | table: conversation_participant | DELETE | conversationId: $conversationId`
- [L884] `ERROR | table: conversation_participant | DELETE | code: ${e.code}`
- [L906, L996, L1156] `User not logged in`
- [L908] `BEFORE | createGroup | name: $name`
- [L912] `BEFORE | table: community_group | op: INSERT`
- [L919, L1004] `BEFORE | storage: group_covers | op: UPLOAD | path: $imagePath`
- [L929, L1014] `AFTER | storage: group_covers | op: UPLOAD | url: $coverUrl`
- [L944] `AFTER | table: community_group | groupId: $groupId`
- [L947] `BEFORE | table: group_member | op: INSERT | role: admin`
- [L955] `BEFORE | table: conversation | op: INSERT | type: creator_group`
- [L968] `BEFORE | table: conversation_participant | op: INSERT | conversationId: $conversationId`
- [L974] `AFTER | createGroup sequence completed | groupId: $groupId`
- [L978] `Permission denied | createGroup`
- [L980] `ERROR | createGroup | code: ${e.code} | ${e.message}`
- [L998] `BEFORE | updateGroupCover | groupId: $groupId`
- [L1016] `BEFORE | table: community_group | op: UPDATE | cover_url`
- [L1021] `AFTER | table: community_group | op: UPDATE | cover_url`
- [L1024] `Permission denied | updateGroupCover`
- [L1026] `ERROR | updateGroupCover | code: ${e.code}`
- [L1038] `groupDetailsProvider build() | groupId: $groupId`
- [L1039] `groupDetailsProvider disposed | groupId: $groupId`
- [L1047] `id, name, description, is_public, creator_id, region_code, language, topic, max_members, member_count, cover_url`
- [L1050] `AFTER | table: community_group | rows: ${data == null ? 0 : 1}`
- [L1051] `Zero rows | table: community_group | groupId: $groupId | possible RLS block`
- [L1055] `Permission denied | table: community_group | groupId: $groupId`
- [L1057] `ERROR | table: community_group | code: ${e.code}`
- [L1063] `s conversation, ordered newest-first.\nfinal groupSharedImagesProvider =\n    FutureProvider.autoDispose.family<List<String>, String>((ref, groupId) async {\n  appLogger.provider(`
- [L1066] `);\n  ref.onDispose(() => appLogger.provider(`
- [L1067] `));\n\n  final client = ref.watch(supabaseClientProvider);\n  final conversationId = await ref.watch(resolveConversationIdProvider(groupId).future);\n  if (conversationId == null) {\n    appLogger.provider(`
- [L1072] `);\n    return [];\n  }\n  appLogger.db(`
- [L1082] `)\n        .order(`
- [L1083] `, ascending: false)\n        .limit(100) as List<dynamic>;\n\n    final urls = data.cast<Map<String, dynamic>>().map((r) => r[`
- [L1086] `] as String).toList();\n    appLogger.db(`
- [L1087] `);\n    return urls;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L1090] `) {\n      appLogger.rls(`
- [L1091] `, error: e, stackTrace: st);\n    } else {\n      appLogger.db(`
- [L1102] `groupSharedRecipesProvider build() | groupId: $groupId`
- [L1103] `groupSharedRecipesProvider disposed | groupId: $groupId`
- [L1108] `groupSharedRecipesProvider → no conversation found`
- [L1130] `AFTER | table: chat_message | recipes: ${ids.length} (deduped)`
- [L1134] `Permission denied | table: chat_message | conversationId: $conversationId`
- [L1136] `ERROR | table: chat_message | code: ${e.code}`
- [L1168] `Update group`
- [L1169] `BEFORE | table: community_group | op: UPDATE | groupId: $groupId`
- [L1180] `AFTER | table: community_group | op: UPDATE | row: $response`
- [L1184] `Permission denied | table: community_group | UPDATE | groupId: $groupId`
- [L1186] `ERROR | table: community_group | UPDATE | code: ${e.code}`
- [L1221] `browseGroupsProvider build()`
- [L1222] `browseGroupsProvider disposed`
- [L1231] `BEFORE | RPC: generate_groups_personalized`
- [L1239] `AFTER | RPC: generate_groups_personalized | rows: ${rpcResult.length}`
- [L1250, L1275] `id, name, description, member_count, max_members, region_code, language, topic, creator_id, cover_url`
- [L1267] `ERROR | RPC: generate_groups_personalized | fallback to direct query`
- [L1284] `AFTER | table: community_group | rows: ${rows.length}`
- [L1300] `pendingGroupInvitesProvider build() | groupId: $groupId`
- [L1301] `pendingGroupInvitesProvider disposed | groupId: $groupId`
- [L1313] `AFTER | table: group_invite | rows: ${rows.length}`

## File: `lib/providers/fan_mode_provider.dart`
- [L18] `myFanSubscriptionProvider build() | userId: ${user.id}`
- [L19] `myFanSubscriptionProvider disposed`
- [L29] `AFTER | table: fan_subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}`
- [L31] `Zero rows | table: fan_subscription | userId: ${user.id} | no subscription or RLS block`
- [L32] `myFanSubscriptionProvider → data (null)`
- [L35] `myFanSubscriptionProvider → data | userId: ${user.id}`
- [L39] `Permission denied | table: fan_subscription | userId: ${user.id}`
- [L41] `ERROR | table: fan_subscription | code: ${e.code}`
- [L43] `myFanSubscriptionProvider → error | ${e.message}`
- [L46] `ERROR | table: fan_subscription | unexpected: $e`
- [L47] `myFanSubscriptionProvider → error | $e`
- [L58] `fanEligibleCreatorsProvider build()`
- [L59] `fanEligibleCreatorsProvider disposed`
- [L67] `AFTER | table: creator | rows: ${data.length}`
- [L69] `Zero rows | table: creator | possible RLS block`
- [L72] `fanEligibleCreatorsProvider → data | eligible: ${eligible.length}`
- [L76] `Permission denied | table: creator`
- [L78] `ERROR | table: creator | code: ${e.code}`
- [L80] `fanEligibleCreatorsProvider → error | ${e.message}`
- [L83] `ERROR | table: creator | unexpected: $e`
- [L84] `fanEligibleCreatorsProvider → error | $e`
- [L95] `creatorProfileProvider build() | creatorId: $creatorId`
- [L96] `creatorProfileProvider disposed | creatorId: $creatorId`
- [L106] `AFTER | table: creator | rows: ${data == null ? 0 : 1} | creatorId: $creatorId`
- [L108] `Zero rows | table: creator | creatorId: $creatorId | possible RLS block or not found`
- [L109] `creatorProfileProvider → data (null)`
- [L112] `creatorProfileProvider → data | creatorId: $creatorId`
- [L116] `Permission denied | table: creator | creatorId: $creatorId`
- [L118] `ERROR | table: creator | creatorId: $creatorId | code: ${e.code}`
- [L120] `creatorProfileProvider → error | ${e.message}`
- [L123] `ERROR | table: creator | creatorId: $creatorId | unexpected: $e`
- [L124] `creatorProfileProvider → error | $e`
- [L135] `${d.year}-${d.month.toString().padLeft(2, `
- [L175] `creatorConsumptionProvider build() | userId: ${user.id}`
- [L176] `creatorConsumptionProvider disposed`
- [L181] `s consumption rows\n  appLogger.db(`
- [L182] `);\n  late final List<Map<String, dynamic>> consumptionRows;\n  try {\n    consumptionRows = await client\n        .from(`
- [L186, L272] `)\n        .select(`
- [L187, L273] `)\n        .eq(`
- [L188, L274] `, user.id)\n        .eq(`
- [L189] `, monthKey);\n    appLogger.db(`
- [L190] `);\n    if (consumptionRows.isEmpty) {\n      appLogger.rls(`
- [L192] `);\n      appLogger.provider(`
- [L193] `);\n      return [];\n    }\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L197, L229, L282] `) {\n      appLogger.rls(`
- [L198, L230, L283] `, error: e, stackTrace: st);\n    } else {\n      appLogger.db(`
- [L200, L232, L285] `, error: e, stackTrace: st);\n    }\n    appLogger.provider(`
- [L202, L234, L287] `);\n    rethrow;\n  } catch (e, st) {\n    appLogger.db(`
- [L205, L237, L290] `, error: e, stackTrace: st);\n    appLogger.provider(`
- [L212] `] as String?)\n      .whereType<String>()\n      .toSet()\n      .toList();\n\n  appLogger.db(`
- [L217] `);\n  late final List<Map<String, dynamic>> creatorRows;\n  try {\n    creatorRows = await client\n        .from(`
- [L221] `)\n        .select()\n        .inFilter(`
- [L223] `, creatorIds);\n    appLogger.db(`
- [L224] `);\n    if (creatorRows.isEmpty && creatorIds.isNotEmpty) {\n      appLogger.rls(`
- [L226] `);\n    }\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L238] `);\n    rethrow;\n  }\n\n  final creatorMap = {for (final r in creatorRows) r[`
- [L242] `] as String: Creator.fromJson(r)};\n  final result = aggregateConsumption(consumptionRows, creatorMap);\n  if (result.isEmpty && consumptionRows.isNotEmpty) {\n    appLogger.rls(\n      `
- [L247] `,\n    );\n  }\n  appLogger.provider(`
- [L263] `);\n  ref.onDispose(() => appLogger.provider(`
- [L264] `));\n\n  final monthKey = currentMonthKey();\n  final client = ref.watch(supabaseClientProvider);\n\n  appLogger.db(`
- [L269] `);\n  try {\n    final data = await client\n        .from(`
- [L275] `, monthKey)\n        .maybeSingle();\n    final count = (data?[`
- [L277] `] as int?) ?? 0;\n    appLogger.db(`
- [L278] `);\n    appLogger.provider(`
- [L279] `);\n    return count;\n  } on PostgrestException catch (e, st) {\n    if (e.code == `
- [L305] `);\n    ref.onDispose(() => _logger.provider(`
- [L306] `));\n  }\n\n  Future<void> activate(String creatorId) async {\n    _logger.userAction(`
- [L310] `, metadata: {`
- [L310] `: creatorId});\n    _logger.edge(`
- [L311, L335] `);\n    _logger.provider(`
- [L312] `);\n\n    final client = ref.read(supabaseClientProvider);\n    state = const AsyncLoading();\n    state = await AsyncValue.guard(() async {\n      try {\n        await client.functions.invoke(\n          `
- [L319] `,\n          body: {`
- [L320] `: creatorId},\n        );\n        _logger.edge(`
- [L322, L343] `);\n        _logger.provider(`
- [L323, L344] `);\n      } catch (e, st) {\n        _logger.edge(`
- [L325, L346] `, error: e, stackTrace: st);\n        _logger.provider(`
- [L326] `);\n        rethrow;\n      }\n    });\n    if (state is AsyncData) ref.invalidate(myFanSubscriptionProvider);\n  }\n\n  Future<void> cancel() async {\n    _logger.userAction(`
- [L334] `);\n    _logger.edge(`
- [L336] `);\n\n    final client = ref.read(supabaseClientProvider);\n    state = const AsyncLoading();\n    state = await AsyncValue.guard(() async {\n      try {\n        await client.functions.invoke(`
- [L342] `, body: {});\n        _logger.edge(`

## File: `lib/providers/food_region_provider.dart`
- [L16, L71] `);\n\n  final locale = ref.watch(userProfileProvider).valueOrNull?.locale ?? `
- [L18] `;\n  final nameColumn = _localeToColumn(locale);\n\n  logger.db(\n      `
- [L22, L76] `);\n\n  final client = ref.watch(supabaseClientProvider);\n  try {\n    final rows = await client\n        .from(`
- [L27, L81] `)\n        .select(`
- [L28] `);\n\n    logger.db(`
- [L30, L82] `);\n\n    final map = <String, String>{};\n    for (final row in rows) {\n      final code = row[`
- [L34, L86] `] as String;\n      final name = (row[nameColumn] as String?) ??\n          (row[`
- [L36] `] as String?) ??\n          code;\n      map[code] = name;\n    }\n\n    logger.provider(`
- [L41] `);\n    return map;\n  } on Exception catch (e, st) {\n    logger.db(\n        `
- [L45] `,\n        error: e,\n        stackTrace: st);\n    rethrow;\n  }\n});\n\nString _localeToColumn(String locale) {\n  switch (locale) {\n    case `
- [L54, L56, L58] `:\n      return `
- [L55, L57] `;\n    case `
- [L59] `;\n    default:\n      return `
- [L73] `;\n  final nameColumn = _localeToColumn(locale);\n\n  logger.db(`
- [L88] `] as String?) ??\n          code;\n      map[code] = name;\n    }\n    logger.db(`
- [L92] `);\n    return map;\n  } on Exception catch (e, st) {\n    logger.db(`

## File: `lib/providers/health_profile_provider.dart`
- [L59] `HealthProfileNotifier build() | userId: ${user.id}`
- [L60] `HealthProfileNotifier disposed`
- [L71] `sex, birth_date, height_cm, weight_kg, target_weight_kg, activity_level, weight_goal, muscle_goal, starting_weight_kg, target_time_weeks`
- [L90] `AFTER | tables: user_health_profile,user_goal | userId: ${user.id}`
- [L94] `Zero rows | table: user_health_profile | userId: ${user.id} | possible RLS block`
- [L98] `HealthProfileNotifier → data | userId: ${user.id}`
- [L104] `Permission denied | HealthProfileNotifier | userId: ${user.id}`
- [L108] `ERROR | HealthProfileNotifier | code: ${e.code}`
- [L111] `HealthProfileNotifier → error | ${e.message}`
- [L120] `HealthProfileNotifier save`
- [L133] `BEFORE | table: user_health_profile | op: UPSERT | userId: ${user.id}`
- [L154] `AFTER | table: user_health_profile | op: UPSERT | rows: 1`
- [L174] `BEFORE | table: user_goal | op: DELETE | userId: ${user.id}`
- [L176] `AFTER | table: user_goal | op: DELETE`
- [L181] `BEFORE | table: user_goal | op: INSERT | userId: ${user.id}`
- [L191] `AFTER | table: user_goal | op: INSERT | rows: 1`
- [L197] `HealthProfileNotifier → save success`
- [L202] `Permission denied | HealthProfileNotifier save | userId: ${user.id}`
- [L207] `ERROR | HealthProfileNotifier save | code: ${e.code}`
- [L211] `HealthProfileNotifier → error (save)`
- [L216] `ERROR | HealthProfileNotifier save | unexpected: $e`
- [L219] `HealthProfileNotifier → error (save unexpected)`

## File: `lib/providers/ingredient_provider.dart`
- [L9] `ingredientDetailProvider build() | ingredientId: $ingredientId`
- [L10] `ingredientDetailProvider disposed | ingredientId: $ingredientId`
- [L19] `id, name_fr, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, description_fr, image_url, tags`
- [L24] `AFTER | table: ingredient | rows: 0`
- [L26] `Zero rows | table: ingredient | ingredientId: $ingredientId | possible RLS block`
- [L30] `AFTER | table: ingredient | rows: 1`
- [L35] `Permission denied | table: ingredient | ingredientId: $ingredientId`
- [L41] `ERROR | table: ingredient | code: ${e.code} | ${e.message}`
- [L47] `ERROR | table: ingredient | unexpected | $e`

## File: `lib/providers/journey_provider.dart`
- [L16] `journeyStatsProvider build() | userId: ${user.id} | ${params.year}-${params.month}`
- [L20] `journeyStatsProvider disposed | ${params.year}-${params.month}`
- [L26] `BEFORE rpc | fn: get_journey_stats | year: ${params.year} | month: ${params.month}`
- [L35] `AFTER rpc | fn: get_journey_stats | rows: ${data == null ? 0 : 1}`
- [L40] `journeyStatsProvider → data | calendar days: ${stats.calendar.length}`
- [L45] `ERROR rpc | fn: get_journey_stats | code: ${e.code} | ${e.message}`
- [L51] `ERROR rpc | fn: get_journey_stats | $e`

## File: `lib/providers/meal_plan_provider.dart`
- [L20] `activeMealPlanProvider build() | userId: ${user.id}`
- [L21] `activeMealPlanProvider disposed`
- [L29] `*, meal_plan_entry(*, meal_ingredient(*), meal_plan_entry_component(*, recipe(id, title, cover_image_url, prep_time_min, cook_time_min, recipe_macro(calories, protein_g, carbs_g, fat_g))))`
- [L34] `AFTER | table: meal_plan | rows: ${data == null ? 0 : 1} | userId: ${user.id}`
- [L36] `Zero rows | table: meal_plan | userId: ${user.id} | no active plan or RLS block`
- [L37] `activeMealPlanProvider → data (null)`
- [L51] `AFTER | table: recipe_comment | rows: ${ratedRecipeIds.length}`
- [L53] `Zero rows | table: recipe_comment | userId: ${user.id} | no ratings or RLS block`
- [L57] `Permission denied | table: recipe_comment | userId: ${user.id}`
- [L59] `ERROR | table: recipe_comment | code: ${e.code}`
- [L61, L72] `activeMealPlanProvider → error | ${e.message}`
- [L64] `activeMealPlanProvider → data | mealPlanId: ${data[`
- [L64] `]} | ratedCount: ${ratedRecipeIds.length}`
- [L68] `Permission denied | table: meal_plan | userId: ${user.id}`
- [L70] `ERROR | table: meal_plan | code: ${e.code}`
- [L75] `ERROR | table: meal_plan | unexpected: $e`
- [L76] `activeMealPlanProvider → error | $e`
- [L90] `MealPlanGeneratorNotifier build()`
- [L91] `MealPlanGeneratorNotifier disposed`
- [L103] `Generate meal plan`
- [L104] `BEFORE | days: $effectiveDays | mealsPerDay: $mealsPerDay | userId: ${user.id}`
- [L105] `MealPlanGeneratorNotifier → loading (generate)`
- [L115] `AFTER | success | responseType: ${res.data.runtimeType}`
- [L131] `ERROR | missing meal_plan_id in response`
- [L132] `generate-meal-plan: missing meal_plan_id in response`
- [L135] `MealPlanGeneratorNotifier → data (generate success) | mealPlanId: $mealPlanId`
- [L138, L392, L408, L644, L763] `ERROR | $e`
- [L139] `MealPlanGeneratorNotifier → error | $e`
- [L144] `MealPlanGeneratorNotifier → invalidating activeMealPlanProvider`
- [L163] `MealPlanSwapNotifier build()`
- [L164] `MealPlanSwapNotifier disposed`
- [L175] `Swap meal plan entry`
- [L176] `BEFORE | rpc: swap_meal_plan_entry | userId: ${user.id} | entryId: $entryId | newRecipeId: $newRecipeId`
- [L177] `MealPlanSwapNotifier → loading (swap)`
- [L188] `AFTER | rpc: swap_meal_plan_entry | success`
- [L189] `MealPlanSwapNotifier → data (swap success)`
- [L191] `ERROR | rpc: swap_meal_plan_entry | code: ${e.code}`
- [L192, L196] `MealPlanSwapNotifier → error | $e`
- [L195] `ERROR | rpc: swap_meal_plan_entry | unexpected: $e`
- [L202] `MealPlanSwapNotifier → invalidating activeMealPlanProvider and shoppingListProvider`
- [L225] `ShoppingListNotifier build()`
- [L226] `ShoppingListNotifier disposed`
- [L230] `ShoppingListNotifier EARLY RETURN | reason: no active meal plan`
- [L240, L256] `id, shopping_list_item(id, ingredient_id, quantity, unit, is_checked, ingredient(name, name_fr, category))`
- [L248] `AFTER | table: shopping_list | found existing list with ${itemsData.length} items`
- [L250] `Shopping list not found. Calling generate_shopping_list RPC`
- [L252] `AFTER | rpc: generate_shopping_list | returned ${rpcResult.length} items`
- [L284] `ShoppingListNotifier → data | items: ${items.length}`
- [L287] `ERROR | shopping_list fetch | $e`
- [L288] `ShoppingListNotifier → error | $e`
- [L298] `Toggle shopping item`
- [L323] `AFTER | table: shopping_list_item | op: UPDATE is_checked=$isChecked | id: $id`
- [L325] `ERROR | table: shopping_list_item | op: UPDATE | $e`
- [L349] `MealConsumptionNotifier build()`
- [L350] `MealConsumptionNotifier disposed`
- [L358] `Toggle meal consumption | isConsumed: $isCurrentlyConsumed`
- [L370, L380] `BEFORE | mealPlanEntryId: $mealPlanEntryId`
- [L371] `MealConsumptionNotifier → loading (unconsume)`
- [L376, L396, L639, L756] `AFTER | success`
- [L377] `MealConsumptionNotifier → data (unconsume $mealPlanEntryId)`
- [L381] `MealConsumptionNotifier → loading (consume)`
- [L389] `Meal already consumed`
- [L390] `WARNING | Already consumed. Treating as success.`
- [L397] `MealConsumptionNotifier → data (consume $mealPlanEntryId)`
- [L409] `MealConsumptionNotifier → error | $e`
- [L435] `CookingSessionsNotifier build()`
- [L436] `CookingSessionsNotifier disposed`
- [L440] `CookingSessionsNotifier EARLY RETURN | reason: no active meal plan`
- [L444] `CookingSessionsNotifier | mealPlanId: ${plan.id}`
- [L451] `*, recipe(id, title, cover_image_url), cooking_session_ingredient(*)`
- [L455] `AFTER | table: cooking_session | rows: ${data.length} | mealPlanId: ${plan.id}`
- [L457] `Zero rows | table: cooking_session | mealPlanId: ${plan.id} | possible RLS block`
- [L459] `CookingSessionsNotifier → data | sessions: ${data.length}`
- [L463] `Permission denied | table: cooking_session | mealPlanId: ${plan.id}`
- [L465] `ERROR | table: cooking_session | code: ${e.code}`
- [L467] `CookingSessionsNotifier → error | ${e.message}`
- [L470] `ERROR | table: cooking_session | unexpected: $e`
- [L471] `CookingSessionsNotifier → error | $e`
- [L487] `Create cooking session`
- [L488] `BEFORE | table: cooking_session | op: INSERT | userId: ${user.id} | recipeId: $recipeId`
- [L498] `${plannedDate.year}-${plannedDate.month.toString().padLeft(2, `
- [L498] `)}-${plannedDate.day.toString().padLeft(2, `
- [L502] `AFTER | table: cooking_session | op: INSERT | success`
- [L506] `Permission denied | table: cooking_session | INSERT | userId: ${user.id}`
- [L508] `ERROR | table: cooking_session | INSERT | code: ${e.code}`
- [L512] `ERROR | table: cooking_session | INSERT | unexpected: $e`
- [L521] `Mark cooking session cooked`
- [L535] `BEFORE | table: cooking_session | op: UPDATE is_cooked=$isCooked | sessionId: $sessionId`
- [L544] `AFTER | table: cooking_session | op: UPDATE is_cooked=$isCooked | success`
- [L547] `Permission denied | table: cooking_session | UPDATE | userId: ${user.id}`
- [L549] `ERROR | table: cooking_session | UPDATE | code: ${e.code}`
- [L557] `ERROR | table: cooking_session | UPDATE | unexpected: $e`
- [L610] `PersonalMealSwapNotifier build()`
- [L611] `PersonalMealSwapNotifier disposed`
- [L620] `Analyze personal meal`
- [L624] `BEFORE | hasDescription: ${description != null} | hasImage: ${imageBase64 != null} | mimeType: ${mimeType ?? "none"}`
- [L625] `PersonalMealSwapNotifier → loading (analyze)`
- [L641] `PersonalMealSwapNotifier → data (analyze success)`
- [L645, L686, L690] `PersonalMealSwapNotifier → error | $e`
- [L662] `Save personal meal swap`
- [L663] `BEFORE | rpc: swap_meal_plan_entry_custom | entryId: $entryId`
- [L664] `PersonalMealSwapNotifier → loading (save)`
- [L681] `AFTER | rpc: swap_meal_plan_entry_custom | success`
- [L682] `PersonalMealSwapNotifier → data (save success)`
- [L685] `ERROR | rpc: swap_meal_plan_entry_custom | code: ${e.code}`
- [L689] `ERROR | rpc: swap_meal_plan_entry_custom | unexpected: $e`
- [L696] `PersonalMealSwapNotifier → invalidating activeMealPlanProvider and shoppingListProvider`
- [L718] `RatingNotifier build()`
- [L719] `RatingNotifier disposed`
- [L730] `Submitting rating (Taste: $ratingTaste, Ease: $ratingEase, Satiety: $ratingSatiety, Comment: ${comment != null})`
- [L738] `BEFORE | mealPlanEntryId: $mealPlanEntryId | rating: $rating`
- [L739] `RatingNotifier → loading`
- [L757] `RatingNotifier → data (submitRating success)`
- [L764] `RatingNotifier → error | $e`
- [L784] `SnackEntryNotifier build()`
- [L785] `SnackEntryNotifier disposed`
- [L796] `Add snack entry`
- [L797] `SnackEntryNotifier → loading (addSnack)`
- [L803, L869] `${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, `
- [L803, L869] `)}-${scheduledDate.day.toString().padLeft(2, `
- [L805] `BEFORE | table: meal_plan_entry | op: INSERT | meal_type: snack | mealPlanId: $mealPlanId | date: $dateStr`
- [L819] `AFTER | table: meal_plan_entry | op: INSERT | entryId: $entryId`
- [L821] `BEFORE | table: meal_plan_entry_component | op: INSERT | role: base | recipeId: $recipeId`
- [L828] `AFTER | table: meal_plan_entry_component | op: INSERT | success`
- [L829] `SnackEntryNotifier → data (addSnack success)`
- [L832, L892] `Permission denied | table: meal_plan_entry | INSERT | userId: ${user.id}`
- [L834] `ERROR | table: meal_plan_entry | INSERT | code: ${e.code}`
- [L836, L898] `SnackEntryNotifier → error | ${e.message}`
- [L839] `ERROR | meal_plan_entry INSERT | unexpected: $e`
- [L840, L903] `SnackEntryNotifier → error | $e`
- [L846, L909] `SnackEntryNotifier → invalidating activeMealPlanProvider`
- [L863] `Add custom snack entry`
- [L865] `SnackEntryNotifier → loading (addCustomSnack)`
- [L874] `BEFORE | table: meal_plan_entry | op: INSERT | is_custom_meal: true | date: $dateStr`
- [L888] `AFTER | table: meal_plan_entry | op: INSERT | custom snack success`
- [L889] `SnackEntryNotifier → data (addCustomSnack success)`
- [L895] `ERROR | table: meal_plan_entry | INSERT custom snack | code: ${e.code}`
- [L901] `ERROR | meal_plan_entry INSERT custom snack | unexpected: $e`

## File: `lib/providers/notifications_provider.dart`
- [L18] `notificationsProvider → [] (no user)`
- [L22] `notificationsProvider build() | userId: ${user.id}`
- [L23] `notificationsProvider disposed`
- [L38] `AFTER | table: notification | rows: ${rows.length}`
- [L42] `Zero rows | table: notification | userId: ${user.id} | possible RLS block`
- [L46] `notificationsProvider → data | count: ${rows.length}`
- [L51] `Permission denied | table: notification | userId: ${user.id}`
- [L56] `ERROR | table: notification | code: ${e.code} | ${e.message}`
- [L60] `notificationsProvider → error | ${e.message}`
- [L76] `unreadNotificationCountProvider build() | userId: ${user.id}`
- [L78] `unreadNotificationCountProvider disposed`
- [L93] `AFTER | table: notification | unread count: $count`
- [L95] `unreadNotificationCountProvider → data | count: $count`
- [L99] `ERROR | table: notification | unread count | code: ${e.code}`
- [L103] `unreadNotificationCountProvider → error | ${e.message}`
- [L121] `BEFORE | table: notification | op: UPDATE is_read | userId: ${user.id}`
- [L130] `AFTER | table: notification | op: UPDATE is_read | success`
- [L134] `Permission denied | table: notification | UPDATE | userId: ${user.id}`
- [L139] `ERROR | table: notification | UPDATE is_read | code: ${e.code}`

## File: `lib/providers/notification_prefs_provider.dart`
- [L59] `notificationPrefsLoader → default (no user)`
- [L63] `notificationPrefsLoader build() | userId: ${user.id}`
- [L64] `notificationPrefsLoader disposed`
- [L80] `notificationPrefsLoader → data | $prefs`
- [L85] `Permission denied | table: user_profile | userId: ${user.id}`
- [L90] `ERROR | table: user_profile | notification_prefs | code: ${e.code} | ${e.message}`
- [L107] `NotificationPrefsNotifier init | state: ${initial.toJson()}`
- [L111] `Push notifications toggled: $value`
- [L117] `Chat notifications toggled: $value`
- [L123] `Meal reminders toggled: $value`
- [L129] `DM requests notifications toggled: $value`
- [L135] `NotificationPrefsNotifier.syncFromDb() | ${prefs.toJson()}`
- [L142] `NotificationPrefsNotifier.save() | no user — skipped`
- [L150] `BEFORE | table: user_profile | op: UPDATE notification_prefs | userId: ${user.id}`
- [L158] `AFTER | table: user_profile | op: UPDATE notification_prefs | success`
- [L159] `NotificationPrefsNotifier saved | ${state.toJson()}`
- [L163] `Permission denied | table: user_profile | UPDATE notification_prefs | userId: ${user.id}`
- [L168] `ERROR | table: user_profile | UPDATE notification_prefs | code: ${e.code} | ${e.message}`
- [L182] `wrong build scope`

## File: `lib/providers/nutrition_plan_provider.dart`
- [L13] `activeNutritionPlanProvider build() | null user`
- [L17] `activeNutritionPlanProvider build() | userId: ${user.id}`
- [L18] `activeNutritionPlanProvider disposed`
- [L26] `*, distributions:meal_distribution(*)`
- [L31] `AFTER | table: nutrition_plan | rows: ${response == null ? 0 : 1}`
- [L34] `Zero rows | table: nutrition_plan | userId: ${user.id} | possible RLS block or no active plan`
- [L41] `Permission denied | table: nutrition_plan | userId: ${user.id}`
- [L43, L145] `ERROR | table: nutrition_plan | code: ${e.code} | ${e.message}`
- [L47] `activeNutritionPlanProvider ERROR | $e`
- [L57] `NutritionPlanNotifier build()`
- [L62] `NutritionPlanNotifier → loading`
- [L66] `NutritionPlanNotifier → data | plan_exists: ${plan != null}`
- [L69] `NutritionPlanNotifier → error | $e`
- [L77] `NutritionPlanNotifier savePlan ERROR: No user`
- [L82] `NutritionPlanNotifier savePlan | userId: ${user.id} | targetCal: ${plan.calorieGoal}`
- [L87] `BEFORE | table: nutrition_plan | op: UPDATE (deactivate old)`
- [L95] `BEFORE | table: nutrition_plan | op: INSERT new active plan`
- [L102] `AFTER | table: nutrition_plan | rows: 1`
- [L114] `BEFORE | table: meal_distribution | op: INSERT | count: ${distsToSave.length}`
- [L116] `AFTER | table: meal_distribution | inserted`
- [L119] `BEFORE | table: user_goal | op: UPDATE (deactivate old)`
- [L125] `AFTER | table: user_goal | old rows deactivated`
- [L127] `BEFORE | table: user_goal | op: INSERT`
- [L136] `AFTER | table: user_goal | inserted`
- [L143] `Permission denied saving plan | userId: ${user.id}`
- [L150] `NutritionPlanNotifier savePlan ERROR | $e`

## File: `lib/providers/nutrition_provider.dart`
- [L58, L219, L281] `${today.year}-${today.month.toString().padLeft(2, `
- [L58, L219, L281] `)}-${today.day.toString().padLeft(2, `
- [L60] `todayNutritionProvider build() | userId: ${user.id} | date: $dateStr`
- [L61] `todayNutritionProvider disposed`
- [L72] `AFTER | table: daily_nutrition_log | rows: ${data == null ? 0 : 1} | userId: ${user.id}`
- [L74] `Zero rows | table: daily_nutrition_log | userId: ${user.id} | date: $dateStr | possible RLS block or no log yet`
- [L75] `todayNutritionProvider → data (null)`
- [L78] `todayNutritionProvider → data | calories: ${data[`
- [L82, L124, L355, L469] `Permission denied | table: daily_nutrition_log | userId: ${user.id}`
- [L84, L126, L357, L471] `ERROR | table: daily_nutrition_log | code: ${e.code}`
- [L86] `todayNutritionProvider → error | ${e.message}`
- [L89, L131, L362, L476] `ERROR | table: daily_nutrition_log | unexpected: $e`
- [L90] `todayNutritionProvider → error | $e`
- [L102] `${weekAgo.year}-${weekAgo.month.toString().padLeft(2, `
- [L102] `)}-${weekAgo.day.toString().padLeft(2, `
- [L104] `weeklyNutritionProvider build() | userId: ${user.id} | since: $weekAgoStr`
- [L105] `weeklyNutritionProvider disposed`
- [L116] `AFTER | table: daily_nutrition_log | rows: ${data.length} | userId: ${user.id}`
- [L118] `Zero rows | table: daily_nutrition_log | userId: ${user.id} | weekly range | possible RLS block or no logs`
- [L120] `weeklyNutritionProvider → data | days: ${data.length}`
- [L128] `weeklyNutritionProvider → error | ${e.message}`
- [L132] `weeklyNutritionProvider → error | $e`
- [L165] `weightLogProvider build() | userId: ${user.id}`
- [L166] `weightLogProvider disposed`
- [L177] `AFTER | table: weight_log | rows: ${data.length} | userId: ${user.id}`
- [L181] `weight_log | 0 rows returned — table is empty OR RLS block (both look identical from client)`
- [L184] `weight_log raw row[$i] | ${data[i]}`
- [L187] `weightLogProvider → data | entries: ${entries.length}`
- [L191] `Permission denied | table: weight_log | userId: ${user.id}`
- [L193] `ERROR | table: weight_log | code: ${e.code}`
- [L195] `weightLogProvider → error | ${e.message}`
- [L198] `ERROR | table: weight_log | unexpected: $e`
- [L199] `weightLogProvider → error | $e`
- [L209] `WeightLogNotifier build()`
- [L210] `WeightLogNotifier disposed`
- [L221] `Add weight entry`
- [L222] `BEFORE | table: weight_log | op: UPSERT | userId: ${user.id} | weightKg: $weightKg | date: $dateStr`
- [L223] `WeightLogNotifier → loading (addEntry)`
- [L237] `AFTER | table: weight_log | op: UPSERT | success | userId: ${user.id}`
- [L238] `WeightLogNotifier → data (addEntry success)`
- [L241] `Permission denied | table: weight_log | UPSERT | userId: ${user.id}`
- [L243] `ERROR | table: weight_log | UPSERT | code: ${e.code}`
- [L245] `WeightLogNotifier → error (addEntry)`
- [L248] `ERROR | table: weight_log | UPSERT | unexpected: $e`
- [L249] `WeightLogNotifier → error (addEntry unexpected)`
- [L271] `WaterLogNotifier build()`
- [L272] `WaterLogNotifier disposed`
- [L287] `Add water glass`
- [L288] `BEFORE | table: daily_nutrition_log | op: UPSERT water_ml | userId: ${user.id} | newWaterMl: $newWater`
- [L301] `AFTER | table: daily_nutrition_log | UPSERT water_ml | success | userId: ${user.id}`
- [L304] `Permission denied | table: daily_nutrition_log | UPSERT water_ml | userId: ${user.id}`
- [L306] `ERROR | table: daily_nutrition_log | UPSERT water_ml | code: ${e.code}`
- [L310] `ERROR | table: daily_nutrition_log | UPSERT water_ml | unexpected: $e`
- [L333] `dailyNutritionForDateProvider build() | userId: ${user.id} | date: $dateStr`
- [L334] `dailyNutritionForDateProvider disposed | date: $dateStr`
- [L345] `AFTER | table: daily_nutrition_log | rows: ${data == null ? 0 : 1} | date: $dateStr`
- [L347] `Zero rows | table: daily_nutrition_log | userId: ${user.id} | date: $dateStr | possible RLS block or no log`
- [L348] `dailyNutritionForDateProvider → data (null) | date: $dateStr`
- [L351] `dailyNutritionForDateProvider → data | calories: ${data[`
- [L351] `]} | date: $dateStr`
- [L359] `dailyNutritionForDateProvider → error | date: $dateStr | ${e.message}`
- [L363] `dailyNutritionForDateProvider → error | date: $dateStr | $e`
- [L391] `consumedRecipesForDateProvider build() | userId: ${user.id} | date: $dateStr`
- [L392] `consumedRecipesForDateProvider disposed | date: $dateStr`
- [L399] `recipe_id, consumed_at, scheduled_date, recipe!inner(title, cover_image_url)`
- [L405] `AFTER | table: meal_consumption | rows: ${data.length} | date: $dateStr`
- [L407] `Zero rows | table: meal_consumption | userId: ${user.id} | date: $dateStr | no meals or RLS block`
- [L426] `consumedRecipesForDateProvider → data | distinct recipes: ${results.length} | date: $dateStr`
- [L430] `Permission denied | table: meal_consumption | userId: ${user.id}`
- [L432] `ERROR | table: meal_consumption | code: ${e.code}`
- [L434] `consumedRecipesForDateProvider → error | date: $dateStr | ${e.message}`
- [L437] `ERROR | table: meal_consumption | unexpected: $e`
- [L438] `consumedRecipesForDateProvider → error | date: $dateStr | $e`
- [L448] `weeklyNutritionForRangeProvider build() | userId: ${user.id} | since: ${range.since} | until: ${range.until}`
- [L449] `weeklyNutritionForRangeProvider disposed | since: ${range.since}`
- [L461] `AFTER | table: daily_nutrition_log | rows: ${data.length} | since: ${range.since} | until: ${range.until}`
- [L463] `Zero rows | table: daily_nutrition_log | userId: ${user.id} | range ${range.since}–${range.until} | possible RLS block or no logs`
- [L465] `weeklyNutritionForRangeProvider → data | days: ${data.length}`
- [L473] `weeklyNutritionForRangeProvider → error | ${e.message}`
- [L477] `weeklyNutritionForRangeProvider → error | $e`

## File: `lib/providers/profile_tabs_provider.dart`
- [L12] `userSavedRecipesProvider build() | userId: $userId`
- [L26] `*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g)`
- [L35] `userCommentsProvider build() | userId: $userId`
- [L39] `*, recipe(title, cover_image_url)`
- [L48] `userGroupsProvider build() | userId: $userId`

## File: `lib/providers/push_token_provider.dart`
- [L17] `pushTokenProvider | User logged in. Setting up FCM.`
- [L39] `FCM Permission status: ${settings.authorizationStatus}`
- [L49] `Error getting FCM token: $e`
- [L56] `Upserting FCM token for user $userId`
- [L63] `FCM token upsert successful`
- [L65] `Failed to upsert FCM token: $e`

## File: `lib/providers/recipe_comment_provider.dart`
- [L19] `Fetching comments for recipe: $recipeId`
- [L23] `*, user_profile(username, first_name, last_name, avatar_url)`
- [L33, L34] `Failed to fetch comments`
- [L39] `Posting comment on recipe: $recipeId`
- [L43, L44] `User must be logged in to post a comment`
- [L48] `s just wait for DB\n      await ref.read(supabaseClientProvider).from(`
- [L49] `).insert({\n        `
- [L50] `: recipeId,\n        `
- [L51] `: userId,\n        `
- [L64] `, error: e, stackTrace: st);\n      throw Exception(`

## File: `lib/providers/recipe_provider.dart`
- [L59] `feedProvider build() | userId: ${user?.id ?? "null"} | region: ${params.regionId} | difficulty: ${params.difficulty} | orderBy: ${params.orderBy} | mealType: ${params.mealType}`
- [L60] `feedProvider disposed`
- [L63] `feedProvider EARLY RETURN | reason: no authenticated user`
- [L83] `BEFORE rpc | fn: generate_feed_personalized | userId: ${user.id} | params: $rpcParams`
- [L90] `AFTER rpc | fn: generate_feed_personalized | rows: ${rpcData.length}`
- [L94] `Zero rows | rpc: generate_feed_personalized | userId: ${user.id} | possible RLS or empty feed`
- [L108, L258, L376] `*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), recipe_save!left(recipe_id), recipe_like!left(recipe_id)`
- [L110] `AFTER | table: recipe | rows: ${recipeData.length}`
- [L114] `Zero rows | table: recipe | possible RLS block | userId: ${user.id}`
- [L127] `feedProvider → data | recipes: ${recipes.length}`
- [L132] `Permission denied | rpc: generate_feed_personalized | userId: ${user.id}`
- [L137] `ERROR rpc | fn: generate_feed_personalized | code: ${e.code} | ${e.message}`
- [L141] `feedProvider → error | ${e.message}`
- [L144] `ERROR rpc | unexpected: $e`
- [L145] `feedProvider → error | $e`
- [L156] `recipeDetailProvider build() | recipeId: $id`
- [L157] `recipeDetailProvider disposed | recipeId: $id`
- [L165] `*, recipe_macro(calories, protein_g, carbs_g, fat_g, fiber_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), ingredients:recipe_ingredient(id, ingredient_id, ingredient:ingredient_id(name_fr, name), quantity, unit, is_optional, sort_order, is_section_header, title), steps:recipe_step(step_number, content, image_url, timer_seconds, sort_order, ingredient_ids, is_section_header, title), recipe_save!left(recipe_id), recipe_like!left(recipe_id)`
- [L170] `AFTER | table: recipe | rows: 0 | recipeId: $id | not found`
- [L171] `Zero rows | table: recipe | recipeId: $id | possible RLS block`
- [L172] `recipeDetailProvider → data (null)`
- [L176] `AFTER | table: recipe | rows: 1 | recipeId: $id`
- [L178] `recipeDetailProvider → data | title: ${recipe.title}`
- [L182] `Permission denied | table: recipe | recipeId: $id`
- [L184] `ERROR | table: recipe | recipeId: $id | code: ${e.code}`
- [L186] `recipeDetailProvider → error | ${e.message}`
- [L189] `ERROR | table: recipe | recipeId: $id | unexpected: $e`
- [L190] `recipeDetailProvider → error | $e`
- [L244] `searchRecipesProvider build() | query: "${params.query}" | region: ${params.regionId} | difficulty: ${params.difficulty} | maxTime: ${params.maxTimeMin} | orderBy: ${params.orderBy}`
- [L245] `searchRecipesProvider disposed | query: "${params.query}"`
- [L249] `searchRecipesProvider EARLY RETURN | reason: query too short (${params.query.length} chars)`
- [L279] `AFTER | table: recipe | rows: ${data.length} | query: "${params.query}"`
- [L283] `Zero rows | table: recipe | search query: "${params.query}" | possible RLS block or no matches`
- [L285] `searchRecipesProvider → data (empty) | no results for "${params.query}"`
- [L289] `searchRecipesProvider → data | recipes: ${recipes.length}`
- [L293] `Permission denied | table: recipe | search query`
- [L295] `ERROR | table: recipe | search | code: ${e.code}`
- [L297] `searchRecipesProvider → error | ${e.message}`
- [L309] `chatRecipePickerProvider build() | query: "$query"`
- [L310] `chatRecipePickerProvider disposed`
- [L313] `id, creator_id, title, cover_image_url, recipe_macro(calories, protein_g, carbs_g, fat_g, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g), like_count, average_rating, is_published, created_at`
- [L315] `BEFORE | table: recipe | chatRecipePicker | query: "$query"`
- [L331] `AFTER | table: recipe | chatRecipePicker | rows: ${data.length}`
- [L334] `ERROR | table: recipe | chatRecipePicker | code: ${e.code}`
- [L345] `userRecipesProvider build() | userId: $userId`
- [L346] `userRecipesProvider disposed | userId: $userId`
- [L349] `userRecipesProvider EARLY RETURN | reason: empty userId`
- [L364] `Zero rows | table: creator | user_id: $userId | not a creator or RLS block`
- [L365] `userRecipesProvider → data (empty) | no creator profile`
- [L369] `AFTER | table: creator | creatorId: $creatorId`
- [L381] `AFTER | table: recipe | rows: ${data.length} | creator_id: $creatorId`
- [L384] `Zero rows | table: recipe | creator_id: $creatorId | possible RLS block or no recipes`
- [L388] `userRecipesProvider → data | recipes: ${recipes.length}`
- [L392] `Permission denied | table: recipe | creator_id: $userId`
- [L394] `ERROR | table: recipe | creator_id: $userId | code: ${e.code} | ${e.message}`
- [L397] `userRecipesProvider → error | ${e.message}`
- [L400] `ERROR | table: recipe | creator_id: $userId | unexpected: $e`
- [L401] `userRecipesProvider → error | $e`
- [L419] `RecipeSaveNotifier build()`
- [L420] `RecipeSaveNotifier disposed`
- [L425] `Recipe save toggle`
- [L426] `RecipeSaveNotifier → loading (toggle)`
- [L431] `BEFORE | recipeId: $recipeId | newSaved: $newSaved`
- [L439] `AFTER | success | recipeId: $recipeId | saved: $newSaved`
- [L440] `RecipeSaveNotifier → data | saved: $newSaved`
- [L449, L500] `ERROR | recipeId: $recipeId | $e`
- [L450] `RecipeSaveNotifier → error | $e`
- [L471] `RecipeLikeNotifier build()`
- [L472] `RecipeLikeNotifier disposed`
- [L477] `Recipe like toggle`
- [L478] `RecipeLikeNotifier → loading (toggle)`
- [L483] `BEFORE | recipeId: $recipeId | newLiked: $newLiked`
- [L491] `AFTER | success | recipeId: $recipeId | liked: $newLiked`
- [L492] `RecipeLikeNotifier → data | liked: $newLiked`
- [L501] `RecipeLikeNotifier → error | $e`

## File: `lib/providers/search_allergen_provider.dart`
- [L21] `search_allergens | query: $query`
- [L28] `ERROR | search_allergens`

## File: `lib/providers/user_allergy_provider.dart`
- [L19] `BEFORE | user_allergy joined with allergen | userId: ${user.id}`
- [L23] `allergen:allergen_id ( id, slug, label )`
- [L26] `AFTER | user_allergy | loaded ${res.length} rows`
- [L33] `ERROR | user_allergy`
- [L43] `addAllergy | allergenId: $allergenId`
- [L52] `ERROR | addAllergy`
- [L61] `removeAllergy | allergenId: $allergenId`
- [L73] `ERROR | removeAllergy`

## File: `lib/providers/user_preferences_provider.dart`
- [L20] `UserPreferencesNotifier build() | userId: ${user.id}`
- [L21] `UserPreferencesNotifier disposed`
- [L36] `batch_cooking_enabled, batch_cooking_max_portions`
- [L54] `allergen:allergen_id ( id, slug, label_fr, label_en )`
- [L79] `AFTER | tables: user_health_profile,user_profile,user_cuisine_preference,user_dietary_restriction,user_allergy | userId: ${user.id}`
- [L80] `UserPreferencesNotifier → data | userId: ${user.id}`
- [L95] `Permission denied | UserPreferencesNotifier | userId: ${user.id}`
- [L97] `ERROR | UserPreferencesNotifier | code: ${e.code}`
- [L99] `UserPreferencesNotifier → error | ${e.message}`
- [L102] `ERROR | UserPreferencesNotifier | unexpected: $e`
- [L103] `UserPreferencesNotifier → error | $e`
- [L112] `UserPreferences save`
- [L123] `BEFORE | table: user_health_profile | op: UPSERT | userId: ${user.id}`
- [L128] `AFTER | table: user_health_profile | op: UPSERT | rows: 1`
- [L130] `BEFORE | table: user_profile | op: UPDATE | userId: ${user.id}`
- [L135] `AFTER | table: user_profile | op: UPDATE | rows: 1`
- [L137] `BEFORE | table: user_cuisine_preference | op: DELETE | userId: ${user.id}`
- [L139] `AFTER | table: user_cuisine_preference | op: DELETE`
- [L142] `BEFORE | table: user_cuisine_preference | op: INSERT | userId: ${user.id}`
- [L148] `AFTER | table: user_cuisine_preference | op: INSERT | rows: 1`
- [L151] `BEFORE | table: user_dietary_restriction | op: DELETE | userId: ${user.id}`
- [L153] `AFTER | table: user_dietary_restriction | op: DELETE`
- [L162] `BEFORE | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}`
- [L166] `AFTER | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}`
- [L169] `BEFORE | table: user_allergy | op: DELETE | userId: ${user.id}`
- [L171] `AFTER | table: user_allergy | op: DELETE`
- [L174] `BEFORE | table: user_allergy | op: INSERT | rows: ${updated.allergens.length}`
- [L178] `AFTER | table: user_allergy | op: INSERT | rows: ${updated.allergens.length}`
- [L181] `UserPreferencesNotifier → save success`
- [L186] `Permission denied | UserPreferencesNotifier save | userId: ${user.id}`
- [L188] `ERROR | UserPreferencesNotifier save | code: ${e.code}`
- [L190] `UserPreferencesNotifier → error (save)`
- [L194] `ERROR | UserPreferencesNotifier save | unexpected: $e`
- [L195] `UserPreferencesNotifier → error (save unexpected)`

## File: `lib/providers/user_profile_provider.dart`
- [L18] `userProfileProvider build() | userId: ${user.id}`
- [L19] `userProfileProvider disposed`
- [L30, L155] `AFTER | table: user_profile | rows: 0 | userId: ${user.id}`
- [L31, L156] `Zero rows | table: user_profile | userId: ${user.id} | possible RLS block`
- [L32] `userProfileProvider → data (null)`
- [L35, L160] `AFTER | table: user_profile | rows: 1 | userId: ${user.id}`
- [L36] `userProfileProvider → data | userId: ${user.id}`
- [L40, L165] `Permission denied | table: user_profile | userId: ${user.id}`
- [L42] `ERROR | table: user_profile | code: ${e.code}`
- [L44] `userProfileProvider → error | ${e.message}`
- [L47] `ERROR | table: user_profile | unexpected: $e`
- [L48] `userProfileProvider → error | $e`
- [L53] `s public profile — used when viewing someone else`
- [L56] `publicUserProfileProvider build() | userId: $userId`
- [L57] `publicUserProfileProvider disposed | userId: $userId`
- [L65] `id, first_name, last_name, username, avatar_url, bio, is_private, is_creator, created_at`
- [L69] `AFTER | table: user_profile | rows: ${data == null ? 0 : 1}`
- [L71] `Zero rows | table: user_profile | userId: $userId | possible RLS block`
- [L74] `publicUserProfileProvider → data | userId: $userId`
- [L82] `Permission denied | table: user_profile | userId: $userId`
- [L84] `ERROR | table: user_profile | code: ${e.code} | ${e.message}`
- [L86] `publicUserProfileProvider → error | ${e.message}`
- [L96] `healthProfileProvider build() | userId: ${user.id}`
- [L97] `healthProfileProvider disposed`
- [L108] `AFTER | table: user_health_profile | rows: 0 | userId: ${user.id}`
- [L109] `Zero rows | table: user_health_profile | userId: ${user.id} | possible RLS block`
- [L110] `healthProfileProvider → data (null)`
- [L113] `AFTER | table: user_health_profile | rows: 1 | userId: ${user.id}`
- [L114] `healthProfileProvider → data | userId: ${user.id}`
- [L118] `Permission denied | table: user_health_profile | userId: ${user.id}`
- [L120] `ERROR | table: user_health_profile | code: ${e.code}`
- [L122] `healthProfileProvider → error | ${e.message}`
- [L125] `ERROR | table: user_health_profile | unexpected: $e`
- [L126] `healthProfileProvider → error | $e`
- [L143] `UserProfileNotifier build() | userId: ${user.id}`
- [L144] `UserProfileNotifier disposed`
- [L157] `UserProfileNotifier → data (null)`
- [L161] `UserProfileNotifier → data | userId: ${user.id}`
- [L167] `ERROR | table: user_profile | build | code: ${e.code}`
- [L169] `UserProfileNotifier → error | ${e.message}`
- [L172] `ERROR | table: user_profile | build | unexpected: $e`
- [L173] `UserProfileNotifier → error | $e`
- [L200] `BEFORE | table: user_profile | op: UPDATE | userId: ${user.id} | fields: ${updates.keys.toList()}`
- [L201] `UserProfileNotifier → loading (updateProfile)`
- [L213] `AFTER | table: user_profile | op: UPDATE | rows: 1 | userId: ${user.id}`
- [L214] `UserProfileNotifier → data (updateProfile success)`
- [L218] `Permission denied | table: user_profile | UPDATE | userId: ${user.id}`
- [L220] `ERROR | table: user_profile | UPDATE | code: ${e.code}`
- [L222] `UserProfileNotifier → error (updateProfile)`
- [L225] `ERROR | table: user_profile | UPDATE | unexpected: $e`
- [L226] `UserProfileNotifier → error (updateProfile unexpected)`
- [L237] `UserProfileNotifier → loading (updateAvatar)`
- [L246] `BEFORE | storage: avatars | op: UPLOAD | path: $path`
- [L248] `AFTER | storage: avatars | op: UPLOAD | success`
- [L258] `AFTER | table: user_profile | op: UPDATE | avatar_url`
- [L262] `ERROR | storage: avatars | UPLOAD | code: ${e.statusCode}`
- [L263, L267] `UserProfileNotifier → error (updateAvatar)`
- [L266] `ERROR | updateAvatar | unexpected: $e`
- [L287] `subscriptionProvider build() | userId: ${user.id}`
- [L288] `subscriptionProvider disposed`
- [L298] `AFTER | table: subscription | rows: ${data == null ? 0 : 1} | userId: ${user.id}`
- [L300] `Zero rows | table: subscription | userId: ${user.id} | possible RLS block`
- [L302] `subscriptionProvider → data | status: ${data?[`
- [L302] `] ?? "none"}`
- [L306] `Permission denied | table: subscription | userId: ${user.id}`
- [L308] `ERROR | table: subscription | code: ${e.code}`
- [L310] `subscriptionProvider → error | ${e.message}`
- [L313] `ERROR | table: subscription | unexpected: $e`
- [L314] `subscriptionProvider → error | $e`
- [L320] `isPremiumProvider evaluated`
- [L326] `isPremiumProvider → isPremium: $isPremium`

## File: `lib/providers/_examples/auth_provider_logged.dart`
- [L11, L12, L13, L14] `;\nimport `
- [L68] `] as String,\n      email: json[`
- [L69] `] as String,\n      displayName: json[`
- [L94] `);\n    \n    try {\n      final supabase = Supabase.instance.client;\n      final session = supabase.auth.currentSession;\n      \n      if (session == null) {\n        _logger.auth(`
- [L101] `);\n        return const AuthState.initial();\n      }\n      \n      _logger.auth(`
- [L110] `);\n      \n      return AuthState(\n        user: session.user,\n        profile: profile,\n      );\n    } catch (e, st) {\n      _logger.auth(`
- [L130, L179] `);\n    \n    state = const AsyncValue.data(\n      AuthState(isLoading: true),\n    );\n    \n    return state = await AsyncValue.guard(() async {\n      try {\n        final supabase = Supabase.instance.client;\n        \n        _logger.debug(`
- [L140] `);\n        final response = await supabase.auth.signInWithPassword(\n          email: email,\n          password: password,\n        );\n        \n        if (response.user == null) {\n          _logger.auth(`
- [L147, L199] `);\n          throw Exception(`
- [L148, L200] `);\n        }\n        \n        _logger.auth(`
- [L156, L211] `);\n        \n        return AuthState(\n          user: response.user,\n          profile: profile,\n        );\n      } on AuthException catch (e, st) {\n        _logger.auth(`
- [L163, L218] `, error: e, stackTrace: st);\n        rethrow;\n      } catch (e, st) {\n        _logger.auth(`
- [L189] `);\n        final response = await supabase.auth.signUp(\n          email: email,\n          password: password,\n          data: {\n            if (displayName != null) `
- [L194] `: displayName,\n          },\n        );\n        \n        if (response.user == null) {\n          _logger.auth(`
- [L229] `);\n    \n    state = const AsyncValue.data(\n      AuthState(isLoading: true),\n    );\n    \n    await AsyncValue.guard(() async {\n      try {\n        final supabase = Supabase.instance.client;\n        \n        _logger.debug(`
- [L239] `);\n        await supabase.auth.signOut();\n        \n        _logger.auth(`
- [L242] `);\n        \n        state = const AsyncValue.data(AuthState.initial());\n      } catch (e, st) {\n        _logger.auth(`
- [L255] `);\n    \n    try {\n      final supabase = Supabase.instance.client;\n      \n      final response = await supabase\n          .from(`
- [L261] `)\n          .select(`
- [L262] `)\n          .eq(`
- [L263] `, userId)\n          .single();\n      \n      final profile = UserProfile.fromJson(response);\n      \n      _logger.db(`
- [L268] `);\n      \n      return profile;\n    } catch (e, st) {\n      _logger.db(`
- [L283] `);\n    \n    try {\n      final supabase = Supabase.instance.client;\n      \n      final response = await supabase.from(`
- [L288] `).insert({\n        `
- [L289] `: userId,\n        `
- [L290] `: email,\n        `
- [L291] `: displayName,\n      }).select().single();\n      \n      _logger.db(`
- [L294] `);\n    } catch (e, st) {\n      _logger.db(`

## File: `lib/providers/_examples/recipe_provider_logged.dart`
- [L94] `RecipeFeedNotifier initialized`
- [L97] `RecipeFeedNotifier disposed`
- [L103] `RecipeFeedNotifier detected auth change, invalidating`
- [L116] `Fetching recipes | userId: ${userId ?? "anonymous"} | offset: $offset | limit: $_pageSize`
- [L134] `\n            id,\n            title,\n            description,\n            creator_id,\n            image_url,\n            created_at,\n            like_count\n          `
- [L150] `Recipe query returned 0 rows for offset 0. Possible RLS policy blocking.`
- [L153] `Check RLS policies on "recipe" table for auth_uid() match or creator visibility`
- [L157] `Retrieved ${response.length} recipes | hasMore: ${response.length >= _pageSize}`
- [L171] `Permission denied on recipe query | userId: $userId | code: ${e.code}`
- [L177] `Query failed on recipe | code: ${e.code} | message: ${e.message}`
- [L185] `Unexpected error fetching recipes: $e`
- [L196] `RecipeFeedNotifier loadMore skipped | hasValue: ${state.hasValue} | hasMore: ${state.value?.hasMore} | isLoading: ${state.isLoading}`
- [L200] `RecipeFeedNotifier loadMore triggered`
- [L217] `Failed to load more recipes: $e`
- [L228] `RecipeFeedNotifier refresh triggered`
- [L235] `RecipeFeedNotifier refresh successful | loaded ${newState.recipes.length} recipes`
- [L238] `Failed to refresh recipes: $e`
- [L249] `Cannot toggle like: No authenticated user`
- [L253] `Toggling like on recipe | recipeId: $recipeId | userId: $userId`
- [L299] `Removing like | recipeId: $recipeId`
- [L309] `Permission denied on unlike | recipeId: $recipeId`
- [L311] `Unlike failed | recipeId: $recipeId | error: ${error.message}`
- [L316] `Recipe unliked successfully | recipeId: $recipeId`
- [L319] `Adding like | recipeId: $recipeId`
- [L330] `Permission denied on like | recipeId: $recipeId`
- [L332] `Like failed | recipeId: $recipeId | error: ${error.message}`
- [L337] `Recipe liked successfully | recipeId: $recipeId`
- [L343] `Failed to toggle like on recipe $recipeId: $e`

## File: `lib/shared/mocks/mock_meal_plan.dart`
- [L41] `Bol d'Avoine Protéiné`
- [L48] `Salade de Quinoa Mediterranéenne`
- [L55] `Poulet Grillé et Patates Douces`
- [L62] `Smoothie Vert Détox`

## File: `lib/shared/mock_data.dart`
- [L15] `Passionnée de cuisine traditionnelle sénégalaise et de nutrition équilibrée.`
- [L39] `Chef Oumar`
- [L41] `Expert en gastronomie ouest-africaine moderne.`
- [L52] `Mamina Cuisine`
- [L54] `Les secrets de la cuisine traditionnelle du Cameroun.`
- [L69, L169] `Thieboudienne Rouge`
- [L70] `Le plat national du Sénégal, riche en saveurs et en couleurs.`
- [L94, L214] `Riz brisé`
- [L95] `Mérou (Thiof)`
- [L96] `Concentré de tomate`
- [L99] `Préparer la farce (rof) avec du persil, piment, sel et ail.`
- [L100] `Faire dorer le poisson et réserver.`
- [L108, L195] `Ndolé Camerounais`
- [L109] `Un plat mythique à base de feuilles de ndolé et de crevettes.`
- [L133, L232] `Feuilles de Ndolé`
- [L134] `Arachides blanches`
- [L138] `Laver et hacher les feuilles de ndolé.`
- [L139] `Écraser les arachides et cuire la pâte.`
- [L223] `Poisson Mérou`
- [L280] `Poids du matin`
- [L286] `Après séance sport`
- [L292] `Début de semaine`

## File: `lib/shared/models/ingredient_detail.dart`
- [L31] `IngredientDetail.fromJson | id: ${json[`

## File: `lib/shared/models/journey_stats.dart`
- [L17] `JourneyCalendarDay.fromJson | date: ${json[`
- [L65] `JourneyStats.fromJson | keys: ${json.keys.toList()}`

## File: `lib/shared/models/recipe.dart`
- [L91] `Recipe.fromJson | id: ${json[`

## File: `lib/shared/models/recipe_comment.dart`
- [L45] `$firstName $lastName`

## File: `lib/shared/models/user_preferences.dart`
- [L42] `UserPreferencesModel.copyWith | batchEnabled: ${batchCookingEnabled ?? this.batchCookingEnabled}`

## File: `lib/shared/models/user_profile.dart`
- [L40] `$firstName ${lastName ?? `

## File: `lib/shared/widgets/akeli_glass_header.dart`
- [L5] `Organic Editorial`
- [L80] `Plus Jakarta Sans`

## File: `lib/shared/widgets/akeli_weight_stepper.dart`
- [L39] `Weight stepper −`
- [L73] `Weight stepper +`

## File: `lib/shared/widgets/chat_bubble.dart`
- [L34] `AkeliChatBubble build() | type: $messageType`
- [L213] `Recipe share tapped`

## File: `lib/shared/widgets/creator_card.dart`
- [L24] `CreatorCard tapped`

## File: `lib/shared/widgets/empty_state.dart`
- [L93] `Une erreur est survenue`

## File: `lib/shared/widgets/meal_card.dart`
- [L7] `Vos repas du jour`

## File: `lib/shared/widgets/recipe_video_card.dart`
- [L35] `RecipeVideoCard initState() | videoUrl: ${widget.videoUrl}`
- [L56] `RecipeVideoCard → initialized`
- [L62] `RecipeVideoCard → error | init failed | ${widget.videoUrl}`
- [L71] `Recipe video playing`
- [L78] `RecipeVideoCard disposed`
- [L87] `RecipeVideoCard build()`

## File: `lib/_annotation_template.dart`
- [L47, L48] `;\nimport `
- [L119] `);\n\n    final recipeState = ref.watch(recipeDetailProvider(recipeId));\n    logger.d(`
- [L122] `);\n\n    return Scaffold(\n      appBar: AppBar(\n        title: const Text(`
- [L126] `),\n        actions: [\n          _buildShareButton(context, ref),\n          _buildSaveButton(ref),\n        ],\n      ),\n      body: recipeState.when(\n        loading: () {\n          logger.d(`
- [L134] `);\n          return const Center(child: CircularProgressIndicator());\n        },\n        error: (error, st) {\n          logger.e(`
- [L138] `, error: error, stackTrace: st);\n          return _buildErrorView(error);\n        },\n        data: (recipe) {\n          logger.d(`
- [L174] `);\n\n        return IconButton(\n          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),\n          onPressed: () {\n            appLogger.i(`
- [L179] `);\n            ref.read(recipeSavedProvider(recipeId).notifier).toggle();\n          },\n        );\n      },\n    );\n  }\n\n  Widget _buildErrorView(dynamic error) {\n    return Center(\n      child: Column(\n        mainAxisAlignment: MainAxisAlignment.center,\n        children: [\n          const Icon(Icons.error_outline, size: 48, color: Colors.red),\n          const SizedBox(height: 16),\n          Text(`
- [L226] `);\n\n  ref.onDispose(() {\n    logger.d(`
- [L247] `, params: {`
- [L254] `);\n    return recipe;\n  } catch (e, st) {\n    logger.e(`
- [L283] `🎯 UI: RecipeStepsList.build() | stepCount: ${steps.length} | evaluating render`
- [L286] `🎯 UI: RecipeStepsList rendering empty state | reason: no steps`
- [L290] `🎯 UI: RecipeStepsList rendering steps | reason: ${steps.length} steps available`

