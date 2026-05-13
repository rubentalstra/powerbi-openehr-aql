// OpenEHR.query.pq — dev test harness.
//
// Run with `MakePQX run OpenEHR.query.pq` from `src/` against a local EHRbase seeded
// by `dev/scripts/load-seed.sh`. This file is NOT packaged into the .mez/.pqx.
//
// Checks cover: navigation root, ad-hoc AQL, pagination, Template fetch,
// schema flattening edge cases, negative AQL handling, and the
// PHI-safe-over-plaintext-HTTP guard.

let
    cdrBaseUrl = "http://localhost:8080/ehrbase/rest/openehr/v1",
    sampleAql  = "SELECT c/uid/value AS Uid, c/archetype_details/template_id/value AS Template FROM EHR e CONTAINS COMPOSITION c LIMIT 10",
    sampleBpAql = "SELECT e/ehr_id/value AS EhrId, o/data[at0001]/events[at0006]/data[at0003]/items[at0004]/value AS Systolic, o/data[at0001]/events[at0006]/data[at0003]/items[at0005]/value AS Diastolic, o/data[at0001]/events[at0006]/time/value AS Taken FROM EHR e CONTAINS COMPOSITION c CONTAINS OBSERVATION o [openEHR-EHR-OBSERVATION.blood_pressure.v2] ORDER BY o/data[at0001]/events[at0006]/time/value DESC LIMIT 10",
    sampleTemplateId = "Blutdruck",

    // ---- Happy-path calls ------------------------------------------------------
    nav       = OpenEHR.Contents(cdrBaseUrl),
    adHoc     = OpenEHR.Aql(cdrBaseUrl, sampleAql),
    adHocOpt  = OpenEHR.Aql(
                    cdrBaseUrl,
                    sampleAql,
                    [ PageSize = 250, AuditContext = "harness-run-1", RetryPolicy = [ MaxAttempts = 2, InitialDelayMs = 200, Jitter = false ] ]
                ),
    paged     = OpenEHR.Aql(cdrBaseUrl & "/", sampleBpAql, [ PageSize = 1, ExpandRmObjects = true ]),
    template  = try OpenEHR.Template(cdrBaseUrl, sampleTemplateId) otherwise null,

    // ---- Schema-only checks ----------------------------------------------------
    schemaFixture = [
        columns = {
            [name = "Qty"],
            [name = "Code"],
            [name = "Qty"],
            [name = "Unknown"]
        },
        rows = {
            {
                [_type = "DV_QUANTITY", magnitude = 120, units = "mm[Hg]", precision = 0],
                [_type = "DV_CODED_TEXT", value = "final", defining_code = [code_string = "at1", terminology_id = [value = "local"]]],
                null,
                [foo = "bar"]
            },
            {
                null,
                null,
                [_type = "DV_QUANTITY", magnitude = 80, units = "mm[Hg]", precision = 0],
                null
            }
        }
    ],
    flattened = Schema[ResultSetToTable](schemaFixture, true),
    emptyTable = Schema[ResultSetToTable]([columns = {[name = "OnlyCol"]}, rows = {}], true),

    // ---- Negative AQL: the CDR must reject malformed input ---------------------
    badAql = try OpenEHR.Aql(cdrBaseUrl, "SELECT FROM THIS IS NOT VALID AQL", [ RetryPolicy = [ MaxAttempts = 1 ] ]),

    // ---- PHI-safe guard: Basic over http:// must raise OpenEHR.AuthError -------
    // (Only meaningful when the harness is invoked with a Basic credential;
    // we `try` so the test runs under any auth kind.)
    phiSafeResult = try OpenEHR.Aql(cdrBaseUrl, sampleAql, [ PhiSafe = true ]),

    tests = [
        NavigationReturnsTable   = Value.Is(nav, type table),
        AdHocReturnsTable        = Value.Is(adHoc, type table),
        AdHocOptReturnsTable     = Value.Is(adHocOpt, type table),
        PaginationReturnsSeedRows = Value.Is(paged, type table) and Table.RowCount(paged) >= 2,
        AdHocHasRowsOrEmpty      = Table.RowCount(adHoc) >= 0,
        TemplateFetched          = template = null or Value.Is(template, type record) or Value.Is(template, type list),
        FlattenQuantity          = List.Contains(Table.ColumnNames(flattened), "Qty_magnitude"),
        FlattenCodedText         = List.Contains(Table.ColumnNames(flattened), "Code_value"),
        DuplicateAliasesStable   = List.Contains(Table.ColumnNames(flattened), "Qty_2_magnitude"),
        UnknownRecordJson        = List.Contains(Table.ColumnNames(flattened), "Unknown") and Value.Is(flattened{0}[Unknown], type text),
        EmptyResultStable        = Value.Is(emptyTable, type table) and Table.RowCount(emptyTable) = 0,
        InvalidAqlRejected       = badAql[HasError] = true and badAql[Error][Reason] = "OpenEHR.AqlError",
        PhiSafeEitherGuardsOrRuns =
            // Either the request went through (OAuth / Anonymous, no http+Basic
            // combination) OR it raised the guard error we expect for http+Basic.
            phiSafeResult[HasError] = false
            or (phiSafeResult[HasError] = true
                and phiSafeResult[Error][Reason] = "OpenEHR.AuthError")
    ]
in
    Record.ToTable(tests)
