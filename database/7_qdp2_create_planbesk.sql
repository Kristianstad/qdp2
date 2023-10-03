--DROP TABLE qdp2.information
CREATE TABLE qdp2.information
(
	info_uuid uuid NOT NULL,
	plan_uuid uuid NOT NULL,
	kapitel text,
	kapitelordning integer,
	rubrik text,
	rubrikordning integer,
	kategori text,
	ordning integer,
	tema text,
	text text,
	lank text,
	stil text,
	CONSTRAINT qdp_info_pkey PRIMARY KEY (info_uuid),
	CONSTRAINT qdp_info_plan_fkey FOREIGN KEY (plan_uuid)
      REFERENCES qdp2.plan (plan_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.information
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.information TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.information TO edit_plan;
GRANT SELECT ON TABLE qdp2.information TO read_geodata;

COMMENT ON TABLE qdp2.information
  IS 'Information för planbeskrivningar';

CREATE INDEX qdp_information_plan_uuid_idx
  ON qdp2.information
  USING btree
  (plan_uuid);

-- DROP TABLE qdp2.info_tagg  
-- Table: qdp2.info_tagg

CREATE TABLE qdp2.info_tagg
(
  id serial NOT NULL,
  info_uuid uuid NOT NULL,
  grupp text,
  undergrupp text,
  CONSTRAINT qdp_info_tagg_pkey PRIMARY KEY (id),
  CONSTRAINT qdp_info_tagg_info_fk FOREIGN KEY (info_uuid)
      REFERENCES qdp2.information (info_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.info_tagg
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.info_tagg TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.info_tagg TO edit_plan;
GRANT SELECT ON TABLE qdp2.info_tagg TO read_geodata;
COMMENT ON TABLE qdp2.info_tagg
  IS 'Infotmationstaggar kopplad till planbeskrivningsinfo';

CREATE INDEX qdp_info_tagg_info_uuid_idx
  ON qdp2.info_tagg
  USING btree
  (info_uuid);

-- DROP TABLE qdp2.info_best  
-- Table: qdp2.info_best

CREATE TABLE qdp2.info_best
(
  id serial NOT NULL,
  info_uuid uuid NOT NULL,
  best_uuid uuid,
  CONSTRAINT qdp_info_best_pkey PRIMARY KEY (id),
  CONSTRAINT qdp_info_best_info_uuid_fk FOREIGN KEY (info_uuid)
      REFERENCES qdp2.information (info_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.info_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.info_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.info_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.info_best TO read_geodata;
COMMENT ON TABLE qdp2.info_best
  IS 'Planbeskrivningsinfo kopplad till planbestämmelse';

CREATE INDEX qdp_info_best_info_uuid_idx
  ON qdp2.info_best
  USING btree
  (info_uuid);
CREATE INDEX qdp_info_best_best_uuid_idx
  ON qdp2.info_best
  USING btree
  (best_uuid);
  
-- DROP TABLE qdp2.info_omr;
-- Table qdp2.info_omr  
CREATE TABLE qdp2.info_omr
(
  io_uuid uuid NOT NULL,
  info_uuid uuid,
  geom geometry(MultiPolygon,3008),
  CONSTRAINT qdp_info_omr_pkey PRIMARY KEY (io_uuid),
  CONSTRAINT qdp_info_omr_info_uuid_fk FOREIGN KEY (info_uuid)
      REFERENCES qdp2.information (info_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.info_omr
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.info_omr TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.info_omr TO edit_plan;
GRANT SELECT ON TABLE qdp2.info_omr TO read_geodata;
COMMENT ON TABLE qdp2.info_omr
  IS 'Områden kopplat till beskrivningen';

-- Index: info_omr_geom_sidx

-- DROP INDEX qdp.info_omr_geom_sidx;

CREATE INDEX info_omr_geom_sidx
  ON qdp2.info_omr
  USING gist (geom);

CREATE INDEX qdp_info_omr_info_uuid_idx
  ON qdp2.info_omr
  USING btree
  (info_uuid);
  

-- Table: qdp2.indelning
-- DROP TABLE qdp2.indelning;

CREATE TABLE qdp2.indelning
(
	id serial NOT NULL, --int GENERATED ALWAYS AS IDENTITY -- alternativ utan sequence
	tema text NOT NULL,
	grupp text NOT NULL,
	undergrupp text,
	sort integer,
	aktiv boolean,
	CONSTRAINT indelning_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.indelning
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.indelning TO edit_geodata;
GRANT SELECT ON TABLE qdp2.indelning TO read_geodata;

COMMENT ON TABLE qdp2.indelning
  IS 'Informationstaggar för planbeskrivning';
  
INSERT INTO qdp2.indelning (tema, grupp, undergrupp, sort, aktiv) VALUES
	('Detaljplanens syfte','Syfte',NULL,1,true),
	('Beskrivning av detaljplanen','Hela detaljplan',NULL,11,true),
	('Beskrivning av detaljplanen','Genomförandetid',NULL,12,true),
	('Beskrivning av detaljplanen','Allmän plats','Huvudmannaskap',13,true),
	('Beskrivning av detaljplanen','Kvartersmark',NULL,14,true),
	('Beskrivning av detaljplanen','Vattenområde',NULL,15,true),
	('Beskrivning av detaljplanen','Befintligt',NULL,16,true),
	('Beskrivning av detaljplanen','Varför ändring av detaljplan valts',NULL,17,true),
	('Beskrivning av detaljplanen','Ärendeinformation',NULL,18,true),
	('Beskrivning av detaljplanen','Annat',NULL,19,true),
	('Motiv till detaljplanens regleringar','Motiv till reglering',NULL,20,false),
	('Genomförandefrågor','Mark- och utrymmesförvärv','Skyldighet inlösen, huvudman',30,true),
	('Genomförandefrågor','Mark- och utrymmesförvärv','Skyldighet inlösen, stat',31,true),
	('Genomförandefrågor','Mark- och utrymmesförvärv','Rätt till inlösen, huvudman',32,true),
	('Genomförandefrågor','Mark- och utrymmesförvärv','Rätt till inlösen av rättighet, kommun',33,true),
	('Genomförandefrågor','Fastighetsrättsliga frågor','Fastighetsindelningsbestämmelser',34,true),
	('Genomförandefrågor','Fastighetsrättsliga frågor','Förändrad fastighetsindelning',35,true),
	('Genomförandefrågor','Fastighetsrättsliga frågor','Rättigheter',36,true);

INSERT INTO qdp2.indelning (tema, grupp, undergrupp, sort, aktiv) VALUES
	('Genomförandefrågor','Tekniska frågor','Tekniska åtgärder',40,true),
	('Genomförandefrågor','Tekniska frågor','Utbyggnad allmän plats',41,true),
	('Genomförandefrågor','Tekniska frågor','Utbyggnad vatten och avlopp',42,true),
	('Genomförandefrågor','Ekonomiska frågor','Planekonomisk bedömning',50,true),
	('Genomförandefrågor','Ekonomiska frågor','Planavgift',51,true),
	('Genomförandefrågor','Ekonomiska frågor','Ersättningsanspråk',52,true),
	('Genomförandefrågor','Ekonomiska frågor','Inlösen',53,true),
	('Genomförandefrågor','Ekonomiska frågor','Gemensamhetsanläggningar',54,true),
	('Genomförandefrågor','Ekonomiska frågor','Drift allmän plats',55,true),
	('Genomförandefrågor','Ekonomiska frågor','Drift vatten och avlopp',56,true),
	('Genomförandefrågor','Ekonomiska frågor','Gatukostnader',57,true),
	('Genomförandefrågor','Organisatoriska frågor','Exploateringsavtal',60,true),
	('Genomförandefrågor','Organisatoriska frågor','Markanvisning',61,true),
	('Genomförandefrågor','Organisatoriska frågor','Tidplan',62,true),
	('Genomförandefrågor','Kulturvärden','Rivningsförbud',70,true),
	('Genomförandefrågor','Kulturvärden','Bevarandekrav',71,true),
	('Genomförandefrågor','Prövning enligt annan lagstiftning',NULL,80,true),
	('Genomförandefrågor','Upplysningar',NULL,81,true),
	('Genomförandefrågor','Annat',NULL,82,true),
	('Planeringsunderlag','Kommunala','Detaljplan',100,true),
	('Planeringsunderlag','Kommunala','Planprogram',101,true),
	('Planeringsunderlag','Kommunala','Grundkarta',102,true),
	('Planeringsunderlag','Kommunala','Översiktsplan',103,true),
	('Planeringsunderlag','Kommunala','Undersökning enligt 6 kap. 6 § plan- och bygglagen (2010:900)',104,true),
	('Planeringsunderlag','Kommunala','Miljökonsekvensbeskrivning',105,true),
	('Planeringsunderlag','Kommunala','Särskilt beslut om betydande miljöpåverkan',106,true),
	('Planeringsunderlag','Utredningar','Dagsljus och skugga',110,true),
	('Planeringsunderlag','Utredningar','Dagvattenutredning',111,true),
	('Planeringsunderlag','Utredningar','Handelsutredning',112,true),
	('Planeringsunderlag','Utredningar','Naturinventering',113,true),
	('Planeringsunderlag','Utredningar','Geoteknisk utredning',114,true),
	('Planeringsunderlag','Utredningar','Markmiljöutredning',115,true),
	('Planeringsunderlag','Utredningar','Bullerutredning',116,true),
	('Planeringsunderlag','Utredningar','Förprojektering',117,true),
	('Planeringsunderlag','Utredningar','Riskutredning',118,true),
	('Planeringsunderlag','Utredningar','Trafikutredning',119,true),
	('Planeringsunderlag','Utredningar','Barnkonsekvensanalys',120,true),
	('Planeringsunderlag','Utredningar','Kulturmiljöutredning',121,true),
	('Planeringsunderlag','Regionala','Regionplan',130,true),
	('Planeringsunderlag','Annat',NULL,140,true),
	('Planeringsförutsättningar','Kommunala','Detaljplan',200,true),
	('Planeringsförutsättningar','Kommunala','Områdesbestämmelser',201,true),
	('Planeringsförutsättningar','Kommunala','Förhandsbesked',202,true),
	('Planeringsförutsättningar','Kommunala','Planeringsbesked',203,true),
	('Planeringsförutsättningar','Kommunala','Planbesked',204,true),
	('Planeringsförutsättningar','Kommunala','Planprogram',205,true),
	('Planeringsförutsättningar','Kommunala','Översiktsplan',206,true),
	('Planeringsförutsättningar','Regionala','Regionplan',210,true),
	('Planeringsförutsättningar','Riksintressen','Rennäring',220,true),
	('Planeringsförutsättningar','Riksintressen','Yrkesfiske',221,true),
	('Planeringsförutsättningar','Riksintressen','Naturvård',222,true),
	('Planeringsförutsättningar','Riksintressen','Friluftsliv',223,true),
	('Planeringsförutsättningar','Riksintressen','Kulturmiljövård',224,true),
	('Planeringsförutsättningar','Riksintressen','Fyndigheter av ämnen och material',225,true),
	('Planeringsförutsättningar','Riksintressen','Industriell produktion',226,true),
	('Planeringsförutsättningar','Riksintressen','Energiproduktion och energidistribution',227,true),
	('Planeringsförutsättningar','Riksintressen','Slutförvaring av kärnbränsle och kärnavfall',228,true),
	('Planeringsförutsättningar','Riksintressen','Elektronisk kommunikation',229,true),
	('Planeringsförutsättningar','Riksintressen','Trafikkommunikation',230,true),
	('Planeringsförutsättningar','Riksintressen','Avfallshantering',231,true),
	('Planeringsförutsättningar','Riksintressen','Vattenförsörjning',232,true),
	('Planeringsförutsättningar','Riksintressen','Totalförsvar',233,true),
	('Planeringsförutsättningar','Riksintressen','Rörligt friluftsliv',234,true),
	('Planeringsförutsättningar','Riksintressen','Obruten kust',235,true),
	('Planeringsförutsättningar','Riksintressen','Högexploaterad kust',236,true),
	('Planeringsförutsättningar','Riksintressen','Obrutet fjäll',237,true),
	('Planeringsförutsättningar','Riksintressen','Skyddade vattendrag',238,true),
	('Planeringsförutsättningar','Riksintressen','Nationalstadspark',239,true),
	('Planeringsförutsättningar','Riksintressen','Natura 2000',240,true),
	('Planeringsförutsättningar','Riksintressen','Områden för geologisk lagring av koldioxid',241,true),
	('Planeringsförutsättningar','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Jordbruksmark',250,true),
	('Planeringsförutsättningar','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Skogsbruk',251,true),
	('Planeringsförutsättningar','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Oexploaterade områden',252,true),
	('Planeringsförutsättningar','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Ekologiskt särskilt känsliga områden',253,true),
	('Planeringsförutsättningar','Miljökvalitetsnormer','Luft',260,true),
	('Planeringsförutsättningar','Miljökvalitetsnormer','Vatten',261,true),
	('Planeringsförutsättningar','Miljökvalitetsnormer','Buller',262,true),
	('Planeringsförutsättningar','Mellankommunala intressen',NULL,270,true),
	('Planeringsförutsättningar','Miljö','Strandskydd',280,true),
	('Planeringsförutsättningar','Miljö','Dagvatten',281,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Omgivningsbuller',290,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Risk för olyckor',291,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Risk för översvämning',292,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Risk för erosion',293,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Risk för skred',294,true),
	('Planeringsförutsättningar','Hälsa och säkerhet','Risk för ras',295,true),
	('Planeringsförutsättningar','Geotekniska förhållanden',NULL,300,true),
	('Planeringsförutsättningar','Hydrologiska förhållanden',NULL,301,true),
	('Planeringsförutsättningar','Kulturmiljö','Fornlämningar',310,true),
	('Planeringsförutsättningar','Kulturmiljö','Byggnadsminnen',311,true),
	('Planeringsförutsättningar','Kulturmiljö','Kyrkligt kulturarv',312,true),
	('Planeringsförutsättningar','Fysisk miljö',NULL,320,true),
	('Planeringsförutsättningar','Sociala',NULL,321,true),
	('Planeringsförutsättningar','Teknik',NULL,322,true),
	('Planeringsförutsättningar','Service',NULL,323,true),
	('Planeringsförutsättningar','Trafik',NULL,324,true),
	('Planeringsförutsättningar','Annat',NULL,325,true),
	('Konsekvenser','Fastigheter och rättigheter',NULL,400,true),
	('Konsekvenser','Natur','Grönområde',401,true),
	('Konsekvenser','Natur','Landskapsbild',410,true),
	('Konsekvenser','Natur','Naturreservat',411,true),
	('Konsekvenser','Miljö','Miljökonsekvensbeskrivning',412,true),
	('Konsekvenser','Miljö','Miljöbedömning',412,true),
	('Konsekvenser','Miljö','Ställningstagande 4 kap. 33 b § plan- och bygglagen (2010:900)',412,true),
	('Konsekvenser','Miljö','Strandskydd',412,true),
	('Konsekvenser','Miljö','Dagvatten',412,true),
	('Konsekvenser','Miljökvalitetsnormer','Luft',420,true),
	('Konsekvenser','Miljökvalitetsnormer','Vatten',421,true),
	('Konsekvenser','Miljökvalitetsnormer','Buller',422,true),
	('Konsekvenser','Hälsa och säkerhet','Beräkning av omgivningsbuller',430,true),
	('Konsekvenser','Hälsa och säkerhet','Översvämning',431,true),
	('Konsekvenser','Hälsa och säkerhet','Olyckor',432,true),
	('Konsekvenser','Hälsa och säkerhet','Erosion',433,true),
	('Konsekvenser','Hälsa och säkerhet','Skred',434,true),
	('Konsekvenser','Hälsa och säkerhet','Ras',435,true),
	('Konsekvenser','Sociala','Barn',440,true),
	('Konsekvenser','Sociala','Barn',441,true),
	('Konsekvenser','Riksintressen','Rennäring',220,true),
	('Konsekvenser','Riksintressen','Yrkesfiske',221,true),
	('Konsekvenser','Riksintressen','Naturvård',222,true),
	('Konsekvenser','Riksintressen','Friluftsliv',223,true),
	('Konsekvenser','Riksintressen','Kulturmiljövård',224,true),
	('Konsekvenser','Riksintressen','Fyndigheter av ämnen och material',225,true),
	('Konsekvenser','Riksintressen','Industriell produktion',226,true),
	('Konsekvenser','Riksintressen','Energiproduktion och energidistribution',227,true),
	('Konsekvenser','Riksintressen','Slutförvaring av kärnbränsle och kärnavfall',228,true),
	('Konsekvenser','Riksintressen','Elektronisk kommunikation',229,true),
	('Konsekvenser','Riksintressen','Trafikkommunikation',230,true),
	('Konsekvenser','Riksintressen','Avfallshantering',231,true),
	('Konsekvenser','Riksintressen','Vattenförsörjning',232,true),
	('Konsekvenser','Riksintressen','Totalförsvar',233,true),
	('Konsekvenser','Riksintressen','Rörligt friluftsliv',234,true),
	('Konsekvenser','Riksintressen','Obruten kust',235,true),
	('Konsekvenser','Riksintressen','Högexploaterad kust',236,true),
	('Konsekvenser','Riksintressen','Obrutet fjäll',237,true),
	('Konsekvenser','Riksintressen','Skyddade vattendrag',238,true),
	('Konsekvenser','Riksintressen','Nationalstadspark',239,true),
	('Konsekvenser','Riksintressen','Natura 2000',240,true),
	('Konsekvenser','Riksintressen','Områden för geologisk lagring av koldioxid',241,true),
	('Konsekvenser','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Jordbruksmark',250,true),
	('Konsekvenser','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Skogsbruk',251,true),
	('Konsekvenser','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Oexploaterade områden',252,true),
	('Konsekvenser','Hushållningsbestämmelser enligt 3 kap. miljöbalken','Ekologiskt särskilt känsliga områden',253,true),
	('Konsekvenser','Trafik','Motortrafik',324,true),
	('Konsekvenser','Trafik','Gång- och cykeltrafik',324,true),
	('Konsekvenser','Mellankommunala frågor',NULL,325,true),
	('Konsekvenser','Annat',NULL,325,true);
	
-- View: qdp2.v_tema

-- DROP VIEW qdp2.v_tema;

CREATE OR REPLACE VIEW qdp2.v_tema
 AS
 SELECT DISTINCT i.tema
   FROM qdp2.indelning i 
   WHERE aktiv;

ALTER TABLE qdp2.v_tema
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_tema
    IS 'Uppslagstabell tema';

GRANT SELECT ON TABLE qdp2.v_tema TO read_geodata;
GRANT ALL ON TABLE qdp2.v_tema TO edit_geodata;

-- View: qdp2.v_grupp

-- DROP VIEW qdp2.v_grupp;

CREATE OR REPLACE VIEW qdp2.v_grupp
 AS
 SELECT DISTINCT concat(i.tema, i.grupp) AS id,
	i.tema, i.grupp
   FROM qdp2.indelning i 
   WHERE aktiv;

ALTER TABLE qdp2.v_grupp
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_grupp
    IS 'Uppslagstabell grupp';

GRANT SELECT ON TABLE qdp2.v_grupp TO read_geodata;
GRANT ALL ON TABLE qdp2.v_grupp TO edit_geodata;

-- View: qdp2.v_undergrupp

-- DROP VIEW qdp2.v_undergrupp;

CREATE OR REPLACE VIEW qdp2.v_undergrupp
 AS
 SELECT DISTINCT concat(i.tema, i.grupp, i.undergrupp) AS id,
 	i.tema, i.grupp, i.undergrupp, i.sort
   FROM qdp2.indelning i 
   WHERE aktiv AND i.undergrupp IS NOT NULL
   ORDER BY i.sort;

ALTER TABLE qdp2.v_undergrupp
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_undergrupp
    IS 'Uppslagstabell undergrupp';

GRANT SELECT ON TABLE qdp2.v_undergrupp TO read_geodata;
GRANT ALL ON TABLE qdp2.v_undergrupp TO edit_geodata;

CREATE TABLE qdp2.info_kapitel
(
	id serial NOT NULL, --int GENERATED ALWAYS AS IDENTITY -- alternativ utan sequence
	kapitel text NOT NULL,
	sort integer,
	aktiv boolean,
	CONSTRAINT info_kapitel_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.info_kapitel
    OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.info_kapitel TO edit_geodata;
GRANT SELECT ON TABLE qdp2.info_kapitel TO read_geodata;

COMMENT ON TABLE qdp2.info_kapitel
  IS 'Kapitelindelnng för planbeskrivning';
  
INSERT INTO qdp2.info_kapitel (kapitel, sort, aktiv) VALUES
	('DETALJPLANENS SYFTE', 1, true),
	('PLANOMRÅDETS LÄGE OCH OMFATTNING',2 , true),
	('MARKÄGOFÖRHÅLLANDEN', 3, true),
	('ÄRENDEINFORMATION', 4, true),
	('PLANHANDLINGAR', 5, true),
	('KARTUNDERLAG', 6, true),
	('UTREDNINGAR', 7, true),
	('ANSÖKAN, UPPDRAG OCH BESLUT', 8, true),
	('PLANPROCESSEN ', 9, true),
	('PLANERINGFÖRUTSÄTTNINGAR', 10, true),
	('PLANFÖRSLAGET', 11, true),
	('DAGSLJUS OCH SKUGGA', 12, true),
	('GEOTEKNIK', 13, true),
	('MARKMILJÖ', 14, true),
	('NATURMILJÖ', 15, true),
	('KULTURMILJÖ', 16, true),
	('ÖVERSVÄMNING', 17, true),
	('DAGVATTEN', 18, true),
	('MILJÖKVALITETSNORMER FÖR VATTEN OCH LUFT', 19, true),
	('TRAFIK', 20, true),
	('TRAFIKBULLER', 21, true),
	('OMGIVNINGSBULLER', 22, true),
	('TEKNIK', 23, true),
	('OLYCKOR', 24, true),
	('SOCIALA PLANERINGSFÖRUTSÄTTNINGAR', 25, true),
	('MILJÖBEDÖMNING', 26, true),
	('GENOMFÖRANDEFRÅGOR ', 27, true),
	('FASTIGHETSRÄTTSLIGA FRÅGOR', 28, true),
	('MARK- OCH UTRYMMESFÖRVÄRV', 29, true),
	('TEKNISKA FRÅGOR', 30, true),
	('EKONOMISKA FRÅGOR', 31, true),
	('ORGANISATORISKA FRÅGOR', 32, true),
	('UPPLYSNINGAR', 33, true),
	('PRÖVNING ENLIGT ANNAN LAGSTIFTNING', 34, true);
