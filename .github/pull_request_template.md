<!--
Translating a language? Append ?template=translation.md to this page's URL for
the translation checklist instead.
-->

**What this changes**
<!-- One or two sentences. Link the issue it closes, if there is one. -->

**Why**
<!-- The problem behind the change, not a restatement of the diff. -->

**Type**

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor or cleanup
- [ ] Documentation

**Tested on device**

<!-- There is no test suite: verification is manual, on a device. -->

- Instagram version(s):
- iOS version(s) and device(s):
- Install type: <!-- sideloaded / TrollStore / rootless / rootful -->

- [ ] Works on the latest Instagram
- [ ] Works on 410.1.0, the last version supported on iOS 15 <!-- if the change touches a hooked surface -->

**Checklist**

- [ ] Hooked Instagram classes and methods are declared in `src/InstagramHeaders.h`, not inline
- [ ] New symbols are prefixed `SPK` / `spk_`
- [ ] New preferences are surface-prefixed and read through `SPKUtils`
- [ ] User-facing text goes through `SPKL` / `SPKLC` / `SPKLP` with semantic keys, and `tools/lint-i18n.py` passes
- [ ] `README.md` and `FEATURES.md` updated, if relevant

**Screenshots or recording**
<!-- Anything touching UI. Before and after, where it helps. -->
