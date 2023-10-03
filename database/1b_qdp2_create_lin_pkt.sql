-- Table qdp2.egenlin  
CREATE TABLE qdp2.egenlin
(
  l_uuid uuid NOT NULL,
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
  geom geometry(LineString,3008),
  best_uuid uuid,
  motiv_id uuid REFERENCES qdp2.motiv,
  galler_endast uuid[],
  avgransning text,
  CONSTRAINT qdp_egenlin_luuid_pkey PRIMARY KEY (l_uuid),
  CONSTRAINT qdp_egenlinbest_fk FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT qdp_egenlinpo_fk FOREIGN KEY (po_uuid)
      REFERENCES qdp2.plan_omr (po_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.egenlin
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.egenlin TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.egenlin TO edit_plan;
GRANT SELECT ON TABLE qdp2.egenlin TO read_geodata;
COMMENT ON TABLE qdp2.egenlin
  IS 'Egenskpasbestämmelse, linje';

-- Index: qdp.egenlin

-- DROP INDEX qdp.lin_geom;

CREATE INDEX qdp_egenlin_geom
  ON qdp2.egenlin
  USING gist (geom);

CREATE INDEX qdp_egenlin_po_uuid
  ON qdp2.egenlin
  USING btree
  (po_uuid);  
  
CREATE INDEX qdp_egenlin_plan_uuid
  ON qdp2.egenlin
  USING btree
  (plan_uuid); 
  
CREATE INDEX qdp_egenlin_best_uuid
  ON qdp2.egenlin
  USING btree
  (best_uuid);
  
CREATE INDEX qdp_egenlin_anvf_uuid
  ON qdp2.egenlin
  USING btree
  (anvandningsform);   
  

	
-- Table qdp2.egenpkt  
CREATE TABLE qdp2.egenpkt
(
  p_uuid uuid NOT NULL,
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
  geom geometry(Point,3008),
  best_uuid uuid,
  motiv_id uuid REFERENCES qdp2.motiv,
  galler_endast uuid[],
  avgransning text,
  CONSTRAINT qdp_egenpkt_puuid_pkey PRIMARY KEY (p_uuid),
  CONSTRAINT qdp_egenpktbest_fk FOREIGN KEY (best_uuid)
      REFERENCES qdp2.best (best_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT qdp_egenpktpo_fk FOREIGN KEY (po_uuid)
      REFERENCES qdp2.plan_omr (po_uuid) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
)
WITH (
  OIDS=FALSE
);
ALTER TABLE qdp2.egenpkt
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.egenpkt TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.egenpkt TO edit_plan;
GRANT SELECT ON TABLE qdp2.egenpkt TO read_geodata;
COMMENT ON TABLE qdp2.egenpkt
  IS 'Egenskpasbestämmelse, punkt';

-- Index: qdp.pkt

-- DROP INDEX qdp.pkt_geom;

CREATE INDEX qdp_egenpkt_geom
  ON qdp2.egenpkt
  USING gist (geom);

CREATE INDEX qdp_egenpkt_po_uuid
  ON qdp2.egenpkt
  USING btree
  (po_uuid);  
 
CREATE INDEX qdp_egenpkt_plan_uuid
  ON qdp2.egenpkt
  USING btree
  (plan_uuid);  

CREATE INDEX qdp_egenpkt_anvf_uuid
  ON qdp2.egenpkt
  USING btree
  (anvandningsform); 
  
CREATE INDEX qdp_egenbestpkt_best_uuid
  ON qdp2.egenpkt
  USING btree
  (best_uuid);
  
