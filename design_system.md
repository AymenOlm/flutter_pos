# Design System — Flutter POS

Purpose
- Provide a single-source-of-truth for visual language, interaction patterns, and Flutter implementation guidance for the Flutter POS app.
- Scope: tokens, component specs, accessibility, examples, contribution guidelines.

Principles
- Clarity: UI elements communicate intent clearly.
- Efficiency: Optimized for quick POS flows and low cognitive load.
- Consistency: Reuse tokens and components across screens.
- Accessibility: Support keyboard, screen readers, contrast and touch targets.

1. Design Tokens

1.1 Color
- Primary: `primary` — #0D47A1 (deep blue)
- Primary Variant: `primaryVariant` — #08306B
- Secondary: `secondary` — #FFB300 (amber)
- Success: `success` — #2E7D32
- Warning: `warning` — #F57C00
- Error: `error` — #D32F2F
- Background: `background` — #FFFFFF
- Surface: `surface` — #F5F7FA
- On-primary: `onPrimary` — #FFFFFF
- On-surface (text): `onSurface` — #111827

Use semantic tokens (e.g., `buttonBackground`, `cardBackground`, `mutedText`) in components and map to color scheme in Flutter.

1.2 Typography
- Typeface: `Inter` (or system fallback)
- Scale (mobile px):
  - Display: 28 / 32 (weight 600)
  - H1: 22 (600)
  - H2: 18 (600)
  - Body Large: 16 (400)
  - Body: 14 (400)
  - Caption: 12 (400)
- Line heights & letter spacing should be defined in Flutter TextTheme mapping.

1.3 Spacing & Layout
- Spacing scale (dp): 4, 8, 12, 16, 20, 24, 32, 40
- Grid: 8dp baseline grid
- Container padding: 16dp standard; 8dp dense

1.4 Radii & Elevation
- Radius small: 4dp
- Radius medium: 8dp
- Radius large: 12dp
- Elevation tokens: none, low (2), medium (6), high (12)

1.5 Icons & Imagery
- Iconography: Material icons (filled) for common actions; custom icons must match stroke weight and grid.
- Asset formats: SVG for vector assets, PNG/WebP for bitmaps.

2. Accessibility
- Contrast: Minimum AA contrast 4.5:1 for body text, 3:1 for large text.
- Touch targets: Minimum 48x48dp.
- Focus order: Logical reading order; use clear focus ring.
- Screen reader labels: All interactive elements require semantic labels.
- Motion: Reduced-motion preference respected; avoid long, distracting animations.

3. Component Specs

3.1 Button
- Variants: Primary (filled), Secondary (outlined), Text (link-style), Icon button.
- Anatomy: content (icon optional) + label. Padding: 12dp vertical, 16dp horizontal (adjust for dense).
- States: enabled, pressed, hovered (desktop), disabled, loading.
- Accessibility: `aria-label` equivalent, minimum contrast, clear disabled state.

Flutter mapping (example):

```dart
final ButtonStyle primaryStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: AppColors.onPrimary,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

ElevatedButton(
  onPressed: onPressed,
  style: primaryStyle,
  child: isLoading ? CircularProgressIndicator() : Text(label),
)
```

3.2 Input / Text Field
- Variants: Filled, Outlined, Search.
- States: focused, unfocused, error, disabled.
- Labels: visible label and optional helper/error text.
- Accessibility: `labelText` and `hintText` for screen readers.

3.3 App Bar / Header
- Height: 56dp mobile
- Left: navigation/back, center: title, right: actions.
- Use concise titles; actions limited to primary tasks.

3.4 Cards
- Use for grouped content; padding 12-16dp; elevation low; radius 8dp.

3.5 Lists & Tables
- Use compact rows for POS: 56dp row height; left-aligned primary content, right-side price or action icons.
- Support selection state, swipe actions where appropriate.

3.6 Dialogs & Sheets
- Dialog width: responsive; mobile full-screen optional for complex flows.
- Buttons: primary action on right, cancel on left (or bottom in sheet).

4. Patterns & Layouts
- Checkout flow: progressive disclosure — show steps, keep primary CTA visible.
- Error handling: inline error messages, toast for transient feedback.
- Empty states: informative copy and primary action to recover.

5. Motion & Interaction
- Micro-interactions: 100–200ms for touch feedback; 200–350ms for meaningful transitions.
- Avoid long animations during checkout; offer reduced-motion mode.

6. Brand & Tone
- Tone: efficient, trustworthy, calm.
- Use plain action labels: Confirm, Cancel, Refund, Hold.

7. Flutter Implementation Guide

7.1 Centralize Tokens
- Create an `AppTheme` that exposes `ColorScheme`, `TextTheme`, `Spacing` constants.

Example `ColorScheme` mapping:

```dart
final ColorScheme appColorScheme = ColorScheme(
  primary: Color(0xFF0D47A1),
  primaryContainer: Color(0xFF08306B),
  secondary: Color(0xFFFFB300),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFF5F7FA),
  onPrimary: Color(0xFFFFFFFF),
  onSurface: Color(0xFF111827),
  error: Color(0xFFD32F2F),
  onError: Colors.white,
  brightness: Brightness.light,
  onSecondary: Colors.black,
  onBackground: Color(0xFF111827),
  tertiary: Color(0xFF2E7D32),
);

ThemeData buildAppTheme() => ThemeData.from(colorScheme: appColorScheme).copyWith(
  textTheme: TextTheme(
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryStyle),
);
```

7.2 Reusable Widgets
- Provide `AppButton`, `AppInput`, `AppCard` wrappers that apply token styles and accessibility.

Example `AppButton` component:

```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const AppButton({required this.label, this.onPressed, this.primary = true});

  @override
  Widget build(BuildContext context) {
    final style = primary ? Theme.of(context).elevatedButtonTheme.style : null;
    return ElevatedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
```

7.3 Theming Tips
- Expose a `Spacing` class with constants (Spacing.xs, .sm, .md) to avoid magic numbers.
- Use `Theme.of(context)` and `TextTheme` for text styling to support dynamic type.

8. Accessibility Implementation
- Provide semantic labels: `Semantics(label: 'Total price')` where necessary.
- Test with TalkBack/VoiceOver and keyboard navigation on Windows runner.
- Provide high-contrast override option if needed.

9. Tokens & Component Versioning
- Track token changes in a single `design_tokens.json` (or Dart map). Bump major version for breaking token renames.

10. Contribution Guidelines
- Add or change tokens: update `design_system.md`, `design_tokens.json`, and `AppTheme` mapping.
- Component changes: include screenshots (light/dark), accessibility checks, and example usage in `lib/`.
- PR template: reference the affected token/component and include visual diff.

11. Examples & Recipes
- Checkout button row: `AppButton(primary)`, `AppButton(secondary)` with `Expanded` layout.
- Price line: left product name, right bold price with currency format.

12. Appendix: Checklist
- Colors mapped to `ColorScheme` ✅
- Text sizes in `TextTheme` ✅
- Buttons: primary/secondary/disabled states drafted ✅
- Accessibility: contrast & labels ✅

----

If you'd like, I can:
- Generate the corresponding `lib/core/theme/app_theme.dart` stub implementing the tokens above.
- Produce a tiny demo page `lib/features/pos/presentation/views/design_system_demo.dart` showing components.

