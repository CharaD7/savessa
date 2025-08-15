# Icon Assets

This directory contains icon assets for the Savessa app.

## Required Icons

### Language Selection
- Flags live in `assets/icons/flags/`.
- The code currently loads `assets/icons/flags/{code}.svg` for language codes: `en`, `fr`, `es`, `sw`, `yo`, `ha`.
- For compatibility with prior docs, we also include duplicate files named `flag_{code}.svg`.
- Provided files:
  - `en.svg` and `flag_en.svg` — English (US) flag
  - `fr.svg` and `flag_fr.svg` — France flag
  - `es.svg` and `flag_es.svg` — Spain flag
  - `sw.svg` and `flag_sw.svg` — Tanzania flag (for Kiswahili)
  - `yo.svg` and `flag_yo.svg` — Nigeria flag (for Yorùbá)
  - `ha.svg` and `flag_ha.svg` — Niger flag (for Hausa)
  - `globe.svg` — generic globe placeholder
  - `unknown.svg` — generic unknown placeholder

### Other SVG Icons
- Live in `assets/icons/svg/`.
- `voice_guidance.svg` — Icon for voice guidance option (custom, using app color scheme)

## Conventions
- Flags are rectangular with a 3:2 aspect ratio and a viewBox of `0 0 60 40` for crisp rendering at 60×40.
- Keep SVGs flat (no embedded rasters, scripts, or external refs). Avoid internal drop shadows; the UI applies shadows.
- Naming: prefer `{languageCode}.svg`. Provide `flag_{languageCode}.svg` duplicates only for backward compatibility.

## Icon Guidelines
1. All icons should be provided in SVG format for better scaling.
2. Use the app color scheme where applicable: Royal Purple (#6A0DAD), Metallic Gold (#FFD700), and Pure White (#FFFFFF).
3. Icons should be simple and easily recognizable.
4. Provide both light and dark mode versions where appropriate.
5. Follow Material Design guidelines for consistency.
