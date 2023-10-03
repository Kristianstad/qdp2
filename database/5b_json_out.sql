WITH lagesmetod AS (
	SELECT l.lage_id,
		jsonb_build_object('typ', l.metod,
						  'variant', l.variant,
						  'tidpunktForUnderlagetsFramtagande',
						   CASE WHEN l.tidpunkt IS NOT NULL THEN jsonb_build_object('fran', l.tidpunkt::TIMESTAMP WITH TIME ZONE-interval '1 month','till', l.tidpunkt::TIMESTAMP WITH TIME ZONE) ELSE NULL END,
						   'kartskala', l.kartskala,
						   'presentationsskala', l.presentationsskala,
						   'lagesosakerhetForReferensobjekt', l.lagesosakerhet
						   ) lagesmetod
	FROM
		(SELECT *,
			CASE metod WHEN 'lägesplacering' THEN skala	ELSE NULL END AS presentationsskala,
			CASE metod WHEN 'vektorisering av analogt material' THEN skala ELSE NULL END AS kartskala
		FROM qdp2.lagesbestamningsmetod) l
), geometri AS (
	SELECT g.ft, g.typ, g.best_uuid, g.g_uuid, g.anvandningsform, g.galler_endast, ST_Union(g.geom) geom,
		ST_AsGeoJSON((ST_Collect(g.geom)),6,1)::jsonb#>'{bbox}' bbox,
			ST_AsGeoJSON((ST_Collect(g.geom)),6,4)::jsonb#>'{crs}' crs,
			jsonb_agg(
			jsonb_build_object(
				'geometri',
				jsonb_build_object(
					'typ', g.typ,
					'absolutLagesosakerhetPlan' , g.absolutlagesosakerhetplan,
					'absolutLagesosakerhetHojd', CASE WHEN ST_CoordDim(g.geom) = 2 THEN null ELSE 0 END,--0,
					'koordinatsystemPlan', 'EPSG:'||ST_SRID(g.geom),
					'hojdsystem', CASE WHEN ST_CoordDim(g.geom) = 2 THEN null ELSE 'EPSG:5613' END,
					'dimension', ST_CoordDim(g.geom),
					'position', ST_AsGeoJSON(g.geom,6,0)::json
				),
				'geometrimetadata',
				jsonb_build_object(
					'tidpunktForLagesbestamning', g.tid_lage::TIMESTAMP WITH TIME ZONE,
					'tidpunktForKontrollAvGeometri', g.tid_kontroll::TIMESTAMP WITH TIME ZONE,
					'lagesbestamningsmetodIPlan', g.lagesmetod)
			)
		) g_json
	FROM (SELECT 'po' ft, 'yta' typ, o.plan_uuid best_uuid, o.plan_uuid g_uuid, NULL::uuid[] galler_endast, 'Planområdet' anvandningsform, o.absolutlagesosakerhetplan, o.tid_lage, o.tid_kontroll, l.lagesmetod, o.geom 
		  FROM qdp2.plan_omr o LEFT JOIN lagesmetod l ON o.lagesbestamningsmetod_plan = l.lage_id UNION 
		  SELECT 'abo' ft, 'yta' typ, x.best_uuid, x.abest_uuid g_uuid, NULL::uuid[] galler_endast, o.anvandningsform, o.absolutlagesosakerhetplan, o.tid_lage, o.tid_kontroll, l.lagesmetod, o.geom --Fel datatyp i tabellen
		  FROM qdp2.anv_best x JOIN qdp2.omr o ON x.o_uuid = o.o_uuid LEFT JOIN lagesmetod l ON o.lagesbestamningsmetod_plan= l.lage_id UNION
		  SELECT 'ebo' ft, 'yta' typ, x.best_uuid, x.ebest_uuid g_uuid, x.galler_endast, o.anvandningsform, o.absolutlagesosakerhetplan, o.tid_lage, o.tid_kontroll, l.lagesmetod, o.geom 
		  FROM qdp2.egen_best x JOIN qdp2.omr o ON x.o_uuid = o.o_uuid LEFT JOIN lagesmetod l ON o.lagesbestamningsmetod_plan= l.lage_id UNION
		  SELECT DISTINCT 'eabo' ft, 'yta' typ, b.best_uuid, b.best_uuid g_uuid, NULL::uuid[] galler_endast, o.anvandningsform, o.absolutlagesosakerhetplan, o.tid_lage, o.tid_kontroll, l.lagesmetod, o.geom 
		  FROM qdp2.best b JOIN qdp2.omr o ON b.plan_uuid = o.plan_uuid AND b.anvandningsform = o.anvandningsform AND b.galler_all_anvandningsform JOIN qdp2.anv_best a ON o.o_uuid = a.o_uuid LEFT JOIN lagesmetod l ON o.lagesbestamningsmetod_plan= l.lage_id UNION
		  SELECT 'ebl' ft, 'linje' typ, l.best_uuid, l.l_uuid g_uuid, l.galler_endast, l.anvandningsform, l.absolutlagesosakerhetplan, l.tid_lage, l.tid_kontroll, la.lagesmetod, l.geom 
		  FROM qdp2.egenlin l LEFT JOIN lagesmetod la ON l.lagesbestamningsmetod_plan= la.lage_id UNION
		  SELECT 'ebp' ft, 'punkt' typ, p.best_uuid, p.p_uuid g_uuid, p.galler_endast, p.anvandningsform, p.absolutlagesosakerhetplan, p.tid_lage, p.tid_kontroll, la.lagesmetod, p.geom 
		  FROM qdp2.egenpkt p LEFT JOIN lagesmetod la ON p.lagesbestamningsmetod_plan= la.lage_id) g
	GROUP BY g.ft, g.typ, g.best_uuid, g.g_uuid, g.anvandningsform, g.galler_endast
), kvalitet AS (
	SELECT k.kval_id,
		jsonb_build_object(
			'digitaliseringsniva', k.digitaliseringsniva,
			'beskrivningNiva', k.beskrivning_niva,
			--'foljerForeskrift', k.foljer_foreskrift,
			'korrigeradeGranser', k.korrigerade_granser,
			'kontrolleratPlaneringsunderlag', k.kontrollerat_underlag
		) kvalitet
	FROM qdp2.kvalitet k
), referens AS (
	SELECT r.dokref_id,
		jsonb_agg(jsonb_build_object(
			'identitet', r.identitet,
			'namnrymd', r.namnrymd,
			'lank', r.url
		)) referens
	FROM qdp2.referens r
	GROUP BY r.dokref_id
), dokref AS (
	SELECT d.dokref_id,
		jsonb_build_object(
			'namn', d.namn,
			'kortnamn', d.kortnamn,
			'datum', jsonb_build_object('datum',d.datum,'handelse', d.handelse),
			'referens', r.referens,
			'specifikReferens', d.specifik_ref
		) dokref
	FROM qdp2.dokref d LEFT JOIN referens r ON r.dokref_id = d.dokref_id
), beslutshandling AS (
	SELECT b.beslut_id,
		jsonb_agg(jsonb_build_object(
			'innehall', b.innehall,
			'dokument', d.dokref
		)) beslutshandling
	FROM qdp2.beslutshandling b LEFT JOIN dokref d ON b.dokref_id = d.dokref_id
	GROUP BY b.beslut_id
--), planbestammelse AS (	--Vilka planbetsämmelser gäller beslutet för? Alla eller specifika?
	--SELECT beslut_id,
	--CASE WHEN array_length(bt.planbestammelse,1) > 0 THEN to_jsonb(bt.planbestammelse)
	--	ELSE jsonb_agg(g_uuid)
	--END AS planbestammelse
	--FROM qdp2.beslut bt JOIN (SELECT b.plan_uuid, g.g_uuid FROM qdp2.v_best b JOIN geometri g ON b.best_uuid = g.best_uuid ) be on bt.plan_uuid = be.plan_uuid
	--GROUP BY beslut_id
), best_geom AS (SELECT b.plan_uuid, g.g_uuid, b.best_uuid FROM qdp2.v_best b JOIN geometri g ON b.best_uuid = g.best_uuid),
planbestammelse AS ( --Vilka planbetsämmelser gäller beslutet för? Alla eller specifika?
	SELECT beslut_id, jsonb_agg(be.g_uuid) AS planbestammelse
	FROM qdp2.beslut bt 
		LEFT JOIN best_geom be ON bt.plan_uuid = be.plan_uuid AND bt.planbestammelse IS NULL --Inget valt, gäller alla i planen
			OR be.best_uuid = ANY (bt.planbestammelse) AND bt.planbestammelse IS NOT NULL --Något valt, koppla relaterade
	GROUP BY beslut_id
), beslut AS (
	SELECT b.plan_uuid,
		jsonb_agg(jsonb_build_object(
			'instansInomKommunen', b.instans,
			'diarienummerKommun', b.diarienummer_kn,
			'diarienummerFullmaktige', b.diareinummer_kf,
			'beslutstyp', b.beslutstyp,
			'beslutshandling', bh.beslutshandling,
			'grundkarta', r.referens,
			'datumPaborjat', b.paborjat,
			'datumAntagande', b.antagande,
			'datumLagakraft', b.lagakraft,
			'genomforandetid', b.genomforandetid,
			'genomforandetidStartar', b.genomforandetid_startar,
			'arkividentitetKommun', b.arkivid_kn,
			'foregaendePlansBeteckning', b.foregaende_plans_bet,
			'berordDomsMalnummer', b.berord_doms_malnr,
			'planbestammelse', p.planbestammelse
		)) beslut
	FROM qdp2.beslut b LEFT JOIN beslutshandling bh ON b.beslut_id = bh.beslut_id LEFT JOIN referens r ON b.beslut_id = r.dokref_id JOIN planbestammelse p ON b.beslut_id = p.beslut_id
	GROUP BY b.plan_uuid
), planbeskrivning AS (
	SELECT p.plan_uuid,
		jsonb_build_object(
			'planbeskrivning', d.dokref
		) planbeskrivning
	FROM qdp2.planbeskrivning p LEFT JOIN dokref d ON p.dokref_id = d.dokref_id
), underlag AS (
	SELECT u.plan_uuid,
		jsonb_agg(jsonb_build_object(
			'huvudomrade', u.huvudomrade,
			'underlagstyp', u.underlagstyp,
			'underlag', d.dokref
		)) underlag
	FROM qdp2.underlag u LEFT JOIN dokref d ON u.dokref_id = d.dokref_id
	GROUP BY u.plan_uuid
), bestammelsevarde AS (
	SELECT v.best_uuid,
		jsonb_agg(jsonb_build_object(
			'datatyp', v.datatyp,
			'variabelvarde', v.variabelvarde,
			'beskrivning', v.beskrivning,
			'vardetyp', v.vardetyp,
			'enhet', v.enhet
		)) bestammelsevarden
	FROM qdp2.variabel v
	GROUP BY v.best_uuid)
,	anvy AS (SELECT g.best_uuid, g.g_uuid, g.geom, g.anvandningsform
	FROM geometri g
	WHERE g.ft='abo')
,	egy AS (SELECT g.best_uuid, g.g_uuid, g.geom, g.anvandningsform, g.galler_endast
	FROM geometri g
	WHERE g.ft='ebo' OR g.ft='eabo')
,	eglp AS (SELECT g.best_uuid, g.g_uuid, g.geom, g.anvandningsform, g.galler_endast
	FROM geometri g
	WHERE g.ft='ebl' OR g.ft='ebp')
, reglerar AS (
	SELECT 
		e.g_uuid, 
		CASE
			WHEN e.galler_endast IS NOT NULL AND array_length(e.galler_endast, 1) > 0 THEN to_jsonb(e.galler_endast)
			ELSE jsonb_agg(a.g_uuid)
		END AS reglerar
	FROM egy e INNER JOIN anvy a ON e.geom && a.geom AND ST_Relate(e.geom, a.geom,'T********')
	GROUP BY e.g_uuid, e.galler_endast
	UNION
	SELECT 
		e.g_uuid, 
		CASE
			WHEN e.galler_endast IS NOT NULL AND array_length(e.galler_endast, 1) > 0 THEN to_jsonb(e.galler_endast)
			ELSE jsonb_agg(a.g_uuid)
		END AS reglerar
	FROM eglp e INNER JOIN anvy a ON ST_DWithin(e.geom,a.geom,0.01)
	WHERE e.anvandningsform = a.anvandningsform
	GROUP BY e.g_uuid, e.galler_endast
), 
xbest AS (
	SELECT e.ebest_uuid xbest_uuid, e.motiv_id, e.best_uuid FROM qdp2.egen_best e
	UNION SELECT l.l_uuid xbest_uuid, l.motiv_id, l.best_uuid FROM qdp2.egenlin l
	UNION SELECT p.p_uuid xbest_uuid, p.motiv_id, p.best_uuid FROM qdp2.egenpkt p
	UNION SELECT a.abest_uuid xbest_uuid, a.motiv_id, a.best_uuid FROM qdp2.anv_best a
),
motiv AS (
	SELECT jsonb_build_object('motiv', m.motiv) motiv,
	COALESCE(m2.xbest_uuid,x.xbest_uuid,m.best_uuid) AS g_uuid
	FROM qdp2.motiv m 
	LEFT JOIN xbest x ON x.motiv_id = m.motiv_id
	LEFT JOIN (
		SELECT m1.best_uuid, x2.xbest_uuid
		FROM (SELECT m.best_uuid, COUNT(*)
			FROM  qdp2.motiv m
			GROUP BY m.best_uuid
			HAVING COUNT(*) = 1
		) m1 LEFT JOIN xbest x2 ON m1.best_uuid = x2.best_uuid
	) m2 ON m.best_uuid = m2.best_uuid	
), bestammelse AS (
	SELECT b.plan_uuid,
	jsonb_agg(
	jsonb_build_object(
		'id', g.g_uuid,--b.best_uuid,
		'type', 'Feature',
		'geometry', null,
		'bbox', g.bbox,
		'properties', jsonb_strip_nulls(jsonb_build_object(
			'objektidentitet' , g.g_uuid,
			'feature:typ', concat(lower(b.bestammelsetyp),'sbestämmelse'),
			'detaljplan', b.plan_uuid, --Special vid tekniska anläggningar
			'planbestammelsekatalogreferens', CASE WHEN b.kategori = 'Tekniska anläggningar' THEN '9b78a950-1bb2-4046-98cf-9efbd5868323' ELSE b.bk_ref END,
			'bestammelseformulering', CASE WHEN b.kategori = 'Tekniska anläggningar' THEN 'Tekniska anläggningar' ELSE b.bform END,
			'ursprungligBestammelseformulering', CASE WHEN b.kategori = 'Tekniska anläggningar' THEN 'Tekniska anläggningar' ELSE b.ursprunglig END,
			'bestammelsevarde', CASE WHEN b.kategori = 'Tekniska anläggningar' THEN NULL ELSE bv.bestammelsevarden END,
			'sekundarEgenskapsgrans', CASE WHEN b.bestammelsetyp = 'Egenskap' THEN b.sekundar ELSE null END,
			'giltighetstid', a.giltighetstid,
			'borjarGallaEfter', a.borjar_galla_efter,
			'vertikalAvgransning', xb.avgransning,
			'kvalitetsbeskrivning', k.kvalitet,
			'anvandbarhet', b.anvandbarhet,
			'anvandbarhetBeskrivning', b.anvandbarhet_beskrivning,
			'bestammelsegeometri', g.g_json,
			'planbestammelsebeskrivning', CASE WHEN b.kategori = 'Tekniska anläggningar' AND m.motiv IS NOT NULL THEN jsonb_build_object('motiv', 'Tekniska anläggningar') ELSE m.motiv	END,
			'reglerarAnvandningsbestammelse', r.reglerar
		))
	)) bestammelser
	FROM qdp2.v_best b 
	JOIN geometri g ON b.best_uuid = g.best_uuid 
	LEFT JOIN qdp2.anv_best a ON g.g_uuid = a.abest_uuid
	LEFT JOIN (SELECT abest_uuid xbest_uuid, avgransning FROM qdp2.anv_best UNION
			   SELECT ebest_uuid xbest_uuid, avgransning FROM qdp2.egen_best UNION
			   SELECT l_uuid xbest_uuid, avgransning FROM qdp2.egenlin UNION
			   SELECT p_uuid xbest_uuid, avgransning FROM qdp2.egenpkt
			  ) xb ON g.g_uuid = xb.xbest_uuid
	LEFT JOIN motiv m ON g.g_uuid = m.g_uuid
	LEFT JOIN bestammelsevarde bv ON b.best_uuid = bv.best_uuid 
	LEFT JOIN kvalitet k ON b.kval_id = k.kval_id
	LEFT JOIN reglerar r ON g.g_uuid = r.g_uuid --b.best_uuid = r.best_uuid 
	GROUP BY b.plan_uuid
)
SELECT 
jsonb_build_object(
	'feature:mediatyp', 'application/vnd.lm.detaljplan.v4+json',
	'type', 'FeatureCollection',
	'bbox', po.bbox,
	'crs', po.crs,
	'features',
jsonb_build_array(
		jsonb_build_object(
		'id', p.plan_uuid,
		'type', 'Feature',
		'geometry', null,
		'bbox', po.bbox,
		'properties', jsonb_strip_nulls(jsonb_build_object(
			'objektidentitet' , p.plan_uuid,--p.objektidentitet,
			'versionGiltigFran', p.v_giltig_fran::TIMESTAMP WITH TIME ZONE,
			'versionGiltigTill', p.v_giltig_till::TIMESTAMP WITH TIME ZONE,
			'objektversion', p.planversion,
			'feature:typ', 'detaljplan',
			'kommun', p.kommun,
			'beteckning', p.beteckning,
			'namn', p.namn,
			'syfte', p.syfte,
			'status', p.status,
			'datumStatusforandring', p.datum_statusforandring,
			'typ', p.typ,
			'kvalitetsbeskrivning', k.kvalitet,
			'anvandbarhet', p.anvandbarhet,
			'beskrivningAnvandbarhet', p.anvandbarhet_beskrivning,
			'plangeometri', po.g_json,
			'vertikalAvgransning', p.avgransning,
			'beslutsinformation', b.beslut,
			'planbeskrivning', pb.planbeskrivning,
			'planeringsunderlag', u.underlag
))))
|| bs.bestammelser
)
FROM qdp2.plan p 
LEFT JOIN geometri po ON p.plan_uuid= po.g_uuid 
LEFT JOIN beslut b ON p.plan_uuid = b.plan_uuid 
LEFT JOIN kvalitet k ON p.kval_id = k.kval_id
LEFT JOIN planbeskrivning pb ON p.plan_uuid = pb.plan_uuid 
LEFT JOIN underlag u ON p.plan_uuid = u.plan_uuid 
LEFT JOIN bestammelse bs ON p.plan_uuid = bs.plan_uuid 
--WHERE p.plan_uuid = 'a9e2e68d-6a7a-4045-80f0-56841335af06'--'42f54e09-f882-46ff-9806-bd7eeae2b44d'--'32113768-a40f-4d10-9a25-4e5e24756ca1'--''c2664c0a-decb-408e-aa21-19f081dee860'--'85a19575-bc9a-4603-9fa4-7d49b321f525'--'647c775c-82b8-4c3d-be0b-0d1f3ac3a70c'
;