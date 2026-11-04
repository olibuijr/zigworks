# Testing

zigworks has two kinds of tests, and both run with one command each.

```sh
zig build test   # unit tests next to the code
zig build e2e    # browser tests and screenshots
```

## Unit tests

Tests sit in the file they test. The router, templates, Markdown, highlighter, static paths and design tokens all have them. Write yours the same way:

```zig
test "remaining counts open todos" {
    const todos = [_]Todo{ .{ .done = true }, .{ .done = false } };
    try std.testing.expectEqual(1, remaining(&todos));
}
```

## Browser tests

`tests/e2e.mjs` starts each app, starts headless Chromium, and drives it over the DevTools protocol, with nothing to install from npm. It clicks, types and presses keys like a person, then checks the DOM:

```js
await test('todo: add', async () => {
  const p = await open(todo);
  await p.type('input[name=title]', 'Buy oat milk');
  await p.key('Enter');
  await p.waitFor(`document.querySelectorAll('#todos > li').length === 1`);
  noErrors(p); // fails on any console error or exception
  await p.shot('todo-light');
});
```

Every test fails on browser console errors, and every screen is saved in light and dark to `zig-out/e2e/`.

## Look at the screenshots

Tests prove behavior; screenshots catch design flaws: cramped labels, broken alignment, a menu hanging off a card. Review them after every UI change. Several bugs in this framework were found that way.

## Requirements

`chromium` and `node` (18+) on the path. Set `CHROMIUM` to use another browser binary.
