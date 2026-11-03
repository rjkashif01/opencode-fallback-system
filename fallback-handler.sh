#!/bin/bash
# Automatic Model Fallback Handler for opencode
#
# Reihenfolge:
#   1. Aktuelles Modell pruefen
#   2. Wenn erschöpft: ALLE Gratis-Modelle (:free) durchprobieren
#   3. Wenn keine Gratis-Modelle mehr gehen: Abo/Credits pruefen
#   4. Nur dann (mit Nachfrage) zu einem kostenpflichtigen Modell wechseln
#
# Vor jedem Wechsel wird gefragt (konfigurierbar in fallback-config.json).
#
# Aufruf:  ./fallback-handler.sh [--force] [--auto-free]
#   --force      aktueller Modell-Check ueberspringen (Simulation)
#   --auto-free  bei Gratis-Modellen NICHT nachfragen, direkt wechseln

CONFIG="/home/raja/.opencode/fallback-config.json"
[ -f "$CONFIG" ] || CONFIG="$(dirname "$0")/fallback-config.json"
AUTH_FILE="/home/raja/.local/share/opencode/auth.json"
OPENCODE_CFG=$(jq -r '.opencode_config' "$CONFIG")
LOG_FILE="/home/raja/.opencode/usage-log.json"
STATE_FILE=$(jq -r '.monitoring.state_file' "$CONFIG")
MAX_TOKENS=$(jq -r '.max_tokens_test // 5' "$CONFIG")

FORCE=false
AUTO_FREE=$(jq -r '.ask_before_switch_free | not' "$CONFIG")   # invertiert: true = nachfragen
ASPAID=$(jq -r '.ask_before_switch_paid' "$CONFIG")
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --auto-free) AUTO_FREE=true ;;
    esac
done

openrouter_key() {
    jq -r '.openrouter.key // empty' "$AUTH_FILE" 2>/dev/null
}

current_model() {
    sed -n 's/^[[:space:]]*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$OPENCODE_CFG" | head -1
}

# Gibt Session-ID zurueck, wenn Modell erreichbar (200); sonst leer
test_model() {
    local model="$1"
    local code
    code=$(curl -s -o /tmp/fr-test.json -w "%{http_code}" --max-time 30 \
        -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $(openrouter_key)" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"$model\",\"max_tokens\":$MAX_TOKENS,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}")
    echo "$code"
}

log_event() {
    local type="$1" model="$2" detail="$3"
    jq -e . "$STATE_FILE" >/dev/null 2>&1 || echo '{}' > "$STATE_FILE"
    jq --arg t "$type" --arg m "$model" --arg d "$detail" --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
       '.events = (.events // []) + [{time: $ts, type: $t, model: $m, detail: $d}] | .events = .events[-50:]' \
       "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

register_failure() {
    local model="$1"
    jq -e . "$STATE_FILE" >/dev/null 2>&1 || echo '{}' > "$STATE_FILE"
    jq --arg m "$model" --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
       '.failed_today = ((.failed_today // []) + [{model: $m, time: $ts}])
        | .failed_today = (.failed_today | map(select(.time >= (now | strftime("%Y-%m-%d") | "\(.)T00:00:00Z"))))
        | .failed_today = .failed_today[-100:]' \
       "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

already_failed_today() {
    jq -r --arg m "$1" --arg t "$(date -u '+%Y-%m-%dT00:00:00Z')" \
       '.failed_today // [] | map(select(.model == $m and .time >= $t)) | length > 0' \
       "$STATE_FILE" 2>/dev/null
}

switch_model() {
    local new="$1"
    local full="openrouter/$new"
    cp "$OPENCODE_CFG" "$OPENCODE_CFG.bak-$(date +%Y%m%d-%H%M%S)"
    sed -i "s|^\([[:space:]]*\"model\"[[:space:]]*:[[:space:]]*\)\"[^\"]*\"|\1\"$full\"|" "$OPENCODE_CFG"
    [ "$(current_model)" = "$full" ]
}

ask_switch() {
    local new="$1" kind="$2"
    if [ "$kind" = "free" ] && [ "$AUTO_FREE" = "true" ]; then return 0; fi
    local prompt="    Wechsel zu [$kind] $new? [y/N] "
    [ "$kind" = "paid" ] && prompt="    ⚠️  Kostenpflichtig! Wechsel zu $new? [y/N] "
    read -r -p "$prompt" ANSWER || return 1
    [[ "$ANSWER" =~ ^[YyJj] ]]
}

excluded() {
    local id="$1"
    for pat in $(jq -r '.exclude_model_patterns[]' "$CONFIG"); do
        [[ "$id" == *"$pat"* ]] && return 0
    done
    return 1
}

# Alle :free-Modelle von OpenRouter abrufen (aktuelles Modell zuerst markiert)
free_models() {
    local current="$1"
    curl -s --max-time 30 "https://openrouter.ai/api/v1/models" 2>/dev/null \
      | jq -r '.data[] | select(.id | endswith(":free")) | select(.architecture.modality | test("text|image")) | .id' \
      | while read -r id; do
            excluded "$id" && continue
            [ "$id" = "$current" ] && continue
            echo "$id"
        done
}

paid_models() {
    local current="$1"
    # 1) Bevorzugte Liste aus der Config
    jq -r '.preferred_paid_models[]' "$CONFIG" | while read -r id; do
        [ "$id" = "$current" ] && continue
        echo "$id"
    done
    # 2) Weitere Paids als Reserve (nach Kontextlaenge absteigend sortiert)
    curl -s --max-time 30 "https://openrouter.ai/api/v1/models" 2>/dev/null \
      | jq -r '
          .data
          | map(select((.id | endswith(":free")) | not))
          | map(select(((.pricing.prompt // "0") | tonumber) > 0))
          | sort_by(.context_length // 0) | reverse
          | .[].id' 2>/dev/null \
      | while read -r id; do
            excluded "$id" && continue
            already_listed "$id" "$current" && continue
            echo "$id"
        done
}

already_listed() {
    local id="$1"
    jq -r '.preferred_paid_models[]' "$CONFIG" | grep -qx "$id"
}

subscription_ok() {
    # Abo/Credits pruefen: is_free_tier=false UND (limit null ODER limit > usage)
    local info
    info=$(curl -s --max-time 30 -H "Authorization: Bearer $(openrouter_key)" "https://openrouter.ai/api/v1/key")
    local free_tier usage limit
    free_tier=$(echo "$info" | jq -r 'if .data.is_free_tier == false then "false" else "true" end')
    usage=$(echo "$info" | jq -r '.data.usage // 0')
    limit=$(echo "$info" | jq -r '.data.limit // "null"')
    if [ "$free_tier" = "false" ]; then
        if [ "$limit" = "null" ] || python3 -c "exit(0 if $usage < $limit else 1)" 2>/dev/null; then
            echo "$info" | jq -r '"    💳 Abo aktiv – genutzt: $\(.data.usage | tostring | .[0:6])$, Limit: \(if .data.limit == null then "unbegrenzt" else (.data.limit|tostring) end)"'
            return 0
        fi
    fi
    return 1
}

# ---------------- Main ----------------

CURRENT=$(current_model)
[ -z "$CURRENT" ] && { echo "❌ Konnte aktuelles Modell aus $OPENCODE_CFG nicht lesen"; exit 1; }
CURRENT="${CURRENT#openrouter/}"
echo "🔍 Aktuelles Modell: $CURRENT"

if [ "$FORCE" != "true" ]; then
    CODE=$(test_model "$CURRENT")
    if [ "$CODE" = "200" ]; then
        echo "✅ $CURRENT funktioniert"
        exit 0
    fi
    echo "⚠️  $CURRENT nicht verfügbar (HTTP $CODE) – Starte Fallback"
    register_failure "$CURRENT"
fi

# --- Stufe 1: alle Gratis-Modelle ---
echo ""
echo "🆓 Stufe 1: Gratis-Modelle durchprobieren..."
FOUND=""
for m in $(free_models "$CURRENT"); do
    [ "$FOUND" != "" ] && break
    CODE=$(test_model "$m")
    if [ "$CODE" = "200" ]; then
        echo "  ✔ funktioniert: $m"
        if ask_switch "$m" "free"; then
            if switch_model "$m"; then
                echo "✅ Gewechselt zu: $m"
                log_event "switch_free" "$m" "HTTP-Test ok"
                exit 0
            fi
        else
            echo "  ✗ übersprungen (abgelehnt)"
        fi
        FOUND="done"   # nur Erstbestes anbieten; weitere erst nach erneutem Lauf
    else
        register_failure "$m"
        echo "  ✗ $m (HTTP $CODE)"
    fi
done
[ -z "$FOUND" ] && echo "  ❌ Kein Gratis-Modell verfügbar"

# --- Stufe 2: Paid-Modelle, nur wenn Abo ---
echo ""
echo "💎 Stufe 2: Kostenpflichtige Modelle (Abo-Prüfung)..."
if subscription_ok; then
    for m in $(paid_models "$CURRENT"); do
        echo "  → Kandidat: $m"
        if ! ask_switch "$m" "paid"; then
            echo "  ✗ übersprungen (abgelehnt)"
            continue
        fi
        # Kurzer Test (kostet nur wenige Tausendstel-Cent bei max_tokens=5)
        CODE=$(test_model "$m")
        if [ "$CODE" = "200" ]; then
            if switch_model "$m"; then
                echo "✅ Gewechselt zu PAID: $m"
                log_event "switch_paid" "$m" "Abo aktiv, HTTP ok"
                exit 0
            fi
        else
            echo "  ✗ $m nicht verfügbar (HTTP $CODE)"
            register_failure "$m"
        fi
    done
    echo "❌ Kein Paid-Modell übernommen"
else
    echo "  ❌ Kein Abo/Credits gefunden – nur Gratis-Modelle möglich"
fi

echo ""
echo "⏳ Empfehlung: Warten bis das Free-Tier-Reset (i.d.R. UTC-Mitternacht) oder 'opencode' neu starten."
exit 1
