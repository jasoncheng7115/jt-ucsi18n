# jt-ucsi18n — Traditional Chinese Language Pack for UCS  `v1.1.0`

Displays the login page, portal and management console (UMC) of
[Univention Corporate Server (UCS)](https://www.univention.com/) in
**Traditional Chinese (zh_TW)**.

> [繁體中文說明](README_zh-TW.md)

## Screenshots

Taken on UCS 5.2-3.

| | |
|---|---|
| **Portal — "Traditional Chinese" in the language menu** | **UMC overview — module tiles** |
| ![portal language menu](images/portal_language_menu.png) | ![UMC overview](images/umc_overview.png) |
| **UMC — user edit page** | |
| ![UMC user edit page](images/umc_user_edit.png) | |

## Install

Run as root on the UCS host:

```bash
curl -fsSL https://raw.githubusercontent.com/jasoncheng7115/jt-ucsi18n/main/install.sh | bash
```

Run it once on every UCS host in the domain; LDAP data such as portal entry
names is only written on the Primary Directory Node.

## Switch the language

Installing the pack does not change the language by itself; each user
switches it in their own browser:

1. Open the UCS portal (`https://<your-ucs-host>/`).
2. Click the **≡** menu in the top-right corner.
3. Click **Change Language**.
4. Pick **Traditional Chinese**.

![portal language menu](images/portal_language_menu.png)

The page reloads in Traditional Chinese, and the login page and UMC follow
the same setting. The choice is remembered per browser, so every user (and
every browser) does this once.

If "Traditional Chinese" is missing from the list or parts of the interface
are still English, reload with Ctrl+Shift+R to clear the cached files. To go
back, use the same menu (now labelled **變更語言**) and pick English.

## Supported versions

| UCS version | Package |
|---|---|
| 5.2-3 to 5.2-7 | `univention-l10n-zh-tw` 1.1.0-1 |

The script reads `ucr get version/version` and `version/patchlevel`, then
picks the matching package from [`dist/versions.txt`](dist/versions.txt):

- Version inside the supported range: installs the matching package.
- Same series but newer than the range (e.g. 5.2-8): installs the latest
  package of that series and prints a notice; strings that only exist in
  the newer version stay in English for now.
- Older than 5.2-3 or another series (5.0, 5.3): stops and lists the
  supported versions; add `--force` to install anyway.

## After a UCS upgrade

The language pack is a standalone `.deb`, so a UCS upgrade does not remove
it. After upgrading, fetch the translation matching the new version:

```bash
jt-ucsi18n update
```

## Other commands

```bash
jt-ucsi18n status     # UCS version, installed package, available packages
jt-ucsi18n remove     # remove the language pack and the zh_TW login option
jt-ucsi18n install --no-ldap   # skip the LDAP display names
```

## What it does

- Installs `univention-l10n-zh-tw` with `dpkg -i` (SHA256 verified after
  download). The package only adds zh_TW `.mo` / `.json` files and does not
  modify any existing UCS file.
- Registers the locale `zh_TW.UTF-8` and the UCR variable
  `ucs/server/languages/zh_TW`.
- Restarts UMC, Portal and Apache.
- On the Primary, adds zh_TW display names to portal categories/entries and
  UDM extended attributes (append only, existing values are kept).

## Known limitations

- The keyboard model / language name lists in System Setup show Simplified
  Chinese, and login error messages end with an extra `.`; both are
  upstream UCS issues.
- About 94% of the strings are translated; test directories, URLs and
  vendor codes are left untranslated on purpose.

## Relation to upstream

The same translation has been submitted to Univention as
[Bug #59524](https://forge.univention.org/bugzilla/show_bug.cgi?id=59524).
This project is a community release until it is merged upstream and is not
an official Univention product.

## License

Released under the same terms as UCS, the **GNU Affero General Public
License v3.0**. See [LICENSE](LICENSE) and
`src/univention-l10n-zh-tw/debian/copyright`.

Traditional Chinese translation and tooling by Jason Cheng
([Jason Tools](https://jason.tools)). The original English strings and the
package template are copyright Univention GmbH.

See the [changelog](CHANGELOG.md) for release history.
