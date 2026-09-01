# SPKSideloadFix

Sparkle-local sideload app-group/keychain fix library.

This is derived from [`asdfzxcvbn/zxPluginsInject`](https://github.com/asdfzxcvbn/zxPluginsInject),
which is itself a rewrite of choco's original patch. It also vendors Facebook's
[`fishhook`](https://github.com/facebook/fishhook) for C symbol rebinding.

Compared with upstream `zxPluginsInject`, this variant changes app-group
container handling so `NSUserDefaults` uses the same redirected container policy
as `NSFileManager` in app-extension processes:

- retry app-group lookup until `LSBundleProxy` returns a usable group URL
- fall back to a Documents-backed group path when no app-group URL is available
- create redirected suite container directories before passing them to defaults
- leave main-app `NSUserDefaults` on its original container so Instagram's
  cold-launch UI dismissal flags can persist normally, while mirroring writes
  from `group.*` suites into the shared container used by app extensions

The additive group-defaults mirror keeps notification-extension account state
in sync with the main app. This matters for multi-account installs where the
extension can otherwise treat a signed-in recipient as logged out and redact or
misroute its notification.

It also normalizes Keychain access groups for sideloaded signatures. The four
intercepted `SecItem` operations resolve a usable group from a sentinel Keychain
item first and fall back to runtime entitlements. Existing access-group values
in add/query/delete dictionaries are replaced, and missing values are injected.
For `SecItemUpdate`, the query is normalized the same way while the separate
attributes-to-update dictionary is changed only when it already contains an
access group, avoiding an unintended item migration.

Keychain diagnostics report only the operation, result status, timing, and
whether a group was found/replaced/injected. Access-group strings, Keychain
values, cookies, and credentials are never logged.

Main-bundle identity is left untouched. Runtime `NSBundle` queries therefore
match the identifier in the installed app's `Info.plist`, including identifiers
rewritten by SideStore or another signer. Keeping those identities consistent
also avoids confusing UIKit/CoreUI when it registers the main app's asset
catalog. App-group and Keychain compatibility are handled by their dedicated
hooks instead of by changing the bundle identity seen by the entire process.

Do not add a global main-bundle identity spoof. In an app extension the
extension's own bundle is the main bundle, and `ExtensionFoundation` derives its
XPC listener name from that identity. Rewriting it prevents SpringBoard from
connecting to the notification extension, causing startup timeouts, unchanged
notification content, and duplicate or delayed banners.

Build with:

```sh
make -C modules/SPKSideloadFix DEBUG=0 FINALPACKAGE=1
```

`build.sh ipa --patch` builds this dylib and passes it to `ipapatch --dylib`
automatically.
