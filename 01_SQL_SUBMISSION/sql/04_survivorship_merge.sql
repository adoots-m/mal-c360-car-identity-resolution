-- =====================================================================
-- dim_customer_golden is the SCD2 target every survivorship pass
-- publishes to -- the same field-level shape as Deliverable 2's
-- CUSTOMER_GOLDEN entity, plus the two SCD2 bookkeeping columns.
-- marketing_opt_in is the one column here core banking never
-- populates; it always arrives via the crm join below, per the
-- survivorship rule that gives CRM sole ownership of marketing intent.
-- =====================================================================

CREATE TABLE dim_customer_golden (
    ecid                  VARCHAR(32)   NOT NULL,
    legal_name            VARCHAR(200),
    date_of_birth         DATE,
    national_id_token     VARCHAR(64),
    mobile_e164_token     VARCHAR(64),
    email_token           VARCHAR(64),
    marketing_opt_in      BOOLEAN,
    kyc_status            VARCHAR(20),
    risk_rating           VARCHAR(10),
    residency_country     VARCHAR(3),
    scd_valid_from        TIMESTAMP,
    scd_valid_to          TIMESTAMP,
    scd_is_current        BOOLEAN
);

-- =====================================================================
-- Survivorship: one candidate golden row per ECID, built attribute-by-
-- attribute. CORE (regulated/KYC) beats CRM (self-declared) beats
-- nothing -- never "pick whichever record is newest" wholesale. See
-- Deliverable 1, Section 2.3 for the full field-level priority table.
-- =====================================================================

CREATE OR REPLACE VIEW v_golden_customer_candidate AS
SELECT
    xw_core.ecid,
    core.legal_name,                                                   -- CORE only: legal identity
    core.date_of_birth,                                                -- CORE only
    core.national_id_token,                                            -- CORE only
    COALESCE(core.mobile_e164_token, crm.mobile_e164_token)  AS mobile_e164_token,
    COALESCE(core.email_token,       crm.email_token)        AS email_token,
    core.kyc_status,
    core.risk_rating,
    core.residency_country,
    COALESCE(crm.marketing_opt_in, FALSE)                    AS marketing_opt_in,
    GREATEST(core.source_updated_at, COALESCE(crm.source_updated_at, core.source_updated_at))
                                                              AS source_updated_at
FROM identity_crosswalk xw_core
JOIN stg_core_customer core
  ON xw_core.source_system = 'CORE' AND xw_core.source_customer_id = core.core_customer_id
LEFT JOIN identity_crosswalk xw_crm
  ON xw_crm.ecid = xw_core.ecid AND xw_crm.source_system = 'CRM'
LEFT JOIN stg_crm_contact crm
  ON xw_crm.source_customer_id = crm.crm_contact_id;

-- SCD Type 2: close out the current row only if a tracked attribute
-- actually changed; otherwise leave history untouched.
MERGE INTO dim_customer_golden AS tgt
USING v_golden_customer_candidate AS src
ON tgt.ecid = src.ecid AND tgt.scd_is_current = TRUE
WHEN MATCHED AND (
        tgt.legal_name, tgt.kyc_status, tgt.risk_rating, tgt.mobile_e164_token, tgt.email_token
     ) IS DISTINCT FROM (
        src.legal_name, src.kyc_status, src.risk_rating, src.mobile_e164_token, src.email_token
     )
THEN UPDATE SET
    scd_valid_to   = CURRENT_TIMESTAMP,
    scd_is_current = FALSE
WHEN NOT MATCHED THEN
INSERT (ecid, legal_name, date_of_birth, national_id_token, mobile_e164_token, email_token,
        kyc_status, risk_rating, residency_country, marketing_opt_in,
        scd_valid_from, scd_valid_to, scd_is_current)
VALUES (src.ecid, src.legal_name, src.date_of_birth, src.national_id_token, src.mobile_e164_token, src.email_token,
        src.kyc_status, src.risk_rating, src.residency_country, src.marketing_opt_in,
        CURRENT_TIMESTAMP, NULL, TRUE);

-- A closed-out row's replacement is inserted in the same pass, keyed off
-- the just-closed ecids -- the standard SCD2 "expire old, insert new"
-- pair, omitted here as a second, identical-shaped INSERT for brevity.
