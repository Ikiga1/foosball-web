----
-- foosball-web database
-- Generated by phpLiteAdmin (http://www.phpliteadmin.org/)
----
BEGIN TRANSACTION;

----
-- Table structure for players
----
CREATE TABLE "players" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" VARCHAR(50));

----
-- Table structure for replays
----
CREATE TABLE "replays" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "url" VARCHAR(50), "time" TIMESTAMP, "match_id" INTEGER NOT NULL);

----
-- Table structure for matches
----
CREATE TABLE 'matches' ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,'bluedef' INTEGER,'blueatk' INTEGER,'redatk' INTEGER,'reddef' INTEGER,'scoreblue' INTEGER,'scorered' INTEGER, "time" TIMESTAMP, "duration" INTEGER, "season_id" INTEGER NOT NULL);

----
-- Table structure for playerpositions
----
CREATE TABLE 'playerpositions' ('position' VARCHAR(8) PRIMARY KEY NOT NULL, 'player_id' INTEGER NOT NULL);

----
-- Table structure for match_ratings
----
CREATE TABLE 'match_ratings' ('match_id' INTEGER PRIMARY KEY NOT NULL, 'bluedef_rating' INTEGER, 'bluedef_delta' INTEGER, 'blueatk_rating' INTEGER, 'blueatk_delta' INTEGER, 'redatk_rating' INTEGER, 'redatk_delta' INTEGER, 'reddef_rating' INTEGER, 'reddef_delta' INTEGER);

----
-- Table structure for player_ratings
----
CREATE TABLE 'player_ratings' ('player_id' INTEGER PRIMARY KEY NOT NULL, 'atk_rating' REAL, 'def_rating' REAL, 'num_matches' INTEGER, 'matches_won' INTEGER, 'atk_matches' INTEGER, 'def_matches' INTEGER, 'active' BOOLEAN);

----
-- Table structure for statistics
----
CREATE TABLE 'statistics' ('key' VARCHAR(16) PRIMARY KEY NOT NULL, 'value' INTEGER);

----
-- structure for index sqlite_autoindex_playerpositions_1 on table playerpositions
----
;

----
-- structure for index index_replays_match on table replays
----
CREATE INDEX "index_replays_match" ON "replays" ("match_id");

----
-- structure for index index_matches_season on table matches
----
CREATE INDEX "index_matches_season" ON "matches" ("season_id");

----
-- structure for index sqlite_autoindex_statistics_1 on table statistics
----
;
COMMIT;
