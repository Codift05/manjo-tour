# Design System Direction (Konvoi Touring App)

## Design Read
Reading this as: Mobile touring and convoy companion app (Flutter frontend MVP) for motorcycle communities and road-trip riders, in a Playful Organic Adventure flat-illustration clean light style with High-Contrast Riding Mode for active navigation, dial **ENERGY 2 / RHYTHM 2 / MOTION 2**.

## Visual Identity & One-Line Reasons (R-31)
- **Color Palette (R-01, R-25, R-29):** Adventure Green (`#2ECC71`, bright `#4ADE80`, deep accessible fill `#15803D`) marks safe routes, active formation, and primary navigation actions; Warm Sunset Orange (`#FF7A3D`, amber `#F59E0B`, deep accessible fill `#C2410C`) is reserved for key CTAs, gap alerts, and distance highlights; neutrals (`#FFFFFF`, `#FAFAFA`, `#F3F4F6`, `#1E293B`, `#475569`, `#64748B`) keep map and card readability high in daylight. High-Contrast Riding Mode (`#0F172A` surface, `#1E293B` elevated panel, `#F8FAFC` ink, `#4ADE80` active route, `#FB923C` warning) keeps glare low on night rides.
- **Verified WCAG AA Contrast Pairs (R-25):**
  - `#1E293B` on `#FFFFFF`: 14.63:1 (PASS)
  - `#64748B` on `#FFFFFF`: 4.76:1 (PASS)
  - `#475569` on `#FAFAFA`: 7.26:1 (PASS)
  - `#0B2E1A` on `#2ECC71`: 7.04:1 (PASS)
  - `#2D1206` on `#FF7A3D`: 6.75:1 (PASS)
  - `#FFFFFF` on `#15803D`: 5.02:1 (PASS)
  - `#FFFFFF` on `#C2410C`: 5.18:1 (PASS)
  - `#FFFFFF` on `#B91C1C`: 6.47:1 (PASS)
  - `#065F46` on `#E8F8F5`: 7.02:1 (PASS)
  - `#9A3412` on `#FEF3C7`: 6.56:1 (PASS)
  - `#F8FAFC` on `#0F172A`: 17.06:1 (PASS)
  - `#4ADE80` on `#0F172A`: 10.25:1 (PASS)
- **Typography (R-06):** Plus Jakarta Sans for headings and interactive labels (rounded geometric terminals match the organic adventure brand while remaining legible at a glance on handlebars), paired with tabular numerals for distances, timers, and split-bill totals.
- **Radius Hierarchy (R-11):** Content cards use `24px`, primary action buttons use `18px`, search/inputs use `16px`, compact metric badges use `12px`, and only category filters and active nav indicators use pill radius (`999px`) so element roles stay visually distinct.
- **Elevation & Shadow (R-12):** Flat soft-tinted surfaces (`#E8F8F5`, `#FEF3C7`, `#F3F4F6`) handle grouping without shadows; diffuse shadow (`blurRadius: 16`, opacity 6-8%) is applied selectively to primary floating elements (floating nav bar, map control overlays, hero action bar, route carousel cards).
- **Illustrations & Mascot (R-22):** Extracted transparent poses from `ref/Maskot.png` appear in the Home hero banner, empty states, and achievement badges, paired with custom flat-vector landscape painters inspired by `Refrensi 1.png`, `Refrensi 2.png`, `Refrensi 4.png`, and `Refrensi 6.png` without heavy black outlines.
- **Glove-Friendly Ergonomics (R-03):** All navigation screen controls (Push-to-Talk, Hazard Pin, SOS) use 56px to 64px height with >= 12px spacing between adjacent controls; all standard tap targets meet >= 48dp.
- **Motion (R-19):** Tactile press feedback (`scale(0.97)`, `140ms` ease-out), crisp modal/drawer entrances (`240ms`, cubic-bezier `0.23, 1, 0.32, 1`), live audio waveform only while Push-to-Talk is held, and automatic simplification under `MediaQuery.disableAnimationsOf(context)`.
- **Identity Motif:** Organic layered flat-vector landscape horizons (soft hills, winding route dashes, rounded white floating sheets) carried consistently across Home, Radar, Trips, and Profile.
