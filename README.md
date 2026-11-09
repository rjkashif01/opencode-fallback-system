# opencode Model Fallback System

Automatisches Wechseln von KI-Modellen, wenn das Free-Tier-Limit erreicht ist.

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open%20in%20GitHub%20Codespaces-7663bf?logo=github)](https://github.com/codespaces/new/rjkashif01/opencode-fallback-system)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ⚠️ Wichtig: API Key erforderlich

Dieses System benötigt einen **OpenRouter API Key** (kostenlos unter [openrouter.ai](https://openrouter.ai) registrieren). Ohne Key funktioniert das Fallback-System nicht.

## Quick-Start

```bash
# 1. Repository klonen
git clone https://github.com/rjkashif01/opencode-fallback-system.git

# 2. In Verzeichnis wechseln
cd opencode-fallback-system

# 3. Skripte berechtigen
chmod +x fallback-handler.sh opencode-fallback

# 4. API Key eintragen (siehe Konfiguration unten)
#    - Kopiere auth.json.template nach auth.json
#    - Füge deinen OpenRouter Key ein

# 5. System testen
./fallback-handler.sh
```

## Installation

### Voraussetzungen

- **Node.js** (empfohlen: v20+)
- **opencode** installiert
- **jq** für JSON-Verarbeitung: `sudo apt install jq` (Linux/Mac)
- **OpenRouter API Key** (kostenlos unter [openrouter.ai](https://openrouter.ai) registrieren)

### Schrittt für Schritt

```bash
# Repository klonen
git clone https://github.com/rjkashif01/opencode-fallback-system.git

# In Verzeichnis wechseln
cd opencode-fallback-system

# Skripte ausführbar machen
chmod +x fallback-handler.sh opencode-fallback

# Optional: Installations-Skript nutzen
./install.sh  # Falls vorhanden

# Konfiguration prüfen und anpassen
cat fallback-config.json

# System starten
./fallback-handler.sh
```

## Konfiguration

### `fallback-config.json`

Die zentrale Konfigurationsdatei. Wichtige Einstellungen:

```json
{
  "provider": "openrouter",
  "opencode_config": "/home/raja/.config/opencode/opencode.jsonc",
  "ask_before_switch_free": true,      # 'true' = nachfragen bei Gratis-Wechsel
  "ask_before_switch_paid": true,      # 'true' = nachfragen bei Paid-Wechsel
  "max_tokens_test": 5,                # Tokens für Test-API-Call
  "exclude_model_patterns": [
    "content-safety",
    "rerank",
    "embed"
  ],
  "preferred_paid_models": [
    "google/gemini-3.8-flash",
    "anthropic/claude-haiku-5.5",
    "anthropic/claude-sonnet-5.5",
    "anthropic/claude-opus-5.5"
  ],
  "monitoring": {
    "track_usage": true,
    "state_file": "/home/raja/.opencode/fallback-state.json"
  }
}
```

### `auth.json`

Speichere deinen OpenRouter API Key:

```json
{
  "openrouter": {
    "type": "api",
    "key": "sk-or-v1-dein-api-key-hier"
  }
}
```

**Hinweis:** Du kannst auch die Umgebungsvariable `OPENROUTER_KEY` setzen, anstelle der Datei zu bearbeiten.

### Modell-Auswahl

Das System wechselt automatisch in dieser Reihenfolge:

1. **Stufe 1:** Aktuelles Modell testen (falls bereits funktionsfähig)
2. **Stufe 2:** Alle `:free` Modelle von OpenRouter durchprobieren
3. **Stufe 3:** Bei aktivem APA/Credits: Bevorzugte Paid-Modelle testen
4. **Stufe 4:** Bei Erschöpfung: Nutzer um manuellen Wechsel bitten

## Nutzung

### Automatischer Modus (empfohlen)

```bash
# Prüft aktuelles Modell und wechselt bei Bedarf
./fallback-handler.sh

# Oder direkt mit Prompt (öffnet opencode mit Fallback-Logik)
./opencode-fallback "Dein Prompt hier"
```

### Manuelles Überwachen

```bash
# Logdatei mit Fehlern und Wechseln anzeigen
cat ~/.opencode/usage-log.json

# Aktuellen Status des Fallback-Systems
cat ~/.opencode/fallback-state.json
```

### Umgebung variablen (Alternative zu Dateien)

```bash
export OPENROUTER_KEY=sk-or-v1-dein-key
export OPENCODE_CFG=/home/raja/.config/opencode/opencode.jsonc
./fallback-handler.sh
```

## Unterstützte Modelle (Free Tier)

| Modell | Anbieter | Free Tier |
|--------|----------|-----------|
| `nvidia/nemotron-3.5-lightning:free` | NVIDIA | Unbegrenzt (dieses Repo) |
| `glm-4` | GLM | Unbegrenzt |
| `phi-3-mini` | Microsoft | 8k Tokens täglich |
| `qwen/qwen3.8-27b:free` | Qwen | Oft überlastet (429 errors) |

## Fehlerbehebung

### Häufige Probleme

1. **"Free usage exceeded" Fehler**
   - Lösung: Warten Sie das Reset (i.d.R. UTC-Mitternacht) oder wechseln Sie manuell zum nächsten Modell
   - Nutzen Sie `--auto-free` Flag, um automatisches Wechseln ohne Nachfrage zu erzwingen

2. **"Could not read current model"**
   - Lösung: Stellen Sie sicher, dass `opencode.jsonc` ein gültiges `model` Feld hat

3. **API Key Fehler**
   - Lösung: Prüfen Sie `auth.json` auf gültigen Key oder setzen Sie `OPENROUTER_KEY` Umgebungvariable

4. **Keine Modelle verfügbar**
   - Lösung: Alle Free-Tier-Modelle sind erschöpft. Warten Sie das Reset ab oder upgraden Sie Ihren Plan

### Logdateien analysieren

- `~/.opencode/usage-log.json` - Alle Fehler und Modell-Wechsel chronologisch
- `~/.opencode/fallback-state.json` - Aktueller Status und letzte Änderungen

## Beiträge

Willkommen! Sie können beitragen durch:

- Hinzufügen weiterer Fallback-Modelle
- Verbesserung der Erkennungslogik
- Verbesserung der Dokumentation
- Behebung von Bugs
- Erstellen von Issues für Feature-Wünsche

Fügen Sie einfach ein Issue oder Pull Request im GitHub Repository ein.

## Lizenz

MIT License - nutzen und weiterverbreiten nach Belieben.

Copyright (c) 2026 rjkashif01

## Kontakt

Für Fragen öffnen Sie ein Issue im GitHub Repository: https://github.com/rjkashif01/opencode-fallback-system

---

*Letzte Aktualisierung: November 2026*