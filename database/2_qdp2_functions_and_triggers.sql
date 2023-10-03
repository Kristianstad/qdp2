-- Function: qdp2.insert_insattning_a()

-- DROP FUNCTION qdp2.insert_insattning_a();

CREATE OR REPLACE FUNCTION qdp2.insert_insattning_a()
  RETURNS trigger AS
$BODY$
declare omr geometry;
	count integer;
BEGIN
	SELECT geom INTO omr FROM qdp2.omr WHERE omr.o_uuid = NEW.o_uuid;
	SELECT count(*) INTO count FROM qdp2.anv_best WHERE anv_best.o_uuid = NEW.o_uuid;
	NEW.norr = st_y(st_pointonsurface(omr)) + 7;
	NEW.ost = st_x(st_pointonsurface(omr)) + 7*count;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_insattning_a()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_insattning_a() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_insattning_a() TO edit_plan;

-- Trigger: insert_anv_best_insattning on qdp2.anv_best

-- DROP TRIGGER insert_anv_best_insattning ON qdp2.anv_best;

CREATE TRIGGER insert_anv_best_insattning
  BEFORE INSERT
  ON qdp2.anv_best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_insattning_a();

-- Function: qdp2.insert_insattning_e()

-- DROP FUNCTION qdp2.insert_insattning_e();

CREATE OR REPLACE FUNCTION qdp2.insert_insattning_e()
  RETURNS trigger AS
$BODY$
declare omr geometry;
	count integer;
BEGIN
	SELECT geom INTO omr FROM qdp2.omr WHERE omr.o_uuid = NEW.o_uuid;
	SELECT count(*) INTO count FROM qdp2.egen_best WHERE egen_best.o_uuid = NEW.o_uuid;
	NEW.norr = st_y(st_pointonsurface(omr)) - 7;
	NEW.ost = st_x(st_pointonsurface(omr)) + 7*count;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_insattning_e()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_insattning_e() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_insattning_e() TO edit_plan;

-- Trigger: insert_egen_best_insattning on qdp2.egen_best

-- DROP TRIGGER insert_egen_best_insattning ON qdp2.egen_best;

CREATE TRIGGER insert_egen_best_insattning
  BEFORE INSERT
  ON qdp2.egen_best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_insattning_e();

-- Function: qdp2.insert_plan_omr()

-- DROP FUNCTION qdp2.insert_plan_omr();

CREATE OR REPLACE FUNCTION qdp2.insert_plan_omr()
  RETURNS trigger AS
$BODY$
declare noggrannhet real;
BEGIN --sätt noggrannhet från fastighetsgränser
	--SELECT  max(f."NOGGRANNHET") INTO noggrannhet
	--FROM (SELECT po_uuid, ST_DumpPoints(NEW.geom) AS dp FROM qdp2.plan_omr) o,
	--	drk.fastgrans_ f
	--WHERE  ST_DWithin((o.dp).geom,f.geom, 0.001)
	--GROUP BY o.po_uuid;
	SELECT  max(f."NOGGRANNHET") INTO noggrannhet
	FROM drk.fastgrans_ f, (SELECT (ST_DumpPoints(NEW.geom)).geom AS dp) o
	WHERE  ST_DWithin(o.dp,f.geom, 0.001);
	IF (NEW.absolutlagesosakerhetplan = 0 OR NEW.absolutlagesosakerhetplan IS NULL) AND noggrannhet > 0 THEN
		NEW.absolutlagesosakerhetplan = noggrannhet;
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION  qdp2.insert_plan_omr()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_plan_omr() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_plan_omr() TO edit_plan;

-- Trigger: insert_plan_omr on qdp2.plan_omr

-- DROP TRIGGER insert_plan_omr ON qdp2.plan_omr;

CREATE TRIGGER insert_plan_omr
  BEFORE INSERT
  ON qdp2.plan_omr
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_plan_omr();

-- Function: qdp2.insert_omr()

-- DROP FUNCTION qdp2.insert_omr();

CREATE OR REPLACE FUNCTION qdp2.insert_omr()
  RETURNS trigger AS
$BODY$
declare noggrannhet real;
BEGIN
	IF st_intersects(NEW.geom,(SELECT po.geom FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom))) THEN --inom planområde? annars NULL
   		--NEW.geom = st_intersection(NEW.geom,(SELECT po.geom FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom))); --klipp till området inom planområdet
		NEW.po_uuid = (SELECT po.po_uuid FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom)); --hämta po_uuid från planområde
		NEW.plan_uuid = (SELECT po.plan_uuid FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom)); --hämta plan_uuid från planområde
		--kolla så området inte läggs över område med annan användningsform
		IF st_intersects(NEW.geom,(SELECT ST_Union( ARRAY( ( SELECT o.geom FROM qdp2.omr o WHERE o.plan_uuid = NEW.plan_uuid AND st_intersects(NEW.geom,geom) AND NOT o.anvandningsform = NEW.anvandningsform))))) THEN
		--	NEW.geom = st_difference(NEW.geom,(SELECT ST_Union( ARRAY( SELECT o.geom FROM qdp2.omr o WHERE o.plan_uuid = NEW.plan_uuid AND st_intersects(NEW.geom,geom) AND NOT o.anvandningsform = NEW.anvandningsform))));
		END IF;
		--snappa befintliga planområde och områden mot det nya så att brytpunkter bildas
		UPDATE qdp2.plan_omr SET
			geom = st_snap(geom,NEW.geom,0.01)
		WHERE plan_uuid = NEW.plan_uuid;
		UPDATE qdp2.omr SET
			geom = st_snap(geom,NEW.geom,0.01)
		WHERE plan_uuid = NEW.plan_uuid AND st_intersects(NEW.geom,geom);
		--sätt noggrannhet från fastighetsgränser
		SELECT  max(f."NOGGRANNHET") INTO noggrannhet
		FROM drk.fastgrans_ f, (SELECT (ST_DumpPoints(NEW.geom)).geom AS dp) o
		WHERE  ST_DWithin(o.dp,f.geom, 0.001);
		IF noggrannhet IS NULL THEN
			SELECT po.absolutlagesosakerhetplan INTO noggrannhet FROM qdp2.plan_omr po WHERE po.po_uuid = NEW.po_uuid;
		END IF;
		IF (NEW.absolutlagesosakerhetplan = 0 OR NEW.absolutlagesosakerhetplan IS NULL) AND noggrannhet > 0 THEN
			NEW.absolutlagesosakerhetplan = noggrannhet;
		END IF;
		RETURN NEW;
   	ELSE
		RETURN NULL;
   	END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION  qdp2.insert_omr()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_omr() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_omr() TO edit_plan;

-- Trigger: insert_omr on qdp2.omr

-- DROP TRIGGER insert_omr ON qdp2.omr;

CREATE TRIGGER insert_omr
  BEFORE INSERT
  ON qdp2.omr
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_omr();


-- Function: qdp2.insert_lin()

-- DROP FUNCTION qdp2.insert_lin();

CREATE OR REPLACE FUNCTION qdp2.insert_lin()
  RETURNS trigger AS
$BODY$
declare noggrannhet real;
BEGIN
	IF st_intersects(NEW.geom,(SELECT po.geom FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom))) THEN --inom planområde? annars NULL
   		--NEW.geom = st_intersection(NEW.geom,(SELECT po.geom FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom))); --klipp till linje inom planområdet
		NEW.po_uuid = (SELECT po.po_uuid FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom)); --hämta po_uuid från planområde
		NEW.plan_uuid = (SELECT po.plan_uuid FROM qdp2.plan_omr po WHERE st_within(ST_PointOnSurface(NEW.geom), po.geom)); --hämta plan_uuid från planområde
		--sätt noggrannhet från fastighetsgränser
		SELECT  max(f."NOGGRANNHET") INTO noggrannhet
		FROM drk.fastgrans_ f, (SELECT (ST_DumpPoints(NEW.geom)).geom AS dp) o
		WHERE  ST_DWithin(o.dp,f.geom, 0.001);
		IF noggrannhet IS NULL THEN
			SELECT po.absolutlagesosakerhetplan INTO noggrannhet FROM qdp2.plan_omr po WHERE po.po_uuid = NEW.po_uuid;
		END IF;
		IF (NEW.absolutlagesosakerhetplan = 0 OR NEW.absolutlagesosakerhetplan IS NULL) AND noggrannhet > 0 THEN
			NEW.absolutlagesosakerhetplan = noggrannhet;
		END IF;
		RETURN NEW;
   	ELSE
		RETURN NULL;
   	END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION  qdp2.insert_lin()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_lin() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_lin() TO edit_plan;

-- Trigger: insert_egenlin

-- DROP TRIGGER insert_egenlin ON qdp2.egenlin;

CREATE TRIGGER insert_egenlin
    BEFORE INSERT
    ON qdp2.egenlin
    FOR EACH ROW
    EXECUTE PROCEDURE qdp2.insert_lin();
	
-- Trigger: insert_egenpkt

-- DROP TRIGGER insert_egenpkt ON qdp2.egenpkt;

CREATE TRIGGER insert_egenpkt
    BEFORE INSERT
    ON qdp2.egenpkt
    FOR EACH ROW
    EXECUTE PROCEDURE qdp2.insert_lin();

-- Function: qdp2.insert_best_var()

-- DROP FUNCTION qdp2.insert_best_var();

CREATE OR REPLACE FUNCTION qdp2.insert_best_var()
  RETURNS trigger AS
$BODY$
declare bf text;
	vtyp text;
	vt text;
	sp integer;
	ep integer;
	var text;
	vkey text;
	dtype text;
BEGIN
	SELECT bestammelseformulering,lower(uttrycktvarde) INTO bf,vtyp FROM qdp2.bkatalog_imp bk WHERE bk.id = NEW.bk_ref;-- AND bk.katalogversion = NEW.katalogversion;
	WHILE position('[' in bf) > 0 LOOP
		sp = strpos(bf, '[');
		ep = strpos(bf, ']');
		var = substring(bf from sp + 1 for ep - sp - 1);
		vkey = split_part(var,':',1);
		dtype = split_part(var,':',2);
		IF dtype = 'decimaltal' THEN
			vt = vtyp;
		ELSE
			vt = NULL;
		END IF;
		bf = substring(bf from ep +1);
		INSERT INTO qdp2.variabel (best_uuid, datatyp, variabelvarde, beskrivning, vardetyp)
			VALUES (new.best_uuid,dtype,'',vkey,vt);
	END LOOP;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_best_var()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_best_var() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_best_var() TO edit_plan;

-- Trigger: insert_best on qdp2.best

-- DROP TRIGGER insert_best ON qdp2.best;

CREATE TRIGGER insert_best
  AFTER INSERT ON qdp2.best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_best_var();

-- Function: qdp2.update_best_var()

-- DROP FUNCTION qdp2.update_best_var();

CREATE OR REPLACE FUNCTION qdp2.update_best_var()
  RETURNS trigger AS
$BODY$
declare bf text;
	vtyp text;
	vt text;
	sp integer;
	ep integer;
	var text;
	vkey text;
	dtype text;
BEGIN
	IF NOT new.bk_ref = old.bk_ref THEN
		DELETE FROM qdp2.variabel WHERE best_uuid= new.best_uuid;
		SELECT bestammelseformulering,lower(uttrycktvarde) INTO bf,vtyp FROM qdp2.bkatalog_imp bk WHERE bk.id = NEW.bk_ref;-- AND bk.katalogversion = NEW.katalogversion;
		WHILE position('[' in bf) > 0 LOOP
			sp = strpos(bf, '[');
			ep = strpos(bf, ']');
			var = substring(bf from sp + 1 for ep - sp - 1);
			vkey = split_part(var,':',1);
			dtype = split_part(var,':',2);
			IF dtype = 'decimaltal' THEN
				vt = vtyp;
			ELSE
				vt = NULL;
			END IF;
			bf = substring(bf from ep +1);
			INSERT INTO qdp2.variabel (best_uuid, datatyp, variabelvarde, beskrivning, vardetyp)
				VALUES (new.best_uuid,dtype,'',vkey,vt);
		END LOOP;
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.update_best_var()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.update_best_var() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.update_best_var() TO edit_plan;

-- Trigger: update_best on qdp2.best

-- DROP TRIGGER update_best ON qdp2.best;

CREATE TRIGGER update_best
  AFTER UPDATE ON qdp2.best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.update_best_var();



-- Function: qdp2.delete_beslut()

-- DROP FUNCTION qdp2.delete_beslut();

CREATE OR REPLACE FUNCTION qdp2.delete_beslut()
  RETURNS trigger AS
$BODY$
BEGIN
--	DELETE FROM qdp2.referens WHERE dokref_id = old.dokref_id;
	DELETE FROM qdp2.referens WHERE dokref_id = old.gk_id;
	RETURN OLD;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.delete_beslut()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.delete_beslut() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.delete_beslut() TO edit_plan;

-- Trigger: delete_beslut on qdp2.beslut

-- DROP TRIGGER delete_beslut ON qdp2.beslut;

CREATE TRIGGER delete_beslut
  AFTER DELETE
  ON qdp2.beslut
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.delete_beslut();

-- Function: qdp2.delete_dokref()

-- DROP FUNCTION qdp2.delete_dokref();

CREATE OR REPLACE FUNCTION qdp2.delete_dokref()
  RETURNS trigger AS
$BODY$
BEGIN
	DELETE FROM qdp2.referens WHERE dokref_id = old.dokref_id;
	RETURN OLD;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.delete_dokref()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.delete_dokref() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.delete_dokref() TO edit_plan;

-- Trigger: delete_planbeskr on qdp2.planbeskrivning

-- DROP TRIGGER delete_planbeskr ON qdp2.planbeskrivning;

CREATE TRIGGER delete_planbeskr
  AFTER DELETE
  ON qdp2.planbeskrivning
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.delete_dokref();

-- Trigger: delete_underlag on qdp2.underlag

-- DROP TRIGGER delete_underlag ON qdp2.underlag;

CREATE TRIGGER delete_underlag
  AFTER DELETE
  ON qdp2.underlag
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.delete_dokref();
  
-- Trigger: delete_beslutshandling on qdp2.beslutshandling

-- DROP TRIGGER delete_beslutshandling ON qdp2.beslutshandling;

CREATE TRIGGER delete_beslutshandling
  AFTER DELETE
  ON qdp2.beslutshandling
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.delete_dokref();
  