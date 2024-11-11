-- View: qdp2.mv_anv
-- DROP MATERIALIZED VIEW qdp2.mv_anv;

CREATE MATERIALIZED VIEW qdp2.mv_anv
TABLESPACE pg_default
 AS
 WITH rings AS (
         SELECT st_exteriorring((st_dumprings((st_dump(o.geom)).geom)).geom) AS geom
           FROM qdp2.omr o JOIN qdp2.anv_best x ON o.o_uuid = x.o_uuid
        ), boundaries AS (
         SELECT st_union(rings.geom) AS geom
           FROM rings
        ), poly AS (
         SELECT (st_dump(st_polygonize(boundaries.geom))).geom AS geom
           FROM boundaries
        ), polys AS (
         SELECT row_number() OVER () AS id,
            poly.geom
           FROM poly
        ), abest AS (
         SELECT x.abest_uuid,
            x.huvudsaklig,
            b.beteckning,
			b.index,
            o.geom,
            k.farg_id,
            f.farg,
            f.fargkod,
			b.status,
			b.publicerad
           FROM qdp2.v_best b,
            qdp2.anv_best x,
            qdp2.omr o,
            qdp2.bkatalog_imp k,
            qdp2.farg f
          WHERE b.best_uuid = x.best_uuid AND x.o_uuid = o.o_uuid AND b.bk_ref = k.id AND k.farg_id = f.id AND b.katalogversion = k.katalogversion
        )
 SELECT p.id,
    count(*) AS antal,
    string_agg(concat(a.beteckning, chr(8320+a.index)::text), ' '::text ORDER BY a.huvudsaklig DESC, a.beteckning, a.index) AS beteckning,
    (array_agg(a.fargkod ORDER BY a.huvudsaklig DESC, a.beteckning))[1] AS fargkod,
	max(a.status) AS status,
	max(a.publicerad) AS publicerad,
    p.geom::geometry(Polygon,3008) AS geom
   FROM polys p
     JOIN abest a ON st_contains(a.geom, st_pointonsurface(p.geom))
  GROUP BY p.id, p.geom
WITH DATA;

ALTER TABLE qdp2.mv_anv
    OWNER TO edit_geodata;

COMMENT ON MATERIALIZED VIEW qdp2.mv_anv
    IS 'Materialiserad vy för Enkla användningsytor';

GRANT SELECT ON TABLE qdp2.mv_anv TO read_geodata;
GRANT ALL ON TABLE qdp2.mv_anv TO edit_geodata;

CREATE INDEX qdp2_mv_anv_sidx
    ON qdp2.mv_anv USING gist
    (geom)
    TABLESPACE pg_default;
CREATE UNIQUE INDEX qdp2_mv_anv_uidx
    ON qdp2.mv_anv USING btree
    (id)
    TABLESPACE pg_default;

-- View: qdp2.mv_eg
-- DROP MATERIALIZED VIEW qdp2.mv_eg;

CREATE MATERIALIZED VIEW qdp2.mv_eg
TABLESPACE pg_default
 AS
 WITH ebest AS (
         SELECT x.ebest_uuid,
            b.beteckning,
	 		b.index,
            o.geom,
            k.symbolbeteckning_type,
            k.symbolbeteckning_id,
            k.symbolbeteckning_name,
	 		b.status,
			b.publicerad
           FROM qdp2.v_best b,
            qdp2.egen_best x,
            qdp2.omr o,
            qdp2.bkatalog_imp k
          WHERE b.best_uuid = x.best_uuid AND x.o_uuid = o.o_uuid AND b.bk_ref = k.id AND NOT b.anvandningsform = 'Planområdet'::text AND NOT b.sekundar AND (NOT b.galler_all_anvandningsform OR b.galler_all_anvandningsform IS NULL) AND b.katalogversion = k.katalogversion
        ), erings AS (
         SELECT st_exteriorring((st_dumprings((st_dump(ebest.geom)).geom)).geom) AS geom
           FROM ebest
        UNION
         SELECT st_exteriorring((st_dumprings((st_dump(o.geom)).geom)).geom) AS geom
           FROM qdp2.omr o JOIN qdp2.anv_best x ON o.o_uuid = x.o_uuid
        ), eboundaries AS (
         SELECT st_union(erings.geom) AS geom
           FROM erings
        ), epoly AS (
         SELECT (st_dump(st_polygonize(eboundaries.geom))).geom AS geom
           FROM eboundaries
        ), epolys AS (
         SELECT row_number() OVER () AS id,
            epoly.geom
           FROM epoly
        ), abest AS (
         SELECT x.ebest_uuid,
            b.beteckning,
			b.index,
            o.geom,
            k.symbolbeteckning_type,
            k.symbolbeteckning_id,
            k.symbolbeteckning_name,
			b.status,
			b.publicerad
           FROM qdp2.v_best b,
            qdp2.egen_best x,
            qdp2.omr o,
            qdp2.bkatalog_imp k
          WHERE b.best_uuid = x.best_uuid AND x.o_uuid = o.o_uuid AND b.bk_ref = k.id AND NOT b.anvandningsform = 'Planområdet'::text AND (b.sekundar OR b.anvandningsform = 'Administrativ'::text) AND (NOT b.galler_all_anvandningsform OR b.galler_all_anvandningsform IS NULL) AND b.katalogversion = k.katalogversion
        ), arings AS (
         SELECT st_exteriorring((st_dumprings((st_dump(abest.geom)).geom)).geom) AS geom
           FROM abest
        UNION
         SELECT st_exteriorring((st_dumprings((st_dump(o.geom)).geom)).geom) AS geom
           FROM qdp2.omr o JOIN qdp2.anv_best x ON o.o_uuid = x.o_uuid
        ), aboundaries AS (
         SELECT st_union(arings.geom) AS geom
           FROM arings
        ), apoly AS (
         SELECT (st_dump(st_polygonize(aboundaries.geom))).geom AS geom
           FROM aboundaries
        ), apolys AS (
         SELECT row_number() OVER () AS id,
            apoly.geom
           FROM apoly
        )
 SELECT row_number() OVER () AS id,
    u.antal,
    u.beteckning,
	u.typ,
    u.symbol,
	u.status,
	u.publicerad,
    u.geom::geometry(Polygon,3008) AS geom
   FROM ( SELECT p.id,
            count(*) AS antal,
            string_agg(concat(a.beteckning, chr(8320+a.index)), ' '::text ORDER BY a.beteckning, a.index) AS beteckning,
            (array_agg(a.symbolbeteckning_name ORDER BY a.symbolbeteckning_name))[1] AS symbol,
		 	'eg' AS typ,
		 	max(a.status) AS status,
			max(a.publicerad) AS publicerad,
            p.geom
           FROM epolys p
             JOIN ebest a ON st_contains(a.geom, st_pointonsurface(p.geom))
          GROUP BY p.id, p.geom
        UNION ALL
         SELECT p.id,
            count(*) AS antal,
            string_agg(concat(a.beteckning, a.index), ' '::text ORDER BY a.beteckning, a.index) AS beteckning,
            (array_agg(a.symbolbeteckning_name ORDER BY a.symbolbeteckning_name))[1] AS symbol,
		 	'eg_sek' AS typ,
		 	max(a.status) AS status,
			max(a.publicerad) AS publicerad,
            p.geom
           FROM apolys p
             JOIN abest a ON st_contains(a.geom, st_pointonsurface(p.geom))
          GROUP BY p.id, p.geom) u
WITH DATA;

ALTER TABLE qdp2.mv_eg
    OWNER TO edit_geodata;

COMMENT ON MATERIALIZED VIEW qdp2.mv_eg
    IS 'Materialiserad vy för Enkla egenskapssytor';

GRANT SELECT ON TABLE qdp2.mv_eg TO read_geodata;
GRANT ALL ON TABLE qdp2.mv_eg TO edit_geodata;

CREATE INDEX qdp2_mv_eg_sidx
    ON qdp2.mv_eg USING gist
    (geom)
    TABLESPACE pg_default;
CREATE UNIQUE INDEX qdp2_mv_eg_uidx
    ON qdp2.mv_eg USING btree
    (id)
    TABLESPACE pg_default;

-- View: qdp2.mv_ega

-- DROP MATERIALIZED VIEW IF EXISTS qdp2.mv_ega;

CREATE MATERIALIZED VIEW IF NOT EXISTS qdp2.mv_ega
TABLESPACE pg_default
AS
	WITH orings AS (
		 SELECT st_exteriorring((st_dumprings((st_dump(omr.geom)).geom)).geom) AS geom
		 FROM qdp2.omr
		),oboundaries AS (
         SELECT st_union(orings.geom) AS geom
           FROM orings
        ), opoly AS (
         SELECT (st_dump(st_polygonize(oboundaries.geom))).geom AS geom
           FROM oboundaries
        )
         SELECT row_number() OVER () AS id,
		 	p.namn,
			'delområde' AS delomr,
		 	p.plan_uuid,
		 	p.status,
			p.publicerad,
            op.geom
           FROM opoly op,
		   qdp2.plan_omr po,
		   qdp2.plan p
		   WHERE st_contains(po.geom, st_pointonsurface(op.geom)) AND po.plan_uuid = p.plan_uuid
WITH DATA;

ALTER TABLE IF EXISTS qdp2.mv_ega
    OWNER TO edit_geodata;

COMMENT ON MATERIALIZED VIEW qdp2.mv_ega
    IS 'Materialiserad vy för enkla betämmelseytor för klick';

GRANT ALL ON TABLE qdp2.mv_ega TO edit_geodata;
GRANT SELECT ON TABLE qdp2.mv_ega TO read_geodata;

CREATE INDEX qdp2_mv_ega_sidx
    ON qdp2.mv_ega USING gist
    (geom)
    TABLESPACE pg_default;
CREATE UNIQUE INDEX qdp2_mv_ega_uidx
    ON qdp2.mv_ega USING btree
    (id)
    TABLESPACE pg_default;

-- View: qdp2.mv_gr

-- DROP MATERIALIZED VIEW qdp2.mv_gr;

CREATE MATERIALIZED VIEW qdp2.mv_gr
TABLESPACE pg_default
AS
 WITH pg AS (
         SELECT g.geom,
            'plan'::text AS typ,
            o.plan_uuid,
            o.status,
	 		o.publicerad
           FROM qdp2.v_plan o
             JOIN ( SELECT unnest(array_agg(a.plan_uuid)) AS plan_uuid,
                    st_linemerge(st_union(st_collectionextract(st_intersection(st_boundary(a.geom), st_boundary(b.geom)), 2))) AS geom
                   FROM qdp2.plan_omr a,
                    qdp2.plan_omr b
                  WHERE st_intersects(a.geom, b.geom) AND a.po_uuid <> b.po_uuid
                UNION ALL
                 SELECT a.plan_uuid,
                        CASE
                            WHEN st_collect(b.geom) IS NOT NULL THEN st_difference(st_boundary(a.geom), st_collect(st_boundary(b.geom)))
                            ELSE st_boundary(a.geom)
                        END AS geom
                   FROM qdp2.plan_omr a
                     LEFT JOIN qdp2.plan_omr b ON st_intersects(a.geom, b.geom) AND a.po_uuid <> b.po_uuid
                  GROUP BY a.plan_uuid, a.geom) g ON o.plan_uuid = g.plan_uuid
        ), ag AS (
         SELECT st_linemerge(st_union(st_boundary(o.geom))) AS geom,
            'anv'::text AS typ,
            b.plan_uuid,
            b.status,
			b.publicerad
           FROM qdp2.v_best b
     			JOIN qdp2.anv_best x ON b.best_uuid::text = x.best_uuid::text
     			JOIN qdp2.omr o ON x.o_uuid = o.o_uuid
          GROUP BY o.po_uuid, b.plan_uuid, b.status, b.publicerad
        ), eg AS (
         SELECT st_linemerge(st_union(st_boundary(o.geom))) AS geom,
            'eg'::text AS typ,
            b.plan_uuid,
            b.status,
			b.publicerad
           FROM qdp2.v_best b,
            qdp2.egen_best x,
            qdp2.omr o
          	WHERE b.best_uuid = x.best_uuid AND x.o_uuid = o.o_uuid AND NOT b.anvandningsform = 'Planområdet'::text AND NOT b.sekundar AND (NOT b.galler_all_anvandningsform OR b.galler_all_anvandningsform IS NULL)
          GROUP BY b.plan_uuid, b.status, b.publicerad -- o.o_uuid,
        ), ad AS (
         SELECT st_linemerge(st_union(st_boundary(o.geom))) AS geom,
            'ad'::text AS typ,
            b.plan_uuid,
            b.status,
			b.publicerad
           FROM qdp2.v_best b,
            qdp2.egen_best x,
            qdp2.omr o
          WHERE b.best_uuid = x.best_uuid AND x.o_uuid = o.o_uuid AND NOT b.anvandningsform = 'Planområdet'::text AND (b.sekundar OR b.anvandningsform = 'Administrativ'::text )AND (NOT b.galler_all_anvandningsform OR b.galler_all_anvandningsform IS NULL)
          GROUP BY  b.plan_uuid, b.status, b.publicerad --o.o_uuid,
        )
 SELECT row_number() OVER () AS id,
    gr.typ,
    gr.plan_uuid,
    gr.status,
	gr.publicerad,
    st_multi(gr.geom)::geometry(MultiLineString,3008) AS geom
   FROM ( SELECT pg.geom,
            pg.typ,
            pg.plan_uuid,
            pg.status,
		 	pg.publicerad
           FROM pg
        UNION ALL
         SELECT
                CASE
                    WHEN st_collect(b.geom) IS NOT NULL THEN st_difference(a.geom, st_collect(b.geom))
                    ELSE a.geom
                END AS geom,
            a.typ,
            a.plan_uuid,
            a.status,
		 	a.publicerad
           FROM ag a
             LEFT JOIN ( SELECT pg.geom,
                    pg.typ
                   FROM pg) b ON st_intersects(a.geom, b.geom)
          GROUP BY a.typ, a.geom, a.plan_uuid, a.status, a.publicerad
        UNION ALL
         SELECT
                CASE
                    WHEN st_collect(b.geom) IS NOT NULL THEN st_difference(a.geom, st_collect(b.geom))
                    ELSE a.geom
                END AS geom,
            a.typ,
            a.plan_uuid,
            a.status,
		 	a.publicerad
           FROM eg a
             LEFT JOIN ( SELECT pg.geom,
                    pg.typ
                   FROM pg
                UNION ALL
                 SELECT ag.geom,
                    ag.typ
                   FROM ag
                UNION ALL
                 SELECT ad.geom,
                    ad.typ
                   FROM ad) b ON st_intersects(a.geom, b.geom)
          GROUP BY a.typ, a.geom, a.plan_uuid, a.status, a.publicerad
        UNION ALL
         SELECT DISTINCT
                CASE
                    WHEN st_collect(b.geom) IS NOT NULL THEN st_difference(a.geom, st_collect(b.geom))
                    ELSE a.geom
                END AS geom,
            a.typ,
            a.plan_uuid,
            a.status,
		 	a.publicerad
           FROM ( SELECT st_linemerge(st_collectionextract(st_intersection(a_1.geom, b_1.geom), 2)) AS geom,
                    'eg_ad'::text AS typ,
                    a_1.plan_uuid,
                    a_1.status,
				 	a_1.publicerad
                   FROM ad a_1,
                    eg b_1
                  WHERE st_intersects(a_1.geom, b_1.geom)) a
             LEFT JOIN ( SELECT pg.geom,
                    pg.typ
                   FROM pg
                UNION ALL
                 SELECT ag.geom,
                    ag.typ
                   FROM ag) b ON st_intersects(a.geom, b.geom)
          GROUP BY a.typ, a.geom, a.plan_uuid, a.status, a.publicerad
        UNION ALL
         SELECT
                CASE
                    WHEN st_collect(b.geom) IS NOT NULL THEN st_difference(a.geom, st_collect(b.geom))
                    ELSE a.geom
                END AS geom,
            a.typ,
            a.plan_uuid,
            a.status,
		 	a.publicerad
           FROM ad a
             LEFT JOIN ( SELECT pg.geom,
                    pg.typ
                   FROM pg
                UNION ALL
                 SELECT ag.geom,
                    ag.typ
                   FROM ag
                UNION ALL
                 SELECT eg.geom,
                    eg.typ
                   FROM eg) b ON st_intersects(a.geom, b.geom)
          GROUP BY a.typ, a.geom, a.plan_uuid, a.status, a.publicerad) gr
  WHERE st_geometrytype(gr.geom) = ANY (ARRAY['ST_LineString'::text, 'ST_MultiLineString'::text])
WITH DATA;

ALTER TABLE qdp2.mv_gr
   OWNER TO edit_geodata;

COMMENT ON MATERIALIZED VIEW qdp2.mv_gr
    IS 'Materialiserad vy för Kartografiska plangränser med status';

GRANT SELECT ON TABLE qdp2.mv_gr TO read_geodata;
GRANT ALL ON TABLE qdp2.mv_gr TO edit_geodata;

CREATE INDEX qdp2_mv_gr_sidx
    ON qdp2.mv_gr USING gist
    (geom)
    TABLESPACE pg_default;
CREATE UNIQUE INDEX qdp2_mv_gr_uidx
    ON qdp2.mv_gr USING btree
    (id)
    TABLESPACE pg_default;

-- View: qdp2.v_best_g

-- DROP VIEW qdp2.v_best_g;

-- CREATE OR REPLACE VIEW qdp2.v_best_g AS 
--  SELECT b.best_uuid,
--     b.plan_uuid,
--     b.bestammelsetyp,
-- 	b.anvandningsform,
--     b.beteckning,
--     b.index,
--     b.bform,
-- 	b.sekundar,
-- 	b.galler_all_anvandningsform,
-- 	o.geom::geometry(MultiSurface,3008)
--    FROM qdp2.v_best b
--    JOIN (
-- 			SELECT x.best_uuid, st_collect(o.geom) AS geom
-- 			FROM qdp2.omr o JOIN qdp2.anv_best x ON o.o_uuid = x.o_uuid
-- 			GROUP BY x.best_uuid
-- 		UNION
-- 		 SELECT e.best_uuid, st_collect(o.geom)
--            FROM qdp2.egen_best e JOIN qdp2.omr o ON e.o_uuid = o.o_uuid
--           GROUP BY e.best_uuid 
-- 	   UNION
-- 	   	 SELECT DISTINCT b.best_uuid, ST_ForceCurve(st_multi(st_union(o.geom)))
-- 		 FROM qdp2.best b JOIN qdp2.omr o ON b.plan_uuid = o.plan_uuid AND b.anvandningsform = o.anvandningsform AND b.galler_all_anvandningsform JOIN qdp2.anv_best a ON o.o_uuid = a.o_uuid
-- 	     GROUP BY b.best_uuid
-- 	   UNION
-- 	     SELECT l.best_uuid, ST_ForceCurve(st_collect(st_buffer(l.geom,1)))
-- 	     FROM qdp2.egenlin l
-- 	     GROUP BY l.best_uuid
-- 	   UNION
-- 	     SELECT p.best_uuid,  ST_ForceCurve(st_collect(st_buffer(p.geom,1)))
-- 	     FROM qdp2.egenpkt p
-- 	     GROUP BY p.best_uuid
--    ) o ON o.best_uuid = b.best_uuid
-- ;
-- ALTER TABLE qdp2.v_best_g
--   OWNER TO edit_geodata;
-- GRANT ALL ON TABLE qdp2.v_best_g TO edit_geodata;
-- GRANT SELECT ON TABLE qdp2.v_best_g TO read_geodata;
-- COMMENT ON VIEW qdp2.v_best_g
--   IS 'Bestämmelser med formulering och sammanslagen geometri';