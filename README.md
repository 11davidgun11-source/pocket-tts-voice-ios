# PocketVoice (personal iOS build)

Offline voice clone on iPhone. SwiftUI + sherpa-onnx PocketTTS (int8).
Record a 10-15s voice print, type text, get WAV + M4A. No server. No login.

## First run on phone
1. Setup tab: Download Model (94 MB, once, public files).
2. My Voice tab: record your sample.
3. Speak tab: type, press Speak.

## Build
Push to main builds an unsigned IPA via GitHub Actions (macOS runner).
Install with SideStore (it signs), run inside LiveContainer.

Model files ship via the `models-v1` release (7 files, not in git).
