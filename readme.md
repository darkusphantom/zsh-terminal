# ZSH Terminal Installation Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Tests](https://img.shields.io/badge/Tests-BATS-blue.svg)](https://github.com/bats-core/bats-core)

Un script robusto y modular para instalar y configurar ZSH con Oh My ZSH, Powerlevel10k y plugins esenciales de manera segura y eficiente.

## 🚀 Características

- **Instalación automatizada** de ZSH, Oh My ZSH, Powerlevel10k y plugins
- **Detección automática del sistema operativo** (Ubuntu, Fedora, Arch Linux, macOS)
- **Arquitectura modular** con funciones reutilizables
- **Manejo robusto de errores** con logging estructurado
- **Validación de checksums** para descargas seguras
- **Sistema de respaldos** automático
- **Tests automatizados** con BATS
- **Configuración externa** fácilmente personalizable
- **Soporte para instalación no interactiva**

## 📋 Requisitos

- **Bash 4.0+**
- **Git**
- **Curl o Wget**
- **Conexión a Internet**
- **Permisos de usuario** (no ejecutar como root)

### Sistemas Operativos Soportados

- Ubuntu 18.04+
- Fedora 30+
- Arch Linux
- macOS 10.15+

## 🛠️ Instalación

### Instalación Rápida

```bash
# Clonar el repositorio
git clone https://github.com/tu-usuario/zsh-terminal.git
cd zsh-terminal

# Hacer ejecutable el script
chmod +x install.sh

# Ejecutar instalación interactiva
./install.sh
```

### Instalación No Interactiva

```bash
# Instalación completa automática
./install.sh --auto

# Instalación solo de ZSH y Oh My ZSH
./install.sh --zsh-only

# Instalación sin fuentes
./install.sh --no-fonts

# Instalación con modo verbose
./install.sh --verbose
```

### Opciones de Línea de Comandos

```bash
Usage: ./install.sh [OPTIONS]

Options:
  --auto, -a          Instalación automática completa
  --zsh-only          Instalar solo ZSH y Oh My ZSH
  --no-fonts          Omitir instalación de fuentes
  --no-plugins        Omitir instalación de plugins
  --verbose, -v       Modo verbose
  --force, -f         Forzar reinstalación
  --help, -h          Mostrar esta ayuda
  --version           Mostrar versión
```

## 📁 Estructura del Proyecto

```
zsh-terminal/
├── install.sh              # Script principal
├── config/
│   └── install.conf         # Configuración centralizada
├── lib/
│   ├── common.sh           # Funciones comunes
│   └── install.sh          # Funciones de instalación
├── tests/
│   ├── test_install.bats   # Tests automatizados
│   └── test_helper.bash    # Funciones helper para tests
├── .github/
│   └── workflows/
│       └── ci.yml          # CI/CD con GitHub Actions
├── docs/
│   ├── CONTRIBUTING.md     # Guía de contribución
│   ├── SECURITY.md         # Política de seguridad
│   └── CHANGELOG.md        # Registro de cambios
├── .shellcheckrc           # Configuración de ShellCheck
├── .pre-commit-config.yaml # Hooks de pre-commit
├── Dockerfile              # Imagen Docker para testing
└── README.md               # Este archivo
```

## ⚙️ Configuración

El archivo `config/install.conf` contiene todas las configuraciones del script:

```bash
# URLs y repositorios
OH_MY_ZSH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"

# Directorios
ZSH_CUSTOM_DIR="$HOME/.oh-my-zsh/custom"
LOG_DIR="$HOME/.zsh-install/logs"
BACKUP_DIR="$HOME/.zsh-install/backup"

# Opciones de instalación
CREATE_BACKUP="true"
VERBOSE_MODE="false"
FORCE_INSTALL="false"

# Timeouts y reintentos
DOWNLOAD_TIMEOUT="30"
MAX_RETRIES="3"
RETRY_DELAY="5"
```

## 🔧 Componentes Instalados

### ZSH y Oh My ZSH
- **ZSH**: Shell avanzado con características mejoradas
- **Oh My ZSH**: Framework para gestión de configuración ZSH

### Tema Powerlevel10k
- Tema altamente personalizable y rápido
- Configuración automática incluida
- Soporte para iconos y símbolos especiales

### Plugins Esenciales
- **zsh-autosuggestions**: Sugerencias automáticas basadas en historial
- **zsh-syntax-highlighting**: Resaltado de sintaxis en tiempo real
- **zsh-completions**: Completado automático mejorado
- **autojump**: Navegación rápida entre directorios

### Fuentes Nerd Fonts
- **Meslo LG Nerd Font**: Fuente optimizada para terminales
- Soporte completo para iconos y símbolos

## 🧪 Testing

### Ejecutar Tests

```bash
# Instalar BATS (si no está instalado)
sudo apt install bats  # Ubuntu/Debian
brew install bats-core # macOS

# Ejecutar todos los tests
bats tests/

# Ejecutar test específico
bats tests/test_install.bats

# Ejecutar con output verbose
bats --verbose-run tests/
```

### Tests Incluidos

- Detección de sistema operativo
- Validación de entrada
- Funciones de logging
- Validación de checksums
- Creación de respaldos
- Estructura del script
- Carga de configuración

## 🔒 Seguridad

### Características de Seguridad

- **No ejecutar como root**: Previene modificaciones del sistema
- **Validación de checksums**: Verifica integridad de descargas
- **Respaldos automáticos**: Protege configuraciones existentes
- **Validación de entrada**: Previene inyección de comandos
- **Logging seguro**: No registra información sensible

### Mejores Prácticas Implementadas

- Uso de `set -euo pipefail` para manejo estricto de errores
- Validación de todas las entradas del usuario
- Escape apropiado de variables
- Verificación de dependencias antes de la instalación
- Manejo seguro de archivos temporales

## 📊 Logging

El script genera logs detallados en `~/.zsh-install/logs/`:

```bash
# Ver logs de instalación
tail -f ~/.zsh-install/logs/install_$(date +%Y%m%d).log

# Ver logs de errores
grep ERROR ~/.zsh-install/logs/install_*.log

# Ver logs con timestamp
cat ~/.zsh-install/logs/install_*.log | grep "$(date +%Y-%m-%d)"
```

### Niveles de Log

- **INFO**: Información general del proceso
- **WARN**: Advertencias no críticas
- **ERROR**: Errores que requieren atención
- **DEBUG**: Información detallada (solo en modo verbose)

## 🐛 Solución de Problemas

### Problemas Comunes

#### Error: "Command not found"
```bash
# Verificar que las dependencias estén instaladas
./install.sh --check-deps

# Instalar dependencias manualmente
sudo apt update && sudo apt install git curl wget  # Ubuntu
brew install git curl wget                        # macOS
```

#### Error: "Permission denied"
```bash
# Asegurarse de no ejecutar como root
whoami  # No debe mostrar 'root'

# Verificar permisos del script
chmod +x install.sh
```

#### Error de descarga
```bash
# Verificar conexión a internet
ping -c 3 github.com

# Ejecutar con modo verbose para más detalles
./install.sh --verbose
```

### Logs de Debug

```bash
# Habilitar modo debug
export DEBUG=1
./install.sh --verbose

# Ver logs detallados
tail -f ~/.zsh-install/logs/debug_*.log
```

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -am 'Añadir nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Crea un Pull Request

### Desarrollo Local

```bash
# Instalar herramientas de desarrollo
sudo apt install shellcheck bats  # Ubuntu
brew install shellcheck bats-core # macOS

# Instalar pre-commit hooks
pip install pre-commit
pre-commit install

# Ejecutar linting
shellcheck install.sh lib/*.sh

# Ejecutar tests
bats tests/
```

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🙏 Agradecimientos

- [Oh My ZSH](https://ohmyz.sh/) - Framework ZSH
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Tema ZSH
- [Nerd Fonts](https://www.nerdfonts.com/) - Fuentes con iconos
- [BATS](https://github.com/bats-core/bats-core) - Framework de testing

## 📞 Soporte

Si encuentras algún problema o tienes preguntas:

1. Revisa la [documentación](docs/)
2. Busca en [issues existentes](https://github.com/tu-usuario/zsh-terminal/issues)
3. Crea un [nuevo issue](https://github.com/tu-usuario/zsh-terminal/issues/new)

---

**¿Te gusta este proyecto?** ⭐ ¡Dale una estrella en GitHub!

**¿Encontraste un bug?** 🐛 [Reporta el issue](https://github.com/tu-usuario/zsh-terminal/issues/new)

**¿Quieres contribuir?** 🤝 [Lee la guía de contribución](docs/CONTRIBUTING.md)
