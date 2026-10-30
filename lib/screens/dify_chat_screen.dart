import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/dify_service.dart';

class DifyChatScreen extends StatefulWidget {
  const DifyChatScreen({super.key});

  @override
  State<DifyChatScreen> createState() => _DifyChatScreenState();
}

class _DifyChatScreenState extends State<DifyChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<DifyChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '¿Qué viscosidad de aceite requiere mi vehículo?',
    '¿Tienen pastillas de freno y discos?',
    '⚡ ¿Qué batería me recomiendan?',
    '¿Cómo rastreo el despacho por GPS en vivo?',
    '¿Qué funciones de diagnóstico incluye el escáner OBD2?',
    '¿Cómo funciona la estimación de llegada ETA por IA?',
  ];

  @override
  void initState() {
    super.initState();
    _addInitialGreeting();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialGreeting() {
    final hasKey = ApiConfig.hasDifyApiKey;
    _messages.add(
      DifyChatMessage(
        id: 'msg_welcome',
        text: 'Bienvenido al Asistente Técnico Oficial de **Grupo Rino E.I.R.L.**\n\n'
            'Puedo asesorarte en repuestos de autos y motocicletas, compatibilidad de piezas, consulta de pedidos con rastreo en vivo y cotizaciones en Huánuco.\n\n'
            '${hasKey ? "🟢 *Asistente Inteligente Conectado y Listo*" : "⚙️ *Modo Asistente Activo.*"}\n\n'
            '¿En qué te puedo ayudar hoy?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
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
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    final userMsg = DifyChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await DifyService.sendMessage(text);
      final botMsg = DifyChatMessage(
        id: 'msg_bot_${DateTime.now().millisecondsSinceEpoch}',
        text: response['answer'] ?? 'Sin respuesta',
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMsg = DifyChatMessage(
        id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
        text: '⚠️ $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      if (mounted) {
        setState(() {
          _messages.add(errorMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showDifySettingsDialog() {
    final keyController = TextEditingController(text: ApiConfig.difyApiKey);
    final urlController = TextEditingController(text: ApiConfig.difyBaseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Configurar Agente Dify', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endpoint API de Dify:',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://api.dify.ai/v1',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF09090B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Dify API Key (App Key):',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: keyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'app-xxxxxxxxxxxxxxxxxxxxxxxx',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF09090B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Consigue tu clave en: Dify Console > Tu App > Menú Lateral "Acceso a la API" > "Claves API".',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await ApiConfig.setDifyConfig(
                keyController.text.trim(),
                baseUrl: urlController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Configuración de Dify guardada con éxito.'),
                  backgroundColor: Colors.green,
                ),
              );
              if (mounted) setState(() {});
            },
            child: const Text('Guardar Clave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset('assets/images/logo_white.png', width: 22, height: 22, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RinoBot - Agente IA',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: ApiConfig.hasDifyApiKey ? Colors.greenAccent : Colors.orangeAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ApiConfig.hasDifyApiKey ? 'Dify Cloud Conectado' : 'Asistente Rino Local',
                        style: TextStyle(
                          color: ApiConfig.hasDifyApiKey ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key, color: Colors.orangeAccent),
            tooltip: 'Configurar API Key de Dify',
            onPressed: _showDifySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            tooltip: 'Nueva Conversación',
            onPressed: () {
              setState(() {
                DifyService.currentConversationId = null;
                _messages.clear();
                _addInitialGreeting();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de Estado de Conexión Dify
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ApiConfig.hasDifyApiKey
                  ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                  : const Color(0xFF78350F).withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(
                  color: ApiConfig.hasDifyApiKey ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  ApiConfig.hasDifyApiKey ? Icons.cloud_done : Icons.cloud_queue,
                  color: ApiConfig.hasDifyApiKey ? Colors.greenAccent : Colors.orangeAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ApiConfig.hasDifyApiKey
                        ? 'Agente Dify activo en ${ApiConfig.difyBaseUrl}'
                        : 'Modo Asistente Local. Presiona la llave de configuración arriba para enlazar tu API Key de Dify.',
                    style: TextStyle(
                      color: ApiConfig.hasDifyApiKey ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Indicador de escritura animado
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'RinoBot está respondiendo...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // Chips de preguntas rápidas sugeridas
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prompt = _quickPrompts[idx];
                return ActionChip(
                  backgroundColor: const Color(0xFF18181B),
                  side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  label: Text(
                    prompt,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  onPressed: () => _handleSendMessage(prompt),
                );
              },
            ),
          ),

          // Barra inferior de entrada de texto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              border: Border(top: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu consulta sobre repuestos...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF09090B),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : () => _handleSendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DifyChatMessage msg) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.2), blurRadius: 6),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: msg.isError ? Colors.redAccent.withValues(alpha: 0.2) : Colors.orangeAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              msg.isError ? Icons.error_outline : Icons.smart_toy,
              color: msg.isError ? Colors.redAccent : Colors.orangeAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isError ? const Color(0xFF450A0A) : const Color(0xFF18181B),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: msg.isError ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white10,
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isError ? Colors.redAccent : Colors.white,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
