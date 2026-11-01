# Nutzungshilfe

## Schnellstart

1. Repository klonen
2. `fallback-config.json` anpassen
3. `chmod +x fallback-handler.sh opencode-fallback`
4. `./opencode-fallback "Ihr Prompt"`

## Fallback Logik

Das System prüft in folgender Reihenfolge:
1. Aktuelles Modell testen
2. Bei Fehler: Nächstes Modell in der Priority-Liste versuchen
3. Bei Erfolg: Neues Modell speichern und verwenden
4. Bei Misserfolg: Nächstes Modell versuchen

## Konfigurationsanpassung

### Eigenes Modell hinzufügen

Bearbeiten Sie `fallback-config.json` und fügen Sie ein neues Modell hinzu:

```json
{
  "fallback_models": [
    {...existing models...},
    {
      "name": "Ihr Modell",
      "type": "Ihr Anbieter",
      "free_tier": "Ihre Free Tier Beschreibung",
      "priority": 5
    }
  ]
}
```

### Prioritäten ändern

Die `priority` Zahl bestimmt die Reihenfolge:
- Niedrigere Zahl = Höhere Priorität (wird zuerst versucht)
- Höhere Zahl = Niedrigere Priorität (wird zuletzt versucht)

## Fehlerbehebung

### Häufige Probleme

1. **Keine Modelle verfügbar**: Alle Fallback-Modelle sind ebenfalls am Limit
   - Lösung: Warten Sie die Reset-Zeit ab oder upgraden Sie Ihren Plan

2. **Wechsel schlägt fehl**: Falsche Konfiguration
   - Lösung: Prüfen Sie `fallback-config.json` auf Tippfehler

3. **Wechsel passiert nicht**: Automatischer Erkennungsmechanismus funktioniert nicht
   - Lösung: Überwachen Sie `usage-log.json` manuell und wechseln Sie manuell

### Logdatei analysieren

```bash
cat ~/.opencode/usage-log.json
```

Zeigt alle Fehler und Modell-Wechsel chronologisch geordnet.

## Beiträge

Willkommen! Sie können beitragen durch:
- Hinzufügen weiterer Fallback-Modelle
- Verbesserung der Erkennungslogik
- Verbesserung der Dokumentation
- Behebung von Bugs

Fügen Sie einfach ein Issue oder Pull Request im Repository ein.

## Kontakt

Für Fragen öffnen Sie ein Issue im GitHub Repository.
