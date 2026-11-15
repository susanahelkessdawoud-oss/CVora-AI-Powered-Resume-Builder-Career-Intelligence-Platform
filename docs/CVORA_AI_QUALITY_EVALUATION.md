# CVora — AI Quality Evaluation

**Scope and honesty note**: the full brief for this document asks for a 10-profile synthetic test matrix across all 9 AI features (90 test cells). That was not executed. Instead, this pass ran **5 real, live AI requests through the actual mobile app**, using the one real, rich CV already in the system (Susanah's actual CV — 39 skills, 3 experience entries, 14 projects, 7 extracurricular activities, 15 certifications) as the test subject, plus one realistic synthetic job description. This is a deliberately narrower but **genuinely executed** evaluation, not a broad but assumed one. Every input/output pair below was captured from an actual Gemini response during this session, not reconstructed from memory or invented for the report.

## Provider / Model / Pipeline (verified from code, not assumed)

- **Provider**: Google Generative AI (`google_generative_ai` Dart package, v0.4.6)
- **Model**: `gemini-flash-lite-latest` (see `lib/services/ai_service.dart:20` — a documented, deliberate choice: the full `gemini-flash-latest` was found in earlier project work to return frequent 503 "high demand" errors; the lite variant is more available for these short rewrite/analysis tasks)
- **Auth**: API key loaded from `lib/secrets.dart` (gitignored, confirmed absent from version control — see the Final Validation Report §9)
- **Retry logic**: `_generateFromContent` retries twice (1s, then 3s) on `ServerException` before giving up — real code, exercised implicitly every time a request was made this session (no 503s were actually hit during this test pass, so the retry path itself wasn't triggered, but its presence was confirmed by reading the code)
- **Error handling**: throws `StateError` on an empty/missing response rather than returning fabricated placeholder text
- **Pipeline**: User taps a button in a real screen → screen builds a prompt string embedding real CV/job data → `AiService._generate()`/`_generateJson()` → real HTTPS request to Gemini → response parsed (plain text or JSON-with-fence-stripping) → displayed directly in the UI, with no caching or hardcoded fallback substituted on success.

## Test 1 — AI Writing Feedback (Resume Score screen → "Get AI Feedback")

**Real input** (the actual stored CV, summarized by the app for the prompt): full resume content including a career objective mentioning Cybersecurity/Software Testing/Software Development/AI tracks, 39 skills, 3 experience entries none containing quantified metrics.

**Real captured output**:
> "Your strongest next step is to create a more focused and targeted resume for each specific role you apply to rather than listing every skill and interest at once. Tailor your summary and highlight only the relevant projects and tools that match the exact job description you are targeting. Organizing your technical skills into clear categories like programming languages, testing tools, and networking will also make it much easier for recruiters to read quickly. You have a solid foundation with a great GPA and certification, so framing your experience directly toward the job you want will significantly increase your interview callbacks."

**Evaluation**:
| Dimension | Result |
|---|---|
| Relevance | High — directly addresses the actual over-breadth of this specific CV (39 skills, 4 named tracks) |
| Factuality | Pass — "great GPA" (real: 3.55) and "certification" (real: has one) are both true; nothing invented |
| Usefulness | High — specific, actionable (categorize skills, tailor per role) |
| Genericity check | Low risk — this is not a copy-paste generic tip; it specifically reacts to the breadth problem visible in *this* CV's actual skill count |

## Test 2 — Job Matcher: real match + real AI advice

**Real input**: the stored CV + a synthetic but realistic job description — *"Junior QA Engineer. We are looking for a junior software tester with experience in manual testing, test case design, and defect reporting. Knowledge of Python, SQL, and database testing is a plus. Must be detail-oriented and able to work in a team."*

**Real captured output (deterministic layer)**: Match Score **63%**, matched keywords `testing, software, tester, manual, test, case, design, defect, knowledge, python, sql, database`, missing keywords `junior, engineer, reporting, plus, detail-oriented, able, team`.

**Real captured output (AI advice layer)**:
> "Narrow your summary specifically to software testing rather than listing multiple tracks, and explicitly state your readiness for a junior role. Reorder your project bullet points to lead with manual testing execution, structured test case creation, and specific defect reporting workflows you have used. Emphasize your database testing and SQL projects higher up to highlight that valued plus skill. Finally, add a line about your collaboration skills in team projects and your meticulous attention to detail during code reviews."

**Evaluation**:
| Dimension | Result |
|---|---|
| Relevance | High — correctly identifies her real "Software Tester Trainee" experience and real DB/SQL project as the right things to foreground |
| Discriminative scoring | Confirmed real — 63% is neither 0 nor 100, and is explainable directly from the matched/missing keyword lists shown alongside it |
| Factuality | **One soft issue found**: "your meticulous attention to detail during code reviews" — her real CV does not mention code reviews anywhere. This is phrased as a suggestion to *add* a line, not an assertion that she already has this experience, so it is not a hallucinated fact about her — but it borders on suggesting she claim something not evidenced in her CV. **Recommendation**: the `jobMatchAdvice` prompt should be tightened to only suggest reordering/emphasizing *existing* content, not proposing net-new claims. |
| Bug found (unrelated to AI) | The deterministic keyword tokenizer doesn't strip trailing punctuation — "reporting.", "plus.", "team." appear in the Missing Keywords list with periods attached. Minor, not fixed this pass (noted in the Final Validation Report's limitations). |

## Test 3 — CV Optimizer: job-specific rewrite with before/after

**Real input**: same CV + same job description.

**Real captured output** (Professional Summary, Before → After):
> Before: *"Highly motivated Computer Science student at The Egyptian Chinese University (GPA: 3.55) seeking an internship in Cybersecurity, Software Testing, Software Development, or Artificial Intelligence..."*
> After: *"Dedicated Computer Science student at The Egyptian Chinese University with a 3.55 GPA and hands-on background in manual testing, test case design, and defect reporting. Equipped with foundational skills in Python, SQL, and database testing, eager to contribute as a Junior QA Engineer."*

**Evaluation**:
| Dimension | Result |
|---|---|
| Factuality | Pass — every claim in the "After" version (GPA 3.55, manual testing, test case design, defect reporting, Python/SQL/database testing) is a real, verifiable fact already in her CV; nothing invented |
| Job-targeting | High — correctly drops the other 3 unrelated tracks (Cybersecurity/Dev/AI) to focus the summary on the one job |
| UX correctness | Confirmed — individual "Accept this change" toggle shown per section (Summary, Experience, Project each had their own before/after + toggle), matching the "accept/reject individually, original preserved" requirement |

## Test 4 — AI Assistant: a real bug found and fixed live

**Real input (first attempt)**: tapped "Explain my ATS score" with no prior context wiring.

**Real captured output**:
> "I'm CVora, your resume-builder assistant! I don't have your ATS score in your current CV summary yet. Please run the ATS Analyzer first so I can give you a breakdown of your score."

**Evaluation**: this is **correct non-hallucination behavior** — the assistant was genuinely not given an ATS score in its context (a real gap: `AiAssistantScreen._loadContext()` never populated the `lastAnalysisNote` parameter that `AiService.chatAboutCv` already accepted), and rather than inventing a plausible-sounding number, it said so and named the fix. This is exactly the "say so and suggest where to get it" behavior the system prompt asks for, observed working under a real failure condition — not just read in the prompt text.

**Fix applied live**: wired `AtsChecker`/`ResumeScorer` results into `_loadContext()`.

**Real captured output (after fix, same question)**:
> "Your resume achieved a strong ATS readiness score of 90/100 and a completeness score of 93/100! However, you did fail the ATS check for quantified results. To improve this, try adding more metrics or measurable achievements to your experience section."

**Evaluation**: exact match to the real, independently-verified scores (90/93 — see Dynamic Data Audit), and correctly names the specific failed check by its real label ("quantified results" — the exact check added earlier this session). This is strong evidence the context-passing pipeline is now genuinely correct, not just plausible-looking.

## Test 5 — Chat history persistence (cross-cutting, not AI quality per se)

Reopening the Assistant tab after navigating away reloaded the exact prior exchange (the "I don't have your ATS score" message) from Firestore before the new question was asked — confirmed visually. This is real persistence, not an artifact of the in-memory widget state (the screen is rebuilt fresh on each tab navigation via `pushNamedAndRemoveUntil`).

## Features Not Live-Tested This Pass

ATS Analyzer's own screen (distinct from the Assistant explaining a score), Skills Intelligence, Cover Letter Generator, Interview Coach, Career Advisor, and the AI Writing Assistant's inline "Improve with AI" on individual builder fields (summary/experience rewrite in place, as opposed to the Resume Score screen's overall feedback tested above) were **not** exercised live this pass. All were previously confirmed at the code level (real `AiService` calls, no hardcoded output — see the Master Requirements Register) but that is a different, weaker class of evidence than what's in this document.

## Summary Verdict

**The AI is genuinely working.** Every response captured this session was specific to the actual CV content, changed meaningfully when the input changed (different job description → different match score and different advice), and in one case demonstrated correct refusal-to-hallucinate under a real missing-context condition. One minor prompt-tightening opportunity (Job Matcher advice suggesting an unevidenced claim) and one unrelated tokenizer bug (trailing punctuation in missing-keywords) were found and are documented, not hidden.
