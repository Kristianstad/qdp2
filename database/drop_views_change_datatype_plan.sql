DROP VIEW qdp2.v_plan_json;
DROP VIEW qdp2.v_egp_best;
DROP VIEW qdp2.v_egl_best;
DROP VIEW qdp2.v_gr;
DROP VIEW qdp2.v_eg;
DROP VIEW qdp2.v_anv;
DROP MATERIALIZED VIEW qdp2.mv_gr;
DROP MATERIALIZED VIEW IF EXISTS qdp2.mv_ega; 
DROP MATERIALIZED VIEW qdp2.mv_eg;
DROP MATERIALIZED VIEW qdp2.mv_anv;
DROP VIEW qdp2.v_anvandning_miss;
DROP VIEW qdp2.v_punkter_miss;
DROP VIEW qdp2.v_egy_best;
DROP VIEW qdp2.v_best_g;
DROP VIEW qdp2.v_anv_best;
DROP VIEW qdp2.v_best;
DROP VIEW qdp2.v_bvar;
DROP VIEW qdp2.v_plan;
DROP VIEW qdp2.v_underkategori;
DROP VIEW qdp2.v_kategori;
DROP VIEW qdp2.v_anvandningsform_name;
DROP VIEW qdp2.v_bestammelsetyp_name;

ALTER TABLE IF EXISTS qdp2.plan
    ADD COLUMN publicerad_new integer;

UPDATE qdp2.plan
	SET publicerad_new = 0;

UPDATE qdp2.plan
	SET publicerad_new = 2
	WHERE publicerad;

ALTER TABLE IF EXISTS qdp2.plan
	DROP COLUMN IF EXISTS publicerad;

ALTER TABLE IF EXISTS qdp2.plan
    RENAME publicerad_new TO publicerad;