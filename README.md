# opencode Model Fallback System

Automatic switching of AI models when the Free-Tier limit is reached.

[![Open in GitHub Codespaces](https://img.shields.io/badge/Open%20in%20GitHub%20Codespaces-7663bf?logo=github)](https://github.com/codespaces/new/rjkashif01/opencode-fallback-system)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ⚠️ Important: API Key required

This system requires an **OpenRouter API Key** (free registration at [openrouter.ai](https://openrouter.ai)). Without a key, the fallback system will not work.

## Quick-Start

```bash
# 1. Clone the repository
git clone https://github.com/rjkashif01/opencode-fallback-system.git

# 2. Change to the directory
cd opencode-fallback-system

# 3. Make scripts executable
chmod +x fallback-handler.sh opencode-fallback

# 4. Edit the configuration (see below)
cat fallback-config.json

# 5. Test the system
./fallback-handler.sh
```

## Installation

### Prerequisites

- **Node.js** (recommended: v20+)
- **opencode** installed
- **jq** for JSON processing: `sudo apt install jq` (Linux/macOS)
- **OpenRouter API Key** (free registration at [openrouter.ai](https://openrouter.ai))

### Step-by-Step

```bash
# Clone the repository
git clone https://github.com/rjkashif01/opencode-fallback-system.git

# Enter the directory
cd opencode-fallback-system

# Make scripts executable
chmod +x fallback-handler.sh opencode-fallback

# Run the install script (optional)
./install.sh

# Check configuration
cat fallback-config.json

# Start the system
./fallback-handler.sh
```

## Configuration

### `fallback-config.json`

The central configuration file. Key settings:

```json
{
  "provider": "openrouter",
  "opencode_config": "/home/raja/.config/opencode/opencode.jsonc",
  "ask_before_switch_free": true,
  "ask_before_switch_paid": true,
  "max_tokens_test": 5,
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

Store your OpenRouter API Key:

```json
{
  "openrouter": {
    "type": "api",
    "key": "sk-or-v1-dein-api-key-hier"
  }
}
```

### Model Selection

The system automatically switches in this order:

1. **Level 1:** Test current model (if already functional)
2. **Level 2:** Try all `:free` models from OpenRouter
3. **Level 3:** If active subscription: Test preferred Paid models
4. **Level 4:** If exhausted: Ask user for manual switch

## Usage

### Automatic Mode (recommended)

```bash
# Checks current model and switches if needed
./fallback-handler.sh

# Or with direct prompt (opens opencode with fallback logic)
./opencode-fallback "Your prompt here"
```

### Manual Monitoring

```bash
# Show log file with errors and switches
cat ~/.opencode/usage-log.json

# Show current status of the fallback system
cat ~/.opencode/fallback-state.json
```

### Environment variables (alternative to files)

```bash
export OPENROUTER_KEY=sk-or-v1-dein-key
export OPENCODE_CFG=/home/raja/.config/opencode/opencode.jsonc
./fallback-handler.sh
```

## Supported Models (Free Tier)

| Model | Provider | Free Tier |
|-------|----------|-----------|
| `nvidia/nemotron-3.5-lightning:free` | NVIDIA | Unlimited (this repo) |
| `glm-4` | GLM | Unlimited |
| `phi-3-mini` | Microsoft | 8k Tokens daily |
| `qwen/qwen3.8-27b:free` | Qwen | Often overloaded (429 errors) |

## Error Troubleshooting

### Common Problems

1. **"Free usage exceeded" error**
   - Solution: Wait for reset (usually UTC midnight) or manually switch to the next model
   - Use `--auto-free` flag to force automatic switching without asking

2. **"Could not read current model"**
   - Solution: Ensure `opencode.jsonc` has a valid `model` field

3. **API Key error**
   - Solution: Check `auth.json` for valid key or set `OPENROUTER_KEY` environment variable

4. **No models available**
   - Solution: All Free-Tier models are exhausted. Wait for reset or upgrade your plan.

### Analyze Log Files

- `~/.opencode/usage-log.json` - All errors and model switches chronologically
- `~/.opencode/fallback-state.json` - Current status and last changes

## Contributing

Welcome! You can contribute by:

- Adding more fallback models
- Improving the detection logic
- Improving the documentation
- Fixing bugs
- Creating Issues for feature requests

Just open an Issue or Pull Request in the GitHub Repository.

## Multilingual Support

**License:** The MIT License is typically kept in **English** because it's a legal document used internationally. The English version is the legally binding one.

**Documentation:** This README is primarily in English, but I've added German descriptions above. For full multilingual support:

- GitHub supports multiple `README.md` files in different languages (e.g., `README.de.md` for German)
- You can use translation badges or separate language folders
- Key commands and configuration remain in English for consistency

**For German users:** The installation scripts and configuration files work the same way regardless of language. The `install.sh` script detects system language and can display messages in German if needed.

## Contact

For questions, open an Issue in the GitHub Repository: https://github.com/rjkashif01/opencode-fallback-system

---

*Last updated: November 2026*