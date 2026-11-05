import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../services/chat_api_service.dart';

class GeminiChatScreen extends StatefulWidget {
  final int? initialConversationId;

  const GeminiChatScreen({super.key, this.initialConversationId});

  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ConversationModel> _conversations = [];
  ConversationModel? _currentConversation;
  List<ChatMessageModel> _messages = [];

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;

  final List<String> _quickPrompts = [
    '¿Qué aceite recomiendan para moto 150cc/200cc?',
    '¿Tienen pastillas de freno y discos en stock?',
    '¿Qué batería me recomiendan y cuál es su garantía?',
    '¿Cómo rastreo mi pedido por GPS en tiempo real?',
    '¿Cómo saber la compatibilidad de una bujía NGK?',
    '¿Hacen envíos rápidos a todo Huánuco?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getToken() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.user?.token ?? '';
  }

  Future<void> _initChat() async {
    final token = _getToken();
    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Inicia sesión para usar el Asistente Gemini AI con historial.';
      });
      return;
    }

    await _loadConversations(autoSelectId: widget.initialConversationId);
  }

  Future<void> _loadConversations({int? autoSelectId}) async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() {
      _isLoadingConversations = true;
      _errorMessage = null;
    });

    try {
      final list = await ChatApiService.getConversations(token);
      if (!mounted) return;

      setState(() {
        _conversations = list;
        _isLoadingConversations = false;
      });

      if (autoSelectId != null) {
        final match = list.where((c) => c.id == autoSelectId).firstOrNull;
        if (match != null) {
          _selectConversation(match);
          return;
        }
      }

      if (_currentConversation == null) {
        if (list.isNotEmpty) {
          _selectConversation(list.first);
        } else {
          _startNewConversation(silently: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _selectConversation(ConversationModel conv) async {
    setState(() {
      _currentConversation = conv;
      _isLoadingMessages = true;
      _errorMessage = null;
    });

    final token = _getToken();
    try {
      final msgs = await ChatApiService.getMessages(token, conv.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _isLoadingMessages = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _startNewConversation({bool silently = false}) async {
    final token = _getToken();
    if (token.isEmpty) return;

    if (!silently) {
      setState(() {
        _isLoadingMessages = true;
        _errorMessage = null;
      });
    }

    try {
      final newConv = await ChatApiService.createConversation(token);
      if (!mounted) return;
      setState(() {
        _currentConversation = newConv;
        _conversations.insert(0, newConv);
        _messages = [];
        _isLoadingMessages = false;
      });

      if (!silently) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nueva conversación iniciada'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF2563EB),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMessages = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _deleteConversation(ConversationModel conv) async {
    final token = _getToken();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('Eliminar conversación', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          '¿Estás seguro de eliminar "${conv.title}"?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ChatApiService.deleteConversation(token, conv.id);
      if (!mounted) return;

      setState(() {
        _conversations.removeWhere((c) => c.id == conv.id);
        if (_currentConversation?.id == conv.id) {
          if (_conversations.isNotEmpty) {
            _selectConversation(_conversations.first);
          } else {
            _startNewConversation(silently: true);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage([String? predefinedText]) async {
    final text = (predefinedText ?? _textController.text).trim();
    if (text.isEmpty || _isSending) return;

    final token = _getToken();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para chatear.')),
      );
      return;
    }

    // Ensure we have a conversation
    if (_currentConversation == null) {
      await _startNewConversation(silently: true);
      if (_currentConversation == null) return;
    }

    _textController.clear();

    final userMessage = ChatMessageModel(
      role: 'user',
      content: text,
      conversationId: _currentConversation!.id,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _errorMessage = null;
    });

    _scrollToBottom();

    try {
      final res = await ChatApiService.sendMessage(
        token,
        _currentConversation!.id,
        text,
      );

      final replyText = res['respuesta'] ?? '';
      final botMessage = res['bot_message'] as ChatMessageModel? ??
          ChatMessageModel(
            role: 'model',
            content: replyText,
            conversationId: _currentConversation!.id,
            createdAt: DateTime.now(),
          );

      if (!mounted) return;

      setState(() {
        _messages.add(botMessage);
        _isSending = false;
      });

      // Refresh conversations list in background to update title and order
      _loadConversationsSilently();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isSending = false;
        _errorMessage = err;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $err'),
          backgroundColor: Colors.redAccent,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _handleSendMessage(text),
          ),
        ),
      );
    }
  }

  Future<void> _loadConversationsSilently() async {
    final token = _getToken();
    if (token.isEmpty) return;
    try {
      final list = await ChatApiService.getConversations(token);
      if (!mounted) return;
      setState(() {
        _conversations = list;
        if (_currentConversation != null) {
          final updated = list.where((c) => c.id == _currentConversation!.id).firstOrNull;
          if (updated != null) {
            _currentConversation = updated;
          }
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle = _currentConversation?.title ?? 'Nuevo Chat';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Image.asset('assets/images/logo_white.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Rino AI',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '• Gemini',
                        style: TextStyle(fontSize: 11, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    currentTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nuevo Chat',
            icon: const Icon(Icons.add_comment_rounded, color: Colors.lightBlueAccent),
            onPressed: () => _startNewConversation(),
          ),
          IconButton(
            tooltip: 'Historial de Conversaciones',
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildConversationsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            if (_errorMessage != null && !_isSending) _buildErrorBanner(),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                    )
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(),
            ),
            if (_isSending) _buildTypingIndicator(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.withAlpha(50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withAlpha(50),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 48, color: Color(0xFF60A5FA)),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Hola! Soy Rino AI con Gemini',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu asistente técnico de Grupo Rino E.I.R.L. en Huánuco.\nPuedo ayudarte con repuestos, compatibilidad técnica, pedidos y entregas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Consultas sugeridas:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quickPrompts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final prompt = _quickPrompts[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleSendMessage(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF60A5FA)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (ctx, idx) {
        final msg = _messages[idx];
        return _buildMessageBubble(msg);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;
    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF2563EB) : const Color(0xFF18181B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFF334155), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isUser ? Colors.white70 : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copiado al portapapeles'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy, size: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, left: 8),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                ),
                SizedBox(width: 8),
                Text(
                  'Gemini está pensando...',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Pregúntale a Gemini sobre repuestos...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _isSending ? const Color(0xFF334155) : const Color(0xFF2563EB),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _isSending ? null : () => _handleSendMessage(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF09090B),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Historial de Chats',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(context);
                      _startNewConversation();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingConversations
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : _conversations.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay conversaciones aún.\n¡Inicia una nueva!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(10),
                          itemCount: _conversations.length,
                          separatorBuilder: (context, index) => const Divider(color: Color(0xFF18181B), height: 1),
                          itemBuilder: (ctx, idx) {
                            final conv = _conversations[idx];
                            final isSelected = conv.id == _currentConversation?.id;
                            final dateText = conv.updatedAt != null
                                ? DateFormat('dd/MM hh:mm a').format(conv.updatedAt!)
                                : '';

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: const Color(0xFF18181B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              leading: Icon(
                                Icons.chat,
                                color: isSelected ? const Color(0xFF60A5FA) : Colors.grey,
                                size: 18,
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                '${conv.messagesCount} msgs • $dateText',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                                onPressed: () => _deleteConversation(conv),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _selectConversation(conv);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
