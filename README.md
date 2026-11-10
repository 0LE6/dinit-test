# Migrar i3 de EndeavourOS a Artix Linux con dinit

Esta guía corresponde a la configuración adaptada a partir de `i3(1).zip`, el segundo archivo enviado. Descarga [i3-artix-dinit.zip](https://chatgpt.com/library?file_id=libfile_aecc9ccde0e08191abf102ea4bc29514&account_id=personal) y guarda el ZIP junto a esta guía.

El ZIP conserva la carpeta raíz `i3/`, los nombres de los archivos que siguen en uso y su orden relativo. De los 26 scripts originales, se conservaron 18, se retiraron 8 y se añadió uno.

## 1. Comprobar qué tienes instalado

Ejecuta esto en Artix. `pacman -Q` consulta los paquetes instalados y `pacman -Si` consulta las bases locales de los repositorios configurados. Estos comandos son de solo lectura.

```bash
ps -p 1 -o comm=
pacman-conf --repo-list

for p in \
  i3-wm i3blocks i3lock xss-lock dex rofi alacritty firefox thunar \
  dunst libnotify polkit-gnome glib2 gsettings-desktop-schemas \
  noto-fonts ttf-nerd-fonts-symbols \
  xorg-server xorg-xinit xorg-xset xorg-xsetroot \
  scrot flameshot imagemagick feh yad brightnessctl \
  libpulse pavucontrol playerctl jq iproute2 python acpi unzip \
  dbus-dinit elogind-dinit \
  power-profiles-daemon power-profiles-daemon-dinit \
  pipewire pipewire-pulse wireplumber \
  pipewire-dinit pipewire-pulse-dinit wireplumber-dinit \
  dbus-dinit-user userspawn-dinit turnstile-dinit \
  networkmanager networkmanager-dinit nm-connection-editor networkmanager-dmenu \
  bluez bluez-utils bluez-dinit dmenu bc; do
    pacman -Q "$p" 2>/dev/null ||
      if pacman -Si "$p" >/dev/null 2>&1; then
        printf 'Disponible, falta instalar: %s\n' "$p"
      else
        printf 'No aparece en tus repositorios configurados: %s\n' "$p"
      fi
done

pacman -Q brave-bin rofi-greenclip rofi-bluetooth-git 2>/dev/null

sudo dinitctl status dbus
sudo dinitctl status elogind
loginctl session-status
dinitctl --user list
pactl info
brightnessctl -l
powerprofilesctl list
```

Si ya usas un helper de AUR, puedes consultar los tres paquetes opcionales con `yay -Si brave-bin rofi-greenclip rofi-bluetooth-git`. Si `pactl info` ya conecta con PulseAudio o con PipeWire, conserva ese servidor de audio.

## 2. Instalar lo que falte

### Escritorio y funciones del ZIP

Este bloque instala i3, la barra, los lanzadores, las notificaciones, las fuentes, las capturas, los controles de audio y brillo y las dependencias de los scripts. Si ya tienes una sesión gráfica X11, puedes omitir `xorg-server`. Añade `xorg-xinit` si entras con `startx`.

```bash
sudo pacman -Syu --needed \
  i3-wm i3blocks i3lock rofi alacritty firefox thunar \
  dunst libnotify polkit-gnome glib2 gsettings-desktop-schemas \
  noto-fonts ttf-nerd-fonts-symbols \
  xorg-server xorg-xset xorg-xsetroot \
  scrot flameshot imagemagick yad brightnessctl \
  libpulse pavucontrol playerctl jq iproute2 python acpi unzip \
  dbus-dinit elogind-dinit
```

`xss-lock` y `dex` están en **`[extra]` de Arch**. El primero conecta el bloqueo de X11 con la inactividad y la suspensión. El segundo ejecuta los autoinicios XDG. Si `pacman -Si xss-lock dex` ya funciona, ve directamente al comando que instala esos dos paquetes. [xss-lock](https://archlinux.org/packages/extra/x86_64/xss-lock/) · [dex](https://archlinux.org/packages/extra/any/dex/)

Si falta `[extra]`, instala primero el soporte de Artix para paquetes de Arch.

```bash
sudo pacman -Syu --needed artix-archlinux-support
sudo pacman-key --populate archlinux
sudoedit /etc/pacman.conf
```

Añade estas dos líneas al final de `/etc/pacman.conf`, debajo de los repositorios de Artix, si todavía no están.

```ini
[extra]
Include = /etc/pacman.d/mirrorlist-arch
```

```bash
sudo pacman -Syu --needed xss-lock dex
```

### D-Bus y elogind

Comprueba primero su estado. Si falta activarlos, los nombres de arranque son `dbus` y `logind`. El servicio `logind` arranca `elogind` en el paquete de Artix. [Manual de dinitctl](https://davmac.org/projects/dinit/man-pages-html/dinitctl.8.html) · [Manual de loginctl de elogind](https://manpages.debian.org/unstable/elogind/loginctl.1.en.html)

```bash
sudo dinitctl enable dbus
sudo dinitctl enable logind
```

### Funciones opcionales

Ejecuta solo los bloques que correspondan a tu PC.

**Perfiles de energía**

```bash
sudo pacman -Syu --needed power-profiles-daemon power-profiles-daemon-dinit
sudo dinitctl enable power-profiles-daemon
powerprofilesctl list
```

**Bluetooth**

```bash
sudo pacman -Syu --needed bluez bluez-utils bluez-dinit
sudo dinitctl enable bluetoothd
bluetoothctl show
```

Para abrir el menú con el clic izquierdo en la barra, instala también `rofi-bluetooth-git` y `bc`. [rofi-bluetooth](https://github.com/nickclyde/rofi-bluetooth)

```bash
sudo pacman -Syu --needed bc
yay -S --needed rofi-bluetooth-git
```

**NetworkManager**

Si ya lo usas o lo has elegido para este PC:

```bash
sudo pacman -Syu --needed networkmanager networkmanager-dinit nm-connection-editor
sudo dinitctl enable NetworkManager
nmcli device status
```

Para el menú del clic izquierdo, instala los paquetes siguientes. Si falta el menú, ese clic abre `nm-connection-editor` cuando está instalado. [networkmanager-dmenu](https://archlinux.org/packages/extra/any/networkmanager-dmenu/)

```bash
sudo pacman -Syu --needed networkmanager-dmenu dmenu
```

**Fondo con imagen**

```bash
sudo pacman -Syu --needed feh
```

Copia tu imagen a `~/.config/i3/wallpaper.jpg` o `~/.config/i3/wallpaper.png`.

**Brave e historial del portapapeles**

Con un helper AUR ya instalado, elige los paquetes que quieras. Si prefieres compilarlos manualmente con `makepkg`, instala `base-devel` y `git`. [brave-bin](https://aur.archlinux.org/packages/brave-bin) · [Greenclip](https://wiki.archlinux.org/title/Greenclip)

```bash
yay -S --needed brave-bin rofi-greenclip
```

### PipeWire si todavía te falta un servidor de audio

Si `pactl info` falla y quieres configurar PipeWire, usa los servicios de usuario de dinit. Conserva tu gestor de sesión de usuario si ya funciona. Si partes de cero, `userspawn-dinit` puede iniciar dinit al entrar. El paquete declara conflicto con `turnstile-dinit`, así que si ya usas Turnstile, conserva ese gestor.

```bash
sudo pacman -Syu --needed \
  pipewire pipewire-pulse wireplumber \
  pipewire-dinit pipewire-pulse-dinit wireplumber-dinit

# Solo para una instalación sin gestor de sesión de usuario:
sudo pacman -Syu --needed userspawn-dinit dbus-dinit-user
```

Vuelve a iniciar sesión. Cuando `dinitctl --user list` funcione, ejecuta como tu usuario:

```bash
dinitctl --user enable pipewire
dinitctl --user enable wireplumber
dinitctl --user enable pipewire-pulse
pactl info
```

## 3. Validar e instalar la configuración del ZIP

Desde el directorio donde descargaste el ZIP, ejecuta este bloque. Valida la configuración antes de colocarla en `~/.config/i3`. Si esa carpeta ya existe, mueve el directorio entero a una copia de seguridad para evitar que se mezclen scripts antiguos y nuevos.

```bash
(
  set -eu
  stage=$(mktemp -d)
  trap 'rm -rf -- "$stage"' EXIT

  unzip -q ./i3-artix-dinit.zip -d "$stage"
  i3 -C -c "$stage/i3/config"
  mkdir -p "$HOME/.config"

  if [ -e "$HOME/.config/i3" ] || [ -L "$HOME/.config/i3" ]; then
    backup=$(mktemp -d "$HOME/.config/i3.backup.XXXXXXXX")
    mv -- "$HOME/.config/i3" "$backup/i3"
    printf 'Copia anterior en %s/i3\n' "$backup"
  fi

  mv -- "$stage/i3" "$HOME/.config/i3"
)
```

Cierra la sesión gráfica y vuelve a entrar para ejecutar todos los autoinicios. Si usas `startx`, conserva tu `.xinitrc` y asegúrate de que termine arrancando i3. Si la sesión carece de bus D-Bus, usa el que proporciona tu gestor de usuario. Con `dbus-dinit-user`, su socket es `$XDG_RUNTIME_DIR/bus`. En una sesión sin bus ni gestor de usuario, puedes iniciar i3 con `exec dbus-run-session i3`.

## 4. Qué cambió, archivo por archivo

| Archivo o parte | Cambios |
|---|---|
| `config` | Se retiraron ejemplos y alternativas comentadas. Se conservaron los espacios 1–10, los atajos para mover ventanas, las flechas, el teclado numérico con y sin Num Lock, los bordes de 1 px, los gaps a cero, la barra superior y la bandeja oculta. `new_window` pasó a `default_border`. Las líneas de color de la barra quedaron con tres campos. Se retiraron la regla duplicada de Blueberry y la específica de Pamac. La fuente queda en una sola línea con Maple Mono, Noto Sans y Symbols Nerd Font como alternativas. |
| `powermenu` | `loginctl` de elogind sustituye a `systemctl` para bloquear, suspender, hibernar, reiniciar y apagar. Cerrar sesión sigue llamando a `i3-msg exit`. Se añadió confirmación para cerrar sesión, reiniciar y apagar, y una notificación si falla una acción. Hibernar depende de la configuración del PC. |
| `blur-lock` | Conserva el desenfoque para el bloqueo manual y por inactividad. La captura se crea en un directorio temporal privado y el archivo se desvincula antes de lanzar i3lock. Si falla la captura o el desenfoque, se usa un fondo azul oscuro. Antes de suspender o hibernar, se usa directamente ese fondo y se transfiere a i3lock el descriptor con el que `xss-lock` retrasa la suspensión hasta el bloqueo. |
| `volume_brightness.sh`, `volume`, `audio-device-switch` | Los controles usan `pactl`, compatible con PulseAudio y con el servidor Pulse de PipeWire. Las teclas conservan el paso de 1 punto de volumen y 5 de brillo. El micrófono actúa sobre la entrada predeterminada. La barra conserva clic derecho para silenciar y rueda para ajustar 5 puntos. Al subir con la rueda ahora también se quita el silencio y se aplica el tope del 100 %. El cambio de salida admite identificadores de varios dígitos y mueve los flujos a la nueva salida cuando el servidor lo permite. |
| `cpu_usage`, `temperature`, `memory`, `disk`, `battery` | La CPU se calcula con dos muestras de `/proc/stat` y la RAM usa `MemAvailable` cuando existe. El disco sigue mostrando espacio libre en `/`. La temperatura usa la lectura más alta de los sensores de CPU reconocidos, con avisos a 70 y 90 °C. Si falta un sensor compatible, el bloque queda vacío. La batería conserva el promedio y la alerta crítica, ahora cuenta las baterías al 0 % y se oculta en equipos sin batería. |
| `network`, `bluetooth`, `calendar` | La red muestra el SSID activo con NetworkManager sin forzar un escaneo. Si no hay SSID, muestra la interfaz de la ruta por defecto. Se conservaron los clics de red y Bluetooth y el calendario junto al puntero. El bloque Bluetooth queda vacío si falta BlueZ o no hay controlador. |
| `power-profiles`, `ppd-status`, `i3blocks.conf` | El menú lista los perfiles que devuelve el daemon y muestra cuál está activo. La barra conserva los indicadores, separadores y acciones. Se corrigieron los iconos duplicados de disco, RAM y CPU. |
| `empty_workspace`, `keyhint-2`, `keybindings` | El espacio libre se busca en el JSON de i3 dentro del rango original 1–20. F1 abre en Rofi una chuleta buscable en español con los atajos reales, el teclado numérico y los clics de la barra. La chuleta es estática. Si cambias los atajos, actualiza también `keybindings`. |
| `import-gsettings`, `session` | Se conservó la importación de tema GTK, iconos, cursor y fuente. Ahora lee solo la sección `[Settings]` y comprueba que exista el esquema. El nuevo script `session` reúne el fondo, los lanzadores de Rofi, Brave con escala 1,2, Greenclip, Polkit y las capturas completas. Cada captura recibe un nombre único y la notificación indica dónde se guardó. |

Se eliminaron `gputemp`, `cputemp`, `keyhint`, `volume_brightness2.sh`, `battery-pinebook-pro`, `bandwidth2`, `openweather` y `vpn` tras revisar las llamadas activas y las referencias entre scripts del ZIP. `keyhint-2` sigue atendiendo F1, `temperature` sigue mostrando la temperatura de la barra y `volume_brightness.sh` sigue atendiendo las teclas de brillo y volumen. Se conservaron los avisos de autoría y licencia.

El ZIP original tampoco incluía el fondo `sakura2-resize.jpeg`, los temas `.rasi` de Rofi, la fuente Maple Mono ni los ajustes personales de Dunst y GTK que estaban fuera de `i3/`. Si los conservas en el PC anterior, puedes copiar los temas a `~/.config/rofi/` y el fondo a la ruta indicada. En ausencia de esos archivos, los menús usan el tema habitual de Rofi y el fondo es azul oscuro.

## 5. Verificación

Se validaron el ZIP, los permisos ejecutables y la configuración con `i3 -C` usando i3 4.25.1 de Artix. Se ejecutó i3blocks 1.5 de Artix, se comprobó su salida y se le envió un clic. También se probaron con comandos simulados la batería, los perfiles, la selección de salida, el brillo, la red, el menú de energía y las dos rutas de bloqueo.

Queda por comprobar en tu equipo el bloqueo real al suspender o hibernar, los permisos de brillo, la detección de sensores y los códigos del teclado numérico. Tras iniciar sesión, pulsa **Super+L**, desbloquea y luego suspende. Comprueba que al volver te pida contraseña.

Referencias de la configuración y el bloqueo. [Guía de i3](https://i3wm.org/docs/userguide.html) · [Documentación de i3blocks](https://vivien.github.io/i3blocks/) · [Manual de xss-lock](https://man.archlinux.org/man/xss-lock.1) · [Manual de i3lock](https://man.archlinux.org/man/extra/i3lock/i3lock.1.en)
