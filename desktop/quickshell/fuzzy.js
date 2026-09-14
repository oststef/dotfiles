// Fuzzy matching for the launcher. Plain JS so `node fuzzy.js` runs the
// self-check at the bottom; QML pulls it in with `import "fuzzy.js" as Fuzzy`.

const WORD_BREAKS = " -_./";

// Score `query` against `text` as a subsequence match. Higher is better;
// -Infinity means the query's characters don't appear in `text` in order.
// Not a sign test: gap and length penalties push a poor-but-real match below 0.
// ponytail: greedy leftmost match, not the optimal alignment fzy computes with
// DP. Fine for app names; revisit if a wrong match ever outranks a right one.
function score(query, text) {
    if (query === "")
        return 0;
    if (!text)
        return -Infinity;

    const q = query.toLowerCase();
    const t = text.toLowerCase();
    let total = 0;
    let from = 0; // next index in t we're allowed to match at
    let run = 0;  // how many query chars have matched back-to-back

    for (let i = 0; i < q.length; i++) {
        const at = t.indexOf(q[i], from);
        if (at < 0)
            return -Infinity;

        // what people actually type: the start of the name, or of a word in it
        if (at === 0)
            total += 12;
        else if (WORD_BREAKS.indexOf(t[at - 1]) >= 0)
            total += 8;

        run = (at === from && i > 0) ? run + 1 : 0;
        total += run * 6;

        // gaps are bad, but cap the penalty so long names stay reachable
        total -= Math.min(at - from, 6);
        from = at + 1;
    }

    // tie-break toward shorter names: "Files" over "Files (recent)"
    return total - text.length * 0.1;
}

// Best score for a desktop entry: its name, or failing that its description
// ranked strictly below every name match.
function scoreEntry(query, entry) {
    const byName = score(query, entry.name);
    if (isFinite(byName))
        return byName;

    // -1000 keeps every description match below every name match
    return Math.max(score(query, entry.genericName), score(query, entry.comment)) - 1000;
}

// ── self-check: node fuzzy.js ──
if (typeof module !== "undefined") {
    const ok = (cond, msg) => {
        if (!cond)
            throw new Error("FAIL: " + msg);
    };
    const rank = (q, names) => names.map(n => [n, score(q, n)]).filter(x => isFinite(x[1])).sort((a, b) => b[1] - a[1]).map(x => x[0]);

    // the whole reason this file exists: gaps are allowed
    ok(isFinite(score("fox", "Firefox")), "fox should match Firefox");
    ok(!isFinite(score("zqx", "Firefox")), "absent characters must not match");
    ok(!isFinite(score("foxx", "Firefox")), "order and count must be respected");
    ok(score("", "anything") === 0, "empty query scores flat, leaving alphabetical order");

    // consecutive characters beat scattered ones
    ok(rank("chr", ["Character Map", "Chromium"])[0] === "Chromium", "chr -> Chromium");
    // a word start beats a mid-word hit
    ok(rank("gimp", ["Digital Image GIMP Plugin", "GIMP"])[0] === "GIMP", "gimp -> GIMP");
    // shorter name wins an otherwise equal match
    ok(rank("files", ["Files (recent)", "Files"])[0] === "Files", "files -> Files");
    // name match outranks any description match
    const named = {name: "Kitty", genericName: "", comment: ""};
    const described = {name: "Zzz", genericName: "Terminal", comment: "kitty-like"};
    ok(scoreEntry("kitty", named) > scoreEntry("kitty", described), "name beats description");
    ok(isFinite(scoreEntry("terminal", described)), "description still matches when the name doesn't");
    ok(!isFinite(scoreEntry("zqx", described)), "no match anywhere stays no match");

    console.log("fuzzy.js: all checks passed");
}
