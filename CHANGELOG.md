# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

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
