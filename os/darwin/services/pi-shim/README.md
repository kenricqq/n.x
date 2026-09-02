# pi-shim

Bun HTTP shim for Pi. Serves on port `4891`.

Run directly:

```bash
bun pi_shim.ts
```

Health check:

```bash
curl http://127.0.0.1:4891/health
```

serviceConfig is defined beside the source:

```text
/Users/kenrictee/KTQQ/m0nix/darwin/services/pi-shim/default.nix
```

launchd agent is listed centrally in:

```text
/Users/kenrictee/KTQQ/m0nix/darwin/knowledge-services.nix
```
