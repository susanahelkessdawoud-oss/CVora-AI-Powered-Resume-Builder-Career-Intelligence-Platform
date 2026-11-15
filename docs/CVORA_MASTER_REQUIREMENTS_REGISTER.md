# CVora — Master Requirements Register

Consolidated from the full development conversation history for this project (no requirement here was re-requested from the user; everything is recovered from prior instructions and the current codebase). Statuses use the fixed vocabulary: **PASS**, **PARTIAL**, **FAIL**, **NOT IMPLEMENTED**, **BLOCKED**, **NOT APPLICABLE**.

A companion document, `CVORA_FINAL_VALIDATION_REPORT.md`, explains how each status was actually verified and what evidence backs it. This register is the index; that report is the evidence.

---

## 1. Product Identity

| ID | Requirement | Expected Behavior | Current Implementation | Screen/Module | Code Files | Status |
|---|---|---|---|---|---|---|
| PI-1 | App is an AI-powered resume/CV builder and career intelligence platform | Build, analyze, optimize, tailor resumes with AI throughout | Implemented across 20+ screens | All | `lib/screens/**` | PASS |
| PI-2 | Target audience: students/new grads (NTI/iSchool X/ODC program context) | Content and demo account reflect a CS student persona | Demo account "Susanah Elkess Dawoud" is a real CS student CV | Home, Profile | `lib/screens/auth/login_screen.dart` | PASS |
| PI-3 | App name stays "CVora" | No rename | Confirmed unchanged throughout | App-wide | `pubspec.yaml`, `android/app/build.gradle*` | PASS |

## 2. Branding and Logo

See `CVORA_BRANDING_VERIFICATION.md` for full detail.

| ID | Requirement | Expected Behavior | Current Implementation | Status |
|---|---|---|---|---|
| BR-1 | Use the exact original CVora logo asset supplied by the user | A real file (PNG/SVG) provided by the user, used unmodified everywhere | **No such file was ever attached to this conversation.** Two hand-built recreations exist (superseded navy+gold mark, then the current blue/purple orbit-ring mark), neither of which is "the original asset" | **BLOCKED** — explicitly flagged to the user; they confirmed they would attach the real file; it has not arrived yet |
| BR-2 | Logo renders correctly on Splash, Login, Create Account, Home, app icon | Consistent, undistorted rendering | Current (recreated) mark renders correctly and consistently on all five | PASS *for the current placeholder mark only* — will need re-verification once the real asset arrives |

## 3. UI Design / Visual Identity

| ID | Requirement | Expected Behavior | Current Implementation | Status |
|---|---|---|---|---|
| UI-1 | Match the detailed screen-by-screen design reference ("kenzy" document): dark-first navy/blue/purple palette, Outfit+Inter type, 18px card radius, 52px controls | Design system applied app-wide | `AppTheme` rewritten to this exact spec; `CvCard`/`IconTile`/`StatusChip`/`AiBadge`/`ScoreRing`/`MetricBar`/`IssueRow`/`CvAppBar`/`CvBottomNav` component library built | PASS — verified live on-device (screenshots), not just code |
| UI-2 | Purple-and-white identity (later message) | — | The shipped design is navy/blue/cyan/purple-on-dark, not a purple-and-white light theme. This is the design actually requested and approved earlier in the same session (the "kenzy" screenshots); the later audit prompt's phrase "purple-and-white" was not accompanied by new reference images | PARTIAL — flagged as a possible terminology mismatch, not acted on without clarification since it would mean discarding already-approved, already-verified work on an unconfirmed reading |
| UI-3 | Bottom navigation: Home / My CVs / Create / Assistant / Profile, persistent across all five | Always present, correct tab highlighted, no dead-ends | Implemented (`CvBottomNav`); a real dead-end bug (My CVs and Create had no way back) was found and fixed this session | PASS — verified live by tapping each tab via adb and confirming the bar persists |
| UI-4 | Screens not explicitly rebuilt inherit the new design system automatically | Colors/type/shapes update without needing per-screen rewrites | Confirmed true for CV Analyzer, ATS Analyzer, etc. — verified via live screenshot during testing | PASS |

## 4. Mobile Navigation

| ID | Requirement | Current Implementation | Test Method | Status |
|---|---|---|---|---|
| NAV-1 | Back navigation works from every pushed screen | `Navigator.pop`/`maybePop` used consistently; `CvAppBar` back button hides itself when `!Navigator.canPop` | Manual adb-driven walkthrough | PASS |
| NAV-2 | No dead-end screens reachable from the bottom nav | All 5 tab destinations (`/home`, `/my-resumes`, `/document-type`, `/ai-assistant`, `/profile`) carry `CvBottomNav` | Live test: tapped Create and My CVs from Home, confirmed bar present both times (screenshots captured) | PASS (fixed this session — was previously FAIL) |
| NAV-3 | State is not lost switching tabs | `pushNamedAndRemoveUntil` resets to each tab's root; in-progress CV edits are saved explicitly before navigation, not relied on implicit state retention | Code review | PARTIAL — true for saved data; unsaved in-progress builder edits are not preserved if a tab is switched mid-edit without saving (no autosave-on-navigate-away implemented) |

## 5. Authentication

| ID | Requirement | Current Implementation | Test Method | Status |
|---|---|---|---|---|
| AUTH-1 | Email/password registration | `AuthService.register` → Firebase `createUserWithEmailAndPassword` | Code review; not re-run end-to-end this session (was verified in earlier sessions per project history) | PARTIAL — implementation present and correct; not independently re-tested in this audit pass |
| AUTH-2 | Login (valid/invalid credentials) | `AuthService.login`, Firebase error codes surfaced as snackbars | Code review only this pass | PARTIAL |
| AUTH-3 | Password reset / forgot password | `ForgotPasswordScreen` (new this session) calls `AuthService.resetPassword` → Firebase `sendPasswordResetEmail`; neutral response regardless of whether the account exists (doesn't leak which emails are registered) | Code review; not live-tested with a real inbox | PARTIAL |
| AUTH-4 | "Remember me" / session persistence across restart | `PreferencesService` stores the flag; `SplashScreen` checks `AuthService.isLoggedIn()` on cold start | Verified empirically all session: the app has repeatedly cold-started straight into Home as the logged-in demo user | PASS |
| AUTH-5 | Logout | `AuthService.logout()` → Firebase `signOut`, routes to `/login` | Code review | PASS (previously verified in-session) |
| AUTH-6 | Two-step signup (account → career goals) | `CreateAccountScreen` → `CareerGoalsScreen`, writes `userProfiles/{uid}` | Code review | PARTIAL — not live end-to-end tested this pass |
| AUTH-7 | Quick Demo Login | One-tap login as `demo.susanah@cvora.app` | Used successfully dozens of times this session as the primary test account | PASS |

## 6. User Profiles

| ID | Requirement | Current Implementation | Status |
|---|---|---|---|
| PROF-1 | Profile screen shows real user data | `ProfileScreen` reads `AuthService.currentUser` + `userProfiles/{uid}` | PASS |
| PROF-2 | Profile completion % is calculated, not fixed | `_completionPct` getter checks 5 real fields | PASS |
| PROF-3 | Edit display name actually persists | **Bug found and fixed this session**: previously wrote to a dead Firestore field; now calls `AuthService.updateProfile` | PASS (post-fix; verified by code path, re-confirm live recommended) |
| PROF-4 | Add industry actually appends to the real list | **Bug found and fixed this session**: previously wrote to a dead field; now appends to `preferredIndustries` | PASS (post-fix) |
| PROF-5 | Languages shown reflect what's actually saved | **Bug found and fixed this session**: previously hardcoded "Arabic · English" regardless of data | PASS (post-fix) |

## 7. Dashboard

See `CVORA_DYNAMIC_DATA_AUDIT.md` for full live-tested evidence.

| ID | Requirement | Status |
|---|---|---|
| DASH-1 | CV count/stats reflect real data, not fixed numbers | PASS — proven live by editing the real CV and watching the number change |
| DASH-2 | Dashboard recomputes on return from any screen | PASS — `_load()` re-runs via `.then()` on every `Navigator.push` return |
| DASH-3 | Empty state when the user has no CV | PASS — code path exists (`_emptyStateCard`); not re-verified live this pass since the test account always has a CV |
| DASH-4 | "Next best step" card is grounded in real scorer output, not invented copy | PASS — pulled directly from `ResumeScorer.score().suggestions` |
| DASH-5 | Notification bell leads somewhere real | PASS (fixed this session) — was a decorative SnackBar, now opens a real Activity feed built from actual resume timestamps |

## 8. CV Management

| ID | Requirement | Current Implementation | Status |
|---|---|---|---|
| CVM-1 | Create, open, edit, save CV | `DocumentTypeScreen` → `ResumeBuilderScreen` → `DatabaseService` | PASS (builder flow walked end-to-end live this session while investigating the "static numbers" question) |
| CVM-2 | Delete CV (with confirmation) | `MyResumesScreen.deleteResume` | PASS (code review; confirmation dialog present) |
| CVM-3 | Reopen CV after app restart — data persists | Firestore-backed, not local-only | PASS — the real CV data edited this session (skills, projects, etc.) persisted across multiple app relaunches, confirmed by direct Firestore read-back |
| CVM-4 | Rename / duplicate CV | — | **NOT IMPLEMENTED** — no rename or duplicate action exists in `MyResumesScreen`'s current menu (only Edit/Delete) |
| CVM-5 | Search/filter/sort "My CVs" | — | **NOT IMPLEMENTED** — `MyResumesScreen` lists all documents with no search field, filter chips, or sort control |

## 9. CV Builder / Sections

| ID | Requirement | Current Implementation | Status |
|---|---|---|---|
| SEC-1 | Personal Info | Step 1 of builder | PASS |
| SEC-2 | Professional Summary | Step 2, with "Improve with AI" | PASS |
| SEC-3 | Experience (multi-entry) | Step 3 | PASS — verified 3 real entries persisted |
| SEC-4 | Skills (add/remove, chip UI) | Step 4 | PASS — verified live (added/removed skills, confirmed persistence) |
| SEC-5 | Projects (multi-entry) | Step 5 | PASS — verified 14 real entries persisted |
| SEC-6 | Achievements (multi-entry) | Step 6 | PASS — verified 7 real entries persisted |
| SEC-7 | Certifications (multi-entry) | Step 7 | PASS — verified 15 real entries persisted |
| SEC-8 | Education | Model field exists (`Resume.education`); the builder wizard does not expose it as a distinct numbered step in the walkthrough performed this session | PARTIAL — data round-trips correctly (confirmed via direct Firestore read), but the dedicated UI step was not located during the live walkthrough and needs explicit confirmation |
| SEC-9 | Languages as a first-class section | No dedicated field on the `Resume` model | **NOT IMPLEMENTED** — folded into the flat `skills` list as a workaround ("English (B2)", "French (Intermediate)") rather than a real structured languages section |
| SEC-10 | Volunteering / Awards / Publications / Interests / Custom sections | — | **NOT IMPLEMENTED** — no model fields or builder steps exist for these |
| SEC-11 | Section reordering | — | **NOT IMPLEMENTED** in the current (pre-redesign) builder; the redesign spec's "drag to reorder" was never built |
| SEC-12 | Style picker (Modern/Professional/Creative) | Step 8 | PASS — found and fixed a real 2px render overflow on the Modern thumbnail this session |
| SEC-13 | Template picker (Template 1/2/3) | Step 9 | PASS — selection UI works; visual distinctness of the 3 templates in the actual exported PDF was not re-verified this pass |

## 10. CV Templates / Live Preview

| ID | Requirement | Status |
|---|---|---|
| TPL-1 | Multiple genuinely different templates | PARTIAL — 3 templates exist with distinct thumbnail previews; full-document visual distinctness in the actual PDF export was not re-verified this pass |
| TPL-2 | Live preview matches what exports | PARTIAL — `ResumePreviewScreen` exists and was opened live this session; pixel-exact match to PDF export not independently re-checked |

## 11–19. AI Features

Full detail in `CVORA_AI_VALIDATION_REPORT.md` is **not produced in this pass** (see Final Validation Report's "Not Completed This Pass" section for why). Summary below is based on code-level verification done across this session (confirmed every AI tool screen calls into real `AiService`/Gemini methods — no hardcoded scores found via repository-wide grep) plus specific live tests actually performed.

| ID | Feature | Code-Level Verification | Live Test This Session | Status |
|---|---|---|---|---|
| AI-1 | AI Writing Assistant (summary/experience rewrite) | Confirmed real Gemini calls (`improveSummary`, `improveExperienceDescription`) | Not re-run live this pass | PARTIAL |
| AI-2 | AI CV Analyzer | Confirmed real Gemini call (`analyzeResume`) with JSON schema | Not re-run live this pass | PARTIAL |
| AI-3 | ATS Analyzer | Deterministic checks (`AtsChecker`, no AI call) + AI fix suggestions (`atsFeedback`) | **Live-tested extensively this session** — opened the screen, confirmed it shows a real "Analyze My CV" action rather than a pre-filled score (correct empty-state behavior) | PASS for the deterministic layer; PARTIAL for the AI-suggestion layer (not re-run live) |
| AI-4 | Job Matcher | Confirmed real logic (`JobMatcher.match`, keyword overlap) + AI advice (`jobMatchAdvice`) | Not re-run live this pass | PARTIAL |
| AI-5 | CV Optimizer | Confirmed real Gemini call (`optimizeForJob`) | Not re-run live this pass | PARTIAL |
| AI-6 | Skills Intelligence | Confirmed real Gemini call (`analyzeSkills`) | Not re-run live this pass | PARTIAL |
| AI-7 | Cover Letter Generator | Confirmed real Gemini call (`generateCoverLetter`) | Not re-run live this pass | PARTIAL |
| AI-8 | Interview Coach | Confirmed real Gemini calls (`generateInterviewQuestions`, `evaluateInterviewAnswer`) | Not re-run live this pass | PARTIAL |
| AI-9 | Career Advisor | Confirmed real Gemini call (`careerRecommendations`) | Not re-run live this pass | PARTIAL |
| AI-10 | Contextual AI Assistant (chat) | New this session; real Gemini call (`chatAboutCv`); conversation now persisted to Firestore (`aiChats/{uid}`) | Built and code-reviewed; not live-tested end-to-end (a real question asked, a real reply received, app restarted, history reloaded) | PARTIAL |
| AI-11 | AI never invents facts not in the CV | All prompts explicitly instruct this (verified by reading every prompt string in `ai_service.dart`) | Not independently verified with adversarial test inputs | PARTIAL |

## 20. Document Upload / Parsing

| ID | Requirement | Current Implementation | Status |
|---|---|---|---|
| DOC-1 | Upload PDF/DOCX via file picker | `CvImportScreen`, `file_picker` package (upgraded to 13.x this session for AGP 9 compatibility) | PARTIAL — implementation present; not live-tested with a real file this pass |
| DOC-2 | AI extracts structured data from the uploaded document | `AiService.parseResumeDocument` (multimodal Gemini call) | PARTIAL — not re-run live this pass |
| DOC-3 | Nothing is saved until the user confirms | Code shows a review step before `Save as new CV` | PARTIAL — not re-verified live |

## 21. PDF Export

| ID | Requirement | Current Implementation | Status |
|---|---|---|---|
| PDF-1 | Export CV to PDF | `PdfService`, `printing`/`pdf` packages | PARTIAL — not re-opened and visually inspected this pass |
| PDF-2 | Export to DOCX | `DocxService` (manual OOXML construction via `archive`) | PARTIAL — not re-verified this pass |
| PDF-3 | Exported file matches live preview | — | PARTIAL — not independently re-checked |

## 22. Backend / Database

See `CVORA_BACKEND_DATABASE_AUDIT.md` is folded into the Final Validation Report this pass (see below) rather than a standalone file, given time constraints.

| ID | Requirement | Status |
|---|---|---|
| BACK-1 | Firebase Auth + Cloud Firestore (migrated from Supabase earlier in the project) | PASS |
| BACK-2 | Every collection enforces owner-only access | PASS — read live from `firestore.rules`, all 6 collections (`resumes`, `achievements`, `interview_sessions`, `interview_answers`, `userProfiles`, `aiChats`) scoped to `request.auth.uid` |
| BACK-3 | Update rules prevent ownership-field tampering | PASS — **real gap found and fixed this session**: `resumes`/`achievements`/`interview_answers` update rules now additionally pin `request.resource.data.userId == resource.data.userId` |
| BACK-4 | No service-role / admin bypass reachable from the client | PASS — no Cloud Functions or admin SDK usage found in the client app |
| BACK-5 | Firestore indexes support the app's actual queries | PASS — `firestore.indexes.json` has composite indexes for every `userId + timestamp` query pattern used |
| BACK-6 | Multi-user data isolation | PARTIAL — proven correct **by rules logic**, not by live-testing two separate real accounts side by side in this pass |

## 23. API Integrations / Secrets

| ID | Requirement | Status |
|---|---|---|
| API-1 | Gemini API key never committed to git | PASS — `lib/secrets.dart` confirmed gitignored and absent from `git ls-files`; repo-wide grep for the key pattern found zero matches in tracked files |
| API-2 | Firebase client config (`firebase_options.dart`, `google-services.json`) — publicly committed by design | PASS — this is correct Firebase practice (security is enforced by Firestore rules, not by hiding this config) |
| API-3 | Demo account password is hardcoded in `login_screen.dart` | **Known and intentional** — a shared demo/grading account, not a real user's credential; flagged here for transparency, not a defect | NOT APPLICABLE (by design) |

## 24. Error Handling / Empty States

| ID | Requirement | Status |
|---|---|---|
| ERR-1 | AI service failure surfaces a real error, not a fake success | PASS — `AiService._generateFromContent` throws `StateError` on empty/missing response, with retry-on-503 |
| ERR-2 | Dashboard shows an empty state with no CVs | PASS (code path exists, not re-verified live this pass — demo account always has a CV) |
| ERR-3 | Forgot-password screen never reveals whether an email is registered | PASS — confirmed by reading the code (same success message shown regardless) |

## 25. Performance

Not independently profiled this pass (no instrumentation run). See Final Validation Report.

## 26. Responsiveness

| ID | Requirement | Status |
|---|---|---|
| RESP-1 | No RenderFlex overflow anywhere in the app | PARTIAL — one real overflow was found and fixed this session (Style picker thumbnail); the rest of the ~20 screens were not individually walked for overflow this pass |
| RESP-2 | Phone-width layouts (the only form factor tested) | PASS on the one device profile tested (Pixel-class emulator, 1080x2400) |
| RESP-3 | Tablet/desktop/web responsive breakpoints | **NOT IMPLEMENTED** — layouts are phone-width-oriented throughout |

## 27. Testing

| ID | Requirement | Status |
|---|---|---|
| TEST-1 | `flutter analyze` clean | PASS — genuinely 0 issues as of this pass (two lints and one dead-code warning fixed this session) |
| TEST-2 | `flutter test` passing | PASS — 12/12 |
| TEST-3 | Widget/unit test coverage of core business logic | PARTIAL — `JobMatcher`, `ResumeScorer`, `Validators` have real unit tests; `AtsChecker`, `AiService`, `DatabaseService`, dashboard calculations, and every screen's widget behavior have no tests |
| TEST-4 | End-to-end journeys (registration→CV→AI→export→restart) | PARTIAL — several journeys walked manually and live this session (CV edit/persist, navigation, dashboard reactivity); not all 14 journeys from the audit brief were executed |

## 28. Documentation

| ID | Requirement | Status |
|---|---|---|
| DOC-SET-1 | README reflects actual architecture and setup | PASS (rewritten earlier this project) |
| DOC-SET-2 | Full audit report set (15 documents requested) | PARTIAL — this register plus the Final Validation Report and Dynamic Data Audit and Branding Verification are produced; the other ~11 requested documents are explicitly not produced this pass (see Final Validation Report) |

## 29. Final Demonstration

| ID | Requirement | Status |
|---|---|---|
| DEMO-1 | Final APK build | See Final Validation Report — attempted this pass |
| DEMO-2 | Demo video under 7 minutes | **NOT ATTEMPTED** — no video-recording/editing capability was exercised this pass; see Final Validation Report for why and what's needed to produce one |
