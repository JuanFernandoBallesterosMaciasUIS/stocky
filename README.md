# Stocky - Gestión de Inventario y Finanzas

Aplicación móvil desarrollada en Flutter para el control eficiente de inventarios, compras, ventas y gestión de gastos en pequeños y medianos negocios.

# Descripción del Proyecto

Stocky es una solución tecnológica diseñada para resolver la falta de control financiero y de existencias que enfrentan los emprendedores y dueños de negocios locales. La aplicación permite llevar un registro detallado de productos, registrar transacciones de compra y venta en tiempo real, y gestionar los pagos de clientes y proveedores, así como los gastos operativos. El contexto de uso es principalmente entornos minoristas donde se requiere una herramienta ágil y móvil para la toma de decisiones basada en datos económicos actualizados.

# Objetivo General

Desarrollar un sistema de gestión integral que permita centralizar la información operativa de un negocio, facilitando el control de inventarios y la trazabilidad de los flujos de caja mediante una interfaz intuitiva y persistencia de datos local.

# Objetivos Específicos

- Implementar un módulo de inventario para el registro, edición y consulta de productos con stock actualizado.
- Desarrollar un sistema de registro de ventas y compras que afecte automáticamente los niveles de inventario.
- Gestionar pagos de clientes y abonos a proveedores para mantener un control de cuentas por cobrar y por pagar.
- Facilitar la visualización de reportes financieros básicos para el análisis de ingresos y egresos.
- Garantizar la persistencia de la información mediante el uso de almacenamiento local para asegurar la disponibilidad sin conexión.
- Integrar capacidades de comando de voz para búsquedas o registros rápidos mediante procesamiento de lenguaje natural básico.

# Integrantes del Equipo

| Nombre | Rol |
| :--- | :--- |
| Juan Fernando Ballesteros Macias | Scrum Master / Lead Developer |
| Equipo de Desarrollo UIS | Software Engineers / Testers |

# Glosario

| Término | Definición |
| :--- | :--- |
| **UI** | User Interface (Interfaz de Usuario): Elementos visuales con los que interactúa el usuario. |
| **UX** | User Experience (Experiencia de Usuario): Percepción y respuesta del usuario al usar la app. |
| **CRUD** | Create, Read, Update, Delete: Operaciones básicas de gestión de datos. |
| **API** | Application Programming Interface: Interfaz que permite la comunicación entre componentes. |
| **Token** | Elemento de seguridad usado para autenticación o identificación de sesiones. |
| **Base de Datos** | Conjunto organizado de datos almacenados sistemáticamente (en este caso, Local Storage). |
| **Flutter** | Framework de Google para crear aplicaciones multiplataforma de forma nativa. |

# Requerimientos Funcionales de este proyecto

| ID | Descripción |
| :--- | :--- |
| RF-01 | **Gestión de Inventario:** Permite registrar, editar y listar productos con precio y cantidad. |
| RF-02 | **Registro de Ventas:** Permite crear facturas de venta restando stock del inventario. |
| RF-03 | **Registro de Compras:** Permite registrar entradas de mercancía sumando stock al inventario. |
| RF-04 | **Gestión de Pagos:** Registro de abonos recibidos de clientes y pagos realizados a proveedores. |
| RF-05 | **Control de Gastos:** Registro de egresos administrativos o de operación ajenos a la compra de mercancía. |
| RF-06 | **Reportes Financieros:** Visualización resumen de ingresos, egresos y utilidad en periodos de tiempo. |
| RF-07 | **Reconocimiento de Voz:** Integración con servicios de voz para búsqueda de elementos. |

# Requerimientos No Funcionales de este proyecto

| ID | Descripción |
| :--- | :--- |
| RNF-01 | **Persistencia Local:** Los datos deben guardarse permanentemente en el dispositivo usando SharedPreferences. |
| RNF-02 | **Rendimiento:** La aplicación debe cargar la lista de productos en menos de 2 segundos. |
| RNF-03 | **Usabilidad:** Diseño basado en Material Design 3 con navegación intuitiva mediante un Scaffold principal. |
| RNF-04 | **Compatibilidad:** Soporte para dispositivos Android (mínimo SDK 21) y entorno Web. |
| RNF-05 | **Escalabilidad:** Arquitectura basada en Store/Provider que facilita añadir nuevos módulos. |

# Casos de Uso de este proyecto

| ID | Caso de Uso | Descripción |
| :--- | :--- | :--- |
| UC1 | Registrar Venta | El usuario selecciona productos del inventario y genera una nueva venta que actualiza el stock. |
| UC2 | Consultar Inventario | El usuario visualiza la lista de productos disponibles y sus cantidades actuales. |
| UC3 | Registrar Gasto | El usuario ingresa un egreso detallando el concepto y el monto para su balance financiero. |
| UC4 | Generar Reporte | El sistema consolida las ventas y gastos para presentar un balance de utilidades. |

# Arquitectura del Sistema

El proyecto sigue una arquitectura de **Gestión de Estado Centralizada** combinada con un **Patrón de Servicios**.

- **Frontend (Flutter):** Implementado con widgets reactivos que responden a los cambios en el Store.
- **Gestión de Estado:** Utiliza un `AppStore` centralizado accedido mediante `StoreProvider` para propagar datos a través del árbol de widgets.
- **Persistencia (Local):** Los datos no se pierden al cerrar la app gracias al `PersistenceService` que interactúa con el almacenamiento local del dispositivo.
- **Modelos:** Orientado a objetos con modelos específicos para `Product`, `Sale`, `Purchase`, `Expense`, etc.

# Tech Stack

**Frontend:**
- **Flutter:** Contenedor y motor de renderizado.
- **Dart:** Lenguaje de programación.

**Base de datos:**
- **Shared Preferences:** Almacenamiento clave-valor local para persistencia rápida y eficiente.

**Servicios adicionales:**
- **Speech to Text:** Para el reconocimiento de voz integrado.
- **Material Design 3:** Guías de diseño para una interfaz moderna.

# Estructura del Proyecto

```text
lib/
 ├── main.dart             # Punto de entrada de la aplicación e inicialización.
 ├── models/               # Modelos de datos (Product, Sale, Expense, etc.).
 ├── res/                  # Recursos estáticos, colores y constantes del sistema.
 ├── screens/              # Pantallas principales del flujo de la aplicación.
 ├── services/             # Lógica de persistencia y servicios externos.
 ├── store/                # Lógica de gestión de estado global (AppStore).
 ├── utils/                # Funciones de ayuda (formateo de moneda, filtros de fecha).
```

### Descripción de carpetas:
- `models/`: Define la estructura de los objetos de negocio.
- `screens/`: Contiene la UI organizada por módulos (Inventario, Ventas, Gastos, Reportes).
- `services/`: Encapsula la lógica que no es de UI, como guardar datos en disco.
- `store/`: Contiene el estado vivo de la aplicación durante la ejecución.
- `utils/`: Utilidades compartidas para visualización de datos.

# Instalación del Proyecto

Requisitos previos: Tener instalado el SDK de Flutter en su versión estable.

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/JuanFernandoBallesterosMaciasUIS/stocky.git
   ```
2. **Navegar al directorio del proyecto:**
   ```bash
   cd stocky
   ```
3. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```
4. **Ejecutar el proyecto:**
   ```bash
   flutter run
   ```

# Uso de la Aplicación

1. **Inicio:** Al abrir la app, verá el panel principal o "Ingresos" por defecto.
2. **Navegación:** Utilice la barra de navegación inferior para desplazarse entre Inventario, Compras, Ingresos (Ventas), Gastos y Reportes.
3. **Registro:** En cada sección, utilice el botón de acción (+) para agregar nuevos registros.
4. **Guardado:** La aplicación guarda automáticamente todos los cambios realizados en el almacenamiento local del teléfono.
5. **Reportes:** Consulte la sección de reportes para ver el resumen del desempeño de su negocio.

# Licencia

Este proyecto está bajo una licencia académica para el curso de Ingeniería de Software 2 en la UIS. Todos los derechos reservados © 2026.
