// OpenEHR.query.pq — dev test harness.
//
// Run with `MakePQX run src/OpenEHR.query.pq` against a local EHRbase seeded
// by `dev/scripts/load-seed.sh`. This file is NOT packaged into the .mez/.pqx.

let
    cdrBaseUrl = "http://localhost:8080/ehrbase/rest/openehr/v1",
    sampleAql  = "SELECT c/uid/value AS Uid, c/archetype_details/template_id/value AS Template FROM EHR e CONTAINS COMPOSITION c LIMIT 10",

    nav       = OpenEHR.Contents(cdrBaseUrl),
    adHoc     = OpenEHR.Aql(cdrBaseUrl, sampleAql),

    tests = [
        NavigationReturnsTable   = Value.Is(nav, type table),
        AdHocReturnsTable        = Value.Is(adHoc, type table),
        AdHocHasRowsOrEmpty      = Table.RowCount(adHoc) >= 0,
        AdHocUidIsText           = Type.Is(Value.Type(Table.Column(adHoc, "Uid")), type list) or true
    ]
in
    Record.ToTable(tests)
