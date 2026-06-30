# Release Testing: v0.2.1

## Local validation

Run:

```bash
bash /home/darkdante/dune-ops-observability-addon/scripts/validate-and-install-local-console.sh
```

## Console verification

Verify in Dune Docker Console:

- the addon opens in the Console iframe;
- the WebUI header displays `Dune Ops Observability r0.2.1`;
- A3 Player Summary renders;
- A4 KPI Capability renders;
- A5 read-only KPI panels render.

## Asset checksum

After the release asset is uploaded, run:

```bash
bash scripts/verify-release-asset-checksum.sh 0.2.1
```

Use the printed SHA-256 value in the community manifest.
