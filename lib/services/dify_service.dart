import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DifyChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  DifyChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class DifyService {
  static String? currentConversationId;

  /// Envía un mensaje al Agente de Dify a través de su API oficial
  static Future<Map<String, dynamic>> sendMessage(
    String query, {
    String? conversationId,
    String? userId,
  }) async {
    final convId = conversationId ?? currentConversationId ?? '';
    final user = userId ?? 'rino_customer_mobile';

    // 1. Si el usuario configuró una API Key de Dify, conectar a la API en la nube
    if (ApiConfig.hasDifyApiKey) {
      final url = Uri.parse('${ApiConfig.difyBaseUrl}/chat-messages');

      try {
        final payload = {
          'inputs': {},
          'query': query,
          'response_mode': 'blocking',
          'conversation_id': convId.isEmpty ? '' : convId,
          'user': user,
        };

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.difyApiKey}',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final answer = data['answer'] ?? 'Sin respuesta del agente.';
          final newConvId = data['conversation_id'] ?? '';
          if (newConvId.isNotEmpty) {
            currentConversationId = newConvId;
          }

          return {
            'answer': answer,
            'conversation_id': newConvId,
            'is_cloud': true,
          };
        } else if (response.statusCode == 401) {
          throw Exception('Clave API no autorizada (401). Verifica tu Dify API Key en el botón ⚙️ de arriba.');
        } else if (response.statusCode == 404) {
          throw Exception('Endpoint de Dify no encontrado (404). Verifica que la URL base sea https://api.dify.ai/v1');
        } else {
          final errorData = jsonDecode(response.body);
          final msg = errorData['message'] ?? 'Error ${response.statusCode} de Dify';
          throw Exception(msg);
        }
      } on TimeoutException {
        throw Exception('El servidor de Dify tardó demasiado en responder (Timeout).');
      } catch (e) {
        if (e.toString().contains('Exception:')) rethrow;
        throw Exception('Error al conectar con Dify: $e');
      }
    }

    // 2. Si aún no ha ingresado API Key, responde con el motor inteligente local de Grupo Rino
    await Future.delayed(const Duration(milliseconds: 700));
    final localAnswer = _generateLocalKnowledgeResponse(query);
    return {
      'answer': localAnswer,
      'conversation_id': 'local-session-rino',
      'is_cloud': false,
    };
  }

  /// Base de conocimiento automotriz integrada de Grupo Rino E.I.R.L.
  static String _generateLocalKnowledgeResponse(String query) {
    final q = query.toLowerCase();

    // 0. Guardrails estrictos: Detección y declinación de consultas ajenas a la app/automotriz
    final offTopicKeywords = [
      'comida', 'receta', 'cocina', 'restaurante', 'pizza', 'hamburguesa', 'almuerzo',
      'tarea', 'matematica', 'matemática', 'historia de', 'capital de', 'presidente',
      'politica', 'política', 'religion', 'religión', 'poema', 'poesía', 'chiste',
      'cancion', 'canción', 'futbol', 'fútbol', 'deporte', 'programar', 'codigo python',
      'medicina', 'dolor de', 'medico', 'médico', 'sintomas', 'farmacia'
    ];
    for (final word in offTopicKeywords) {
      if (q.contains(word)) {
        return '⚠️ **Consulta fuera del alcance de la app:**\n\n'
            'Disculpa, solo estoy capacitado para responder consultas relacionadas con la **aplicación de Grupo Rino, repuestos de autos y motos, catálogo, seguimiento de pedidos y asesoría mecánica**.\n\n'
            '¿En qué repuesto o función de la app te puedo orientar?';
      }
    }

    if (q.contains('aceite') || q.contains('lubricante') || q.contains('mobil') || q.contains('motul')) {
      return '🛢️ **Asesoría de Lubricación Automotriz & Motos - Grupo Rino:**\n\n'
          '• **Para Autos / SUVs:** Recomendamos **Mobil 1 Sintético 5W-30 (1 Galón)** (S/ 145.00). Brinda máxima protección térmica y ahorro de combustible para motores Toyota, Kia, Hyundai y Nissan.\n'
          '• **Para Motos Lineales / 4T:** Disponemos de **Motul 7100 4T 10W-40 100% Sintético con Ester (1L)** (S/ 58.00). Protege la caja de cambios y embrague en motos Pulsar, Honda CB y Yamaha FZ.\n'
          '• **Líquido de Frenos:** Bosch DOT 4 (500ml) a S/ 28.00.\n'
          '• **Refrigerante:** Prestone 50/50 listo para usar (1 Galón) a S/ 42.00.\n\n'
          '¿Deseas que agregue alguno de estos productos a tu carrito?';
    }

    if (q.contains('freno') || q.contains('pastilla') || q.contains('disco') || q.contains('brembo')) {
      return '🛑 **Sistema de Frenos de Alta Seguridad:**\n\n'
          '• **Pastillas Delanteras Cerámicas Fras-le:** S/ 95.00 el juego. Frenado silencioso sin polvo negro.\n'
          '• **Discos de Freno Ranurados/Ventilados Brembo:** S/ 240.00 el par delantero para alto rendimiento en bajadas y carretera.\n'
          '• **Pastillas de Cerámica para Motos:** S/ 35.00 (compatibles con Bajaj Pulsar, Honda y Yamaha).\n\n'
          'Nuestros técnicos recomiendan verificar el grosor de las pastillas cada 10,000 km.';
    }

    if (q.contains('bateria') || q.contains('batería') || q.contains('electr') || q.contains('luz') || q.contains('led')) {
      return '⚡ **Baterías y Sistema Eléctrico:**\n\n'
          '• **Batería Capsa Gold 13 Placas (12V 65Ah):** S/ 280.00. Libre de mantenimiento con 18 meses de garantía para autos y camionetas.\n'
          '• **Batería de Gel Sellada Yuasa YTX9-BS (12V 8Ah):** S/ 115.00 para motos lineales y cuatrimotos.\n'
          '• **Focos LED Philips Ultinon H4 (Par):** S/ 160.00. Luz blanca fría 6000K de alta penetración.\n'
          '• **Kit de Fusibles Automotrices (50 unidades):** S/ 25.00 surtidos de 5A a 30A.';
    }

    if (q.contains('escaner') || q.contains('escáner') || q.contains('obd') || q.contains('herramienta') || q.contains('gata')) {
      return '🔧 **Herramientas de Mecánica & Diagnóstico:**\n\n'
          '• **Escáner Automotriz OBD2 Bluetooth ELM327:** S/ 65.00. Se conecta a tu smartphone para leer y borrar códigos de falla (Check Engine) y ver datos de sensores en vivo.\n'
          '• **Gata Hidráulica Tipo Caimán 2.5 Toneladas:** S/ 195.00 con maletín transportable.\n'
          '• **Juego de Llaves y Dados Cr-V (46 piezas):** S/ 85.00 de 4 a 14mm con rachet ergonómico.\n'
          '• **Manómetro Digital de Presión de Llantas 150 PSI:** S/ 32.00 con pantalla retroiluminada.';
    }

    if (q.contains('pedido') || q.contains('orden') || q.contains('rastre') || q.contains('donde') || q.contains('gps') || q.contains('mapa')) {
      return '📦 **Rastreo Satelital GPS en Tiempo Real:**\n\n'
          '• En la pestaña **"Mis Pedidos"** puedes ver el estado en vivo de tu compra.\n'
          '• Pulsando en **"Rastrear con GPS Satelital"**, verás el mapa vial interactivo con la ubicación en tiempo real del repartidor de Grupo Rino, su velocidad y el tiempo estimado de llegada.\n'
          '• Las coordenadas se actualizan automáticamente en tiempo real.';
    }

    if (q.contains('eta') || q.contains('tiempo') || q.contains('ia') || q.contains('inteligencia')) {
      return '⏱️ **Estimación de Tiempo de Entrega:**\n\n'
          'El sistema calcula dinámicamente el tiempo de llegada evaluando:\n'
          '1. La distancia exacta hacia tu taller o domicilio.\n'
          '2. Las condiciones de tráfico en la ciudad de Huánuco.\n'
          '3. La velocidad de desplazamiento del repartidor.\n\n'
          'El tiempo estimado promedio en zona urbana es de **12 a 25 minutos**.';
    }

    if (q.contains('pago') || q.contains('yape') || q.contains('plin') || q.contains('tarjeta') || q.contains('efectivo')) {
      return '💳 **Métodos de Pago Disponibles:**\n\n'
          '• **Yape / Plin:** Transferencia inmediata con confirmación digital.\n'
          '• **Tarjeta de Crédito / Débito:** Visa, Mastercard, Diners.\n'
          '• **Efectivo Contraentrega:** Pagas al recibir los repuestos en tu domicilio o taller mecánico en Huánuco.';
    }

    if (q.contains('quien') || q.contains('que eres') || q.contains('quién eres') || q.contains('rino') || q.contains('app') || q.contains('ayuda')) {
      return '👋 ¡Hola! Soy **RinoBot**, el Asistente Virtual oficial de **Grupo Rino E.I.R.L.**\n\n'
          'Estoy capacitado exclusivamente para asesorarte en:\n'
          '• Elección de repuestos compatibles con tu auto o motocicleta.\n'
          '• Consulta de precios, catálogo de lubricantes, frenos, baterías y herramientas.\n'
          '• Seguimiento satelital de pedidos y entregas en tiempo real.\n'
          '• Métodos de pago y cálculo de tiempos estimados de llegada (ETA).\n\n'
          '¿Qué repuesto o consulta sobre tu vehículo necesitas revisar hoy?';
    }

    // Respuesta genérica guiada estrictamente al dominio de la app
    return '👋 Disculpa, solo estoy capacitado para responder consultas relacionadas con la **aplicación de Grupo Rino**, repuestos de autos y motos, catálogo, seguimiento de pedidos y asesoría mecánica.\n\n'
        '¿Deseas consultar sobre algún repuesto específico (aceites, frenos, bujías, baterías) o el estado de tu pedido?';
  }
}
