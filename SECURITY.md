# Security policy

## Supported versions

Only the latest release gets security fixes.

## Reporting a vulnerability

Please **do not open a public issue**. Report it privately through
[GitHub private vulnerability reporting](https://github.com/olibuijr/zigworks/security/advisories/new).
Include the version, a minimal reproduction and the impact you expect. You should get a reply
within a week.

## Scope and known limits

zigworks is young. Before exposing an app to the open internet, read the
[Limits](README.md#limits) section: there is no TLS, no CSRF protection, no idle timeout, and apps
listen on all interfaces by default. Run behind a reverse proxy, or set `HOST=127.0.0.1`.
