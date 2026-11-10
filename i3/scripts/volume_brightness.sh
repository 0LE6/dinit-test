#!/bin/bash
# Original: https://gitlab.com/Nmoleo/i3-volume-brightness-indicator
# Adaptación para brightnessctl: joekamprad, agosto de 2025.
export LC_ALL=C
action=${1-}
step=${2:-1}
[[ $step =~ ^[1-9][0-9]?$ ]] || exit 2
sink=@DEFAULT_SINK@
source=@DEFAULT_SOURCE@

notify() {
    notify-send -a i3 -t 1000 -h "string:x-dunst-stack-tag:$1" "$2" "${3-}"
}

case "$action" in
    volume_up|volume_down|volume_mute)
        case "$action" in
            volume_up)
                volume=$(pactl get-sink-volume "$sink" | awk '/^Volume:/ {
                    for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+%$/ && $i+0>max) max=$i+0
                    print max+0
                }')
                [[ $volume =~ ^[0-9]+$ ]] || exit 1
                pactl set-sink-mute "$sink" 0 || exit 1
                if (( volume + step > 100 )); then
                    pactl set-sink-volume "$sink" 100%
                else
                    pactl set-sink-volume "$sink" "+$step%"
                fi
                ;;
            volume_down) pactl set-sink-volume "$sink" "-$step%" ;;
            volume_mute) pactl set-sink-mute "$sink" toggle ;;
        esac || { notify volume "Audio" "No se pudo cambiar el volumen"; exit 1; }
        label=$(env -u button -u BLOCK_BUTTON "$HOME/.config/i3/scripts/volume")
        value=$(pactl get-sink-volume "$sink" | awk '/^Volume:/ {
            for (i=1; i<=NF; i++) if ($i ~ /^[0-9]+%$/) {print $i+0; exit}
        }')
        notify-send -a i3 -t 1000 -h string:x-dunst-stack-tag:volume -h "int:value:${value:-0}" 'Volumen' "$label"
        ;;
    mic_mute)
        pactl set-source-mute "$source" toggle || exit 1
        case "$(pactl get-source-mute "$source")" in
            'Mute: yes') notify microphone 'Micrófono silenciado' ;;
            'Mute: no') notify microphone 'Micrófono activo' ;;
        esac
        ;;
    brightness_up|brightness_down)
        change=+5%
        [[ $action == brightness_down ]] && change=5%-
        if ! brightnessctl -q -c backlight set "$change"; then
            notify brightness 'Brillo no disponible' 'Comprueba el dispositivo y los permisos'
            exit 1
        fi
        value=$(brightnessctl -m -c backlight info | awk -F, 'NR==1 {print $4+0}')
        notify-send -a i3 -t 1000 -h string:x-dunst-stack-tag:brightness -h "int:value:${value:-0}" "Brillo ${value:-0}%"
        ;;
    *) exit 2 ;;
esac
