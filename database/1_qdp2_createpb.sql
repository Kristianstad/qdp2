-- Create roles

CREATE ROLE edit_geodata
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
CREATE ROLE read_geodata
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
CREATE ROLE edit_plan
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
  
-- SCHEMA: qdp2
-- DROP SCHEMA qdp2 ;

CREATE SCHEMA qdp2
    AUTHORIZATION edit_geodata;

COMMENT ON SCHEMA qdp2
    IS 'QGIS Detaljplan 22';

GRANT ALL ON SCHEMA qdp2 TO edit_geodata;
GRANT USAGE ON SCHEMA qdp2 TO edit_plan;
GRANT USAGE ON SCHEMA qdp2 TO read_geodata;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- DROP TABLE qdp2.farg;
-- DROP TABLE qdp2.kodlista;
-- DROP TABLE qdp2.referens;
-- DROP TABLE qdp2.plandokumentation;
-- DROP TABLE qdp2.underlag;
-- DROP TABLE qdp2.planbeskrivning;
-- DROP TABLE qdp2.beslutshandling;
-- DROP TABLE qdp2.beslut;
-- DROP TABLE qdp2.dokref;
-- DROP TABLE qdp2.lagesbestamningsmetod;
-- DROP TABLE qdp2.kvalitet;
-- DROP TABLE qdp2.variabel;
-- DROP TABLE qdp2.egen_best;
-- DROP TABLE qdp2.anv_best;
-- DROP TABLE qdp2.egenlin;
-- DROP TABLE qdp2.egenpkt;
-- DROP TABLE qdp2.omr;
-- DROP TABLE qdp2.motiv;
-- DROP TABLE qdp2.best;
-- DROP TABLE qdp2.bkatalog_imp;
-- DROP TABLE qdp2.plan_omr;
-- DROP TABLE qdp2.plan;

CREATE TABLE qdp2.plan
(
	plan_uuid uuid NOT NULL,
	objektidentitet uuid,
	planversion integer,
	v_giltig_fran timestamp,
	v_giltig_till timestamp,
	kommun text NOT NULL default 'Kristianstad',
	beteckning text,
	namn text NOT NULL,
	syfte text NOT NULL,
	status text NOT NULL,
	datum_statusforandring date,
	typ text NOT NULL,
	kval_id uuid,
	anvandbarhet text,
	anvandbarhet_beskrivning text,
	avgransning text,
	akt text, 
	katalogversion text,
	anteckning text,
	publicerad boolean,
	CONSTRAINT qdp_plan_pkey PRIMARY KEY (plan_uuid)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.plan
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.plan TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.plan TO edit_plan;
GRANT SELECT ON TABLE qdp2.plan TO read_geodata;

COMMENT ON TABLE qdp2.plan
  IS 'Huvudtabell för detaljplaner';

-- Table: qdp2.plan_omr

CREATE TABLE qdp2.plan_omr
(
  po_uuid uuid NOT NULL,
  plan_uuid uuid NOT NULL,
  zmin decimal,
  zmax decimal,
  tid_lage timestamp without time zone NOT NULL DEFAULT now(),
  tid_kontroll timestamp without time zone,
  lagesbestamningsmetod_plan uuid,
  lagesbestamningsmetod_hojd uuid,
  absolutlagesosakerhetplan decimal,
  absolutlagesosakerhethojd decimal,
  geom geometry(Polygon,3008),
--  solid_geometry geometry(PolyhedralSurfaceZ,3008),
  CONSTRAINT qdp_plan_omr_pkey PRIMARY KEY (po_uuid),
  CONSTRAINT qdp_plan_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.plan_omr
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.plan_omr TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.plan_omr TO edit_plan;
GRANT SELECT ON TABLE qdp2.plan_omr TO read_geodata;

COMMENT ON TABLE qdp2.plan_omr
  IS 'Planområden';

-- Index: qdp2.qdp_plan_omr_geom

-- DROP INDEX qdp2.qdp_plan_omr_geom;

CREATE INDEX qdp_plan_omr_geom
  ON qdp2.plan_omr
  USING gist
  (geom);
  
CREATE INDEX qdp_plan_omr_plan_uuid
  ON qdp2.plan_omr
  USING btree
  (plan_uuid);

-- Table: qdp2.bkatalog_imp

-- DROP TABLE qdp2.bkatalog_imp;

CREATE TABLE qdp2.bkatalog_imp
(
  katalogversion text,
  bestammelsetyp_name text,
  anvandningsform_name text,
  huvudmannaskap_name text,
  kategorienligtboverketsallmannarad text,
  underkategorienligtboverketsallmannarad text,
  anvandningsslag text,
  bestammelseformulering text,
  uttrycktvarde text,
  enligtboverketsallmannarad text,
  beteckning text,
  lagstod text,
  kapitel text,
  paragraf text,
  stycke text,
  punkt text,
  forklaring text,
  farg_id integer,
  farg text,
  borjargalla date,
  slutargalla date,
  bestammelsekod text,
  redigerad date,
  publicerad date,
  id uuid NOT NULL,
  symbolbeteckning_type text,
  symbolbeteckning_updated text,
  symbolbeteckning_id bigint,
  symbolbeteckning_name text,
  geometrityp text,
  CONSTRAINT qdp_tmp_bkatalog_imp_pkey PRIMARY KEY (katalogversion, bestammelsekod)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.bkatalog_imp
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.bkatalog_imp TO edit_geodata;
GRANT SELECT ON TABLE qdp2.bkatalog_imp TO read_geodata;

COMMENT ON TABLE qdp2.bkatalog_imp
  IS 'Bestämmelsekatalog';

CREATE INDEX qdp_bkatalog_imp_id_idx
  ON qdp2.bkatalog_imp
  USING btree
  (id);
  
-- Index: qdp_bkatalog_imp_katalog_idx

-- DROP INDEX qdp2.qdp_bkatalog_imp_katalog_idx;

CREATE INDEX qdp_bkatalog_imp_katalog_idx
    ON qdp2.bkatalog_imp USING btree
    (katalogversion ASC NULLS LAST)
    TABLESPACE pg_default;
	
-- Table: qdp2.best

CREATE TABLE qdp2.best
(
	best_uuid uuid NOT NULL,
	plan_uuid uuid,
	bestammelsetyp text,
	anvandningsform text,
	kategori text,
	underkategori text, 
	bk_ref uuid NOT NULL,
	sekundar boolean,
	galler_all_anvandningsform boolean,
	ursprunglig text,
	beteckning text,
	index smallint,
  	kval_id uuid,
	anvandbarhet text,
	anvandbarhet_beskrivning text,
  CONSTRAINT qdp_best_pkey PRIMARY KEY (best_uuid),
  CONSTRAINT qdp_plan_fk FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.best TO edit_plan;
GRANT SELECT ON TABLE qdp2.best TO read_geodata;
COMMENT ON TABLE qdp2.best
  IS 'Planbestämmelser';
  
CREATE INDEX qdp_best_plan_uuid
  ON qdp2.best
  USING btree
  (plan_uuid);

-- Table: qdp2.motiv
-- DROP TABLE qdp2.motiv

CREATE TABLE qdp2.motiv
(
	motiv_id uuid NOT NULL,
	best_uuid uuid,
	motiv text NOT NULL,
	CONSTRAINT motiv_pkey PRIMARY KEY (motiv_id),
	CONSTRAINT qdp_plan_motiv_fkey FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.motiv
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.motiv TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.motiv TO edit_plan;
GRANT SELECT ON TABLE qdp2.motiv TO read_geodata;

COMMENT ON TABLE qdp2.motiv
  IS 'Motiv för planbestämmelser';

-- Table qdp2.omr  
CREATE TABLE qdp2.omr
(
  o_uuid uuid NOT NULL,
  po_uuid uuid,
  plan_uuid uuid,
  anvandningsform text,
  zmin decimal,
  zmax decimal,
  tid_lage timestamp without time zone NOT NULL DEFAULT now(),
  tid_kontroll timestamp without time zone,	
  lagesbestamningsmetod_plan uuid,
  lagesbestamningsmetod_hojd uuid,
  absolutlagesosakerhetplan decimal,
  absolutlagesosakerhethojd decimal,
  geom geometry(Polygon,3008),
--  solid_geometry geometry(PolyhedralSurfaceZ,3008),
  CONSTRAINT qdp_omr_pkey PRIMARY KEY (o_uuid),
  CONSTRAINT qdp_omr_fk FOREIGN KEY (po_uuid)
      REFERENCES qdp2.plan_omr (po_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.omr
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.omr TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.omr TO edit_plan;
GRANT SELECT ON TABLE qdp2.omr TO read_geodata;
COMMENT ON TABLE qdp2.omr
  IS 'Planbestämmelseområden';

-- Index: qdp2.omr_geom

-- DROP INDEX qdp2.omr_geom;

CREATE INDEX qdp_omr_geom
  ON qdp2.omr
  USING gist (geom);

CREATE INDEX qdp_omr_po_uuid
  ON qdp2.omr
  USING btree
  (po_uuid);
  
CREATE INDEX qdp_omr_plan_uuid
  ON qdp2.omr
  USING btree
  (plan_uuid);  

CREATE INDEX qdp_omr_anvf_uuid
  ON qdp2.omr
  USING btree
  (anvandningsform);   
  
-- Table: qdp2.anv_best

CREATE TABLE qdp2.anv_best
(
  abest_uuid uuid NOT NULL,
  best_uuid uuid,
  o_uuid uuid,
  motiv_id uuid REFERENCES qdp2.motiv,
  huvudsaklig boolean,
  avgransning text,
  giltighetstid integer,
  borjar_galla_efter integer,
  norr numeric(10,3),
  ost numeric(10,3),
  rotation numeric(10,3),
  CONSTRAINT qdp_anv_best_pkey PRIMARY KEY (abest_uuid),
  CONSTRAINT qdp_anvbest_fk FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT qdp_anvomr_fk FOREIGN KEY (o_uuid)
      REFERENCES qdp2.omr (o_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.anv_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.anv_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.anv_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.anv_best TO read_geodata;
COMMENT ON TABLE qdp2.anv_best
  IS 'Användningsbestämmelse kopplad till område';

CREATE INDEX qdp_anv_bestomr_anb_uuid
  ON qdp2.anv_best
  USING btree
  (best_uuid);
CREATE INDEX qdp_anv_bestomr_ano_uuid
  ON qdp2.anv_best
  USING btree
  (o_uuid);

  
-- Table: qdp2.egen_best

CREATE TABLE qdp2.egen_best
(
  ebest_uuid uuid NOT NULL,
  best_uuid uuid,
  o_uuid uuid,
  motiv_id uuid REFERENCES qdp2.motiv,
  galler_endast uuid[],
  avgransning text,
  norr numeric(10,3),
  ost numeric(10,3),
  rotation numeric(10,3),
  CONSTRAINT qdp_bestomr_pkey PRIMARY KEY (ebest_uuid),
  CONSTRAINT qdp_best_fk FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT qdp_omr_fk FOREIGN KEY (o_uuid)
      REFERENCES qdp2.omr (o_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.egen_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.egen_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.egen_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.egen_best TO read_geodata;
COMMENT ON TABLE qdp2.egen_best
  IS 'Egenskapsbestämmelse  (+ admin) kopplad till område';

CREATE INDEX qdp_bestomr_best_uuid
  ON qdp2.egen_best
  USING btree
  (best_uuid);
CREATE INDEX qdp_bestomr_o_uuid
  ON qdp2.egen_best
  USING btree
  (o_uuid);
 
-- Table: qdp2.variabel

CREATE TABLE qdp2.variabel
(
  id serial NOT NULL, --int GENERATED ALWAYS AS IDENTITY -- alternativ utan sequence
  best_uuid uuid,
  datatyp text,
  variabelvarde text,
  beskrivning text,
  vardetyp text,
  enhet text,
  CONSTRAINT poc_variabel_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.variabel
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.variabel TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.variabel TO edit_plan;
GRANT SELECT ON TABLE qdp2.variabel TO read_geodata;
COMMENT ON TABLE qdp2.variabel
  IS 'Variabler till bestämmelser';
  
CREATE INDEX qdp_var_best_uuid
  ON qdp2.variabel
  USING btree
  (best_uuid);
-- Add foreign key to variabel
ALTER TABLE qdp2.variabel
  ADD CONSTRAINT qdp_plan_variabel_fk FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

-- Table: qdp2.kvalitet

CREATE TABLE qdp2.kvalitet
(
	kval_id uuid NOT NULL,
	plan_uuid uuid,
	digitaliseringsniva text,
	beskrivning_niva text,
	--foljer_foreskrift boolean,
	korrigerade_granser boolean,
	--forbattrat_underlag boolean,
	kontrollerat_underlag boolean,
	CONSTRAINT poc_kvalitet_pkey PRIMARY KEY (kval_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.kvalitet
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.kvalitet TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.kvalitet TO edit_plan;
GRANT SELECT ON TABLE qdp2.kvalitet TO read_geodata;
COMMENT ON TABLE qdp2.kvalitet
  IS 'Kvalitet på plan och bestämmelser';
  
CREATE INDEX qdp_kval_best_uuid
  ON qdp2.kvalitet
  USING btree
  (plan_uuid);

-- Add foreign key to kvalitet
ALTER TABLE qdp2.kvalitet
  ADD CONSTRAINT qdp_plan_kvalitet_fk FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

-- Table: qdp2.lagesbestamningsmetod
-- DROP TABLE qdp2.lagesbestamningsmetod

CREATE TABLE qdp2.lagesbestamningsmetod
(
	lage_id uuid NOT NULL,
	plan_uuid uuid,
	metod text NOT NULL,
	variant text NOT NULL,
	tidpunkt date ,
	skala integer,
	lagesosakerhet decimal,
	CONSTRAINT lagesbestamningsmetod_pkey PRIMARY KEY (lage_id),
	CONSTRAINT qdp_plan_lagesb_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.lagesbestamningsmetod
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.lagesbestamningsmetod TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.lagesbestamningsmetod TO edit_plan;
GRANT SELECT ON TABLE qdp2.lagesbestamningsmetod TO read_geodata;

COMMENT ON TABLE qdp2.lagesbestamningsmetod
  IS 'Lägesbestämningsmetoder för detaljplaner';
  
-- Table: qdp2.dokref
-- DROP TABLE qdp2.dokref

CREATE TABLE qdp2.dokref
(
	dokref_id uuid NOT NULL,
	namn text,
	kortnamn text,
	datum date,
	handelse text,
	specifik_ref text[],
	CONSTRAINT dokref_pkey PRIMARY KEY (dokref_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.dokref
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.dokref TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.dokref TO edit_plan;
GRANT SELECT ON TABLE qdp2.dokref TO read_geodata;

COMMENT ON TABLE qdp2.dokref
  IS 'Dokumentreferens';

-- Table: qdp2.beslut
-- DROP TABLE qdp2.beslut

CREATE TABLE qdp2.beslut
(
	beslut_id uuid NOT NULL,
	plan_uuid uuid,
	instans text,
	diarienummer_kn text,
	diareinummer_kf text,
	beslutstyp text,
	gk_id uuid,
	paborjat date,
	antagande date,
	lagakraft date[],
	genomforandetid integer,
	genomforandetid_startar date,
	arkivid_kn text,
	foregaende_plans_bet text[],
	berord_doms_malnr text[],
	planbestammelse uuid[],
	CONSTRAINT beslut_pkey PRIMARY KEY (beslut_id),
	CONSTRAINT qdp_plan_beslut_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)

WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.beslut
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.beslut TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.beslut TO edit_plan;
GRANT SELECT ON TABLE qdp2.beslut TO read_geodata;

COMMENT ON TABLE qdp2.beslut
  IS 'Beslutsinformation';

-- Table: qdp2.beslutshandling
-- DROP TABLE qdp2.beslutshandling

CREATE TABLE qdp2.beslutshandling
(
	beslh_id uuid NOT NULL,
	beslut_id uuid,
	innehall text[],
	CONSTRAINT beslh_pkey PRIMARY KEY (beslh_id),
	CONSTRAINT qdp_plan_beslut_fkey FOREIGN KEY (beslut_id)
      REFERENCES qdp2.beslut (beslut_id) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
INHERITS (qdp2.dokref)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.beslutshandling
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.beslutshandling TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.beslutshandling TO edit_plan;
GRANT SELECT ON TABLE qdp2.beslutshandling TO read_geodata;

COMMENT ON TABLE qdp2.beslutshandling
  IS 'Beslutshandlingar';

-- Table: qdp2.planbeskrivning
-- DROP TABLE qdp2.planbeskrivning

CREATE TABLE qdp2.planbeskrivning
(
	planbeskr_id uuid NOT NULL,
	plan_uuid uuid,
	CONSTRAINT planbeskr_pkey PRIMARY KEY (planbeskr_id),
	CONSTRAINT qdp_plan_planbeskr_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
INHERITS (qdp2.dokref)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.planbeskrivning
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.planbeskrivning TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.planbeskrivning TO edit_plan;
GRANT SELECT ON TABLE qdp2.planbeskrivning TO read_geodata;

COMMENT ON TABLE qdp2.planbeskrivning
  IS 'Planbeskrivning';

-- Table: qdp2.underlag
-- DROP TABLE qdp2.underlag

CREATE TABLE qdp2.underlag
(
	underlag_id uuid NOT NULL,
	plan_uuid uuid,
	huvudomrade text,
	underlagstyp text,
	CONSTRAINT underlag_pkey PRIMARY KEY (underlag_id),
	CONSTRAINT qdp_plan_underlag_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
INHERITS (qdp2.dokref)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.underlag
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.underlag TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.underlag TO edit_plan;
GRANT SELECT ON TABLE qdp2.underlag TO read_geodata;

COMMENT ON TABLE qdp2.underlag
  IS 'Planeringsunderlag';

-- Table: qdp2.plandokumentation
-- DROP TABLE qdp2.plandokumentation

CREATE TABLE qdp2.plandokumentation
(
	plandok_id uuid NOT NULL,
	plan_uuid uuid,
	CONSTRAINT plandok_pkey PRIMARY KEY (plandok_id),
	CONSTRAINT qdp_plan_plandok_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
INHERITS (qdp2.dokref)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.plandokumentation
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.plandokumentation TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.plandokumentation TO edit_plan;
GRANT SELECT ON TABLE qdp2.plandokumentation TO read_geodata;

COMMENT ON TABLE qdp2.plandokumentation
  IS 'Plandokumentation';
  
-- Table: qdp2.referens
-- DROP TABLE qdp2.referens

CREATE TABLE qdp2.referens
(
	ref_id serial NOT NULL, --int GENERATED ALWAYS AS IDENTITY -- alternativ utan sequence
	identitet uuid,
	namnrymd text,
	url text,
	fil text,
	dokref_id uuid,
	CONSTRAINT referens_pkey PRIMARY KEY (ref_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.referens
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.referens TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.referens TO edit_plan;
GRANT SELECT ON TABLE qdp2.referens TO read_geodata;

COMMENT ON TABLE qdp2.referens
  IS 'Referenser';
  
-- Table: qdp2.farg

-- DROP TABLE qdp2.farg;

CREATE TABLE qdp2.farg
(
  id integer NOT NULL,
  farg text,
  fargkod text,
  CONSTRAINT qdp_farg_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.farg
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.farg TO edit_geodata;
GRANT SELECT ON TABLE qdp2.farg TO read_geodata;

COMMENT ON TABLE qdp2.farg
  IS 'Kodlista för färger';
  
INSERT INTO qdp2.farg VALUES 
	(21, 'Ljusgrå', '#ecedf0'),
	(14, 'Ljusgrön', '#b6da9b'),
	(19, 'Ljust grå', '#ecedf0'),
	(20, 'Ljust grön', '#b6da9b'),
	(16, 'Lila', '#c7a0c9'),
	(13, 'Beige', '#f5ddbb'),
	(12, 'Grå', '#bdbdbd'),
	(11, 'Blågrå', '#99b4cd'),
	(10, 'Brun', '#ba9873'),
	(9, 'Orange', '#f9a86f'),
	(8, 'Röd', '#f48472'),
	(6, 'Gul', '#fff686'),
	(4, 'Blå', '#c6eafa'),
	(3, 'Grön', '#80ca9c');
	

-- Table: qdp2.kodlista
-- DROP TABLE qdp2.kodlista;

CREATE TABLE qdp2.kodlista
(
	id serial NOT NULL, --int GENERATED ALWAYS AS IDENTITY -- alternativ utan sequence
	kategori text NOT NULL,
	kod text NOT NULL,
	beskrivning text NOT NULL,
	sort integer,
	aktiv boolean,
	CONSTRAINT kodlista_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.kodlista
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.kodlista TO edit_geodata;
GRANT SELECT ON TABLE qdp2.kodlista TO read_geodata;

COMMENT ON TABLE qdp2.kodlista
  IS 'Kodlista för detaljplaner';

INSERT INTO qdp2.kodlista (kategori, kod, beskrivning, sort, aktiv) VALUES
	('datatyp','text','Text',1,true),
	('datatyp','decimaltal','Decimaltal',2,true),
	('plantyp','avstyckningsplan','Avstyckningsplan',2,true),
	('plantyp','byggnadsplan','Byggnadsplan',3,true),
	('plantyp','detaljplan','Detaljplan',1,true),
	('plantyp','stadsplan','Stadsplan',4,true),
	('planstatus','påbörjad','Påbörjad',1,true),
	('planstatus','samråd','Samråd',2,true),
	('planstatus','granskning','Granskning',3,true),
	('planstatus','antagen','Antagen',4,true),
	('planstatus','överklagad','Överklagad',5,true),
	('planstatus','tillsyn','Tillsyn',6,true),
	('planstatus','laga kraft','Laga kraft',7,true),
	('planstatus','upphävd','Upphävd',8,true),
	('planstatus','avslutad','Avslutad',9,true),
	('beslutstyp','antagande av ny detaljplan','Antagande av ny detaljplan',1,true),
	('beslutstyp','antagande om ändring','Antagande om ändring',2,true),
	('beslutstyp','antagande om upphävande','Antagande om upphävande',3,true),
	('beslutstyp','beslut om avslut','Beslut om avslut',4,true),
	('tillförlitlighet','god','God',1,true),
	('tillförlitlighet','medel','Medel',2,true),
	('tillförlitlighet','låg','Låg',3,true),
	('digitaliseringsnivå','komplett','Komplett',1,true),
	('digitaliseringsnivå','ej komplett','Ej komplett',2,true),
	('kommuninstans','byggnadsnämnd enligt PBL','Byggnadsnämnd enligt PBL',1,true),
	('kommuninstans','kommunstyrelse','Kommunstyrelse',2,true),
	('kommuninstans','kommunfullmäktige','Kommunfullmäktige',3,true),
	('innehåll','plankarta','Plankarta',1,true),
	('innehåll','beslutsprotokoll','Beslutsprotokoll',2,true),
	('innehåll','övrigt','Övrigt',3,true),
	('enhet','meter','m',1,true),
	('enhet','kvadratmeter','m2',2,true),
	('enhet','kubikmeter','m3',3,true),
	('enhet','procent','%',4,true),
	('enhet','grader','gr',5,true),
	('enhet','antal','st',6,true),
	('enhet','år','år',7,true),
	('värdetyp','min','min',1,true),
	('värdetyp','max','max',2,true),
	('värdetyp','exakt','exakt',3,true),
	('lägesbestamningsmetod','lägesplacering','Lägesplacering',1,true),
	('lägesbestamningsmetod','vektorisering av analogt material','Vektorisering av analogt material',2,true),
	('lägesplacering','digital karta','Digital karta',1,true),
	('lägesplacering','befintligt objekt i digital karta','Befintligt objekt i digital karta',2,true),
	('lägesplacering','3D-modell','3D-modell',3,true),
	('lägesplacering','befintligt objekt i 3D-modell','Befintligt objekt i 3D-modell',4,true),
	('lägesplacering','okänd','Okänd',5,true),
	('vektorisering av analogt material','skannad analog karta, skärmdigitalisering','Skannad analog karta, skärmdigitalisering',1,true),
	('vektorisering av analogt material','skannad analog karta, automatisk tolkning','Skannad analog karta, automatisk tolkning',2,true),
	('vektorisering av analogt material','okänd','Okänd',3,true),
	('anvandningsform','allmän plats','Allmän plats',1,true),
	('anvandningsform','kvartersmark','Kvartersmark',1,true),
	('anvandningsform','vattenområde','Vattenområde',1,true),
	('anvandningsform','planområdet','Planområdet',1,true)
	;
INSERT INTO qdp2.kodlista (kategori, kod, beskrivning, sort, aktiv) VALUES
	('resurshandelse','skapad','Skapad',1,true),
	('resurshandelse','publicerad','Publicerad',2,true),
	('resurshandelse','reviderad','Reviderad',3,true),
	('huvudomrade','kommunala','Kommunala',1,true),
	('huvudomrade','utredningar','Utredningar',2,true),
	('huvudomrade','regionala','Regionala',3,true),
	('huvudomrade','annat','Annat',4,true),
	('kommunala','detaljplan','Detaljplan',1,true),
	('kommunala','planprogram','Planprogram',2,true),
	('kommunala','grundkarta','Grundkarta',3,true),
	('kommunala','översiktsplan','Översiktsplan',4,true),
	('kommunala','undersökning enligt 6 kap. 6 § plan- och bygglagen (2010:900)','Undersökning enligt 6 kap. 6 § plan- och bygglagen (2010:900)',5,true),
	('kommunala','miljökonsekvensbeskrivning','Miljökonsekvensbeskrivning',6,true),
	('kommunala','särskilt beslut om betydande miljöpåverkan','Särskilt beslut om betydande miljöpåverkan',7,true),
	('kommunala','annat','Annat',8,true),
	('utredningar','dagsljus och skugga','Dagsljus och skugga',1,true),
	('utredningar','dagvattenutredning','Dagvattenutredning',2,true),
	('utredningar','handelsutredning','Handelsutredning',3,true),
	('utredningar','naturinventering','Naturinventering',4,true),
	('utredningar','geoteknisk utredning','Geoteknisk utredning',5,true),
	('utredningar','markmiljöutredning','Markmiljöutredning',6,true),
	('utredningar','bullerutredning','Bullerutredning',7,true),
	('utredningar','förprojektering','Förprojektering',8,true),
	('utredningar','riskutredning','Riskutredning',9,true),
	('utredningar','trafikutredning','Trafikutredning',10,true),
	('utredningar','barnkonsekvensanalys','Barnkonsekvensanalys',11,true),
	('utredningar','kulturmiljöutredning','Kulturmiljöutredning',12,true),
	('utredningar','annat','Annat',13,true),
	('regionala','regionplan','regionplan',1,true),
	('regionala','annat','Annat',2,true),
	('annat','-','-',13,true)
	;
INSERT INTO qdp2.kodlista (kategori, kod, beskrivning, sort, aktiv) VALUES
	('avgränsning','nedåt','Nedåt',1,true),
	('avgränsning','uppåt','Uppåt',2,true)
;
INSERT INTO qdp2.kodlista (kategori, kod, beskrivning, sort, aktiv) VALUES
	('lägesbestamningsmetod','okänd','Okänd',3,true),
	('okänd','okänd','Okänd',1,true)
;
INSERT INTO qdp2.kodlista (kategori, kod, beskrivning, sort, aktiv) VALUES
	('datatyp','heltal','Heltal',3,true) --Kan vara bra för äldre planer där det behövs i äldre versioner av planbetsämmelsekatalogen
;
-- Table: qdp2.planinfo
-- DROP TABLE qdp2.planinfo

CREATE TABLE qdp2.planinfo
(
	plan_uuid uuid NOT NULL,
	rubrik text,
	ingress text,
	bild text,
	bildtext text,
	syfte text,
    synpunkter text,
	CONSTRAINT planinfo_pkey PRIMARY KEY (plan_uuid),
	CONSTRAINT qdp_planinfo_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)

WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.planinfo
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.planinfo TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.planinfo TO edit_plan;
GRANT SELECT ON TABLE qdp2.planinfo TO read_geodata;

COMMENT ON TABLE qdp2.planinfo
  IS 'Planinformation, översiktlig';
	
	