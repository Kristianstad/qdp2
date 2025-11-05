-- View: qdp2.v_bestammelsetyp_name

-- DROP VIEW qdp2.v_bestammelsetyp_name;

CREATE OR REPLACE VIEW qdp2.v_bestammelsetyp_name
 AS
 SELECT DISTINCT concat(bkatalog_imp.katalogversion,bkatalog_imp.bestammelsetyp_name) AS id,
    bkatalog_imp.katalogversion,
    bkatalog_imp.bestammelsetyp_name
   FROM qdp2.bkatalog_imp
  ORDER BY  bkatalog_imp.katalogversion;

ALTER TABLE qdp2.v_bestammelsetyp_name
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_bestammelsetyp_name
    IS 'Uppslagstabell bestammelsetyp_name';

GRANT SELECT ON TABLE qdp2.v_bestammelsetyp_name TO read_geodata;
GRANT ALL ON TABLE qdp2.v_bestammelsetyp_name TO edit_geodata;


-- View: qdp2.v_anvandningsform_name

-- DROP VIEW qdp2.v_anvandningsform_name;

CREATE OR REPLACE VIEW qdp2.v_anvandningsform_name
 AS
 SELECT DISTINCT concat(bkatalog_imp.katalogversion,bkatalog_imp.bestammelsetyp_name, bkatalog_imp.anvandningsform_name) AS id,
    bkatalog_imp.katalogversion,
	bkatalog_imp.anvandningsform_name,
    bkatalog_imp.bestammelsetyp_name
   FROM qdp2.bkatalog_imp
  ORDER BY  bkatalog_imp.katalogversion, bkatalog_imp.anvandningsform_name;

ALTER TABLE qdp2.v_anvandningsform_name
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_anvandningsform_name
    IS 'Uppslagstabell anvandningsform_name';

GRANT SELECT ON TABLE qdp2.v_anvandningsform_name TO read_geodata;
GRANT ALL ON TABLE qdp2.v_anvandningsform_name TO edit_geodata;

-- View: qdp2.v_kategori

-- DROP VIEW qdp2.v_kategori;

CREATE OR REPLACE VIEW qdp2.v_kategori
 AS
 SELECT DISTINCT concat(bkatalog_imp.katalogversion,bkatalog_imp.bestammelsetyp_name, bkatalog_imp.anvandningsform_name, bkatalog_imp.kategorienligtboverketsallmannarad) AS id,
    bkatalog_imp.katalogversion,
	bkatalog_imp.anvandningsform_name,
    bkatalog_imp.bestammelsetyp_name,
    bkatalog_imp.kategorienligtboverketsallmannarad
   FROM qdp2.bkatalog_imp
   WHERE slutargalla IS NULL
  ORDER BY bkatalog_imp.katalogversion, bkatalog_imp.kategorienligtboverketsallmannarad;

ALTER TABLE qdp2.v_kategori
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_kategori
    IS 'Uppslagstabell kategori';

GRANT SELECT ON TABLE qdp2.v_kategori TO read_geodata;
GRANT ALL ON TABLE qdp2.v_kategori TO edit_geodata;

-- View: qdp2.v_underkategori

-- DROP VIEW qdp2.v_underkategori;

CREATE OR REPLACE VIEW qdp2.v_underkategori
 AS
 SELECT DISTINCT concat(bkatalog_imp.katalogversion,bkatalog_imp.bestammelsetyp_name, bkatalog_imp.anvandningsform_name, bkatalog_imp.kategorienligtboverketsallmannarad, bkatalog_imp.underkategorienligtboverketsallmannarad) AS id,
    bkatalog_imp.katalogversion,
	bkatalog_imp.anvandningsform_name,
    bkatalog_imp.bestammelsetyp_name,
    bkatalog_imp.kategorienligtboverketsallmannarad,
	bkatalog_imp.underkategorienligtboverketsallmannarad
   FROM qdp2.bkatalog_imp
   WHERE slutargalla IS NULL
  ORDER BY bkatalog_imp.katalogversion, bkatalog_imp.underkategorienligtboverketsallmannarad;

ALTER TABLE qdp2.v_underkategori
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_underkategori
    IS 'Uppslagstabell underkategori';

GRANT SELECT ON TABLE qdp2.v_underkategori TO read_geodata;
GRANT ALL ON TABLE qdp2.v_underkategori TO edit_geodata;

-- View: qdp2.v_plan

-- DROP VIEW qdp2.v_plan;

CREATE OR REPLACE VIEW qdp2.v_plan
 AS
 SELECT p.plan_uuid,
    p.objektidentitet,
    p.planversion,
    p.v_giltig_fran,
    p.v_giltig_till,
    p.kommun,
    p.beteckning,
    p.namn,
    p.syfte,
    p.status,
    p.datum_statusforandring,
    p.typ,
    p.kval_id,
    p.anvandbarhet,
    p.anvandbarhet_beskrivning,
	p.avgransning,
    p.akt,
    p.katalogversion,
	p.anteckning,
    p.publicerad,
    po.geom::geometry(MultiPolygon,3008) AS geom
   FROM qdp2.plan p,
    ( SELECT plan_omr.plan_uuid,
            st_collect(plan_omr.geom) AS geom
           FROM qdp2.plan_omr
          GROUP BY plan_omr.plan_uuid) po
  WHERE p.plan_uuid = po.plan_uuid;

ALTER TABLE qdp2.v_plan
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_plan
    IS 'Plan med sammanslagen geometri';

GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE qdp2.v_plan TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_plan TO read_geodata;
GRANT ALL ON TABLE qdp2.v_plan TO edit_geodata;


-- Rule: v_plan_del ON qdp2.v_plan

-- DROP Rule v_plan_del ON qdp2.v_plan;

CREATE OR REPLACE RULE v_plan_del AS
    ON DELETE TO qdp2.v_plan
    DO INSTEAD
(DELETE FROM qdp2.plan
  WHERE (plan.plan_uuid = old.plan_uuid));

-- Rule: v_plan_ins ON qdp2.v_plan

-- DROP Rule v_plan_ins ON qdp2.v_plan;

CREATE OR REPLACE RULE v_plan_ins AS
    ON INSERT TO qdp2.v_plan
    DO INSTEAD NOTHING;

-- Rule: v_plan_upd ON qdp2.v_plan

-- DROP Rule v_plan_upd ON qdp2.v_plan;

CREATE OR REPLACE RULE v_plan_upd AS
    ON UPDATE TO qdp2.v_plan
    DO INSTEAD
(UPDATE qdp2.plan SET objektidentitet = new.objektidentitet, planversion = new.planversion, v_giltig_fran = new.v_giltig_fran, v_giltig_till = new.v_giltig_till, kommun = new.kommun, beteckning = new.beteckning, namn = new.namn, syfte = new.syfte, status = new.status, datum_statusforandring = new.datum_statusforandring, typ = new.typ, kval_id = new.kval_id, anvandbarhet = new.anvandbarhet, anvandbarhet_beskrivning = new.anvandbarhet_beskrivning, avgransning = new.avgransning, akt = new.akt, katalogversion = new.katalogversion, anteckning = new.anteckning, publicerad = new.publicerad
  WHERE (plan.plan_uuid = old.plan_uuid));

-- View: qdp2.v_bvar

-- DROP VIEW qdp2.v_bvar;

CREATE OR REPLACE VIEW qdp2.v_bvar AS 
 SELECT v2.best_uuid,
    count(*) AS vcount,
    array_agg(v2.vkey) AS vkeys,
    array_agg(v2.value) AS vvalues
   FROM ( SELECT v_1.best_uuid,
		v_1.beskrivning,
		v_1.beskrivning || ':' || v_1.datatyp AS vkey,
        v_1.variabelvarde AS value
        FROM qdp2.variabel v_1
	) v2
  GROUP BY v2.best_uuid;

ALTER TABLE qdp2.v_bvar
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_bvar TO edit_geodata;
GRANT SELECT ON TABLE qdp2.v_bvar TO read_geodata;
COMMENT ON VIEW qdp2.v_bvar
  IS 'Bestämmelsevariabler';

-- View: qdp2.v_best

-- DROP VIEW qdp2.v_best;

CREATE OR REPLACE VIEW qdp2.v_best AS 
 SELECT b.best_uuid,
    b.plan_uuid,
    p.status,
    p.katalogversion,
	p.publicerad,
    b.bestammelsetyp,
	b.anvandningsform,
	b.kategori,
	b.underkategori,
	b.bk_ref,
	b.sekundar,
	b.galler_all_anvandningsform,
    b.ursprunglig,
    b.kval_id,
	b.anvandbarhet,
    b.anvandbarhet_beskrivning,
    b.beteckning,
		--CASE v.vcount
        --    WHEN 1 THEN replace(b.beteckning, ('['::text || v.vkeys[1]) || ']'::text, v.vvalues[1])
        --    WHEN 2 THEN regexp_replace(regexp_replace(b.beteckning, ('\['::text || v.vkeys[1]) || '\]'::text, v.vvalues[1]), ('\['::text || v.vkeys[2]) || '\]'::text, v.vvalues[2])
        --    WHEN 3 THEN regexp_replace(regexp_replace(regexp_replace(b.beteckning, ('\['::text || v.vkeys[1]) || '\]'::text, v.vvalues[1]), ('\['::text || v.vkeys[2]) || '\]'::text, v.vvalues[2]), ('\['::text || v.vkeys[3]) || '\]'::text, v.vvalues[3])
        --    ELSE b.beteckning
        --END AS bet,
    b.index,
        CASE v.vcount
            WHEN 1 THEN replace(k.bestammelseformulering, ('['::text || v.vkeys[1]) || ']'::text, v.vvalues[1])
            WHEN 2 THEN regexp_replace(regexp_replace(k.bestammelseformulering, ('\['::text || v.vkeys[1]) || '\]'::text, v.vvalues[1]), ('\['::text || v.vkeys[2]) || '\]'::text, v.vvalues[2])
            WHEN 3 THEN regexp_replace(regexp_replace(regexp_replace(k.bestammelseformulering, ('\['::text || v.vkeys[1]) || '\]'::text, v.vvalues[1]), ('\['::text || v.vkeys[2]) || '\]'::text, v.vvalues[2]), ('\['::text || v.vkeys[3]) || '\]'::text, v.vvalues[3])
            ELSE k.bestammelseformulering
        END AS bform,
    k.symbolbeteckning_id,
    k.symbolbeteckning_name,
	k.geometrityp,
    k.lagstod,
    k.kapitel,
    k.paragraf,
    k.punkt
   FROM qdp2.best b
     JOIN qdp2.plan p ON p.plan_uuid = b.plan_uuid
     JOIN qdp2.bkatalog_imp k ON b.bk_ref = k.id AND p.katalogversion = k.katalogversion
     LEFT JOIN qdp2.v_bvar v ON b.best_uuid = v.best_uuid
 ;

ALTER TABLE qdp2.v_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_best TO edit_geodata;
GRANT DELETE, INSERT, UPDATE, SELECT ON TABLE qdp2.v_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_best TO read_geodata;
COMMENT ON VIEW qdp2.v_best
  IS 'Bestämmelser med formulering och beteckning';

-- Rule: v_best_del ON qdp2.v_best

-- DROP RULE v_best_del ON qdp2.v_best;

CREATE OR REPLACE RULE v_best_del AS
    ON DELETE TO qdp2.v_best DO INSTEAD  DELETE FROM qdp2.best
  WHERE best.best_uuid = old.best_uuid;

-- Rule: v_best_ins ON qdp2.v_best

-- DROP RULE v_best_ins ON qdp2.v_best;

CREATE OR REPLACE RULE v_best_ins AS
    ON INSERT TO qdp2.v_best DO INSTEAD  INSERT INTO qdp2.best (best_uuid,  plan_uuid, bestammelsetyp, anvandningsform, kategori, underkategori, bk_ref, sekundar, galler_all_anvandningsform, ursprunglig, beteckning, index, kval_id, anvandbarhet, anvandbarhet_beskrivning)
  VALUES (new.best_uuid, new.plan_uuid, new.bestammelsetyp, new.anvandningsform, new.kategori, new.underkategori, new.bk_ref, new.sekundar, new.galler_all_anvandningsform, new.ursprunglig, new.beteckning, new.index, new.kval_id, new.anvandbarhet, new.anvandbarhet_beskrivning)
  RETURNING best.best_uuid,
    best.plan_uuid,
    ''::text AS status,
    ''::text AS katalogversion,
	NULL::integer AS publicerad,
    best.bestammelsetyp,
    best.anvandningsform, 
	best.kategori, 
	best.underkategori, 
	best.bk_ref, 
	best.sekundar, 
	best.galler_all_anvandningsform, 
    best.ursprunglig,
	best.kval_id, 
	best.anvandbarhet, 
	best.anvandbarhet_beskrivning,
    best.beteckning,
	--''::text AS bet,
    best.index,
	''::text AS bform,
    0::bigint AS symbolbeteckning_id,
    ''::text AS symbolbeteckning_name,
	''::text AS geometrityp,
    ''::text AS lagstod,
    ''::text AS kapitel,
    ''::text AS paragraf,
    ''::text AS punkt ;

-- Rule: v_best_upd ON qdp2.v_best

-- DROP RULE v_best_upd ON qdp2.v_best;

CREATE OR REPLACE RULE v_best_upd AS
    ON UPDATE TO qdp2.v_best DO INSTEAD  UPDATE qdp2.best SET bestammelsetyp = new.bestammelsetyp, anvandningsform = new.anvandningsform, kategori = new.kategori, underkategori= new.underkategori, bk_ref = new.bk_ref, sekundar = new.sekundar, galler_all_anvandningsform = new.galler_all_anvandningsform, ursprunglig = new.ursprunglig, beteckning = new.beteckning, index = new.index , kval_id = new.kval_id, anvandbarhet = new.anvandbarhet, anvandbarhet_beskrivning = new.anvandbarhet_beskrivning
  WHERE best.best_uuid = old.best_uuid;

-- View: qdp2.v_anv_best

-- DROP VIEW qdp2.v_anv_best;

CREATE OR REPLACE VIEW qdp2.v_anv_best AS 
 SELECT x.abest_uuid, --objektidentitet
    b.best_uuid,
	b.anvandningsform, --användningsform
	k.huvudmannaskap_name, --utgår i 2020
	b.kategori, --kategori
	k.anvandningsslag, --ej i spec
	b.bk_ref, --planbestämmelsekatalogreferens
    k.bestammelsekod AS b_kod, -- ej i spec
	b.bform, --bestämmelseformulering
	x.motiv_id, 
	m.motiv,
    x.huvudsaklig, --ej i spec
	x.avgransning,
	--'Avgränsad vertikalt ' || x.avgransning || ' till ' || coalesce( o.zmin, o.zmax) || ' meter över angivet nollplan' AS avgransning_text, --Avgränsning i höjdled
	x.giltighetstid,
	x.borjar_galla_efter,
    b.ursprunglig, --ursprunglig bestämmelseformulering
	b.kval_id,
	b.anvandbarhet,
	b.anvandbarhet_beskrivning,
    b.beteckning, --ej i spec
--	b.bet, --ej i spec
    b.index, --ej i spec
    x.norr, --ej i spec
    x.ost, --ej i spec
    x.rotation, --ej i spec
    f.farg, --ej i spec
    f.fargkod, --ej i spec
	x.o_uuid,
    b.plan_uuid,
    b.status,
    b.katalogversion,
	b.publicerad,
    o.geom--, --bestämmelsegeometri
--	CASE WHEN (zmin IS NOT NULL AND zmax IS NOT NULL AND zmax > zmin) THEN
--		ST_MakeSolid(ST_Extrude(ST_Translate(ST_Force3DZ(o.geom),0,0,zmin),0,0,zmax - zmin))
--		ELSE NULL
--	END AS solid_geom
   FROM qdp2.v_best b
     JOIN qdp2.anv_best x ON b.best_uuid::text = x.best_uuid::text
     JOIN qdp2.omr o ON x.o_uuid = o.o_uuid
     LEFT JOIN qdp2.motiv m ON m.motiv_id = x.motiv_id
     JOIN qdp2.bkatalog_imp k ON b.bk_ref::text = k.id::text AND b.katalogversion = k.katalogversion
     LEFT JOIN qdp2.farg f ON k.farg_id = f.id
  ORDER BY b.plan_uuid, x.huvudsaklig NULLS FIRST, x.o_uuid ;

ALTER TABLE qdp2.v_anv_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_anv_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.v_anv_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_anv_best TO read_geodata;
COMMENT ON VIEW qdp2.v_anv_best
  IS 'Användningsbestämmelser';

-- Rule: v_anv_del ON qdp.v_anv_best

-- DROP RULE v_anv_del ON qdp.v_anv_best;

CREATE OR REPLACE RULE v_anv_del AS
    ON DELETE TO qdp2.v_anv_best DO INSTEAD  DELETE FROM qdp2.anv_best
  WHERE anv_best.abest_uuid = old.abest_uuid;

-- Rule: v_anv_ins ON qdp.v_anv_best
-- Trigger (below) instead due to insert triggers on the table

CREATE OR REPLACE RULE v_anv_upd AS
    ON UPDATE TO qdp2.v_anv_best DO INSTEAD  UPDATE qdp2.anv_best SET best_uuid=new.best_uuid, motiv_id = new.motiv_id, huvudsaklig = new.huvudsaklig, avgransning = new.avgransning, giltighetstid = new.giltighetstid, borjar_galla_efter = new.borjar_galla_efter, norr = new.norr, ost = new.ost, rotation = new.rotation
  WHERE anv_best.abest_uuid = old.abest_uuid;

-- Function: qdp2.insert_v_anv_best()

-- DROP FUNCTION qdp2.insert_v_anv_best();

CREATE OR REPLACE FUNCTION qdp2.insert_v_anv_best()
  RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO qdp2.anv_best (abest_uuid,best_uuid,o_uuid,motiv_id,huvudsaklig,avgransning,giltighetstid,borjar_galla_efter)
		VALUES (new.abest_uuid,new.best_uuid,new.o_uuid,new.motiv_id,new.huvudsaklig,new.avgransning,new.giltighetstid,new.borjar_galla_efter);
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_v_anv_best()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_v_anv_best() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_v_anv_best() TO edit_plan;

-- Trigger: insert_v_anv_best_insattning on qdp2.v_anv_best

-- DROP TRIGGER insert_v_anv_best_insattning ON qdp2.v_anv_best;

CREATE TRIGGER insert_v_anv_best_insattning
  INSTEAD OF INSERT
  ON qdp2.v_anv_best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_v_anv_best();

CREATE OR REPLACE VIEW qdp2.v_best_g AS 
 SELECT b.best_uuid,
    b.plan_uuid,
    b.bestammelsetyp,
	b.anvandningsform,
	b.kategori,
	b.underkategori,
    b.beteckning,
    b.index,
	b.symbolbeteckning_id,
    b.bform,
	b.sekundar,
	b.galler_all_anvandningsform,
	b.ursprunglig,
	b.anvandbarhet,
	b.anvandbarhet_beskrivning,
	o.geom::geometry(MultiPolygon,3008)
   FROM qdp2.v_best b
   JOIN (
			SELECT x.best_uuid, st_collect(o.geom) AS geom
			FROM qdp2.omr o JOIN qdp2.anv_best x ON o.o_uuid = x.o_uuid
			GROUP BY x.best_uuid
		UNION
		 SELECT e.best_uuid, st_collect(o.geom)
           FROM qdp2.egen_best e JOIN qdp2.omr o ON e.o_uuid = o.o_uuid
		   JOIN qdp2.best b_1 ON e.best_uuid = b_1.best_uuid AND (NOT b_1.galler_all_anvandningsform OR b_1.galler_all_anvandningsform IS NULL)
          GROUP BY e.best_uuid 
	   UNION
	   	 SELECT DISTINCT b.best_uuid, st_collect(o.geom)--ST_ForceCurve(st_multi(st_union(o.geom))) --gav felaktiga geometrier ibland (curve?)
		 FROM qdp2.best b JOIN qdp2.omr o ON b.plan_uuid = o.plan_uuid AND b.anvandningsform = o.anvandningsform AND b.galler_all_anvandningsform JOIN qdp2.anv_best a ON o.o_uuid = a.o_uuid
	     GROUP BY b.best_uuid
	   UNION
	     SELECT b_2.best_uuid, st_multi(po.geom) as geom
	     FROM qdp2.best b_2 JOIN qdp2.plan_omr po ON b_2.plan_uuid = po.plan_uuid
		 WHERE b_2.anvandningsform = 'Planområdet'
	   UNION
	     SELECT l.best_uuid, st_collect(st_buffer(l.geom,1))
	     FROM qdp2.egenlin l
	     GROUP BY l.best_uuid
	   UNION
	     SELECT p.best_uuid,  st_collect(st_buffer(p.geom,1))
	     FROM qdp2.egenpkt p
	     GROUP BY p.best_uuid
   ) o ON o.best_uuid = b.best_uuid
;
ALTER TABLE qdp2.v_best_g
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_best_g TO edit_geodata;
GRANT SELECT ON TABLE qdp2.v_best_g TO read_geodata;
COMMENT ON VIEW qdp2.v_best_g
  IS 'Bestämmelser med formulering och sammanslagen geometri';
  
-- View: qdp2.v_egy_best

-- DROP VIEW qdp2.v_egy_best;

CREATE OR REPLACE VIEW qdp2.v_egy_best AS 
 SELECT o.g_uuid ebest_uuid, --objektidentitet
    b.best_uuid,
	b.anvandningsform, --användningsform
	k.huvudmannaskap_name, --utgår i 2020
	b.kategori, --kategori
	k.anvandningsslag, --ej i spec
	b.bk_ref, --planbestämmelsekatalogreferens
	b.sekundar,
	b.galler_all_anvandningsform,
--	b.galler_endast,
    k.bestammelsekod AS b_kod, -- ej i spec
--	k.bestammelseformulering AS bform_kat, -- ej i spec, jo? Nej!
	b.bform, --bestämmelseformulering
	x.motiv_id,
	m.motiv,
    b.ursprunglig, --ursprunglig bestämmelseformulering
	b.kval_id,
	b.anvandbarhet,
	b.anvandbarhet_beskrivning,
	x.galler_endast,
	x.avgransning,
    b.beteckning, --ej i spec
--	b.bet, --ej i spec
    b.index, --ej i spec
	b.symbolbeteckning_name, --ej i spec
    x.norr, --ej i spec
    x.ost, --ej i spec
    x.rotation, --ej i spec
	x.o_uuid,
    b.plan_uuid,
    b.status,
    b.katalogversion,
	b.publicerad,
    ST_Multi(o.geom)::geometry(MultiPolygon,3008) AS geom--, --bestämmelsegeometri
--	CASE WHEN (zmin IS NOT NULL AND zmax IS NOT NULL AND zmax > zmin) THEN
--		ST_MakeSolid(ST_Extrude(ST_Translate(ST_Force3DZ(o.geom),0,0,zmin),0,0,zmax - zmin))
--		ELSE NULL
--	END AS solid_geom
   FROM qdp2.v_best b
   	 JOIN (	SELECT g.ft, g.typ, g.best_uuid, g.g_uuid,ST_Collect(g.geom) geom
		FROM (
			  SELECT 'ebo' ft, 'yta' typ, x.best_uuid, x.ebest_uuid g_uuid, o.geom 
			  FROM qdp2.egen_best x JOIN qdp2.omr o ON x.o_uuid = o.o_uuid UNION
			  SELECT DISTINCT 'eabo' ft, 'yta' typ, b.best_uuid, b.best_uuid g_uuid, o.geom 
			  FROM qdp2.best b JOIN qdp2.omr o ON b.plan_uuid = o.plan_uuid AND b.anvandningsform = o.anvandningsform AND b.galler_all_anvandningsform JOIN qdp2.anv_best a ON o.o_uuid = a.o_uuid
			  UNION
			  SELECT 'po' ft, 'yta' typ, b_2.best_uuid, po.po_uuid g_uuid, po.geom
                   FROM qdp2.best b_2 JOIN qdp2.plan_omr po ON b_2.plan_uuid = po.plan_uuid WHERE b_2.anvandningsform = 'Planområdet'
			  ) g
		GROUP BY g.ft, g.typ, g.best_uuid, g.g_uuid) o ON b.best_uuid = o.best_uuid
     LEFT JOIN qdp2.egen_best x ON o.g_uuid::text = x.ebest_uuid::text
     --JOIN qdp2.omr o ON x.o_uuid = o.o_uuid
	 LEFT JOIN qdp2.motiv m ON m.motiv_id = x.motiv_id
     JOIN qdp2.bkatalog_imp k ON b.bk_ref::text = k.id::text AND b.katalogversion = k.katalogversion
  ORDER BY b.plan_uuid, x.o_uuid;

ALTER TABLE qdp2.v_egy_best
  OWNER TO edit_geodata;
GRANT ALL ON TABLE qdp2.v_egy_best TO edit_geodata;
GRANT SELECT, UPDATE, INSERT, DELETE ON TABLE qdp2.v_egy_best TO edit_plan;
GRANT SELECT ON TABLE qdp2.v_egy_best TO read_geodata;
COMMENT ON VIEW qdp2.v_egy_best
  IS 'Egenskapsbestämmelser, ytor';

-- Rule: v_egen_del ON qdp.v_egy_best

-- DROP RULE v_egen_del ON qdp.v_egy_best;

CREATE OR REPLACE RULE v_egen_del AS
    ON DELETE TO qdp2.v_egy_best DO INSTEAD  DELETE FROM qdp2.egen_best
  WHERE egen_best.ebest_uuid = old.ebest_uuid;

-- Rule: v_egen_upd ON qdp.v_egy_best

-- DROP RULE v_egen_upd ON qdp.v_egy_best;

CREATE OR REPLACE RULE v_egen_upd AS
    ON UPDATE TO qdp2.v_egy_best DO INSTEAD  UPDATE qdp2.egen_best SET best_uuid = new.best_uuid, motiv_id = new.motiv_id, norr = new.norr, ost = new.ost, rotation = new.rotation, galler_endast = new.galler_endast, avgransning = new.avgransning
  WHERE egen_best.ebest_uuid = old.ebest_uuid;

-- Function: qdp2.insert_v_egen_best()

-- DROP FUNCTION qdp2.insert_v_egen_best();

CREATE OR REPLACE FUNCTION qdp2.insert_v_egen_best()
  RETURNS trigger AS
$BODY$
BEGIN
	INSERT INTO qdp2.egen_best (ebest_uuid,best_uuid,o_uuid,motiv_id,galler_endast,avgransning)
		VALUES (new.ebest_uuid,new.best_uuid,new.o_uuid,new.motiv_id,new.galler_endast,new.avgransning);
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_v_egen_best()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_v_egen_best() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_v_egen_best() TO edit_plan;

-- Trigger: insert_v_egen_best_insattning on qdp2.v_egy_best

-- DROP TRIGGER insert_v_egen_best_insattning ON qdp2.v_egy_best;

CREATE TRIGGER insert_v_egen_best_insattning
  INSTEAD OF INSERT
  ON qdp2.v_egy_best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_v_egen_best();

-- CREATE MATERIALIZED VIEW qdp2.kontrollobjekt
-- TABLESPACE pg_default
-- AS
-- SELECT
-- 	row_number() OVER () AS id,
-- 	st_multi(k.geom)::geometry(MultiLineString,3008) AS geom
-- 		 FROM (SELECT geom 
-- 			FROM drk.fastgrans_
-- 		 UNION SELECT st_boundary(geom)
-- 			FROM drk.planyta_) k
-- WITH DATA;

-- ALTER TABLE qdp2.kontrollobjekt
--     OWNER TO edit_geodata;

-- COMMENT ON MATERIALIZED VIEW qdp2.kontrollobjekt
--     IS 'Materialiserad vy för kontrollobjekt';

-- GRANT SELECT ON TABLE qdp2.kontrollobjekt TO read_geodata;
-- GRANT ALL ON TABLE qdp2.kontrollobjekt TO edit_geodata;

-- CREATE INDEX qdp4_mv_ko_sidx
--     ON qdp2.kontrollobjekt USING gist
--     (geom)
--     TABLESPACE pg_default;
-- VACUUM ANALYZE qdp2.kontrollobjekt;
-- View: qdp2.v_punkter_miss

-- DROP VIEW qdp2.v_punkter_miss;

CREATE OR REPLACE VIEW qdp2.v_punkter_miss
 AS
 WITH omraden AS (
         SELECT plan_omr.po_uuid AS g_uuid,
            st_boundary(plan_omr.geom) AS geom
           FROM qdp2.plan_omr
        UNION
         SELECT omr.o_uuid AS g_uuid,
            st_boundary(omr.geom) AS geom
           FROM qdp2.omr
        ), omradespunkter AS (
         SELECT omraden.g_uuid,
            omraden.geom,
            (st_dumppoints(omraden.geom)).geom AS pgeom
           FROM omraden
        )
 SELECT row_number() OVER () AS id,
    x.g_uuid,
    x.geom
   FROM ( SELECT DISTINCT o.g_uuid,
            o.pgeom::geometry(Point,3008) AS geom
           FROM omradespunkter o,
            drk.fastgrans_ f--qdp2.kontrollobjekt f
          WHERE st_dwithin(o.pgeom, f.geom, 0.5::double precision) AND NOT st_dwithin(o.pgeom, f.geom, 0.001::double precision)
        UNION
		  SELECT DISTINCT o.g_uuid,
		 	fp.pgeom::geometry(Point,3008) AS geom
		 FROM (SELECT (st_dumppoints(f_1.geom)).geom AS pgeom
           		FROM drk.fastgrans_ f_1, omraden o_1
              WHERE st_dwithin(o_1.geom, f_1.geom, 0.5::double precision)) fp,
		 	omraden o
		 WHERE st_dwithin(fp.pgeom, o.geom, 0.5::double precision) AND NOT st_dwithin(fp.pgeom, o.geom, 0.001::double precision)
		) x;

ALTER TABLE qdp2.v_punkter_miss
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_punkter_miss
    IS 'Områdesytor med mismatch mot fastighetsgränser';

GRANT SELECT ON TABLE qdp2.v_punkter_miss TO read_geodata;
GRANT ALL ON TABLE qdp2.v_punkter_miss TO edit_geodata;
  
-- View: qdp2.v_anvandning_miss

-- DROP VIEW qdp2.v_anvandning_miss;

CREATE OR REPLACE VIEW qdp2.v_anvandning_miss
 AS
 SELECT miss.plan_uuid,
    miss.geom::geometry(MultiPolygon,3008) AS geom
   FROM ( SELECT o.plan_uuid,
            st_multi(st_difference(st_union(po.geom), st_union(o.geom))) AS geom
           FROM qdp2.omr o,
            qdp2.plan_omr po,
            qdp2.anv_best a
          WHERE o.plan_uuid = po.plan_uuid AND o.o_uuid = a.o_uuid
          GROUP BY o.plan_uuid) miss
  WHERE st_area(miss.geom) > 0::double precision;

ALTER TABLE qdp2.v_anvandning_miss
    OWNER TO edit_geodata;
COMMENT ON VIEW qdp2.v_anvandning_miss
    IS 'Planytor som inte täcks av användnigsyta';

GRANT SELECT ON TABLE qdp2.v_anvandning_miss TO read_geodata;
GRANT ALL ON TABLE qdp2.v_anvandning_miss TO edit_geodata;
  
  
