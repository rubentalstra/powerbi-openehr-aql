// OpenEHR.pq — Power BI custom data connector for openEHR AQL.
//
// Source plan: IMPLEMENTATION_PLAN.md
// Conventions: CLAUDE.md
//
// DataSource.Kind = "OpenEHR" is LOCKED for the life of the connector.
// Changing it orphans every saved credential.

section OpenEHR;

// ---------------------------------------------------------------------------
// Module loader (pattern from Microsoft DataConnectors samples).
//   Each *.pqm under src/ is packed as an embedded resource by MakePQX and
//   reached here via Extension.Contents.
//
//   Aql.pqm and Schema.pqm are records with no cross-module deps and can be
//   loaded directly. Paging.pqm and Navigation.pqm are factory functions that
//   take their dependencies as parameters — this keeps every .pqm self-contained
//   (Extension.LoadFunction is a local helper in this section, not in #shared,
//   so it cannot be called from inside another .pqm during Expression.Evaluate).
// ---------------------------------------------------------------------------
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

Aql        = Extension.LoadFunction("Aql.pqm");
Schema     = Extension.LoadFunction("Schema.pqm");
Paging     = Extension.LoadFunction("Paging.pqm")(Aql);
Navigation = Extension.LoadFunction("Navigation.pqm")(Aql, Paging, Schema);

// ---------------------------------------------------------------------------
// Public function: OpenEHR.Aql
// ---------------------------------------------------------------------------
OpenEHR.AqlImpl = (
    cdrBaseUrl as text,
    aql as text,
    optional options as nullable record
) as table =>
    let
        opts        = if options = null then [] else options,
        pageSize    = Record.FieldOrDefault(opts, "PageSize",        1000),
        expand      = Record.FieldOrDefault(opts, "ExpandRmObjects", true),
        timeout     = Record.FieldOrDefault(opts, "Timeout",         null),
        queryParams = Record.FieldOrDefault(opts, "QueryParameters", null),
        rs          = Paging[GetAllRows](cdrBaseUrl, aql, queryParams, pageSize, timeout)
    in
        Schema[ResultSetToTable](rs, expand);

OpenEHR.AqlType = type function (
    cdrBaseUrl as (type text meta [
        Documentation.FieldCaption     = "openEHR REST base URL",
        Documentation.FieldDescription = "Base URL of the CDR, ending in /rest/openehr/v1 (no trailing slash).",
        Documentation.SampleValues     = { "http://localhost:8080/ehrbase/rest/openehr/v1" }
    ]),
    aql as (type text meta [
        Documentation.FieldCaption     = "AQL query",
        Documentation.FieldDescription = "Archetype Query Language. Alias every projection with AS so columns have stable names.",
        Formatting.IsMultiLine         = true,
        Formatting.IsCode              = true,
        Documentation.SampleValues     = { "SELECT c/uid/value AS Uid FROM EHR e CONTAINS COMPOSITION c LIMIT 10" }
    ]),
    optional options as (type [
        optional PageSize        = nullable number,
        optional ExpandRmObjects = nullable logical,
        optional Timeout         = nullable duration,
        optional QueryParameters = nullable record
    ] meta [
        Documentation.FieldCaption     = "Options",
        Documentation.FieldDescription = "PageSize (rows per round-trip, default 1000). ExpandRmObjects (flatten DV_QUANTITY/DV_CODED_TEXT/... into scalar columns, default true). Timeout (per-request, default 2m). QueryParameters (record substituted into :name placeholders)."
    ])
) as table meta [
    Documentation.Name        = "OpenEHR.Aql",
    Documentation.LongDescription =
        "Executes an openEHR AQL query against a Clinical Data Repository and returns the result as a Power BI table. Pagination and RM-object flattening are handled automatically."
];

[DataSource.Kind="OpenEHR"]
shared OpenEHR.Aql = Value.ReplaceType(OpenEHR.AqlImpl, OpenEHR.AqlType);

// ---------------------------------------------------------------------------
// Public function: OpenEHR.StoredQuery
// ---------------------------------------------------------------------------
OpenEHR.StoredQueryImpl = (
    cdrBaseUrl as text,
    qualifiedName as text,
    optional version as nullable text,
    optional options as nullable record
) as table =>
    let
        opts   = if options = null then [] else options,
        expand = Record.FieldOrDefault(opts, "ExpandRmObjects", true),
        rs     = Aql[ExecuteStored](cdrBaseUrl, qualifiedName, version)
    in
        Schema[ResultSetToTable](rs, expand);

OpenEHR.StoredQueryType = type function (
    cdrBaseUrl as (type text meta [
        Documentation.FieldCaption = "openEHR REST base URL"
    ]),
    qualifiedName as (type text meta [
        Documentation.FieldCaption     = "Stored query qualified name",
        Documentation.SampleValues     = { "org.openehr::compositions" }
    ]),
    optional version as (type nullable text meta [
        Documentation.FieldCaption = "Version (optional)"
    ]),
    optional options as (type [
        optional ExpandRmObjects = nullable logical
    ])
) as table meta [
    Documentation.Name = "OpenEHR.StoredQuery",
    Documentation.LongDescription =
        "Executes a stored (named) AQL query from the CDR's query registry."
];

[DataSource.Kind="OpenEHR"]
shared OpenEHR.StoredQuery = Value.ReplaceType(OpenEHR.StoredQueryImpl, OpenEHR.StoredQueryType);

// ---------------------------------------------------------------------------
// Public function: OpenEHR.Contents  — navigation entry point
// ---------------------------------------------------------------------------
OpenEHR.ContentsImpl = (cdrBaseUrl as text) as table =>
    Navigation[BuildRoot](cdrBaseUrl, OpenEHR.Aql);

OpenEHR.ContentsType = type function (
    cdrBaseUrl as (type text meta [
        Documentation.FieldCaption     = "openEHR REST base URL",
        Documentation.FieldDescription = "Base URL of the CDR, ending in /rest/openehr/v1 (no trailing slash).",
        Documentation.SampleValues     = { "http://localhost:8080/ehrbase/rest/openehr/v1" }
    ])
) as table meta [
    Documentation.Name = "openEHR"
];

[DataSource.Kind="OpenEHR", Publish="OpenEHR.Publish"]
shared OpenEHR.Contents = Value.ReplaceType(OpenEHR.ContentsImpl, OpenEHR.ContentsType);

// ---------------------------------------------------------------------------
// Data source kind registration
// ---------------------------------------------------------------------------
OpenEHR = [
    // TestConnection is MANDATORY — missing it = silent gateway-refresh failure.
    TestConnection = (dataSourcePath) =>
        let
            parsed = try Json.Document(dataSourcePath) otherwise null,
            url    = if parsed <> null and parsed is record then parsed[cdrBaseUrl] else dataSourcePath
        in
            { "OpenEHR.Contents", url },

    Authentication = [
        UsernamePassword = [
            UsernameLabel = Extension.LoadString("UsernameLabel"),
            PasswordLabel = Extension.LoadString("PasswordLabel"),
            Label         = Extension.LoadString("BasicAuthLabel")
        ],
        Anonymous = []
    ],

    Label = Extension.LoadString("DataSourceLabel")
];

OpenEHR.Publish = [
    Beta                = true,
    Category            = "Online Services",
    ButtonText          = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl        = "https://github.com/rubentalstra/powerbi-openehr-aql",
    SupportsDirectQuery = false,
    SourceImage         = OpenEHR.Icons,
    SourceTypeImage     = OpenEHR.Icons
];

OpenEHR.Icons = [
    Icon16 = {
        Extension.Contents("OpenEHR16.png"),
        Extension.Contents("OpenEHR20.png"),
        Extension.Contents("OpenEHR24.png"),
        Extension.Contents("OpenEHR32.png")
    },
    Icon32 = {
        Extension.Contents("OpenEHR32.png"),
        Extension.Contents("OpenEHR40.png"),
        Extension.Contents("OpenEHR48.png")
    }
];
