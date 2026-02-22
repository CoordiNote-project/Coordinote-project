--
-- PostgreSQL database dump
--

\restrict s5S6t773a1VXnoVaWU1A0musfVs5vbx8Rw4lFbXbRdzj47Nz8XJcpkmjqDYEZg1

-- Dumped from database version 16.11
-- Dumped by pg_dump version 18.0

-- Started on 2026-02-22 23:00:31

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;



--
-- TOC entry 5894 (class 0 OID 33217)
-- Dependencies: 224
-- Data for Name: universes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.universes (uni_name, access, descri, uni_id) FROM stdin;
CoordiNote_testingGroup	t	We are the developers behind CoordiNote. Currently testing our project.	400000
LisboaFunfacts	f	Funfacts about the city of Lisbon.	400001
GeoTech252627	t	Universe for all GeoTech students.	400002
RestaurantReviewsLisbon	f	Users reviews of restaurants in Lisbon.	400003
SunsetViewpoints	f	Best viewpoints to watch the sunset in Lisbon.	400004
LisbonEvents	f	Universe for sharing information about events happening in Lisbon.	400009
LostAndFound	f	Universe for sharing information about lost and found items in Lisbon.	400008
LisbonRepair	f	Real-time sharing of information about locations in Lisbon that need construction or maintenance work.	400007
Swifties	f	Universe for all Taylor Swift fans worldwide. <3	400006
Erasmus2026summer	f	Erasmus student network for the summer semester of 2026.	400005
climbing crew <3	t	Best climbers in the city! Climbing, drinking coffee, chilling.	400010
\.


--
-- TOC entry 5896 (class 0 OID 33229)
-- Dependencies: 226
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (pwd, us_name, us_id) FROM stdin;
$2b$12$3eFlgYnaFlwMewG8p0BOueR8GcRJMgx5LvmUx5KWWQ3trZOySmLD2	anda	100012
$2b$12$/MrRk6mL9BpvK2WNYJ1sd.MUoTGFjS7hX7AWP2WhEJtsErqa8GiIe	tilak	100015
$2b$12$bl0BgxfDQwiIdf/rEDGC2.yje7O5qyCQzPqD51b3WGauNIr/u6W6S	marie_tr	100000
$2b$12$6HdsPu6xJTpFIEk44lJoy.nl1f0riYq1oJMvK77JB2nbDakoYpK6m	bekirbeko	100001
$2b$12$chqhLpGcE3JHD2VFMZA45ekYEiGbONOw3Pg.b5IIRkpZhHGBWznu.	wilmadora	100002
$2b$12$3aB7yIE1FDzKsClWsnmBZeYB2kHTIP/jd/LbSTRqidY6t2h2rXSI6	jacobvanmeer	100003
$2b$12$9vevClUbWCR7fkseB/bQn.vCQS7zHlaw7iMGD8qHPYBwz3vHbJYZm	lindaelfriede	100004
$2b$12$DUZ8IIjn2WTylCTNXdrrE.bL0PwCQRKey3TrwYIKt4dUyfRihc.Ga	rikostryko	100005
$2b$12$uZcPTdqwGH5nh2Ue4CTv5uU7Z6d0jJ51t8Xrw1uKE2NbCG4OEzaNC	Johana	100009
\.


--
-- TOC entry 5893 (class 0 OID 33200)
-- Dependencies: 223
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, location_id, m_id) FROM stdin;
text	30	2026-02-20 14:55:26.053355	f	Hello everyone! Testing the connection	100000	400000	911585	700000
text	30	2026-02-20 14:57:23.480188	t	There was an earthquake in Lisbon on 19th February 2026.	100000	400001	911586	700001
text	50	2026-02-20 14:58:39.857498	t	Start learning programming now!! haha	100000	400002	911587	700002
text	20	2026-02-20 15:01:56.605253	f	Let's go to the karaoke!	100000	400002	911588	700003
text	20	2026-02-20 15:02:30.264845	f	I want to eat sushiiii. If you want to join me, call me.	100000	400002	911589	700004
text	20	2026-02-20 15:04:31.868744	f	This sidewalk has this huge hole since forever!	100002	400007	911590	700005
text	20	2026-02-20 15:04:48.126684	f	Floods everywhere in this area. :((	100002	400007	911591	700006
text	30	2026-02-20 15:05:10.313883	f	This lamp is not working since 20. 2. 2026. Please fix it.	100002	400007	911592	700007
text	30	2026-02-20 15:06:01.926179	f	Found a ring under this bench, contact me if you've lost it. Describe how it looked. (+420 777 999 000)	100002	400008	911593	700008
text	30	2026-02-20 15:07:05.902114	f	I've lost my glasses on my way home! If anyone has found it, let me know!! pleaseeee. (ig: wilmimi)	100002	400008	911594	700009
text	30	2026-02-20 15:08:36.142456	t	Brazilian DJs in the town. Sunset b2b set, this Friday!! COME! <3	100002	400009	911595	700010
text	30	2026-02-20 15:09:09.942073	t	Only 3 days until carnival! Don't skip Bairro Alto.	100002	400009	911596	700011
\.


--
-- TOC entry 5902 (class 0 OID 33347)
-- Dependencies: 232
-- Data for Name: poll_options; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.poll_options (option_id, m_id, option_text) FROM stdin;
\.


--
-- TOC entry 5904 (class 0 OID 33353)
-- Dependencies: 234
-- Data for Name: poll_votes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.poll_votes (option_id, us_id, voted_at, m_id) FROM stdin;
\.


--
-- TOC entry 5899 (class 0 OID 33297)
-- Dependencies: 229
-- Data for Name: seen; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.seen (m_id, us_id, seen_at) FROM stdin;
700010	100005	2026-02-20 15:18:42.612073
\.


--
-- TOC entry 5696 (class 0 OID 32426)
-- Dependencies: 217
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- TOC entry 5905 (class 0 OID 33430)
-- Dependencies: 235
-- Data for Name: user_univ; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_univ (us_id, uni_id) FROM stdin;
100000	400000
100000	400001
100000	400002
100000	400003
100001	400004
100001	400005
100001	400006
100002	400007
100002	400008
100002	400009
100005	400004
100005	400006
100005	400008
100005	400007
100005	400005
100005	400009
100002	400010
\.


--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 222
-- Name: locations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.locations_id_seq', 911596, true);


--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 228
-- Name: messages_m_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_m_id_seq', 700012, true);


--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 233
-- Name: poll_options_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.poll_options_option_id_seq', 900000, false);


--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 230
-- Name: sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sessions_session_id_seq', 104, true);


--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 225
-- Name: universe_uni_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.universe_uni_id_seq', 400010, true);


--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 227
-- Name: users_us_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_us_id_seq', 100015, true);


-- Completed on 2026-02-22 23:00:32

--
-- PostgreSQL database dump complete
--

\unrestrict s5S6t773a1VXnoVaWU1A0musfVs5vbx8Rw4lFbXbRdzj47Nz8XJcpkmjqDYEZg1

