# Changelog

All notable changes are documented here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are those
of the `univention-l10n-zh-tw` package.

> [繁體中文版](CHANGELOG_zh-tw.md)

## [1.1.0] — 2026-10-03

**Theme: first standalone community release, one package for UCS 5.2-3 to 5.2-7.**

### Added
- **One-line installer `install.sh`.** Detects the UCS version, picks the
  matching package from `dist/versions.txt`, verifies its SHA256 and
  installs it with `dpkg -i`. It leaves `/usr/local/sbin/jt-ucsi18n` behind
  with the commands `status`, `update` and `remove` and the flags
  `--force` and `--no-ldap`.
- **Version map `dist/versions.txt`** and the prebuilt
  `univention-l10n-zh-tw_1.1.0-1_all.deb`.
- **Strings from UCS 5.2-3 to 5.2-7.** The 62 message IDs that differ
  between these patch levels are merged into the same `.po` files, so a
  single package covers the whole range.
- **LDAP display names from the installer.** On the Primary Directory Node
  it adds zh_TW names to portal categories/entries and UDM extended
  attributes (append only).
- Release tooling: `src/tools/check_version.sh`, `src/tools/merge_multi.py`,
  `src/tools/build_release.sh`.

### Changed
- The release package no longer depends on `univention-l10n-dev`, a
  development package that is not installed on normal systems.
- Project renamed from `ucs_zhtw` to `jt-ucsi18n`.

## [1.0.0] — 2026-06-21

**Theme: initial translation, submitted to Univention.**

### Added
- Traditional Chinese (zh_TW) translation package `univention-l10n-zh-tw`
  for UCS 5.2: 117 `.po` files, 5,786 strings, about 94% translated. Covers
  the login page, portal, UMC framework, the UDM interface (users, groups,
  computers, DNS, DHCP, shares, policies, settings), App Center, Diagnostic,
  Updater, System Setup, domain join, connectors, self-service and the
  REST API.
- Client-side JSON is also installed under `zh`, because the UMC web
  frontend only requests the primary language subtag.
- Submitted upstream as
  [Bug #59524](https://forge.univention.org/bugzilla/show_bug.cgi?id=59524).
