# =====================================================================
# AWS Glue job (PySpark). Runs only on the residual pool that failed the
# deterministic waterfall in 02_deterministic_waterfall.sql. Never
# auto-merges outright: below-threshold candidates and the review band
# both land in a steward queue. See Deliverable 1, Section 2.2 for the
# technology comparison (AWS Glue FindMatches, selected) and the
# feasibility discussion (labeling effort, integration, and why this is
# deliberately not an LLM-based decision).
# =====================================================================

from pyspark.sql import functions as F

unmatched_crm  = crm_contacts.join(identity_crosswalk, on="crm_contact_id", how="left_anti")
unmatched_core = core_customers.join(identity_crosswalk, on="core_customer_id", how="left_anti")

# Blocking key keeps this from being an O(n*m) cross join: only compare
# within the same birth year and residency country.
blocked = (
    unmatched_crm.withColumn("block_key", F.concat_ws("_", F.year("date_of_birth"), "residency_country"))
    .join(
        unmatched_core.withColumn("block_key", F.concat_ws("_", F.year("date_of_birth"), "residency_country")),
        on="block_key"
    )
)

# name_similarity: Jaro-Winkler over normalized (lower, whitespace-
# collapsed) name strings -- tolerant of the kind of formatting drift
# seen between "Amina Al Suwaidi" and "AMINA MOHAMED AL SUWAIDI".
scored = blocked.withColumn(
    "name_similarity", jaro_winkler_udf(F.col("full_name"), F.col("legal_name"))
).withColumn(
    "dob_exact_match", F.col("date_of_birth_crm") == F.col("date_of_birth_core")
)

# Three-way split, per the Fellegi-Sunter framing in Deliverable 1 S2.2:
# confidently the same person, confidently different, or genuinely
# ambiguous and worth a human's attention. Nothing in the middle band
# auto-merges.
auto_merge = scored.filter(
    (F.col("name_similarity") >= 0.97) & F.col("dob_exact_match")
).withColumn("match_method", F.lit("PROBABILISTIC_FINDMATCHES")) \
 .withColumn("match_confidence", F.col("name_similarity"))

steward_review_queue = scored.filter(
    (F.col("name_similarity") >= 0.90) & (F.col("name_similarity") < 0.97) & F.col("dob_exact_match")
).withColumn("queue_reason", F.lit("BELOW_AUTO_MERGE_THRESHOLD"))

# auto_merge            -> appended to identity_crosswalk, same shape as 02_deterministic_waterfall.sql
# steward_review_queue  -> human review UI (spreadsheet-based at Day 30/60)
# everything scoring below 0.90 -> left unmatched, re-attempted next run,
#                                   never silently discarded

# Steward decisions made against steward_review_queue are periodically
# folded back in as new labeled training examples for FindMatches, per
# Deliverable 1 Section 2.2 -- the classifier's calibration improves from
# real corrections over time rather than staying frozen at its first
# trained version.
