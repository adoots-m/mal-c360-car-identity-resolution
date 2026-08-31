# Mal --- Customer 360 & CAR: Identity Resolution SQL Submission

**This repository is being submitted for the SQL/identity-resolution deliverable.** The graded submission lives entirely in one place:

> ## [`sql-submission/`](./sql-submission/)
> Runnable-shape SQL for the deterministic waterfall and the SCD2 survivorship merge, plus Glue/PySpark pseudocode for the one step that genuinely needs a graph engine instead of a single query. Its own [README](./sql-submission/README.md) explains each file.

Everything below `sql-submission/` is supporting material, included so the SQL isn't read in isolation from the design it implements -- not part of what's being submitted for this deliverable.

---

## What else is in this repository

The SQL submission is the code companion to a larger, three-part Customer 360 & CAR platform design for Mal, a fictional AI-native Islamic digital bank. The rest of that design set is included here for reference and traceability -- every table and column name in `sql-submission/` matches these documents exactly.

| Folder | Contents |
|---|---|
| [`sql-submission/`](./sql-submission/) | **The submission.** Deterministic waterfall SQL, probabilistic-fallback pseudocode, survivorship-merge SQL, validation checks. |
| [`design-documents/`](./design-documents/) | The finished, brand-styled PDFs: architecture & design rationale, the entity-relationship diagram (as a document and as a standalone image), a defense Q&A, and the trade-offs/privacy/streaming design briefs. |
| [`latex-source/`](./latex-source/) | The LaTeX source that builds every PDF above, including fonts and the logo asset, so any of them can be recompiled or revised. |

### Reading order, if you want the full picture

1. `design-documents/Mal_Deliverable1_Architecture.pdf` -- the overall architecture and why it's shaped this way
2. `design-documents/Mal_Deliverable2_ERD.pdf` (or the standalone `..._ERD_Diagram.png`) -- the complete field-level schema
3. **`sql-submission/`** -- the runnable SQL and pseudocode implementing Section 2 of Deliverable 1, against the schema in Deliverable 2 -- **this is the submission**
4. `design-documents/Mal_Part2_Tradeoffs_Privacy_QA.pdf` -- trade-offs revisited, privacy/regulatory posture, stakeholder Q&A
5. `design-documents/Mal_Architecture_Defense_QA.pdf` -- a direct Q&A defense of the design, exam-paper format
6. `design-documents/Mal_Part3_Streaming_Layer_Brief.pdf` -- the real-time streaming layer design

## Status

Review Request, across all parts.

---
Adithya Menon &bull; amenon3002@gmail.com
