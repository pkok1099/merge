#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
OUT_BULK="ublock-merged.txt"
OUT_BLOCK="filter-block.txt"
OUT_ALLOW="filter-allow.txt"
OUT_COSMETIC="filter-cosmetic.txt"
OUT_META="filter-metadata.txt"

TMPDIR=$(mktemp -d)
CURL_CONFIG="$TMPDIR/curl_config"

REPOS=(
    "https://api.github.com/repos/uBlockOrigin/uAssets/contents/filters"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/BaseFilter/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/SpywareFilter/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/AnnoyancesFilter/Popups/sections"
    "https://api.github.com/repos/AdguardTeam/AdguardFilters/contents/AnnoyancesFilter/Cookies/sections"
)

# --- 1. FETCH API LISTS ---
echo "⚡ Fetching API lists..."
AUTH_HEADER=()
[ -n "$GITHUB_TOKEN" ] && AUTH_HEADER=(-H "Authorization: token $GITHUB_TOKEN")

for i in "${!REPOS[@]}"; do
    curl -sL "${AUTH_HEADER[@]}" "${REPOS[$i]}" -o "$TMPDIR/api_$i.json" &
done
wait

if grep -qi "rate limit exceeded" "$TMPDIR"/api_*.json; then
    echo "❌ ERROR: GitHub API Rate Limit exceeded!"
    exit 1
fi

# --- 2. DOWNLOAD QUEUE ---
jq -r 'if type=="array" then .[] | select(.type=="file" and (.name | endswith(".txt"))) | .download_url else empty end' "$TMPDIR"/api_*.json | \
awk -v dir="$TMPDIR" '{ 
    print "url = \"" $0 "\""; 
    print "output = \"" dir "/file_" NR ".tmp\"";
    print "fail"; 
}' > "$CURL_CONFIG"

echo "⬇️  Downloading files (Parallel + Retry)..."
curl -sL --parallel --parallel-max 15 --retry 3 --retry-delay 2 --config "$CURL_CONFIG" || {
    echo "❌ ERROR: Download failed."
    exit 1
}

# --- 3. CLASSIFICATION & NORMALIZATION ---
echo "🧹 Normalizing & Classifying..."
# Skip comments/empty lines early to avoid expensive transformations.
# Avoid writing to bulk.raw here; it's reconstructed faster later using sort -m.
LC_ALL=C awk -v f_block="$TMPDIR/block.raw" \
             -v f_allow="$TMPDIR/allow.raw" \
             -v f_cosmetic="$TMPDIR/cosmetic.raw" \
             -v f_meta="$TMPDIR/meta.raw" \
    '
    /^!/ || !NF { next }
    { gsub(/\r/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, ""); }
    /^!/ || !NF { next }
    !seen[$0]++ {
        if ($0 ~ /^@@/) print $0 >> f_allow
        else if ($0 ~ /##|#@#|#\?#|#\$#/) print $0 >> f_cosmetic
        else if ($0 ~ /^\[.*\]$/) print $0 >> f_meta
        else print $0 >> f_block
    }
' "$TMPDIR"/file_*.tmp

# --- 4. INTEGRITY CHECK ---
# Ensure we actually have data in at least one of the main categories
if [ ! -s "$TMPDIR/block.raw" ] && [ ! -s "$TMPDIR/allow.raw" ] && [ ! -s "$TMPDIR/cosmetic.raw" ]; then
    echo "❌ ERROR: Merged data is empty. Aborting push."
    exit 1
fi

# --- 5. SORTING & FINAL ASSEMBLY ---
echo "⚡ Sorting & Assembling (Parallel)..."
for cat in block allow cosmetic meta; do
    (
        target_var="OUT_${cat^^}"
        # Use C locale for faster, deterministic sorting
        LC_ALL=C sort "$TMPDIR/$cat.raw" > "$TMPDIR/$cat.sorted" 2>/dev/null || touch "$TMPDIR/$cat.sorted"

        case $cat in
            block) title="Network Blocking Rules" ;;
            allow) title="Exception Rules" ;;
            cosmetic) title="Cosmetic Rules" ;;
            meta) title="Metadata" ;;
        esac

        {
            echo "! Title: $title"
            echo "! Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
            echo "! Total Rules: $(wc -l < "$TMPDIR/$cat.sorted")"
            echo ""
            cat "$TMPDIR/$cat.sorted"
        } > "${!target_var}"
    ) &
done
wait

# Reconstruct bulk merged file using fast merge-sort (O(n)) from sorted categories
LC_ALL=C sort -m "$TMPDIR"/block.sorted "$TMPDIR"/allow.sorted "$TMPDIR"/cosmetic.sorted "$TMPDIR"/meta.sorted > "$TMPDIR/bulk.sorted"
{
    echo "! Title: Bulk Merged Filters"
    echo "! Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "! Total Rules: $(wc -l < "$TMPDIR/bulk.sorted")"
    echo ""
    cat "$TMPDIR/bulk.sorted"
} > "$OUT_BULK"

echo "✅ Success!"
rm -rf "$TMPDIR"
