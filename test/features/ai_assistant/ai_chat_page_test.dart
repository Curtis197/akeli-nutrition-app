import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/features/ai_assistant/ai_chat_page.dart';
import 'package:akeli/core/supabase_client.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/l10n/app_localizations.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockFunctionsClient extends Mock implements FunctionsClient {}

class FakeBeautyModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.beauty;
}

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.functions).thenReturn(mockFunctions);
    when(() => mockFunctions.invoke(any(), body: any(named: 'body')))
        .thenAnswer((_) async => FunctionResponse(
              data: {'conversation_id': 'conv-1', 'response': 'Bonjour !'},
              status: 200,
            ));
  });

  testWidgets(
      'AiChatPage sends mode: beauty in the invoked function body when appMode is Beauty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
          supabaseClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: AiChatPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.tap(find.byIcon(Icons.send));
    // Bounded pumps instead of pumpAndSettle(): the typing-indicator dots
    // use repeating AnimationControllers while a message is in flight,
    // which would make pumpAndSettle() time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final captured = verify(() =>
            mockFunctions.invoke('ai-assistant-chat', body: captureAny(named: 'body')))
        .captured;
    expect(captured.single, isA<Map<String, dynamic>>().having((m) => m['mode'], 'mode', 'beauty'));
  });
}
