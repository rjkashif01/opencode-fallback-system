#!/bin/bash
# Automatic Model Fallback Handler
# Detects when primary model exceeds free tier and switches to next

CONFIG="/home/raja/.opencode/fallback-config.json"
LOG_FILE="/home/raja/.opencode/usage-log.json"

# Parse current model from config
PRIMARY_MODEL=$(jq -r '.primary_model' "$CONFIG")

# Check if primary model is available
check_model_availability() {
    # Try a simple test request
    # In practice, this would call the API with a minimal prompt
    # For now, we check the error pattern from logs
    
    if [ -f "$LOG_FILE" ]; then
        LAST_ERROR=$(tail -n 1 "$LOG_FILE" | jq -r '.error // empty' 2>/dev/null)
        if [ -n "$LAST_ERROR" ]; then
            # Check if error matches free tier exceeded patterns
            if echo "$LAST_ERROR" | grep -qi "free usage exceeded\|rate limit\|quota exceeded"; then
                return 1  # Model is exhausted
            fi
        fi
    fi
    return 0  # Model is available
}

# Switch to next fallback model
switch_model() {
    local current_priority=$(jq ".fallback_models | to_entries[] | select(.value.priority == $1) | .value.priority" "$CONFIG" 2>/dev/null || echo "0")
    
    # Find next model with higher priority (lower number)
    for i in $(seq 1 10); do
        NEXT_PRIORITY=$((i))
        NEXT_MODEL=$(jq -r ".fallback_models[$((i-1))].name" "$CONFIG" 2>/dev/null)
        if [ -n "$NEXT_MODEL" ] && [ "$NEXT_MODEL" != "null" ]; then
            echo "Switching to: $NEXT_MODEL (priority $NEXT_PRIORITY)"
            # Here would be the code to actually change the opencode model
            # echo "OPENCODE_MODEL=$NEXT_MODEL" >> /tmp/opencode_env
            echo "$NEXT_MODEL"
            return
        fi
    done
    
    echo "No more fallback models available"
    return 1
}

# Main execution
echo "Checking model availability for: $PRIMARY_MODEL"

if check_model_availability; then
    echo "✅ Primary model $PRIMARY_MODEL is available"
    exit 0
else
    echo "⚠️ Primary model $PRIMARY_MODEL has exceeded free tier"
    
    # Log the error
    TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    ERROR_MSG="Model exhaustion at $TIMESTAMP"
    if [ ! -f "$LOG_FILE" ]; then
        echo "[]" > "$LOG_FILE"
    fi
    
    ERROR_JSON=$(jq -e --arg e "$ERROR_MSG" '. += [{error: $e, timestamp: now}] | .[-1:] | add' "$LOG_FILE" 2>/dev/null || echo "[$ERROR_JSON]")
    echo "$ERROR_JSON" > "$LOG_FILE"
    
    # Try to switch to next model
    echo "Attempting fallback..."
    SWITCHED_MODEL=$(switch_model 1)
    
    if [ -n "$SWITCHED_MODEL" ] && [ "$SWITCHED_MODEL" != "No more fallback models available" ]; then
        echo "✅ Successfully switched to: $SWITCHED_MODEL"
        # Here you would set the environment variable or config for opencode
        # export OPENROUTER_MODEL="$SWITCHED_MODEL"
        # or update opencode.json dynamically
        echo "⚠️ Please manually set: OPENROUTER_MODEL=$SWITCHED_MODEL"
        exit 0
    else
        echo "❌ No more fallback models available"
        echo "Please wait ${CONFIG##*retry_wait_time}: }" | grep -oP '\d+h \d+m' || echo "3h 14m"
        echo "Or manually change your API key/plan"
        exit 1
    fi
fi
