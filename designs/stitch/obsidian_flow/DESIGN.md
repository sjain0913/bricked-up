# Design System Strategy: The Disciplinary Utility

## 1. Overview & Creative North Star: "The Stoic Monolith"
This design system is not a playground; it is a tool of restraint. Inspired by high-end precision hardware and the minimalist philosophy of physical "Brick" devices, the North Star is **The Stoic Monolith**. 

We move away from the "sticky" dopamine-driven patterns of traditional mobile apps. The UI should feel like an expensive piece of dark obsidian—silent, heavy, and purposeful. We break the standard app "template" look by using aggressive negative space, asymmetric type placement, and a strict rejection of structural lines. The goal is to make the user feel a sense of calm authority and digital discipline.

## 2. Colors & Tonal Depth
The palette is rooted in deep charcoal and "off-black" tones to reduce eye strain and cognitive load. The accent (`primary`) is a muted, desaturated slate-emerald that serves as a beacon of intentionality, not a shout for attention.

### The "No-Line" Rule
**Explicit Instruction:** You are prohibited from using 1px solid borders for sectioning. 
Structure must be defined through "Tonal Stepping." If you need to separate a card from the background, do not draw a line; instead, shift from `surface` (#0d0f0f) to `surface_container_low` (#111414). Boundaries are felt through luminance, not drawn with strokes.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of materials. 
- **Base Layer:** `surface` (#0d0f0f) for the primary application background.
- **Secondary Tier:** `surface_container` (#161a1a) for grouped content.
- **Active Tier:** `surface_container_highest` (#212727) for interactive elements like cards or inputs.
- **Glassmorphism:** For floating modals or navigation bars, use `surface_variant` at 60% opacity with a `24px` backdrop blur. This ensures the UI feels "integrated" into the device rather than floating on top of it.

### Signature Textures
Main action buttons or critical status indicators should use a subtle linear gradient: 
`primary_container` (#304b50) → `primary` (#afccd1) at a 135-degree angle. This adds a "metallic" sheen reminiscent of machined aluminum.

## 3. Typography: The Editorial Hierarchy
We utilize a pairing of **Manrope** (for authoritative, hardware-styled displays) and **Inter** (for high-clarity functional data).

- **Display (Manrope):** Use `display-lg` for session timers or high-level status. It should feel massive yet quiet. Use `negative letter-spacing (-0.02em)` to create a "locked-in" look.
- **Headlines (Manrope):** Use `headline-sm` for section titles. These should be placed with generous top-padding to emphasize the start of a new "thought."
- **Body & Labels (Inter):** Use `body-md` for all instructional text. 
- **The Intentional Gap:** Use `spacing-10` (3.5rem) between a headline and a list to force the user to "slow down" and read with intent.

## 4. Elevation & Depth: Tonal Layering
Traditional drop shadows are too "software-generic." We use **Ambient Occlusion** logic.

- **The Layering Principle:** Depth is achieved by "stacking." A `surface_container_lowest` (#000000) element placed inside a `surface_container_high` (#1c2021) wrapper creates an "etched-in" look, suggesting a physical recession in the hardware.
- **Ambient Shadows:** When a floating element is required (e.g., a critical alert), use a shadow with a blur of `40px`, Y-offset of `12px`, and a color of `on_surface` (#e1e7e6) at **4% opacity**. It should be a whisper, not a shadow.
- **The "Ghost Border" Fallback:** If accessibility requires a border, use `outline_variant` (#434949) at **15% opacity**. It must look like a faint reflection on the edge of a screen, not a container boundary.

## 5. Components: Functional Primitives

### Buttons (The "Actuators")
Buttons should feel like physical switches.
- **Primary:** Gradient fill (Primary to Primary Container), `xl` (1.5rem) corner radius. Use `label-md` uppercase with `0.05em` tracking for a "system" feel.
- **Secondary:** `surface_container_highest` background with `on_surface` text. No border.
- **Tertiary:** Pure text using `primary_dim` color, no background.

### Cards & Lists (The "Data Bricks")
- **The Forfeiture of Dividers:** Vertical lines are banned. Separate list items using `spacing-3` (1rem) of pure void or a subtle background shift to `surface_container_low`.
- **Corner Radius:** All containers must use `xl` (1.5rem) for large cards and `lg` (1rem) for smaller nested elements. This softens the "industrial" feel, making it feel premium rather than brutalist.

### High-Clarity Status Indicators
To indicate a "Blocked" or "Deep Focus" state, use a `tertiary_container` (#d9f0ef) pulse. It should be a slow, rhythmic opacity shift (0.2 to 0.4) rather than a bright flashing color.

### Input Fields
- **Resting:** `surface_container_highest` background, no border, `md` corner radius.
- **Focus:** `primary` (#afccd1) text color and a "Ghost Border" at 20% opacity. 

## 6. Do's and Don'ts

| Do | Don't |
| :--- | :--- |
| **Do** use `spacing-16` (5.5rem) for top-level margins to create an editorial feel. | **Don't** use standard 16px/24px "mobile-standard" padding everywhere. |
| **Do** use `primary` sparingly as a "Status Beacon." | **Don't** use `primary` for large decorative backgrounds. |
| **Do** embrace asymmetry (e.g., left-aligned headers with right-aligned data). | **Don't** center-align everything; it feels like a landing page template. |
| **Do** use `surface_container_lowest` (#000000) for recessed inputs. | **Don't** use pure white or bright greys for any background surface. |
| **Do** ensure `on_surface_variant` is used for "Secondary" information. | **Don't** use gamified progress bars (use subtle numeral countdowns instead). |

## 7. Spacing Strategy
The spacing scale is non-linear to prevent "rhythmic fatigue."
- Use **Small Gaps** (`0.5` to `2`) for related data points.
- Use **Macro Gaps** (`12` to `20`) to separate different mental contexts (e.g., separating "Active Session" from "Settings"). High-end design is defined by the luxury of wasted space.