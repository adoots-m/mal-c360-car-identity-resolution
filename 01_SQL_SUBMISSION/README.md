# Mal Customer 360 & CAR — Identity Resolution SQL & Pseudocode

*This is the SQL submission. For the full design set this code implements — architecture, ERD, trade-offs, streaming — see the [repository root](../README.md).*

Runnable-shape SQL for the deterministic waterfall and the SCD2 survivorship merge,
plus Glue/PySpark pseudocode for the one step — probabilistic matching — that
genuinely needs a graph engine instead of a single query.

This folder is the code companion to **Deliverable 3** of the Mal Customer 360 & CAR
design set. It is scoped narrowly to identity resolution — the matching, clustering,
and survivorship logic behind Section 2 of **Deliverable 1 (Architecture & Design
Rationale)**. It does not include the PII masking policy or the CAR population query;
those belong to different requirements. Every table and column name here matches
**Deliverable 2 (the ERD)** exactly, so the two can be read side by side.

The worked example threaded through this code — a customer named Amina, whose CRM,
core banking, and Amplitude records disagree on email and name formatting but share
a phone number — is the same example introduced in Deliverable 1, Section 1.

SQL is written against Redshift's current surface, including native `MERGE` and
`FILTER`-clause aggregates. The one step that is a poor fit for pure SQL — scoring
similarity between every unmatched pair — is shown as Glue/PySpark pseudocode
instead; Deliverable 3, Section 3 explains why that split is deliberate.

## Files, in read order

| File | What it does |
|---|---|
| `sql/01_staging.sql` | Bronze → Silver staging tables. Every PII field is tokenized (HMAC-SHA256, KMS-keyed) before landing — nothing downstream ever touches a raw identifier. |
| `sql/02_deterministic_waterfall.sql` | The `identity_crosswalk` DDL, then Passes 1–3: national ID, then verified mobile, then verified email. Deterministic, exact-match, run as `UNION ALL` because each pass targets a disjoint slice of the unmatched population. Each pass records its own `match_method` and `match_confidence` rather than collapsing all three into one undifferentiated label. |
| `sql/03_probabilistic_fallback.py` | Pass 4, as an AWS Glue (PySpark) job: Fellegi–Sunter-style blocking + similarity scoring for the residual pool that failed every deterministic key. Three-way split — auto-merge, steward review, no-merge — nothing in the middle band merges automatically. |
| `sql/04_survivorship_merge.sql` | The `dim_customer_golden` DDL, then field-level survivorship (core banking wins identity fields, CRM wins marketing intent) and the SCD Type 2 merge into it. |
| `sql/05_validation.sql` | The two checks to run after every identity-resolution batch: no ECID spans more than one national ID, and the worked example actually resolved end to end. |

## Companion documents

- **Deliverable 1 — Architecture & Design Rationale**: why the waterfall is ordered
  this way, the Fellegi–Sunter theory behind Pass 4, the AWS Glue FindMatches vs.
  Zingg vs. custom PySpark technology comparison, and the PII tier model.
- **Deliverable 2 — Entity-Relationship Diagram**: the complete field-level schema
  every table and column name here is drawn from.

## Status

Draft for review. Identity resolution only — this repo does not include the CAR
population job, the consent-gating logic, or the PII masking policy.

---
Adithya Menon &bull; amenon3002@gmail.com
