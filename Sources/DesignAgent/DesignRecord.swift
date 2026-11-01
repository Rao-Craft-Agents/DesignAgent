import GraniteAgents

/// The design agent's place in Granite's roster: an app that links this package finds the `design` agent by this
/// record, with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let designRecord: GraniteRoster.Record = { GraniteRoster.record(DesignAgent.self) }
