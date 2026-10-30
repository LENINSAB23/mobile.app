import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/chat_message.dart';
import 'package:mobile_app/models/conversation.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/screens/gemini_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Models Test', () {
    test('ConversationModel fromJson and toJson', () {
      final json = {
        'id': 10,
        'title': 'Consulta de Pastillas',
        'created_at': '2026-10-17T12:00:00Z',
        'updated_at': '2026-10-17T12:05:00Z',
        'messages_count': 4,
        'latest_message': {
          'content': 'Tenemos pastillas cerámicas.',
        },
      };

      final conv = ConversationModel.fromJson(json);

      expect(conv.id, 10);
      expect(conv.title, 'Consulta de Pastillas');
      expect(conv.messagesCount, 4);
      expect(conv.lastMessage, 'Tenemos pastillas cerámicas.');
      expect(conv.createdAt, isNotNull);

      final map = conv.toJson();
      expect(map['id'], 10);
      expect(map['title'], 'Consulta de Pastillas');
    });

    test('ChatMessageModel user and model roles', () {
      final userMsgJson = {
        'id': 1,
        'conversation_id': 10,
        'role': 'user',
        'content': '¿Tienen aceite Motul 7100?',
        'created_at': '2026-10-17T12:00:00Z',
      };

      final userMsg = ChatMessageModel.fromJson(userMsgJson);
      expect(userMsg.isUser, isTrue);
      expect(userMsg.role, 'user');
      expect(userMsg.content, '¿Tienen aceite Motul 7100?');

      final botMsgJson = {
        'id': 2,
        'conversation_id': 10,
        'role': 'model',
        'content': 'Sí, disponemos de Motul 7100 10W40 sintético.',
        'created_at': '2026-10-17T12:00:05Z',
      };

      final botMsg = ChatMessageModel.fromJson(botMsgJson);
      expect(botMsg.isUser, isFalse);
      expect(botMsg.role, 'model');
      expect(botMsg.content, 'Sí, disponemos de Motul 7100 10W40 sintético.');
    });
  });

  group('GeminiChatScreen Widget Test', () {
    testWidgets('renders GeminiChatScreen title and input bar', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake-token-test',
        'user_id': 1,
        'user_name': 'Cliente Test',
        'user_role': 'customer',
      });

      final authProvider = AuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const MaterialApp(
            home: GeminiChatScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Rino AI'), findsOneWidget);
      expect(find.text('• Gemini'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_comment_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });
  });
}
