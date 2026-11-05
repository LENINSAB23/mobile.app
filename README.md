# Documentación Técnica del Sistema Multiplataforma
## Proyecto de Tesis: Plataforma de Comercio Electrónico, Telemetría GPS Satelital y Asistencia Técnica IA para Repuestos Automotrices
### Empresa Beneficiaria: **Grupo Rino E.I.R.L. (Huánuco, Perú)**

---

## 1. Resumen Ejecutivo

El presente proyecto de investigación e ingeniería de software implementa un ecosistema integral multiplataforma diseñado para resolver las problemáticas de disponibilidad de inventario, asesoría técnica especializada y seguimiento logístico de repuestos para automóviles y motocicletas en la ciudad de Huánuco.

La solución articula:
- Una **aplicación móvil nativa multiplataforma (Flutter)** con roles diferenciados para clientes y repartidores, transmisión en tiempo real de telemetría GPS y mapa cartográfico interactivo.
- Un **portal web de alta velocidad (React 19 + Vite 8)** con un diseño minimalista monocromático enfocado en velocidad de carga y navegación técnica clara.
- Un **servidor central API RESTful (Laravel 11)** que gestiona la persistencia transaccional (MySQL), autenticación segura (Sanctum) y orquestación de servicios.
- Un **subsistema de Inteligencia Artificial híbrido**:
  1. Microservicio de Machine Learning en **Python (Scikit-learn)** para el cálculo dinámico del tiempo estimado de llegada (ETA).
  2. Asistente técnico conversacional **RinoBot (Google Gemini)** con guardrails de restricción de dominio automotriz estricta.

---

## 2. Pila Tecnológica Empleada (Stack Tecnológico)

A continuación se detallan las tecnologías y librerías utilizadas, junto con la justificación técnica de su elección para el marco metodológico de la tesis:

### 2.1 Aplicación Móvil (`mobile_app`)

| Tecnología / Librería | Versión | Rol en el Proyecto | Justificación Académica / Técnica |
| :--- | :--- | :--- | :--- |
| **Flutter SDK** | 3.x (Dart 3.x) | Framework base de UI y lógica | Compilación Ahead-Of-Time (AOT) a código máquina nativo (ARM64), renderizado a 60-120 fps sin puente de serialización JavaScript (como ocurre en React Native), garantizando máxima fluidez en mapas interactivos y telemetría. |
| **Provider** | `^6.1.5` | Gestión de estado (State Management) | Implementa el patrón InheritedWidget con bajo consumo de memoria y ciclo de vida predecible. Desacopla la lógica de negocio de la interfaz gráfica sin la sobrecarga cognitiva de frameworks más pesados como Bloc. |
| **geolocator** | `^14.1.1` | Captura de coordenadas GPS | Acceso directo a los sensores GNSS/GPS del dispositivo Android. Permite configurar precisión fina (`LocationAccuracy.high`), distancia mínima de actualización y captura de velocidad instantánea en km/h. |
| **flutter_map** | `^8.3.2` | Motor de renderizado cartográfico | Alternativa de código abierto de alto rendimiento basada en Leaflet. Permite consumir capas de mosaicos satelitales y vectoriales de **OpenStreetMap (OSM)** sin requerir claves de API de pago ni tarifas recurrentes por petición (frente a Google Maps SDK). |
| **latlong2** | `^0.10.1` | Cálculos geoespaciales | Modelado de coordenadas de latitud/longitud, cálculo de distancias euclidianas y geodésicas en ruta. |
| **http** | `^1.6.0` | Cliente RESTful HTTP | Conexión ligera y asíncrona mediante Futures/Streams con la API central, inyectando tokens de autenticación Bearer y manejo robusto de excepciones de red. |
| **shared_preferences** | `^2.5.6` | Persistencia local ligera | Almacena en almacenamiento seguro clave-valor la sesión del usuario, tokens de acceso y la dirección IP/Host de conexión al servidor central. |
| **intl** | `^0.20.3` | Internacionalización y formateo | Formato de moneda en Soles Peruanos (`S/`), marcas de tiempo ISO-8601 y formatos numéricos locales. |

#### Filosofía de Diseño de la App Móvil:
- **Minimalismo Monocromático**: Se prescindió de elementos gráficos ornamentales y emojis para garantizar una estética industrial profesional de alto contraste (fondo `#09090B`, tarjetas `#18181B`, bordes finos `#27272A` y tipografía blanca `#FAFAFA`).
- **Espacio Negativo y Velocidad**: Prioriza la legibilidad en condiciones de taller o conducción con luz diurna y reduce la fatiga visual.

---

### 2.2 Portal Web (`frontend_web`)

| Tecnología / Librería | Versión | Rol en el Proyecto | Justificación Académica / Técnica |
| :--- | :--- | :--- | :--- |
| **React** | 19.3.x | Biblioteca de interfaz de usuario | Paradigma funcional basado en Hooks (`useState`, `useEffect`, `useMemo`), renderizado optimizado y modularidad basada en componentes reutilizables. |
| **Vite** | 8.3.x | Empaquetador y servidor de desarrollo | Servidor de compilación ultrarrápido basado en ES Modules nativos. Elimina los prolongados tiempos de espera de Webpack e integra proxy inverso para evitar problemas de CORS durante el desarrollo local. |
| **Lucide React** | 1.61.x | Iconografía técnica vectorial | Iconos SVG optimizados, con peso mínimo en el bundle final y consistencia visual en herramientas mecánicas, vehículos y navegación. |
| **CSS3 Custom Properties** | Nativo | Sistema de diseño atómico | Arquitectura de estilos basada en variables globales CSS sin dependencia de librerías externas de CSS-in-JS, logrando tiempos de First Contentful Paint (FCP) inferiores a 300 ms. |

---

### 2.3 Backend y Persistencia Transaccional (`backend-api`)

| Tecnología | Rol en el Proyecto | Justificación Académica / Técnica |
| :--- | :--- | :--- |
| **Laravel 11 (PHP 8.2+)** | API RESTful y lógica de negocio central | Framework empresarial con soporte estricto de tipos, arquitectura MVC, migraciones de base de datos declarativas y Eloquent ORM para consultas optimizadas contra inyecciones SQL. |
| **Laravel Sanctum** | Autenticación y control de accesos | Sistema de tokens de portador (Bearer Tokens) de bajo consumo, adecuado para dispositivos móviles y aplicaciones web de página única (SPA). |
| **MySQL (Laragon)** | Base de datos relacional principal | Motor relacional con integridad referencial, índices de búsqueda en catálogo y transacciones ACID para evitar inconsistencias en pedidos e inventario. |

---

### 2.4 Módulos de Inteligencia Artificial

| Subsistema | Tecnología | Función |
| :--- | :--- | :--- |
| **Predictor de ETA (Tiempo Estimado de Llegada)** | Python / FastAPI / Scikit-learn (`ai-services`) | Modelo de regresión lineal multivariable entrenado para calcular el tiempo real de despacho urbano evaluando: distancia kilométrica, hora punta de congestión vehicular en Huánuco y velocidad media del repartidor. |
| **Asistente Técnico RinoBot** | Google Gemini (Gemini API) | Agente conversacional que asiste a los usuarios en la compatibilidad de aceites, bujías, frenos y estado de sus pedidos. Dispone de **Guardrails de Restricción de Dominio**: si el usuario consulta temas ajenos al rubro automotriz de Grupo Rino, el agente declina la respuesta de forma estricta. |

---

## 3. Arquitectura del Sistema

```
+-----------------------------------------------------------------------------------+
|                              CAPA DE PRESENTACIÓN                                 |
|                                                                                   |
|   [ App Móvil Flutter (Android/iOS) ]         [ Portal Web React 19 + Vite ]      |
|    - Catálogo & Ficha Técnica                  - Catálogo Interactivo             |
|    - Carrito & Checkout (Yape/Tarjeta)         - RinoBot Web Chat                 |
|    - Telemetría GPS en Vivo (Repartidor)       - Configuración API                |
|    - Rastreo Satelital (Cliente)                                                  |
+------------------------------------------+----------------------------------------+
                                           | Peticiones HTTP / REST API (JSON)
                                           v
+-----------------------------------------------------------------------------------+
|                              CAPA DE SERVICIOS (BACKEND)                          |
|                                                                                   |
|   [ Laravel 11 API Gateway - Puerto 8000 ]                                        |
|    - Autenticación Sanctum (Roles: Cliente, Repartidor, Administrador)           |
|    - Controlador de Catálogo & Productos (`/api/products`, `/api/categories`)     |
|    - Controlador de Órdenes & Checkout (`/api/orders`)                            |
|    - Controlador de Telemetría GPS en Tiempo Real (`/api/orders/{id}/tracking`)   |
+---------------------+-------------------------------------+-----------------------+
                      |                                     |
                      v                                     v
+-----------------------------+     +-----------------------------------------------+
|     CAPA DE PERSISTENCIA    |     |          CAPA DE INTELIGENCIA ARTIFICIAL      |
|                             |     |                                               |
|   [ MySQL 8.x - Laragon ]   |     |   [ Microservicio ETA (Python / FastAPI) ]    |
|    - Tablas de Usuarios     |     |    - Modelo Scikit-Learn de regresión temporal|
|    - Tabla de Productos     |     |                                               |
|    - Tabla de Pedidos       |     |   [ Agente RinoBot (Google Gemini API) ]      |
|    - Coordenadas GPS (Logs) |     |    - Restricción estricta de dominio          |
+-----------------------------+     +-----------------------------------------------+
```

---

## 4. Funcionamiento Detallado de los Módulos de la Aplicación Móvil

### 4.1 Módulo de Catálogo y Filtrado Vehicular
- **Filtrado Bidireccional**: Permite filtrar repuestos simultáneamente por categoría funcional (Aceites, Frenos, Baterías, Herramientas) y por tipo de vehículo (**Automóvil/SUV**, **Motocicleta 4T** o **Universal**).
- **Ficha Técnica Detallada**: Muestra especificaciones de grado de viscosidad (SAE), normas de homologación internacional (API SP, JASO MA2, DOT 4) y marcas oficiales (Mobil 1, Motul, Brembo, Bosch, Capsa).

### 4.2 Módulo de Carrito de Compras y Pasarela Digital
- **Gestión Reactiva con Provider**: Los productos agregados se almacenan en el estado global `CartProvider`.
- **Validación de Métodos de Pago**:
  - **Yape / Billetera Digital**: Registro inmediato del número telefónico y referencia.
  - **Tarjeta de Crédito/Débito**: Simulación de pasarela segura.
  - **Efectivo Contraentrega**: Pago directo al motorizado al recibir la pieza en domicilio o taller.

### 4.3 Módulo de Telemetría Satelital del Repartidor (`DriverDashboardScreen`)
- **Captura Satelital en Primer y Segundo Plano**: Mediante la librería `geolocator`, el repartidor activa el modo "En Turno" e inicia el flujo de coordenadas de alta precisión.
- **Transmisión de Coordenadas**: La aplicación envía periódicamente las coordenadas latitud/longitud y velocidad hacia el backend (`/api/orders/{id}/location`).
- **Mapa de Ruta Óptima**: Visualiza en un mapa OpenStreetMap la ubicación actual de la moto y el destino del cliente en Huánuco, trazando la poligonal de ruta.

### 4.4 Módulo de Rastreo Satelital del Cliente (`OrderTrackingScreen`)
- **Visualización en Tiempo Real**: El cliente visualiza un mapa con dos marcadores distintivos:
  1. Ubicación del repartidor en movimiento.
  2. Domicilio o taller del cliente.
- **Estimación Predictiva (ETA)**: Muestra el tiempo restante estimado calculado por el microservicio de IA, adaptándose a las condiciones de tránsito local.

### 4.5 Módulo de Asistencia Técnica Inteligente (`GeminiChatScreen`)
- **Asesoría de Lubricación**: Asiste al usuario en la elección del aceite correcto según el año, kilometraje y fabricante del motor.
- **Guardrail de Seguridad**: Algoritmo que filtra cualquier consulta ajena al catálogo automotriz para evitar el uso indebido de la API.

---

## 5. Justificación de Aportes Metodológicos para la Tesis

1. **Soberanía y Reducción de Costos Operativos**:
   - Al usar **OpenStreetMap** con `flutter_map` en vez de Google Maps Platform, el sistema elimina costos por facturación mensual de APIs propietarias, haciéndolo viable para pequeñas y medianas empresas automotrices en el Perú.
2. **Alta Eficiencia Energética y de Datos**:
   - El protocolo de telemetría envía cargas útiles mínimas en JSON (latitud, longitud, timestamp, batería, velocidad) de menos de 150 bytes por trama, asegurando operatividad incluso en zonas con cobertura móvil 3G/4G inestable en Huánuco.
3. **Resiliencia Operativa (Modo Demostración Offline)**:
   - Toda la suite integra un modo de demostración aislado que permite ejecutar pruebas completas de sustentación ante jurados académicos sin requerir conexión a internet obligatoria.

---

## 6. Estructura de Directorios del Código Fuente

```text
mobile_app/
├── android/                     # Configuración nativa Android y permisos de GPS
├── assets/
│   └── images/
│       ├── logo.png             # Logo oficial Grupo Rino (fondo oscuro)
│       └── logo_white.png       # Logo oficial Grupo Rino (fondo transparente claro)
├── lib/
│   ├── config/
│   │   └── api_config.dart      # Dirección de red, puertos y claves de API
│   ├── models/                  # Modelos de datos inmutables (Product, Category, Order, User)
│   ├── providers/               # Controladores de estado reactivo (AuthProvider, CartProvider, OrderProvider)
│   ├── screens/                 # Vistas de usuario:
│   │   ├── login_screen.dart             # Selector de roles y autenticación
│   │   ├── home_customer_screen.dart     # Catálogo, carrito, órdenes y perfil
│   │   ├── driver_dashboard_screen.dart  # Panel de despacho y telemetría
│   │   ├── order_tracking_screen.dart    # Rastreo satelital en vivo con mapa
│   │   └── gemini_chat_screen.dart       # Asistente IA RinoBot (Google Gemini)
│   ├── services/                # Servicios de red, GPS y telemetría
│   └── main.dart                # Punto de entrada y configuración de tema minimalista
├── pubspec.yaml                 # Dependencias y registro de assets
└── README.md                    # Documentación técnica de tesis
```
