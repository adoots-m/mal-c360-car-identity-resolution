-- =====================================================================
-- The crosswalk itself is a thin, append-mostly bridge table -- one row
-- per (source system, source customer ID) pair, exactly the grain
-- described in Deliverable 2's entity dictionary. It is the one table
-- every pass in this repo writes to, so its shape is pinned down here
-- before the waterfall query itself.
-- =====================================================================

CREATE TABLE identity_crosswalk (
    ecid                 VARCHAR(32)  NOT NULL,   -- MD5 of the anchoring national_id_token
    source_system        VARCHAR(20)  NOT NULL,   -- 'CORE' | 'CRM' | 'AMPLITUDE'
    source_customer_id   VARCHAR(64)  NOT NULL,   -- source_id from the pass that resolved it
    match_confidence     FLOAT,
    match_method         VARCHAR(40),              -- e.g. DETERMINISTIC_NATIONAL_ID, PROBABILISTIC_FINDMATCHES
    linked_at            TIMESTAMP,
    PRIMARY KEY (source_system, source_customer_id)
);

-- =====================================================================
-- Deterministic waterfall. A record is checked against the strongest
-- available signal first; passes are UNION ALL'd, not chained, because
-- each pass targets a disjoint slice of the unmatched population.
-- match_confidence here is retained for audit/reporting granularity
-- only -- every deterministic pass is treated as equally authoritative
-- regardless of its numeric value. The 0.90/0.97 cutoffs used by the
-- probabilistic pass (03_probabilistic_fallback.py) are a separate
-- scale that only ever applies to PROBABILISTIC_FINDMATCHES rows,
-- never compared against these deterministic scores.
-- =====================================================================

WITH core_keyed AS (
    -- Pass 1: every KYC'd core customer gets an ECID from national_id_token
    SELECT
        core_customer_id            AS source_id,
        'CORE'                      AS source_system,
        national_id_token,
        mobile_e164_token,
        email_token,
        'DETERMINISTIC_NATIONAL_ID' AS match_method,
        1.00                        AS match_confidence
    FROM stg_core_customer
    WHERE national_id_token IS NOT NULL   -- KYC complete
),

crm_matched AS (
    -- Pass 2/3: CRM contact attaches via verified mobile first, else
    -- verified email -- the CASE order mirrors the waterfall's own
    -- trust ordering, so a contact matching on both still records the
    -- stronger signal.
    SELECT
        c.crm_contact_id   AS source_id,
        'CRM'              AS source_system,
        k.national_id_token,
        CASE WHEN c.mobile_e164_token IS NOT NULL AND c.mobile_e164_token = k.mobile_e164_token
             THEN 'DETERMINISTIC_MOBILE' ELSE 'DETERMINISTIC_EMAIL' END AS match_method,
        CASE WHEN c.mobile_e164_token IS NOT NULL AND c.mobile_e164_token = k.mobile_e164_token
             THEN 0.99 ELSE 0.97 END AS match_confidence
    FROM stg_crm_contact c
    JOIN core_keyed k
      ON (c.mobile_e164_token IS NOT NULL AND c.mobile_e164_token = k.mobile_e164_token)
      OR (c.email_token       IS NOT NULL AND c.email_token       = k.email_token)
),

amplitude_matched AS (
    -- Amplitude device attaches only once an authenticated session has
    -- bound the device to a verified mobile number -- never speculatively.
    SELECT
        a.amplitude_user_id    AS source_id,
        'AMPLITUDE'            AS source_system,
        k.national_id_token,
        'DETERMINISTIC_MOBILE' AS match_method,
        0.99                   AS match_confidence
    FROM stg_amplitude_user a
    JOIN core_keyed k
      ON a.login_bound_mobile_token = k.mobile_e164_token
),

all_matched AS (
    SELECT source_id, source_system, national_id_token, match_method, match_confidence FROM core_keyed
    UNION ALL SELECT source_id, source_system, national_id_token, match_method, match_confidence FROM crm_matched
    UNION ALL SELECT source_id, source_system, national_id_token, match_method, match_confidence FROM amplitude_matched
)

INSERT INTO identity_crosswalk (ecid, source_system, source_customer_id, match_confidence, match_method, linked_at)
SELECT
    MD5(national_id_token)   AS ecid,          -- Enterprise Customer ID: stable cluster key,
                                                -- derived from the *tokenized* national ID --
                                                -- never the raw value (see 01_staging.sql)
    source_system,
    source_id                AS source_customer_id,
    match_confidence,
    match_method,
    CURRENT_TIMESTAMP         AS linked_at
FROM all_matched;

-- Everything that did NOT resolve here -- CRM leads with no core-banking
-- match at all -- falls through to the probabilistic pass in
-- 03_probabilistic_fallback.py.

-- Notice crm_matched joins on mobile OR email, not name, and records
-- which one actually matched rather than collapsing both into one
-- undifferentiated pass. Walking the Amina example from Deliverable 1
-- through this query: her core banking row mints ecid =
-- MD5(national_id_token) at Pass 1 -- computed from her *tokenized*
-- national ID, never the raw '784-1997-...' value itself, which this
-- pipeline never persists past staging. Her Salesforce contact has no
-- national ID to compare, so it never even reaches that branch -- but
-- it joins into crm_matched with match_method = 'DETERMINISTIC_MOBILE'
-- because +971501234567 matches on mobile_e164_token, despite her CRM
-- email (amina.s92@gmail.com) and core banking email
-- (amina.alsuwaidi@icloud.com) sharing nothing at all.
