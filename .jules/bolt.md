## 2025-01-31 - Optimized Bash Merger
**Learning:** For processing large text files in Bash, AWK and sort are efficient, but their performance can be significantly improved by:
1. Minimizing I/O in AWK (removing redundant writes).
2. Skipping complex regex/transformations early (early `next` in AWK for comments).
3. Using `LC_ALL=C` for sorting (byte-wise comparison is much faster).
4. Parallelizing independent sorting tasks.
5. Using `sort -m` (merge) to combine pre-sorted files in O(N) time instead of re-sorting everything in O(N log N).

**Action:** Always check if multiple output files in AWK are redundant and can be replaced by a merge step later. Use `LC_ALL=C` for all `sort` calls unless locale-specific sorting is explicitly required.
