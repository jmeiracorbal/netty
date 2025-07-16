# Netty

Una caja de herramientas de utilidades de red para macOS que reúne herramientas esenciales de red en la terminal. Obtén información WiFi, prueba velocidades, gestiona DNS, monitoriza tráfico y más, todo con comandos simples.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-Monterey%2B-blue.svg)](https://www.apple.com/macos/)
[![Homebrew](https://img.shields.io/badge/Homebrew-Compatible-orange.svg)](https://brew.sh/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## Quick Start

### Instalación vía Homebrew (Recomendado)
```bash
brew tap jmeiracorbal/tools
brew install netty
netty wifi
```

### Instalación Manual
```bash
curl -O https://raw.githubusercontent.com/jmeiracorbal/netty/main/netty.sh
chmod +x netty.sh
./netty.sh wifi
```

## Características

- Información WiFi: Ver conexión actual, redes guardadas y detalles de interfaz
- Prueba de velocidad: Descarga, latencia y resolución DNS
- Gestión de DNS: Vaciar caché, probar resolución y ver servidores DNS
- Monitorización de red: Monitorización de tráfico en tiempo real
- IP y geolocalización: Información de IP pública/privada y localización
- Ping avanzado: Pruebas de ping con estadísticas detalladas
- Exportar resultados: Guardar reportes en JSON, CSV o texto plano
- Registro de sesión: Registro automático de operaciones de red
- Interfaz clara: Salida en tablas y con indicadores de progreso

## Comandos principales

### WiFi y redes inalámbricas
```bash
netty wifi
netty info
```

### Velocidad y rendimiento
```bash
netty speed
netty ping google.com
netty ping 8.8.8.8
```

### Gestión de DNS
```bash
netty dns flush
netty dns test
netty dns servers
```

### Monitorización y análisis
```bash
netty monitor
netty ip
netty export json
```

## Ejemplo de salida

### Información WiFi
```
=== WiFi Network Scanner ===

Analizando información WiFi...
┌────────────────────────────────┬─────────┬─────────┬──────────┬──────────┐
│ Network Name (SSID)            │ Channel │ Signal  │ Security │ Status   │
├────────────────────────────────┼─────────┼─────────┼──────────┼──────────┤
│ MyNetwork-5G                   │ 36      │ ████    │ WPA2     │ Connected│
│ HomeOffice                     │ ?       │ ░░░░    │ Known    │ Saved    │
│ CoffeeShop_WiFi                │ ?       │ ░░░░    │ Known    │ Saved    │
└────────────────────────────────┴─────────┴─────────┴──────────┴──────────┘

WiFi Interface Information:
Interface: active
MAC Address: aa:bb:cc:dd:ee:ff
Supports: 2.4GHz & 5GHz bands

Actualmente conectado a: MyNetwork-5G
IP Address: 192.168.1.105
```

### Resultados de prueba de velocidad
```
=== Internet Speed Test ===

Probando velocidad de conexión...

Probando descarga...
Download Speed: 85.42 Mbps
Probando latencia...
Average Ping: 12.3 ms
Probando resolución DNS...
DNS Resolution: 28 ms

Prueba de velocidad completada
```

### Monitorización de red
```
=== Network Traffic Monitor ===
Interface: en0
Thu Jun 26 14:30:22 2025

Recibido: 2.45 GB (1,234,567 paquetes)
Transmitido: 892.1 MB (567,890 paquetes)

Conexiones activas:
  tcp4  192.168.1.105.52847  151.101.1.140.443   ESTABLISHED
  tcp4  192.168.1.105.52848  140.82.112.25.443   ESTABLISHED
```

## Guía detallada de comandos

### Comandos WiFi
```bash
netty wifi
netty info
```

- Conexión WiFi actual con intensidad y canal
- Lista de redes conocidas/guardadas
- Estado de la interfaz, MAC y capacidades
- Comandos útiles para diagnóstico

### Prueba de velocidad
```bash
netty speed
```

- Descarga: Archivo real desde CDN (1MB)
- Latencia: Ping a varios servidores
- Resolución DNS: Tiempo de resolución

### Herramientas DNS
```bash
netty dns flush
netty dns test
netty dns servers
```

Servidores recomendados:
- Google: 8.8.8.8, 8.8.4.4
- Cloudflare: 1.1.1.1, 1.0.0.1
- OpenDNS: 208.67.222.222, 208.67.220.220
- Quad9: 9.9.9.9, 149.112.112.112

### Ping avanzado
```bash
netty ping example.com
netty ping 8.8.8.8 10
```

- Resolución de host a IP
- Estadísticas de pérdida de paquetes
- RTT (min/avg/max)
- Registro automático de resultados

### Monitorización de red
```bash
netty monitor
```

Controles interactivos:
- q, Q: Salir
- r, R: Refrescar
- s, S: Guardar snapshot

Muestra:
- RX/TX y paquetes
- Conexiones activas
- Estadísticas de interfaz

### IP y geolocalización
```bash
netty ip
```

- Detalles de interfaces locales (IPv4, IPv6, MAC)
- Gateway y DNS
- IP pública y geolocalización
- ISP y ciudad/región/país

## Datos y configuración

### Ubicación de archivos
```bash
~/.netty/
├── netty.log
├── config
└── results/
    ├── netty_report_20250626_143022.json
    └── netty_report_20250626_144512.csv
```

### Formatos de exportación
```bash
netty export json
netty export csv
netty export txt
```

Ejemplo JSON:

```json
{
  "timestamp": "2025-06-26T14:30:22Z",
  "network_info": {
    "interface": "en0",
    "ipv4": "192.168.1.105",
    "gateway": "192.168.1.1",
    "dns_servers": ["8.8.8.8", "1.1.1.1"]
  },
  "generated_by": "netty v1.1.0"
}
```

## Opciones de línea de comandos

```bash
netty [OPTIONS] [COMMAND]

OPTIONS:
  -h, --help              Mostrar ayuda
  -v, --version           Mostrar versión
  -q, --quiet             Modo silencioso
  -f, --format FORMAT     Formato de salida: table, json, csv
  -c, --continuous        Monitorización continua
  --log-file FILE         Ruta personalizada de log

COMMANDS:
  wifi                    Información WiFi
  speed                   Prueba de velocidad
  dns [action]            Gestión de DNS
  monitor                 Monitorización de red
  ip                      Información de IP y geolocalización
  ping HOST [count]       Ping avanzado
  export [format]         Exportar reporte
  info                    Información de interfaces
```

## Personalización y consejos

### Modo silencioso para scripts
```bash
netty -q speed > speed_results.txt
netty --quiet dns flush
```

### Monitorización continua
```bash
netty --continuous monitor
netty -c monitor | tee network_activity.log
```

### Ejemplos de integración
```bash
if netty ping github.com >/dev/null 2>&1; then
    echo "Conectividad confirmada"
    ./deploy.sh
fi

netty speed | grep "Download Speed" | awk '{print $3}'

netty dns flush && netty dns test
```

## Instalación con Homebrew

### Añadir el tap
```bash
brew tap jmeiracorbal/tools
```

### Instalar Netty
```bash
brew install netty
```

### Actualizar a la última versión
```bash
brew update
brew upgrade netty
```

### Desinstalar
```bash
brew uninstall netty
```

```
brew untap jmeiracorbal/tools
```

## Casos de uso

### Para desarrolladores
- Pruebas de API
- Monitorización de rendimiento
- Diagnóstico DNS
- Validación de red para trabajo remoto

### Para administradores de sistemas
- Diagnóstico rápido de red
- Pruebas de rendimiento periódicas
- Documentación de configuraciones
- Análisis en incidentes

### Para trabajadores remotos
- Validación de conexión
- Pruebas de velocidad
- Optimización WiFi
- Monitorización de estabilidad

### Para estudiantes e investigadores
- Aprendizaje de protocolos
- Exportación de métricas
- Investigación de conectividad
- Documentación técnica

## Privacidad y seguridad

### Manejo de datos
- No se recopilan datos: Todo es local
- Sin dependencias externas
- Sin seguimiento ni analíticas
- Almacenamiento local únicamente

### Seguridad
- Operaciones de solo lectura
- Vaciar DNS seguro
- No requiere sudo para la mayoría de funciones
- Operaciones transparentes

## Detalles técnicos

### Requisitos
- macOS Monterey (12.0) o superior
- Intel y Apple Silicon
- Interfaz WiFi o Ethernet
- Solo utilidades estándar de macOS

### Impacto en el rendimiento
- Uso de CPU: Mínimo (< 1%)
- Memoria: ~2-5MB
- Red: Solo durante pruebas
- Almacenamiento: < 1MB

### Compatibilidad
- Terminal.app, iTerm2, etc.
- Bash (macOS)
- WiFi, Ethernet, USB, VPN
- macOS 12.0+

## Contribuir

¡Contribuciones bienvenidas! El objetivo es ser una herramienta de referencia para usuarios de macOS.

### Áreas de contribución
- Nuevas utilidades de red
- Reportes mejorados
- Integraciones
- Mejoras de UI
- Documentación

### Desarrollo
```bash
git clone https://github.com/jmeiracorbal/netty.git

cd netty
chmod +x netty.sh
./netty.sh --help
```

### Pruebas
```bash
./netty.sh wifi
./netty.sh speed  
./netty.sh dns test
./netty.sh export json
```

## Licencia

Este proyecto está bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## FAQ

**¿Por qué crear otra herramienta de red si macOS ya tiene utilidades?**  
Netty ofrece una interfaz unificada y fácil de usar que combina varias herramientas con mejor formato de salida y funciones adicionales como geolocalización y pruebas de velocidad.

**¿Requiere permisos de administrador?**  
La mayoría de funciones no requieren sudo. Solo vaciar la caché DNS lo requiere y la herramienta lo indicará.

**¿Puedo usarlo en redes corporativas?**  
Sí. Netty solo realiza operaciones de solo lectura y no modifica configuraciones sin acción explícita.

**¿Qué tan precisos son los resultados de velocidad?**  
Las pruebas usan descargas reales y ping a varios servidores. Los resultados deberían estar dentro del 10-15% de herramientas dedicadas.

**¿Puedo automatizarlo en scripts?**  
Sí. Usa la opción --quiet para salida mínima y verifica los códigos de salida.

**¿En qué se diferencia de otras herramientas?**  
Netty se enfoca en facilidad de uso, salida clara, registro completo y optimizaciones para macOS.

## Roadmap

### Versión 1.1
- [ ] Escaneo de puertos
- [ ] Monitorización por aplicación
- [ ] Historial y gráficos
- [ ] Pruebas de DNS personalizadas

### Versión 1.2  
- [ ] Detección y análisis de VPN
- [ ] Gestión de perfiles de red
- [ ] Notificaciones del sistema
- [ ] Dashboard web

### Versión 2.0
- [ ] App con GUI
- [ ] Sincronización en la nube
- [ ] Escaneo de seguridad avanzado
- [ ] Funciones para equipos

## Proyectos relacionados

- [Mac Optimizer](https://github.com/jmeiracorbal/mac-optimizer)
- [Cloud Storage Symlinks](https://github.com/jmeiracorbal/cloud-storage-symlinks)
- [Pomodoro Timer](https://github.com/jmeiracorbal/pomodoro-timer)
