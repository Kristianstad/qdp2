-- View: qdp2.v_egl_best

-- DROP VIEW qdp2.v_egl_best;

CREATE OR REPLACE VIEW qdp2.v_egl_best AS 
 SELECT l.l_uuid, --objektidentitet
    l.po_uuid,
	l.plan_uuid,
	l.anvandningsform,
	l.zmin,
	l.zmax,
	l.tid_lage,
	l.tid_kontroll,
	l.lagesbestamningsmetod_plan,
	l.lagesbestamningsmetod_hojd,
	l.absolutlagesosakerhetplan,
	l.absolutlagesosakerhethojd,
    b.best_uuid,
	b.bform, --bestämmelseformulering
	l.motiv_id,
	m.motiv,
    b.ursprunglig, --ursprunglig bestämmelseformulering
	b.kval_id,
	b.anvandbarhet,
	b.anvandbarhet_beskrivning,
	l.galler_endast,
	l.avgransning,
	b.symbolbeteckning_name, --ej i spec
    b.status,
	b.publicerad,
    b.katalogversion,
    l.geom AS geom
   FROM qdp2.v_best b
   	 JOIN qdp2.egenlin l ON b.best_uuid = l.best_uuid
	 LEFT JOIN qdp2.motiv m ON m.motiv_id = l.motiv_id
  ORDER BY b.plan_uuid, l.l_uuid;

ALTER TABLE qdp2.v_egl_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_egl_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.v_egl_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_egl_best TO read_geodata;
COMMENT ON VIEW qdp2.v_egl_best
  IS 'Egenskapsbestämmelser, linjer';

-- Rule: v_egenlin_del ON qdp2.v_egl_best

-- DROP RULE v_egenlin_del ON qdp2.v_egl_best;

CREATE OR REPLACE RULE v_egenlin_del AS
    ON DELETE TO qdp2.v_egl_best DO INSTEAD  DELETE FROM qdp2.egenlin
  WHERE egenlin.l_uuid = old.l_uuid;

-- Rule: v_egenlin_upd ON qdp2.v_egl_best

-- DROP RULE v_egenlin_upd ON qdp2.v_egl_best;

CREATE OR REPLACE RULE v_egenlin_upd AS
    ON UPDATE TO qdp2.v_egl_best DO INSTEAD UPDATE qdp2.egenlin SET 
		po_uuid = new.po_uuid,
		plan_uuid = new.plan_uuid,
		anvandningsform = new.anvandningsform,
		zmin = new.zmin,
		zmax = new.zmax,
		tid_lage = new.tid_lage,
		tid_kontroll = new.tid_kontroll,
		lagesbestamningsmetod_plan = new.lagesbestamningsmetod_plan,
		lagesbestamningsmetod_hojd = new.lagesbestamningsmetod_hojd,
		absolutlagesosakerhetplan = new.absolutlagesosakerhetplan,
		absolutlagesosakerhethojd = new.absolutlagesosakerhethojd,
		geom = new.geom,
		best_uuid = new.best_uuid,
		motiv_id = new.motiv_id,
		galler_endast = new.galler_endast, 
		avgransning = new.avgransning
  WHERE egenlin.l_uuid = old.l_uuid;

CREATE OR REPLACE RULE v_egenlin_ins AS
    ON INSERT TO qdp2.v_egl_best DO INSTEAD INSERT INTO 
	qdp2.egenlin (l_uuid,po_uuid,plan_uuid,anvandningsform,zmin,zmax,tid_lage,tid_kontroll,
					   lagesbestamningsmetod_plan,lagesbestamningsmetod_hojd,absolutlagesosakerhetplan,
					   absolutlagesosakerhethojd,geom,best_uuid,motiv_id,galler_endast,avgransning)
  VALUES (new.l_uuid,new.po_uuid,new.plan_uuid,new.anvandningsform,new.zmin,new.zmax,new.tid_lage,new.tid_kontroll,
					   new.lagesbestamningsmetod_plan,new.lagesbestamningsmetod_hojd,new.absolutlagesosakerhetplan,
					   new.absolutlagesosakerhethojd,new.geom,new.best_uuid,new.motiv_id,new.galler_endast,new.avgransning)
  RETURNING 
    egenlin.l_uuid,
    egenlin.po_uuid,
	egenlin.plan_uuid,
	egenlin.anvandningsform,
	egenlin.zmin,
	egenlin.zmax,
	now()::timestamp without time zone,--egenlin.tid_lage,
	egenlin.tid_kontroll,
	egenlin.lagesbestamningsmetod_plan,
	egenlin.lagesbestamningsmetod_hojd,
	egenlin.absolutlagesosakerhetplan,
	egenlin.absolutlagesosakerhethojd,
    NULL :: uuid AS best_uuid,
	'':: text AS bform,
	egenlin.motiv_id,
	'':: text AS motiv,
    '':: text AS ursprunglig,
	NULL :: uuid kval_id,
	'':: text AS anvandbarhet,
	'':: text AS anvandbarhet_beskrivning,
	egenlin.galler_endast,
	egenlin.avgransning,
	'':: text AS symbolbeteckning_name,
    '':: text AS status,
	NULL::integer AS publicerad,
    '':: text AS katalogversion,
    egenlin.geom AS geom;

-- View: qdp2.v_egp_best

-- DROP VIEW qdp2.v_egp_best;

CREATE OR REPLACE VIEW qdp2.v_egp_best AS 
 SELECT p.p_uuid, --objektidentitet
    p.po_uuid,
	p.plan_uuid,
	p.anvandningsform,
	p.zmin,
	p.zmax,
	p.tid_lage,
	p.tid_kontroll,
	p.lagesbestamningsmetod_plan,
	p.lagesbestamningsmetod_hojd,
	p.absolutlagesosakerhetplan,
	p.absolutlagesosakerhethojd,
    b.best_uuid,
	b.bform, --bestämmelseformulering
	p.motiv_id,
	m.motiv,
    b.ursprunglig, --ursprunglig bestämmelseformulering
	b.kval_id,
	b.anvandbarhet,
	b.anvandbarhet_beskrivning,
	p.galler_endast,
	p.avgransning,
	b.beteckning,
	b.index,
	b.symbolbeteckning_name, --ej i spec
    b.status,
	b.publicerad,
    b.katalogversion,
    p.geom AS geom
   FROM qdp2.v_best b
   	 JOIN qdp2.egenpkt p ON b.best_uuid = p.best_uuid
	 LEFT JOIN qdp2.motiv m ON m.motiv_id = p.motiv_id
  ORDER BY b.plan_uuid, p.p_uuid;

ALTER TABLE qdp2.v_egp_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_egp_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.v_egp_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_egp_best TO read_geodata;
COMMENT ON VIEW qdp2.v_egp_best
  IS 'Egenskapsbestämmelser, punkter';

-- Rule: v_egenpkt_del ON qdp2.v_egp_best

-- DROP RULE v_egenpkt_del ON qdp2.v_egp_best;

CREATE OR REPLACE RULE v_egenpkt_del AS
    ON DELETE TO qdp2.v_egp_best DO INSTEAD  DELETE FROM qdp2.egenpkt
  WHERE egenpkt.p_uuid = old.p_uuid;

-- Rule: v_egenpkt_upd ON qdp2.v_egp_best

-- DROP RULE v_egenpkt_upd ON qdp2.v_egp_best;

CREATE OR REPLACE RULE v_egenpkt_upd AS
    ON UPDATE TO qdp2.v_egp_best DO INSTEAD UPDATE qdp2.egenpkt SET 
		po_uuid = new.po_uuid,
		plan_uuid = new.plan_uuid,
		anvandningsform = new.anvandningsform,
		zmin = new.zmin,
		zmax = new.zmax,
		tid_lage = new.tid_lage,
		tid_kontroll = new.tid_kontroll,
		lagesbestamningsmetod_plan = new.lagesbestamningsmetod_plan,
		lagesbestamningsmetod_hojd = new.lagesbestamningsmetod_hojd,
		absolutlagesosakerhetplan = new.absolutlagesosakerhetplan,
		absolutlagesosakerhethojd = new.absolutlagesosakerhethojd,
		geom = new.geom,
		best_uuid = new.best_uuid,
		motiv_id = new.motiv_id,
		galler_endast = new.galler_endast, 
		avgransning = new.avgransning
  WHERE egenpkt.p_uuid = old.p_uuid;

CREATE OR REPLACE RULE v_egenpkt_ins AS
    ON INSERT TO qdp2.v_egp_best DO INSTEAD INSERT INTO 
	qdp2.egenpkt (p_uuid,po_uuid,plan_uuid,anvandningsform,zmin,zmax,tid_lage,tid_kontroll,
					   lagesbestamningsmetod_plan,lagesbestamningsmetod_hojd,absolutlagesosakerhetplan,
					   absolutlagesosakerhethojd,geom,best_uuid,motiv_id,galler_endast,avgransning)
  VALUES (new.p_uuid,new.po_uuid,new.plan_uuid,new.anvandningsform,new.zmin,new.zmax,new.tid_lage,new.tid_kontroll,
					   new.lagesbestamningsmetod_plan,new.lagesbestamningsmetod_hojd,new.absolutlagesosakerhetplan,
					   new.absolutlagesosakerhethojd,new.geom,new.best_uuid,new.motiv_id,new.galler_endast,new.avgransning)
  RETURNING 
    egenpkt.p_uuid,
    egenpkt.po_uuid,
	egenpkt.plan_uuid,
	egenpkt.anvandningsform,
	egenpkt.zmin,
	egenpkt.zmax,
	now()::timestamp without time zone,--egenpkt.tid_lage,
	egenpkt.tid_kontroll,
	egenpkt.lagesbestamningsmetod_plan,
	egenpkt.lagesbestamningsmetod_hojd,
	egenpkt.absolutlagesosakerhetplan,
	egenpkt.absolutlagesosakerhethojd,
    NULL :: uuid AS best_uuid,
	'':: text AS bform,
	egenpkt.motiv_id,
	'':: text AS motiv,
    '':: text AS ursprunglig,
	NULL :: uuid kval_id,
	'':: text AS anvandbarhet,
	'':: text AS anvandbarhet_beskrivning,
	egenpkt.galler_endast,
	egenpkt.avgransning,
	'':: text AS beteckning,
	NULL:: smallint AS index,
	'':: text AS symbolbeteckning_name,
    '':: text AS status,
	NULL::integer AS publicerad,
    '':: text AS katalogversion,
    egenpkt.geom AS geom;