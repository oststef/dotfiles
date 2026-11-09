#!/bin/sh
# Account limits are global, so any session's latest herdr-metrics snapshot is good enough.
f=$(ls -t "${XDG_CACHE_HOME:-$HOME/.cache}"/herdr-agent-metrics/claude/*.json 2>/dev/null | head -1)
[ -n "$f" ] || exit 0
jq -r '
  def bar: (. / 10 | round) as $n | ("█" * $n) + ("░" * (10 - $n));
  [.limits[] | "\(.label) \(.used_percent | bar) \(.used_percent | round)%"] | join("  ")
' "$f"
