# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

## [0.4.1] - 2026-11-04

### Fixed
- The sidebar scrolled away with the page on wide screens (a later `inset:auto` reset its sticky `top`).
- Scrolling glass (the sidebar) no longer gets a refraction lens or a sheen layer that the links scroll under; it keeps plain blur with the sheen in its background.

### Added
- MIT license, security policy, CI workflow, GitHub-style README.

## [0.4.0] - 2026-11-04

### Added
- 14 components: `tabs`, `disclosure`, `path`, `empty`, `textarea`, `stepper`, `checkbox`, `radio`, `tooltip`, `tag`, `avatar`, `kbd`, `skeleton`, `toast` (35 in all), each with a docs page and live demo.
- Toasts: return `ui.toast(...)` from any handler; it lands in the layout's toast region (`z-oob="beforeend"`) and leaves after 4 s.
- `z-keep` / `ui.Z{ .keep = true }`: a form keeps its values after a successful send (settings forms).
- Gallery: Account (avatar, textarea, removable tags, checkbox, toast on save), Printing (tabs with stepper, radio, empty state), Activity (skeleton while loading), Developer (path, disclosure, kbd), tooltip on the toolbar.
- e2e tests for the new components and for no zoom-on-focus on touch screens.

### Fixed
- iOS no longer zooms into text fields on focus: on touch screens (`pointer: coarse`) inputs and textareas use at least 16px text. Page zoom stays enabled.

## [0.3.0] - 2026-11-04

### Added
- Liquid Glass material (`src/ui/glass.zig`): tint, blur, specular rim, sheen, pointer-following light; `zw-glass`, `zw-glass--clear`, `zw-press` classes.
- `glass.js`: real refraction in Chromium. Each glass element gets an SVG displacement lens built from a rounded-rectangle signed distance field, cached per size.
- Spring motion tokens as CSS `linear()` curves (`spring`, `spring_bouncy`, `spring_snappy` with durations), with a `cubic-bezier` fallback.
- Press inertia: controls grow, stretch toward the pointer and spring back.
- Switch and slider knobs swell into clear, magnifying glass drops while pressed.
- Segmented controls get a sliding glass pill.
- Menus, pickers, sheets, dialogs and the mobile sidebar spring out of their source and settle.
- New list rows drop in, deleted rows collapse, completed checks pop, and out-of-band badges pop.
- `zw-js` class on `<html>` when z.js runs.
- Docs page "Liquid Glass" and a glass e2e test with pressed-state screenshots.

### Changed
- Buttons, search field and badges are capsules; the sidebar floats as a glass panel; the title bar is a scroll edge with soft blur instead of a bar with a line.
- Larger, concentric radii (`radius` 14px, `radius_control` 8px, new `radius_panel` 20px).
- The slider knob is drawn over the track (native thumb kept without JS).
- The token `material` is replaced by `glass_filter` and `glass_filter_clear`.

## [0.2.0] - 2026-11-04

### Added
- Documentation site in `docs/`, built with zigworks: Markdown pages, live component demos, live search, previous/next links (`zig build docs`).
- Components: `sidebar`, `search`, `callout`, `code`, `table`, `progress`, and `.zw-prose` text styles.
- `layout` gains `sidebar` (two-column app, slide-in sidebar on narrow screens) and `brand`.
- `zw.markdown` / `zw.markdownWith`: safe Markdown subset with custom fences.
- `zw.highlight`: server-side Zig highlighting with the compiler's tokenizer.
- `c.pass()`: a handler can decline so the next route or `public/` answers.
- `app.not_found`: custom 404 handler.
- `HOST` environment variable.
- z.js: Copy buttons for code blocks; Esc closes search results.
- Exports `ui.SegmentedOption`, `ui.PickerOption`, `ui.MenuItem`.
- Gallery shows storage (progress, table, callout) and code; e2e tests cover the docs site.

### Changed
- Apps listen on `0.0.0.0` (the LAN) by default instead of `127.0.0.1`.

## [0.1.0] - 2026-11-04

### Added
- HTTP/1.1 server on `std.http` with keep-alive, per-request arena, 413 body limit, `PORT` override.
- Comptime router with `:params` and `*` rest captures.
- `Ctx`: params, query, form, JSON, headers, HTML/text/JSON/redirect responses.
- Svelte-style templates compiled at comptime with auto-escaping, `{#if}`, `{#each}`, `{@html}`, nesting.
- `props()` with compile errors for missing or unknown props; `each()` for lists of components.
- Design tokens to CSS variables, macOS HIG defaults, dark mode, Reduce Transparency, Increase Contrast.
- Component library: layout, card, list, setting, sheet, button, field, check, toggle, segmented, slider, picker, menu, badge, island.
- z.js: htmx-style requests and swaps, `closest` targets, out-of-band updates, custom confirm dialog, islands.
- Static files from `public/` with MIME types for JS modules, wasm and 3D assets.
- Examples: todo (works without JS), gallery, three.js scene.
- Browser e2e tests and light/dark screenshots via Chromium DevTools protocol (`zig build e2e`).
