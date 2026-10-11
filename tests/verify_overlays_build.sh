#!/bin/sh
# verify_overlays_build.sh — every kustomize root in this repository must build with a plain
# `kubectl kustomize`, i.e. under kustomize's *default* load restrictions, with no
# `--load-restrictor LoadRestrictionsNone`.
#
# Why it matters: Flux's kustomize-controller loads unrestricted, so a reference that escapes
# its own kustomize root (`../../common/...`) is invisible to the cluster and to everyone who
# only looks at Flux — until somebody builds the overlay by hand, and then the hand-build
# silently disagrees with what Flux applies. `infrastructure/instances` and
# `infrastructure/cluster-instances` could not be built plainly at all until the pgadmin and
# mnemosyne-mcp `wait-for-db-patch.yaml` references were repointed at their own roots
# (step 47, finding 3).
#
# A root that cannot build plainly yet is listed in KNOWN_BROKEN with its reason. The check
# fails if a root fails that is not listed, and it also fails if a listed root starts building,
# so the list cannot rot.
#
# Usage:  sh tests/verify_overlays_build.sh      (from anywhere; exit 0 when all is well)
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
KUSTOMIZE=${KUSTOMIZE:-kubectl kustomize}

KNOWN_BROKEN="
infrastructure/operators|accumulates operators/namespaces, which cannot build (see below)
infrastructure/operators/namespaces|references ../monitoring/namespace.yaml, outside its own root
infrastructure/operators/vso-secrets|references ../vso/vaultconnection.yaml, outside its own root
infrastructure/tls|kustomization.yaml is empty
"

is_known_broken() {
    printf '%s\n' "$KNOWN_BROKEN" | cut -d'|' -f1 | grep -qxF -- "$1"
}

known_reason() {
    printf '%s\n' "$KNOWN_BROKEN" | grep -F -- "$1|" | head -n1 | cut -d'|' -f2-
}

LIST=$(mktemp)
trap 'rm -f "$LIST"' EXIT
find "$ROOT/infrastructure" "$ROOT/apps" "$ROOT/clusters" \
     \( -name kustomization.yaml -o -name kustomization.yml \) -print \
    | sed 's#/[^/]*$##' | sort -u > "$LIST"

echo "Verifying that every kustomize root builds plainly ($KUSTOMIZE, default load restrictions)"
echo "  repository: $ROOT"

fail=0
checked=0
known=0
while IFS= read -r dir; do
    rel=${dir#"$ROOT"/}
    checked=$((checked + 1))
    if out=$($KUSTOMIZE "$dir" 2>&1 >/dev/null); then
        if is_known_broken "$rel"; then
            echo "  FAIL  $rel builds plainly now — remove it from KNOWN_BROKEN"
            fail=1
        fi
    else
        if is_known_broken "$rel"; then
            known=$((known + 1))
            echo "  known-broken  $rel — $(known_reason "$rel")"
        else
            echo "  FAIL  $rel"
            printf '%s\n' "$out" | head -n1 | sed 's/^/          /'
            fail=1
        fi
    fi
done < "$LIST"

if [ "$fail" -eq 0 ]; then
    echo "  OK    $checked roots build plainly ($known known-broken, listed in this script)"
    echo "VERIFY-OVERLAYS: OK"
else
    echo "VERIFY-OVERLAYS: FAILURES"
fi
exit "$fail"
