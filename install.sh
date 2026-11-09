#!/bin/bash
# Install script for opencode-fallback-system
# This script sets up the environment for the model fallback system

set -e

echo "🔧 Richte opencode-fallback-system ein..."

# Prüfe, ob jq installiert ist
if ! command -v jq &>/dev/null; then
    echo "❌ jq ist nicht installiert. Bitte installieren Sie es zuerst."
    echo "   Ubuntu/Debian: sudo apt install jq"
    echo "   macOS: brew install jq"
    exit 1
fi

echo "✅ jq gefunden"

# Prüfe, ob opencode installiert ist
if ! command -v opencode &>/dev/null; then
    echo "⚠️ opencode ist nicht im PATH gefunden."
    echo "   Stelle sicher, dass opencode installiert ist und im PATH steht."
fi

echo "✅ Prerequisites geprüft"

# Erstelle notwendige Verzeichnisse
mkdir -p ~/.opencode
mkdir -p ~/.local/share/opencode

echo "✅ Verzeichnisse erstellt: ~/.opencode, ~/.local/share/opencode"

# Mach Skripte ausführbar
chmod +x fallback-handler.sh opencode-fallback

echo "✅ Skripte sind jetzt ausführbar"

# Prüfe auf auth.json, falls nicht vorhanden Template erstellen
AUTH_FILE="/home/raja/.local/share/opencode/auth.json"
if [ ! -f "$AUTH_FILE" ]; then
    AUTH_TEMPLATE="/home/raja/opencode-fallback-system/auth.json.template"
    if [ -f "$AUTH_TEMPLATE" ]; then
        echo "ℹ️ auth.json nicht gefunden. Kopiere Template..."
        cp "$AUTH_TEMPLATE" "$AUTH_FILE"
        echo "✅ auth.json Template erstellt."
        echo "   Bitte öffne es und füge deinen OpenRouter API Key ein:"
        echo "   nano $AUTH_FILE"
    else
        echo "⚠️ Kein auth.json Template gefunden."
        echo "   Erstelle minimale Konfiguration..."
        jq -n --arg key "sk-or-v1-DEIN_KEY_HERE" \
            '{openrouter: {type: "api", key: $key}}' > "$AUTH_FILE"
        echo "✅ Minimale auth.json erstellt."
        echo "   Erinnere dich: Ersetze 'sk-or-v1-DEIN_KEY_HERE' durch deinen echten Key!"
    fi
else
    echo "✅ auth.json bereits vorhanden"
fi

# Prüfe opencode Konfiguration
OPENCODE_CFG="/home/raja/.config/opencode/opencode.jsonc"
if [ ! -f "$OPENCODE_CFG" ]; then
    echo "⚠️ opencode Konfiguration nicht gefunden unter $OPENCODE_CFG"
    echo "   Stelle sicher, dass opencode konfiguriert ist."
fi

echo ""
echo "========================================"
echo "✅ Einrichtung abgeschlossen!"
echo ""
echo "Nächste Schritte:"
echo "1. API Key in ~/.local/share/opencode/auth.json eintragen"
echo "2. Optional: ./fallback-handler.sh testen"
echo "3. Dokumentation in README.md lesen"
echo "========================================"