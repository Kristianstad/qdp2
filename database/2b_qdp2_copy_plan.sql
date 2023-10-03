-- Function: qdp2.before_insert_plan()
-- DROP TRIGGER before_insert_plan ON qdp2.plan; DROP FUNCTION qdp2.before_insert_plan();
-- DROP FUNCTION qdp2.before_insert_plan();

CREATE OR REPLACE FUNCTION qdp2.before_insert_plan()
  RETURNS trigger AS
$BODY$
BEGIN
	IF NEW.plan_uuid IN (SELECT plan_uuid FROM qdp2.plan) THEN --Planen finns redan och ska uppdateras
		DELETE FROM qdp2.plan_omr WHERE plan_uuid = NEW.plan_uuid;
		DELETE FROM qdp2.best WHERE plan_uuid = NEW.plan_uuid;
		DELETE FROM qdp2.kvalitet WHERE plan_uuid = NEW.plan_uuid;
		DELETE FROM qdp2.lagesbestamningsmetod WHERE plan_uuid = NEW.plan_uuid;
		--DELETE FROM qdp2.plan WHERE plan_uuid = NEW.plan_uuid;
		UPDATE qdp2.plan
			SET v_giltig_fran = NEW.v_giltig_fran, v_giltig_till = NEW.v_giltig_till, beteckning = NEW.beteckning, kommun = NEW.kommun,
			namn = NEW.namn, syfte = NEW.syfte, status= NEW.status, typ = NEW.typ, avgransning = NEW.avgransning, akt = NEW.akt,
			datum_statusforandring = NEW.datum_statusforandring, kval_id = NEW.kval_id, anvandbarhet = NEW.anvandbarhet, 
			anvandbarhet_beskrivning = NEW.anvandbarhet_beskrivning, anteckning = NEW.anteckning, publicerad = NEW.publicerad
			WHERE plan_uuid = NEW.plan_uuid;
		RETURN NULL;
		--RETURN NEW;
	END IF;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.before_insert_plan()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.before_insert_plan() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.before_insert_plan() TO edit_plan;

-- Trigger: before_insert_plan on qdp2.plan

-- DROP TRIGGER before_insert_plan ON qdp2.plan;

CREATE TRIGGER before_insert_plan
  BEFORE INSERT
  ON qdp2.plan
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.before_insert_plan();

-- Function: qdp2.insert_plan()
-- DROP TRIGGER insert_plan ON qdp2.plan;
-- DROP FUNCTION qdp2.before_insert_plan();

CREATE OR REPLACE FUNCTION qdp2.insert_plan()
  RETURNS trigger AS
$BODY$
BEGIN
	IF NEW.objektidentitet IN (SELECT plan_uuid FROM qdp2.plan) AND NOT NEW.plan_uuid = NEW.objektidentitet THEN --IN (SELECT plan_uuid FROM qdp2.plan) THEN --Kopierad plan
		INSERT INTO qdp2.kvalitet --kopiera kvaliteter
		SELECT uuid_generate_v4(), NEW.plan_uuid, digitaliseringsniva, beskrivning_niva, korrigerade_granser, kontrollerat_underlag
		FROM qdp2.kvalitet
		WHERE plan_uuid = NEW.objektidentitet;
		INSERT INTO qdp2.lagesbestamningsmetod --kopiera lägesbestämningsmetoder
		SELECT uuid_generate_v4(), NEW.plan_uuid, metod, variant, tidpunkt, skala, lagesosakerhet
		FROM qdp2.lagesbestamningsmetod
		WHERE plan_uuid = NEW.objektidentitet;
		ALTER TABLE qdp2.best DISABLE TRIGGER insert_best;
		ALTER TABLE qdp2.best ENABLE TRIGGER copy_best;
		INSERT INTO qdp2.best --kopiera bestämmelser
		SELECT best_uuid, NEW.plan_uuid, bestammelsetyp,anvandningsform,kategori,underkategori,bk_ref,sekundar,
		galler_all_anvandningsform,ursprunglig,beteckning,index,
		NULL as kval_id,anvandbarhet,anvandbarhet_beskrivning
		FROM qdp2.best
		WHERE plan_uuid = NEW.objektidentitet;
		--ALTER TABLE qdp2.best DISABLE TRIGGER copy_best;
		--ALTER TABLE qdp2.best ENABLE TRIGGER insert_best;
	END IF;
	UPDATE qdp2.plan SET objektidentitet = NEW.plan_uuid, kval_id = NULL WHERE plan_uuid = NEW.plan_uuid;
	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.insert_plan()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.insert_plan() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.insert_plan() TO edit_plan;

-- Trigger: insert_plan on qdp2.plan

-- DROP TRIGGER insert_plan ON qdp2.plan;

CREATE TRIGGER insert_plan
  AFTER INSERT
  ON qdp2.plan
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.insert_plan();

-- Function: qdp2.copy_best()

-- DROP FUNCTION qdp2.copy_best();

CREATE OR REPLACE FUNCTION qdp2.copy_best()
  RETURNS trigger AS
$BODY$
declare old_best_uuid uuid;
BEGIN
  	SELECT NEW.best_uuid INTO old_best_uuid;
  	SELECT uuid_generate_v4() INTO NEW.best_uuid;
  	INSERT INTO qdp2.motiv --kopiera motiv
	SELECT uuid_generate_v4(), NEW.best_uuid, motiv
	FROM qdp2.motiv
	WHERE best_uuid = old_best_uuid;
	INSERT INTO qdp2.variabel (best_uuid,datatyp,variabelvarde,beskrivning,vardetyp,enhet)--kopiera variabler
	SELECT NEW.best_uuid,datatyp,variabelvarde,beskrivning,vardetyp,enhet
	FROM qdp2.variabel
	WHERE best_uuid = old_best_uuid;
	RETURN NEW;--NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION qdp2.copy_best()
  OWNER TO edit_geodata;
GRANT EXECUTE ON FUNCTION  qdp2.copy_best() TO edit_geodata;
GRANT EXECUTE ON FUNCTION qdp2.copy_best() TO edit_plan;

-- Trigger: copy_best on qdp2.best

-- DROP TRIGGER copy_best ON qdp2.best;

CREATE TRIGGER copy_best
  BEFORE INSERT
  ON qdp2.best
  FOR EACH ROW
  EXECUTE PROCEDURE qdp2.copy_best();
 