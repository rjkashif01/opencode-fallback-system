# opencode Model Fallback System

Automatisches Wechseln von KI-Modellen, wenn das Free-Tier-Limit erreicht ist.

## Problem
Wenn KI-Modelle wie `glm-5.3-flash` ihr kostenloses Kontingent überschreiten, bricht die API mit der Meldung "Free usage exceeded" ab. Benutzer müssen warten oder manuell das Modell wechseln.

## Lösung
Dieses System erkennt automatisch, wenn das Free-Level erreicht ist, und wechselt nahtlos zu einem alternativen kostenlosen Modell.

## Installation

```bash
# Repository klonen
git clone https://github.com/your-username/opencode-fallback-system.git

# In das Verzeichnis wechseln
cd opencode-fallback-system

# Konfigurationsdatei prüfen und anpassen
cat fallback-config.json
```

## Einrichtung

1. **Konfigurationsdatei anpassen**: `fallback-config.json` an Ihre Bedürfnisse anpassen
2. **Skripte berechtigen**: `chmod +x fallback-handler.sh opencode-fallback`
3. **Verwendung**: Siehe `USAGE.md`

## Dateien

### `fallback-config.json`
Die zentrale Konfigurationsdatei mit:
- Primary Model Einstellungen
- Fallback Modelle Liste
- Fehlererkennung Mustern
- Monitoring Optionen

### `fallback-handler.sh`
Shell-Skript, das erkennt, wenn das Free-Level erreicht ist, und zum nächsten Modell wechselt.

### `opencode-fallback`
Wrapper-Skript, das opencode aufruft und Fallback-Logik hinzufügt.

## Verwendung

### Automatischer Modus
```bash
./opencode-fallback "Ihr Prompt hier"
```

Manuelles Überwachen:
```bash
# Logdatei prüfen
cat usage-log.json

# Manuelles Modell wechseln
# Exportieren Sie die Umgebung variable:
export OPENROUTER_MODEL=glm-4
```

## Unterstützte Modelle

| Modell | Typ | Free Tier |
|--------|-----|-----------|
| glm-5.3-flash | GLM | Täglich begrenzt |
| glm-4 | GLM | Unbegrenzt |
| phi-3-mini | Microsoft | 8k Tokens täglich |
| nemotron | NVIDIA | Unbegrenzt |
| gpt-3.5-turbo | OpenAI | 10k Tokens monatlich |

## Lizenz

MIT License - nutzen und weiterverbreiten nach Belieben.

## Kontakt

Fragen und Beiträge sind willkommen. Erstellen Sie einfach ein Issue im Repository.
