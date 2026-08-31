-- =====================================================================
-- Bronze -> Silver staging: one table per source. Matching, masking, and
-- the CAR all operate on tokens from this point forward -- never on a
-- raw identifier.
-- =====================================================================

CREATE TABLE stg_core_customer (
    core_customer_id      VARCHAR(40)   NOT NULL,   -- core banking's native CIF
    national_id_token     VARCHAR(64),               -- HMAC-SHA256(national_id, kms_key)
    mobile_e164_token     VARCHAR(64),               -- HMAC-SHA256(e164_phone, kms_key)
    email_token           VARCHAR(64),               -- HMAC-SHA256(lower(email), kms_key)
    legal_name            VARCHAR(200),
    date_of_birth         DATE,
    kyc_status            VARCHAR(20),
    risk_rating           VARCHAR(10),
    residency_country     VARCHAR(3),
    source_updated_at     TIMESTAMP
);

CREATE TABLE stg_crm_contact (
    crm_contact_id         VARCHAR(40)  NOT NULL,    -- Salesforce Contact Id
    mobile_e164_token      VARCHAR(64),
    email_token            VARCHAR(64),
    full_name              VARCHAR(200),
    marketing_opt_in       BOOLEAN,
    source_updated_at      TIMESTAMP
);

CREATE TABLE stg_amplitude_user (
    amplitude_user_id          VARCHAR(64) NOT NULL, -- Amplitude anonymous/user id
    device_id                  VARCHAR(64),
    login_bound_mobile_token   VARCHAR(64),           -- set only after authenticated session
    first_seen_at              TIMESTAMP,
    last_seen_at                TIMESTAMP
);

-- Every field that could identify a person is tokenized at landing time --
-- a deterministic, keyed HMAC-SHA256, key held in KMS -- before any
-- matching logic ever runs. Nothing downstream of this point, including
-- the matching engine itself, ever touches a raw national ID, phone
-- number, or email. See Deliverable 1, Section 4 for the full PII tier
-- model this feeds.
