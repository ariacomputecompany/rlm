#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

python3 - <<'PY' "$root"
import json
import sys
from pathlib import Path

import jsonschema

root = Path(sys.argv[1])

pairs = [
    ("schemas/session-manifest.v1.schema.json", "examples/session-manifest.v1.json"),
    ("schemas/trajectory-manifest.v1.schema.json", "examples/trajectory-manifest.v1.json"),
    ("schemas/mesh-manifest.v1.schema.json", "examples/mesh-manifest.v1.json"),
    ("schemas/agent-config.v1.schema.json", "examples/agent-config.v1.json"),
    ("schemas/jets-envelope.v1.schema.json", "examples/jets-envelope.v1.json"),
]

for schema_rel, example_rel in pairs:
    schema = json.loads((root / schema_rel).read_text())
    example = json.loads((root / example_rel).read_text())
    if schema["properties"]["protocol"]["properties"]["name"]["const"] != example["protocol"]["name"]:
        raise SystemExit(f"{example_rel}: protocol name mismatch")
    if schema["properties"]["protocol"]["properties"]["version"]["const"] != example["protocol"]["version"]:
        raise SystemExit(f"{example_rel}: protocol version mismatch")
    jsonschema.Draft202012Validator(schema).validate(example)

print("validated protocol examples")
PY
