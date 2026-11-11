# CVora-AI-Powered-Resume-Builder-Career-Intelligence-Platform
An intelligent AI-powered platform that helps users build, analyze, optimize, and tailor professional resumes, perform ATS analysis, match job descriptions, and accelerate career development using advanced AI technologies.

## AI features (Google Gemini)

- **Improve with AI** — rewrite the professional summary, an experience
  description, or an achievement description, right from the resume
  builder / Achievement Vault.
- **Job Matcher → Get AI Advice** — turns the keyword match score into a
  few sentences of honest, actionable advice for the selected job
  description.
- **Resume Score → Get AI Feedback** — a reviewer's take on the single
  most impactful improvement to make next.
- **Cover Letter** — pick a saved resume, paste a job description, and
  generate a tailored, editable, PDF-exportable cover letter.

To enable these:
```bash
cp lib/secrets.example.dart lib/secrets.dart
# then edit lib/secrets.dart and paste your key from https://aistudio.google.com/apikey
```
`lib/secrets.dart` is gitignored — never commit a real key. Without a key
the app still runs fine; only the AI-assisted actions show an error when
tapped.
