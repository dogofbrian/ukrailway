MATCH (n) DETACH DELETE n;

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/stations.csv" AS row
CREATE (s:Station)
SET s.id = toInteger(row.id),
    s.name = row.name,
    s.tiplocCode = row.tiplocCode,
    s.crsCode = row.crsCode,
    s.location = point({latitude: toFloat(row.latitude), longitude: toFloat(row.longitude)})
WITH s WHERE row.groupName = 'LONDON GROUP'
SET s:LondonGroup;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/calling_points.csv" AS row
CALL {
    WITH row
    CREATE (c:CallingPoint)
    SET c.id = toInteger(row.id),
        c.routeName = row.routeName, 
        c.stopNumber = toInteger(row.stopNumber)
} IN TRANSACTIONS OF 10000 ROWS;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/stops.csv" AS row
CALL {
    WITH row
    CREATE (s:Stop)
    SET s.id = toInteger(row.id),
        s.stopNumber = toInteger(row.stopNumber)
    WITH row, s
    CALL {
        WITH row, s
        WITH row, s WHERE row.arrives <> ''
        SET s.arrives = time(row.arrives)
    }
    CALL {
        WITH row, s
        WITH row, s WHERE row.departs <> ''
        SET s.departs = time(row.departs)
    }
} IN TRANSACTIONS OF 10000 ROWS;

CREATE INDEX station_id IF NOT EXISTS FOR (s:Station) ON (s.id);
CREATE INDEX callingPoint_id IF NOT EXISTS FOR (c:CallingPoint) ON (c.id);
CREATE INDEX stop_id IF NOT EXISTS FOR (s:Stop) ON (s.id);
CREATE INDEX station_name IF NOT EXISTS FOR (s:Station) ON (s.name);

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/links.csv" AS row
MATCH (source:Station), (target:Station)
WHERE source.id = toInteger(row.source) AND target.id = toInteger(row.target)
CALL {
    WITH source, target, row
    CREATE (source)-[:LINK {distance: toFloat(row.distance)}]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/calling_point_seq.csv" AS row
MATCH (source:CallingPoint), (target:CallingPoint)
WHERE source.id = toInteger(row.source) AND target.id = toInteger(row.target)
CALL {
    WITH source, target, row
    CREATE (source)-[:NEXT]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/stop_seq.csv" AS row
MATCH (source:Stop), (target:Stop)
WHERE source.id = toInteger(row.source) AND target.id = toInteger(row.target)
CALL {
    WITH source, target, row
    CREATE (source)-[:NEXT]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/calls_at.csv" AS row
MATCH (source:CallingPoint), (target:Station)
WHERE source.id = toInteger(row.source) AND target.id = toInteger(row.target)
CALL {
    WITH source, target
    CREATE (source)-[:CALLS_AT]->(target)
} IN TRANSACTIONS OF 10000 ROWS;

:auto
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/dogofbrian/ukrailway/main/data/calling_point_stops.csv" AS row
MATCH (source:CallingPoint), (target:Stop)
WHERE source.id = toInteger(row.source) AND target.id = toInteger(row.target)
CALL {
    WITH source, target
    CREATE (source)-[:HAS]->(target)
} IN TRANSACTIONS OF 10000 ROWS;