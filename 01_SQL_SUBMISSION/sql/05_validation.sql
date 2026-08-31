-- Check 1: no ECID should ever span more than one national_id_token --
-- if this returns rows, two genuinely different core-banking customers
-- were merged, which is the one failure mode this design treats as
-- worse than a missed match.
SELECT ecid, COUNT(DISTINCT national_id_token) AS distinct_nids
FROM stg_core_customer core
JOIN identity_crosswalk xw
  ON xw.source_system = 'CORE' AND xw.source_customer_id = core.core_customer_id
GROUP BY ecid
HAVING COUNT(DISTINCT national_id_token) > 1;

-- Check 2: confirm the worked example actually resolved across all
-- three sources into one ECID, the way Deliverable 1's Section 2.1
-- walkthrough claims.
SELECT source_system, source_customer_id, match_method, match_confidence
FROM identity_crosswalk
WHERE ecid = (
    SELECT ecid FROM identity_crosswalk
    WHERE source_system = 'CORE' AND source_customer_id = 'CIF-000481932'
)
ORDER BY linked_at;
-- Expected: three rows, all sharing one ecid -- CORE / CIF-000481932
-- (DETERMINISTIC_NATIONAL_ID), CRM / (Amina's contact id)
-- (DETERMINISTIC_MOBILE), and AMPLITUDE / (her device id)
-- (DETERMINISTIC_MOBILE).

-- Check 1 is the one query this whole design exists to make pass.
-- Everything in Deliverable 1 Section 2 -- the trust-ordered waterfall,
-- the conservative probabilistic thresholds, never letting Amplitude
-- originate a link -- is ultimately in service of this single invariant
-- never being violated: one national ID, one ECID, always.
