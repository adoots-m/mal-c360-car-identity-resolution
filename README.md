# Mal --- Customer 360 & CAR: Identity Resolution SQL Submission

> *Disclaimer: This repository is not related to MAL.AI or currently recognized by MAL.AI. This repository -- including its name, logo, and color scheme -- is borrowed design for a technical exercise, not affiliated with, endorsed by, or representing any real bank, company, or organization. All data, scenarios, and branding are functionally fictional.*

**This repository is being submitted for the SQL/identity-resolution deliverable.** The graded submission lives entirely in one place:

> ## [`01_SQL_SUBMISSION/`](./01_SQL_SUBMISSION/)
> Runnable-shape SQL for the deterministic waterfall and the SCD2 survivorship merge, plus Glue/PySpark pseudocode for the one step that genuinely needs a graph engine instead of a single query. Its own [README](./01_SQL_SUBMISSION/README.md) explains each file.

**A Note to Whoever's Reviewing This**

Hi, I'm Adithya Menon — this repo is also my interview submission for Mal. I'm a data scientist/engineer with three years building ETL pipelines and ML systems on AWS and Azure (fraud detection at UPS, large-scale Snowflake pipelines in Dubai), so identity resolution and governed customer data aren't new territory for me. What drew me to Mal specifically is AI/ML applied where compliance and Sharia governance genuinely matter -- this was one of the more fun design problems I've worked on lately.

— Adithya

Everything below `01_SQL_SUBMISSION/` is supporting material, included so the SQL isn't read in isolation from the design it implements -- not part of what's being submitted for this deliverable. It's numbered ahead of the other folders deliberately, so it's also the first thing that sorts to the top of the file listing above.

---

## What else is in this repository

The SQL submission is the code companion to a larger, three-part Customer 360 & CAR platform design for Mal, a fictional AI-native Islamic digital bank. The rest of that design set is included here for reference and traceability -- every table and column name in `01_SQL_SUBMISSION/` matches these documents exactly.

| Folder | Contents |
|---|---|
| [`01_SQL_SUBMISSION/`](./01_SQL_SUBMISSION/) | **The submission.** Deterministic waterfall SQL, probabilistic-fallback pseudocode, survivorship-merge SQL, validation checks. |
| [`02_Design_Documents_PDFs/`](./02_Design_Documents_PDFs/) | The finished, brand-styled PDFs: architecture & design rationale, the entity-relationship diagram (as a document and as a standalone image), a defense Q&A, and the trade-offs/privacy/streaming design briefs. |
| [`03_LaTeX_Source/`](./03_LaTeX_Source/) | The LaTeX source that builds every PDF above, including fonts and the logo asset, so any of them can be recompiled or revised. |

### Reading order, if you want the full picture

1. `02_Design_Documents_PDFs/Mal_Deliverable1_Architecture.pdf` -- the overall architecture and why it's shaped this way
2. `02_Design_Documents_PDFs/Mal_Deliverable2_ERD.pdf` (or the standalone `..._ERD_Diagram.png`) -- the complete field-level schema
3. **`01_SQL_SUBMISSION/`** -- the runnable SQL and pseudocode implementing Section 2 of Deliverable 1, against the schema in Deliverable 2 -- **this is the submission**
4. `02_Design_Documents_PDFs/Mal_Part2_Tradeoffs_Privacy_QA.pdf` -- trade-offs revisited, privacy/regulatory posture, stakeholder Q&A
5. `02_Design_Documents_PDFs/Mal_Architecture_Defense_QA.pdf` -- a direct Q&A defense of the design, exam-paper format
6. `02_Design_Documents_PDFs/Mal_Part3_Streaming_Layer_Brief.pdf` -- the real-time streaming layer design

## Status

Draft for review, across all parts.

---
Adithya Menon &bull; amenon3002@gmail.com
