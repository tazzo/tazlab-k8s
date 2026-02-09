#!/bin/bash
# verify_manifest_purity.sh - Ensure base manifests are provider-agnostic.

FORBIDDEN=("longhorn" "metallb" "192.168.1.")
BASE_DIRS=("/workspace/tazlab-k8s/infrastructure/operators" "/workspace/tazlab-k8s/infrastructure/instances")

echo "🔍 Verifying manifest purity in: ${BASE_DIRS[*]}"
EXIT_CODE=0

for term in "${FORBIDDEN[@]}"; do
    echo "  Checking for: $term ..."
    FOUND=$(grep -r "$term" "${BASE_DIRS[@]}" | grep -v "verify_manifest_purity.sh")
    if [ -z "$FOUND" ]; then
        echo "    ✅ Clean."
    else
        echo "    ❌ Found matches:"
        echo "$FOUND"
        EXIT_CODE=1
    fi
done

if [ $EXIT_CODE -eq 0 ]; then
    echo "🏁 SUCCESS: Base manifests are decoupled."
else
    echo "🏁 FAILURE: Provider-specific hardcodings detected."
fi

exit $EXIT_CODE
