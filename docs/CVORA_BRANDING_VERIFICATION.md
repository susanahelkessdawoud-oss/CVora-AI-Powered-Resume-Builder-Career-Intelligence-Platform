# CVora — Branding Verification

## Status: BLOCKED on the original logo asset

**This is reported honestly rather than worked around.** The explicit instruction for this audit is: *"If you cannot find the original logo, stop and report that it is missing. Do not create a replacement."* That is exactly the situation.

### What was actually supplied in this conversation

- A detailed design-reference document ("CVora — Screen-by-Screen Build Prompts") containing **screenshots/renders** that show a logo: a CV-document icon (profile line + text lines + two checklist rows) wrapped in a blue-to-cyan-to-purple gradient orbit ring, with a small sparkle accent, next to a "CVora" wordmark with the "o" colored light blue.
- **No image file, SVG, or any other standalone asset was ever attached to this conversation.** Every reference to the logo is a *rendering of it inside a mockup screenshot*, not the asset itself.

### What exists in the app today

Two mark designs were built this project, by hand, as a stated **recreation** of what the screenshots showed — not as "the original file":

1. An earlier navy-and-gold "C + aura glow" mark (superseded).
2. The current mark: `assets/branding/cvora_mark.png` / `cvora_icon_source.png`, generated via a Python/PIL script (`lib/widgets/cvora_mark.dart` renders it as an `Image.asset`). This is a faithful visual match to the screenshots' composition (document + checklist + orbit ring + sparkle), built because no real asset was ever provided and two attempts at AI image generation were blocked by API quota (documented earlier in this project).

### Verification against the stated requirement

| Check | Result |
|---|---|
| Is the exact original asset in `assets/` or anywhere in the repo? | **No** — searched; nothing matches "an uploaded logo file" |
| Is the current mark the original artwork? | **No** — it is a hand-built recreation |
| Same colors/typography/icon/proportions as "the original"? | Cannot be assessed — there is no original file to compare against, only mockup screenshots |
| Used consistently across Splash, Login, Create Account, Home, app icon? | **Yes**, for the current (recreated) mark — verified live on-device this session |

### What is needed to close this out

The user has said they will attach the real file. Once it arrives:
1. Save it to `assets/branding/` under its own filename (do not overwrite the recreation until the real one is confirmed).
2. Point `CvoraMark` (`lib/widgets/cvora_mark.dart`) at the real file.
3. Regenerate the Android/Windows app icons from it (`dart run flutter_launcher_icons`).
4. Re-verify on Splash, Login, Create Account, Home, and the installed app icon.
5. Update this document's status to PASS with a screenshot comparison.

**Until that file arrives, every other part of this audit that mentions "the logo" refers to the current recreation, not a verified-original asset.**
