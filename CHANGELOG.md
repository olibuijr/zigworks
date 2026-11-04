# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

**Releasing:** bump the version in `build.zig.zon`, `src/zigworks.zig` (`version`) and the README
install snippet (`#vX.Y.Z`), rename `[Unreleased]` to the version and date, then tag `vX.Y.Z`.

## [0.6.1] - 2026-11-04

### Fixed
- `zig build test` printed a "failed command" block on every fresh run, which looked like an intermittent test failure. Every test passed: the build runner shows any test output under that header, and the 500-response test logged an expected warning. The test now silences it, so a clean run prints nothing.

## [0.6.0] - 2026-11-04

Motion for every action.

### Added
- Dismissing a sticky toast (×) animates it out instead of hiding it at once; pressing a toast's action button dismisses it the same way.
- Replaced content (`inner`/`outer` swaps) fades up from half opacity, so updates are visible.
- The `z-confirm` dialog animates out when it closes.
- Copy buttons flip to "Copied" (in green) with a small spring.
- Page navigations crossfade with a cross-document view transition (skipped with Reduce Motion).
- e2e test for the toast and dialog exit animations.

### Changed
- Removals collapse smoothly along their flow axis: toasts close up their stack, tags in a row shrink sideways, list rows fold away, and the parent's gap closes with them instead of jumping at the end.

## [0.5.2] - 2026-11-04

### Changed
- Component CSS trimmed with native CSS nesting, merged rules and removed dead or duplicate declarations: zw.css 80.8 KB to 74524 bytes (15644 bytes gzipped). Nothing looks or behaves differently: every docs demo and every e2e state screenshot matches 0.5.1 pixel for pixel.

## [0.5.1] - 2026-11-04

Codebase hygiene: less code, fewer surprises, same API.

### Changed
- `+` stays literal in route params and static file paths (only form bodies and query strings decode it as a space).
- Built-in assets (`/_zw/z.js`, `/_zw/zw.css`) send an `ETag` and answer `304 Not Modified`.
- Per-connection memory is bounded.
- Markdown blockquotes no longer stop at 64 lines.
- Shared base CSS for the focus ring, `.zw-input` and `.zw-sr`; components reuse it instead of repeating it.
- glass.js lights only glass surfaces and keeps at most 64 refraction lenses (sizes rounded to 2px), so resizing no longer grows memory.
- z.js logs an error when a `z-target` matches nothing instead of dropping the response.
- Prose styles use `@scope`.

### Internal
- Server tests run in-process.
- e2e helpers shorten the browser tests; new tests cover the slider readout, textarea counter, stepper wrap, mixed checkbox, menu arrow keys, Ctrl+K search, sheet focus and the skip link; the three.js test skips when the CDN is unreachable.
- All component unit tests run (68 unit tests).
- One add-a-component checklist in the agents docs; size, Node and host facts corrected in the docs.

## [0.5.0] - 2026-11-04

Every component reviewed and extended. All new props have defaults, so existing code compiles unchanged.
Each component's docs page lists its props and shows them in its demo.

### Added
- **Layout:** skip-to-content link, `footer` slot, centered title (`title_align`), `lang`.
- **Sidebar:** link icons and badges, collapsible sections, `size`, pinned `footer`, inline mode.
- **Sheet:** `size`, `description`, `footer`, close button, focus on the first field when opened.
- **Card:** `subtitle`, header `accessory`, `footer`, `variant` (elevated/inset/plain), `flush`, link cards (`href`).
- **List:** `header`/`footer` captions, `separators`, navigation rows with chevrons (`nav`), hover-revealed delete (`reveal`), `inset`.
- **Setting:** `description`, `icon`, `disabled`, navigation rows (`href`); `control` is optional.
- **Empty state:** `icon`, `size`, `secondary` action.
- **Tabs:** per-tab `badges`, `disabled` tabs, `full_width`, `label`.
- **Disclosure:** exclusive accordions (`name`), trailing `detail`, `.card` style.
- **Path:** `separator`, collapsing long paths (`max`), item icons.
- **Button:** `size`, `icon` (and icon-only), `loading`, links (`href`), `full`, `describedby`.
- **Menu:** item icons, shortcut hints, checkmark items, disabled items, section headers, links, `alignment`, arrow-key navigation.
- **Tooltip:** left and right sides, `delay`, `detail`, `shortcut`, `id`; hidden on touch screens.
- **Field:** `help` and `invalid` messages, `prefix`/`suffix`, `disabled`, `readonly`, `inputmode`, `pattern`, `maxlength`.
- **Textarea:** character counter (`maxlength`), `max_rows`, `grow`, `resize`, `help`/`invalid`, `disabled`, `readonly`.
- **Search:** `size`, clear button, keyboard shortcut (⌘K), `min_length`, `name`, `value`.
- **Check, checkbox, radio, toggle:** sizes, tints, descriptions, `disabled`; mixed checkboxes; horizontal radios; switch label side.
- **Segmented:** `size`, `full`, icons, icon-only, disabled options.
- **Slider:** tick marks, min/max labels, live value readout with unit, `disabled`.
- **Stepper:** `unit`, `wrap`, `editable`, `disabled`.
- **Picker:** placeholder, icons, descriptions, headings, separators, disabled options, `full`.
- **Badge:** tones, sizes, `solid`, dot badges, counts with `max` (99+).
- **Tag:** tones, sizes, icons, link tags, filter chips (`name`/`value`/`selected`), `disabled`.
- **Avatar:** status dot, rounded shape, `hue`, `+N` overflow, stacked groups (`.zw-avatars`).
- **Kbd:** PC key names (`platform`), sizes, `joiner` (e.g. "then"), `plain` menu style.
- **Progress:** sizes, tones, captions, percentage, determinate rings.
- **Skeleton:** shapes (lines, block, circle, media), `shimmer`.
- **Toast:** `warning` kind, action button, `sticky`.
- **Callout:** `important` and `caution` kinds (also in Markdown: `[!IMPORTANT]`, `[!CAUTION]`), `icon`, `compact`.
- **Code:** file name caption, line numbers, highlighted lines, `wrap`, `copy`.
- **Table:** column alignment, `caption`, `striped`, `compact`, row headers, empty text.
- **Island:** `aspect` ratio, loading shimmer, no-JS fallback text.

### Changed
- The e2e browser behaves like a desktop with a mouse (hover styles are testable); all component unit tests now run.

## [0.4.2] - 2026-11-04

### Added
- `zw-not-prose`: a wrapper class that keeps `.zw-prose` text styles off the components inside it. Docs demos use it.
- `ui.sidebar(.{ .inline_ = true })` shows a sidebar inside content (no popover, no id).

### Fixed
- Phones: the sidebar demo was empty, a settings row squeezed its segmented control (clipped label, misplaced pill), and docs text styles leaked into demo components (underlined sidebar links, big card titles).
- Phones: app pages use 16px side margins instead of 36px; demos use 16px padding.

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
