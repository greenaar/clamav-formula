# ClamAV formula

Installs and configures the distribution-supported ClamAV daemon and FreshClam updater on current Debian and Ubuntu releases.

Include `clamav` and override individual native ClamAV directives under `clamav:clamd:config` or `clamav:freshclam:config`. Maps are deeply merged by Salt, so the supplied production pillar can remain flat and explicit. Both generated configuration files are checked by their owning binaries before replacement.

The default local socket is `/run/clamav/clamd.ctl`, owned by `clamav` and mode `0660`. MailScanner deployments should set `LocalSocketGroup: mtagroup` and add their mail-processing users to that group; never use a root daemon or a world-writable socket.

The formula also carries the AppArmor systemd-resolved Varlink compatibility rule needed by modern Debian/Ubuntu releases. See `pillar.example`.

## Relationship to upstream

**This is a heavily modified fork of
[`saltstack-formulas/clamav-formula`](https://github.com/saltstack-formulas/clamav-formula). Do not treat it as a drop-in
replacement for it.**

States have been renamed, split, merged, and removed; pillar keys have moved;
defaults differ; and behaviour has changed in ways that are not backward
compatible. Pointing an existing deployment at this formula without reading
`pillar.example` and the state list above will not do what you expect.

It is also not a newer version of upstream — it diverged and was maintained
separately, so upstream may well have fixes and platform support that this
does not. If you want the maintained original, use
[`saltstack-formulas/clamav-formula`](https://github.com/saltstack-formulas/clamav-formula).

### Credit

The foundation of this formula, and much of what still works well in it, is
the work of the [saltstack-formulas](https://github.com/saltstack-formulas) authors and contributors. Any
bugs introduced in the divergence are this fork's own.

## License

Dedicated to the public domain under [CC0 1.0 Universal](LICENSE).
