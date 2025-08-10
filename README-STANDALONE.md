# ZSH Terminal Standalone Installer

## Descripción

Este es un instalador autocontenido para ZSH Terminal que incluye todos los archivos necesarios embebidos dentro del script. No requiere descargar el repositorio completo para funcionar.

## Características

- **Autocontenido**: Todos los archivos necesarios están embebidos en el script
- **Sin dependencias externas**: No necesita descargar el repositorio
- **Multiplataforma**: Compatible con Ubuntu, CentOS, Fedora y macOS
- **Instalación completa**: Incluye ZSH, Oh My ZSH, Powerlevel10k, plugins y configuración personalizada
- **Modo interactivo y automatizado**: Soporta ambos modos de instalación
- **Verificación de instalación**: Incluye herramientas de verificación
- **Logging completo**: Registra todas las operaciones

## Componentes Incluidos

### Software Principal
- **ZSH**: Shell avanzado
- **Oh My ZSH**: Framework para ZSH
- **Powerlevel10k**: Tema moderno y rápido
- **Fuentes MesloLGS NF**: Fuentes optimizadas para el tema

### Plugins
- **zsh-syntax-highlighting**: Resaltado de sintaxis en tiempo real
- **zsh-autosuggestions**: Sugerencias automáticas basadas en historial
- **alias-tips**: Recordatorios de aliases disponibles

### Configuración Personalizada
- **Aliases de Git**: Comandos Git personalizados
- **Aliases de Shell**: Comandos de sistema útiles
- **Variables de entorno**: Configuración de directorios comunes
- **Aliases de C++**: Preparado para desarrollo en C++

## Uso

### Descarga del Ejecutable

```bash
# Opción 1: Descargar directamente (si está disponible en un servidor)
wget https://tu-servidor.com/zsh-installer-standalone.sh
chmod +x zsh-installer-standalone.sh

# Opción 2: Copiar desde el repositorio local
cp /ruta/al/repositorio/zsh-installer-standalone.sh .
chmod +x zsh-installer-standalone.sh
```

### Instalación Completa (Recomendada)

```bash
# Modo automatizado - instalación completa
./zsh-installer-standalone.sh --complete

# Modo interactivo
./zsh-installer-standalone.sh
# Luego selecciona la opción 1
```

### Instalaciones Específicas

```bash
# Solo ZSH y Oh My ZSH
./zsh-installer-standalone.sh --zsh-only

# Verificar instalación existente
./zsh-installer-standalone.sh --verify

# Mostrar ayuda
./zsh-installer-standalone.sh --help
```

### Modo Interactivo

Ejecuta el script sin parámetros para acceder al menú interactivo:

```bash
./zsh-installer-standalone.sh
```

Opciones disponibles:
1. **Instalación Completa** (Recomendada)
2. **Instalar ZSH y Oh My ZSH solamente**
3. **Instalar tema Powerlevel10k**
4. **Instalar plugins de ZSH**
5. **Instalar configuración personalizada**
6. **Verificar instalación actual**
7. **Salir**

## Requisitos del Sistema

### Requisitos Mínimos
- **Bash 4.0+**: Para compatibilidad del script
- **Usuario no-root**: Por seguridad
- **Acceso sudo**: Para instalación de paquetes (opcional)
- **Conexión a internet**: Para descargar componentes

### Sistemas Operativos Soportados
- **Ubuntu/Debian**: Con apt package manager
- **CentOS/RHEL**: Con yum package manager
- **Fedora**: Con dnf package manager
- **macOS**: Con o sin Homebrew
- **Otros Linux**: Instalación manual de dependencias

### Dependencias Automáticas
El script instalará automáticamente:
- `zsh`
- `git`
- `wget` o `curl`
- `fonts-powerline` (en sistemas que lo soporten)

## Estructura de Archivos Creados

Después de la instalación, se crearán los siguientes archivos y directorios:

```
$HOME/
├── .oh-my-zsh/                     # Oh My ZSH framework
│   └── custom/
│       ├── themes/powerlevel10k/   # Tema Powerlevel10k
│       └── plugins/                # Plugins adicionales
│           ├── zsh-syntax-highlighting/
│           ├── zsh-autosuggestions/
│           └── alias-tips/
├── .config/zsh/                    # Configuración personalizada
│   ├── git_aliases.zsh
│   ├── shell_aliases.zsh
│   ├── environment.zsh
│   └── cpp_aliases.zsh
├── .zshrc                          # Configuración principal de ZSH
└── .local/
    ├── log/zsh-install/            # Logs de instalación
    └── backup/zsh-install/         # Respaldos automáticos
```

## Configuración Post-Instalación

### Activar ZSH

Después de la instalación:

```bash
# Opción 1: Reiniciar terminal
exit
# Abrir nueva terminal

# Opción 2: Cambiar a ZSH inmediatamente
exec zsh
```

### Configurar Powerlevel10k

La primera vez que ejecutes ZSH con Powerlevel10k:

1. Se ejecutará automáticamente el asistente de configuración
2. Sigue las instrucciones en pantalla
3. Selecciona las opciones que prefieras para el prompt

### Personalizar Configuración

Los archivos de configuración personalizada están en `~/.config/zsh/`:

```bash
# Editar aliases de Git
vim ~/.config/zsh/git_aliases.zsh

# Editar aliases de Shell
vim ~/.config/zsh/shell_aliases.zsh

# Editar variables de entorno
vim ~/.config/zsh/environment.zsh

# Editar aliases de C++
vim ~/.config/zsh/cpp_aliases.zsh
```

## Aliases Incluidos

### Git
- `arbolito`: Muestra el log de git en formato gráfico

### Shell
- `zshconfig`: Edita .zshrc
- `ohmyzshconfig`: Edita configuración de Oh My ZSH
- `showpath`: Muestra la variable PATH
- `delforce`: Elimina archivos/directorios forzadamente

### Gestión de Paquetes (Ubuntu/Debian)
- `installApt`: Instala paquetes con apt
- `installSnap`: Instala paquetes con snap
- `removeApt`: Remueve paquetes con apt
- `removeSnap`: Remueve paquetes con snap

## Solución de Problemas

### Problemas Comunes

#### Error: "Bash version too old"
```bash
# Actualizar Bash (Ubuntu/Debian)
sudo apt update && sudo apt install bash

# Verificar versión
bash --version
```

#### Error: "Sudo not available"
```bash
# Instalar sudo (si no está disponible)
su -c "apt install sudo"

# Agregar usuario al grupo sudo
su -c "usermod -aG sudo $USER"
```

#### Error: "Git not found"
```bash
# Instalar Git manualmente
sudo apt install git  # Ubuntu/Debian
sudo yum install git   # CentOS/RHEL
sudo dnf install git   # Fedora
brew install git       # macOS
```

#### Fuentes no se muestran correctamente
1. Instala las fuentes MesloLGS NF manualmente
2. Configura tu terminal para usar estas fuentes
3. Reinicia el terminal

### Logs y Debugging

Los logs se guardan en `~/.local/log/zsh-install/`:

```bash
# Ver el último log
ls -la ~/.local/log/zsh-install/
tail -f ~/.local/log/zsh-install/install_*.log
```

### Verificación de Instalación

```bash
# Ejecutar verificación
./zsh-installer-standalone.sh --verify

# Verificación manual
which zsh
ls -la ~/.oh-my-zsh
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k
ls -la ~/.oh-my-zsh/custom/plugins/
```

## Desinstalación

Para desinstalar completamente:

```bash
# Cambiar shell de vuelta a bash
chsh -s /bin/bash

# Remover archivos (CUIDADO: esto eliminará toda la configuración)
rm -rf ~/.oh-my-zsh
rm -rf ~/.config/zsh
rm ~/.zshrc

# Restaurar backup si existe
cp ~/.local/backup/zsh-install/.zshrc.backup.* ~/.zshrc
```

## Contribución

Este script standalone está basado en el proyecto original. Para contribuir:

1. Modifica el proyecto original
2. Regenera el script standalone
3. Prueba en diferentes sistemas
4. Envía pull request al repositorio original

## Licencia

Este proyecto mantiene la misma licencia que el proyecto original.

## Soporte

Para reportar problemas o solicitar características:

1. Verifica que el problema no esté en la sección de solución de problemas
2. Ejecuta `./zsh-installer-standalone.sh --verify` para diagnóstico
3. Incluye los logs relevantes al reportar el problema
4. Especifica tu sistema operativo y versión

---

**Nota**: Este es un instalador standalone que no requiere el repositorio completo. Todos los archivos necesarios están embebidos en el script para máxima portabilidad.