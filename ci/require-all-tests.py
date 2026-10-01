#!/usr/bin/env python3

import json
import sys

model = json.load(sys.stdin)
disabled = []

for test in model["tests"]:
    properties = {
        property_["name"]: property_["value"]
        for property_ in test.get("properties", [])
    }
    if properties.get("DISABLED"):
        disabled.append(test["name"])

if disabled:
    print("CI requires every integration test to be enabled:", file=sys.stderr)
    for name in disabled:
        print(f"  {name}", file=sys.stderr)
    raise SystemExit(1)
