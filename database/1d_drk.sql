-- SCHEMA: drk

-- DROP SCHEMA drk ;

CREATE SCHEMA drk
    AUTHORIZATION edit_geodata;

GRANT ALL ON SCHEMA drk TO edit_geodata;

GRANT USAGE ON SCHEMA drk TO read_geodata;

ALTER DEFAULT PRIVILEGES IN SCHEMA drk
GRANT SELECT ON TABLES TO read_geodata;

-- Table: drk.fastgrans_

-- DROP TABLE drk.fastgrans_;

CREATE TABLE drk.fastgrans_
(
    "ID" double precision NOT NULL,
    "SUBTYP" double precision,
    "OBJEKTTYP" character varying(35) COLLATE pg_catalog."default",
    "SAMMANFALLANDE" character varying(40) COLLATE pg_catalog."default",
    "URSPRUNG" character varying(100) COLLATE pg_catalog."default",
    "GRANSKOD" smallint,
    "NOGGRANNHET" real,
    geom geometry(LineString,3008),
    CONSTRAINT fastgrans__pkey PRIMARY KEY ("ID")
)

TABLESPACE pg_default;

ALTER TABLE drk.fastgrans_
    OWNER to edit_geodata;

GRANT ALL ON TABLE drk.fastgrans_ TO edit_geodata;

GRANT SELECT ON TABLE drk.fastgrans_ TO read_geodata;
-- Index: fastgrans__geom_1402487408250

-- DROP INDEX drk.fastgrans__geom_1402487408250;

CREATE INDEX fastgrans__geom_1402487408250
    ON drk.fastgrans_ USING gist
    (geom)
    TABLESPACE pg_default;

-- Table: drk.planyta_

-- DROP TABLE drk.planyta_;

CREATE TABLE drk.planyta_
(
    "ID" double precision,
    "PLANBETECKNING" character varying(64) COLLATE pg_catalog."default",
    "CODENUM" integer,
    "PLANFORKORTNING" character varying(10) COLLATE pg_catalog."default",
    "PLANTYP" character varying(250) COLLATE pg_catalog."default",
    "LAGAKRAFTDATUM" character varying(64) COLLATE pg_catalog."default",
    "AREA" double precision,
    "FILE" character varying(64) COLLATE pg_catalog."default",
    geom geometry(Polygon,3008)
)

TABLESPACE pg_default;

ALTER TABLE drk.planyta_
    OWNER to edit_geodata;

GRANT ALL ON TABLE drk.planyta_ TO edit_geodata;

GRANT SELECT ON TABLE drk.planyta_ TO read_geodata;
-- Index: planyta_geom_1381750484814695001

-- DROP INDEX drk.planyta_geom_1381750484814695001;

CREATE INDEX planyta_geom_1381750484814695001
    ON drk.planyta_ USING gist
    (geom)
    TABLESPACE pg_default;

ALTER TABLE drk.planyta_
    CLUSTER ON planyta_geom_1381750484814695001;