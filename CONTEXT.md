# Machine configuration

The named machines and user environments managed by this configuration.

## Language

**Machine**:
A named computer profile with a platform and primary user.
_Avoid_: Host (used here for platform capability flags).

**Machine paths**:
The locations of a machine's configuration checkout, dotfiles, scripts, and snippets relative to its user's home.
_Avoid_: Darwin paths (these locations also belong to Linux machines).
