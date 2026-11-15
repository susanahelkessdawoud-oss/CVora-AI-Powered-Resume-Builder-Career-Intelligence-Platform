# CVora — Dynamic Data Audit

Scope: verify that displayed numbers come from real data, not fabricated/fixed values, per the explicit "no fake statistics" requirement. This document only reports what was **actually tested this session**, with evidence — not a theoretical review of what the code "should" do.

## Headline finding (resolved this session)

Earlier this session, the Home dashboard consistently showed **100 ATS ready / 100% Complete** for the demo account's CV, which read as suspicious/static to the user. Two things were actually true at once:

1. **The numbers were never hardcoded.** They are computed live by `ResumeScorer.score()` and `AtsChecker.check()`, real synchronous functions that read the actual `Resume` object's fields (see Data Source Traceability below).
2. **But the scoring model had no headroom.** Both scorers gave full marks for merely having a long-enough section, with no check for *quality* of content — so once a CV cleared every presence/length threshold, it flatlined at 100 with nothing further to measure, which is legitimately bad feedback even though it wasn't "fake."

**Fix applied and verified live**: added a "quantified results" signal (percentages, counts, rankings) to both scorers, with partial credit for detailed-but-unquantified content. Verified before/after on the real demo CV:

| Metric | Before fix | After fix |
|---|---|---|
| ATS ready | 100 | 90 |
| Complete | 100% | 93% |
| Skills | 39 (unchanged — correct, it's a direct count) | 39 |
| Dashboard "Next best step" | hidden (no gaps left to suggest) | **"Quantify your experience — your descriptions are detailed, but none include a measurable result — a percentage, a count, a ranking."** |

Screenshot evidence captured both before and after this change during the live session.

## Live reactivity test (the actual proof, not just code review)

To settle "are these numbers really dynamic," the real demo CV was edited through the actual app UI (not a backend shortcut) and the result observed:

1. Opened the real Resume Builder for the demo account's CV.
2. Deleted one skill ("Kali Linux") from a real list of 36.
3. Walked the full wizard (Summary → Experience → Skills → Projects → Achievements → Certifications → Style → Template) to **Complete**.
4. Returned to Home.

**Result**: "Skills" went from 36 → 35 immediately, and "edited just now" updated. This is direct proof `_load()` re-fetches from Firestore and the scorers recompute on every return to Home — not a cached or fixed value.

(The removed skill was later restored, along with a much larger, fully accurate content update — see below — bringing the real total to 39.)

## Full CV content replacement (separate real-data verification)

The user supplied the complete, real content of their CV (career objective, 3 experience entries, 39 skills, 14 projects, 7 extracurricular activities including NASA Space Apps Challenge, 15 certifications, 1 education entry). This was written directly into the Firestore document (matching the exact `Resume.toJson()` schema used by the app's own `DatabaseService`) and **independently read back and counted** via a separate verification script — not assumed from the write succeeding:

```
skills: 39
experience: 3
projects: 14
achievements: 7
certifications: 15
education: 1
```

All counts match the supplied content exactly. This was then re-confirmed visually in the running app (Skills tile showing 39, "edited just now").

## Data Source Traceability

| Displayed value | Source | Model/Service | Calculation | Refresh | Empty state |
|---|---|---|---|---|---|
| Home "ATS ready" | Firestore `resumes/{id}` | `AtsChecker.check(resume)` | 10 weighted deterministic checks (contact, summary, experience, education, skills, dates, unsafe chars, content length, **quantified results**) | On every `_load()` (screen init + return from any pushed screen) | N/A — only rendered when `_activeResume != null`; otherwise `_emptyStateCard()` shows a Create/Upload prompt |
| Home "Complete" % | Firestore `resumes/{id}` | `ResumeScorer.score(resume)` | 7 weighted criteria (contact, title, summary, **quantified experience**, education, skills count, extras) | Same as above | Same as above |
| Home "Skills" count | Firestore `resumes/{id}.skills` | Direct `.length` | None — a straight count | Same as above | Shows `0` if the array is empty (not hidden) |
| Home "Next best step" | `ResumeScorer.score(resume).suggestions` | Filtered to `!isPositive`, first item shown | Generated as a byproduct of scoring, not separately invented | Same as above | Card is omitted entirely (`_nextBestStep` returns `[]`) when there are no gaps |
| Home active-CV title/template/"edited Xm ago" | Firestore `resumes/{id}` | Direct fields | `_timeAgo()` relative-time formatting | Same as above | N/A |
| Profile "completion %" | Firestore `userProfiles/{uid}` + Auth | `_completionPct` getter | 5 boolean checks / 5 | On screen load | Shows 0% if no profile doc exists yet |
| Activity feed | Firestore `resumes` (all docs for the user) | `ActivityScreen` | Sorted by `updatedAt`; "Created" vs "Updated" inferred from `createdAt`≈`updatedAt` | On screen load / pull-to-refresh | **Real empty state**: "No activity yet — Create or edit a CV and it will show up here." (This replaced a decorative SnackBar this session.) |

## What was NOT re-verified this pass

- The other AI-tool screens (CV Analyzer, Job Matcher, Cover Letter, etc.) were confirmed via code/grep to call real `AiService` methods (no hardcoded scores found anywhere in a repository-wide search), but were **not re-run live** in this specific audit pass — see the Master Requirements Register, section 11–19, for the honest PARTIAL status on each.
- Behavior with **zero CVs** (true empty-state dashboard) was not re-tested live this pass, since the demo account always has at least one CV. The code path exists (`_emptyStateCard`) but wasn't exercised.
- A second, independent test account was not created to verify dashboard numbers differ correctly per-user (see Backend audit for the rules-level isolation proof, which is a different kind of evidence than a live two-account UI test).
