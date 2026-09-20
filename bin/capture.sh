#!/usr/bin/env bash
# capture.sh ocr|qr|color - screen region to clipboard
# Wayland-native (grim/slurp or the GNOME portal) with an X11 fallback.
set -euo pipefail

# shellcheck source=bin/hw-profile.sh
source "$(dirname "$(readlink -f "$0")")/hw-profile.sh"

case "${1:-}" in
  ocr)
    screenshot_region | tesseract stdin stdout 2> /dev/null | clip_copy
    notify-send "OCR" "Text copied to clipboard"
    ;;
  qr)
    out=$(screenshot_region | zbarimg --quiet - | sed 's/^[^:]*://')
    printf '%s' "$out" | clip_copy
    notify-send "QR" "$out"
    ;;
  color)
    # hyprpicker-style pickers are Wayland-only; gpick and xcolor are X11
    if is_wayland && command -v hyprpicker > /dev/null 2>&1; then
      out=$(hyprpicker -a -f hex)
    elif command -v gpick > /dev/null 2>&1; then
      out=$(gpick -pso 2> /dev/null)
    elif command -v xcolor > /dev/null 2>&1; then
      out=$(xcolor)
    else
      notify-send -u critical "Color" "No picker installed"
      exit 1
    fi
    printf '%s' "$out" | clip_copy
    notify-send "Color" "$out"
    ;;
  *)
    echo "Usage: capture.sh ocr|qr|color"
    exit 1
    ;;
esac
