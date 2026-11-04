# Changelog

All notable changes are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning: [SemVer](https://semver.org/).

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
