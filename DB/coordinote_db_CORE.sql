--
-- PostgreSQL database dump
--

\restrict UFrUiiGnfSxen6an594NTwkOsB9iQmm7FbdVJO6s1l4s2gsXzwskBgvkxsb44zB

-- Dumped from database version 16.11
-- Dumped by pg_dump version 18.0

-- Started on 2026-02-20 16:17:43

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
-- TOC entry 5921 (class 0 OID 33188)
-- Dependencies: 221
-- Data for Name: locations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5923 (class 0 OID 33200)
-- Dependencies: 223
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.messages VALUES ('tex', 30, '2026-02-20 14:55:26.053355', false, 'Hello everyone! Testing the connection', 100000, 400000, NULL, NULL, 700000);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 14:57:23.480188', true, 'There was an earthquake in Lisbon on 19th February 2026.', 100000, 400001, NULL, NULL, 700001);
INSERT INTO public.messages VALUES ('text', 50, '2026-02-20 14:58:39.857498', true, 'Start learning programming now!! haha', 100000, 400002, NULL, NULL, 700002);
INSERT INTO public.messages VALUES ('text', 20, '2026-02-20 15:01:56.605253', false, 'Let''s go to the karaoke!', 100000, 400002, NULL, NULL, 700003);
INSERT INTO public.messages VALUES ('text', 20, '2026-02-20 15:02:30.264845', false, 'I want to eat sushiiii. If you want to join me, call me.', 100000, 400002, NULL, NULL, 700004);
INSERT INTO public.messages VALUES ('text', 20, '2026-02-20 15:04:31.868744', false, 'This sidewalk has this huge hole since forever!', 100002, 400007, NULL, NULL, 700005);
INSERT INTO public.messages VALUES ('text', 20, '2026-02-20 15:04:48.126684', false, 'Floods everywhere in this area. :((', 100002, 400007, NULL, NULL, 700006);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 15:05:10.313883', false, 'This lamp is not working since 20. 2. 2026. Please fix it.', 100002, 400007, NULL, NULL, 700007);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 15:06:01.926179', false, 'Found a ring under this bench, contact me if you''ve lost it. Describe how it looked. (+420 777 999 000)', 100002, 400008, NULL, NULL, 700008);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 15:07:05.902114', false, 'I''ve lost my glasses on my way home! If anyone has found it, let me know!! pleaseeee. (ig: wilmimi)', 100002, 400008, NULL, NULL, 700009);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 15:08:36.142456', true, 'Brazilian DJs in the town. Sunset b2b set, this Friday!! COME! <3', 100002, 400009, NULL, NULL, 700010);
INSERT INTO public.messages VALUES ('text', 30, '2026-02-20 15:09:09.942073', true, 'Only 3 days until carnival! Don''t skip Bairro Alto.', 100002, 400009, NULL, NULL, 700011);


--
-- TOC entry 5924 (class 0 OID 33212)
-- Dependencies: 224
-- Data for Name: poll; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5933 (class 0 OID 33347)
-- Dependencies: 233
-- Data for Name: poll_options; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5935 (class 0 OID 33353)
-- Dependencies: 235
-- Data for Name: poll_votes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5930 (class 0 OID 33297)
-- Dependencies: 230
-- Data for Name: seen; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.seen VALUES (700010, 100005, '2026-02-20 15:18:42.612073');


--
-- TOC entry 5932 (class 0 OID 33331)
-- Dependencies: 232
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sessions VALUES (100, 100006, '5df5f907-df62-4f1e-8518-c1400db5a87d', '2026-02-20 12:54:10.56165', '2026-02-23 12:54:10.560671');
INSERT INTO public.sessions VALUES (101, 100000, '95b5a15d-6040-4447-8f67-a78ca8d3c0ef', '2026-02-20 12:54:22.256447', '2026-02-23 12:54:22.256004');
INSERT INTO public.sessions VALUES (102, 100002, '920f3f70-27f8-4f2b-a849-af86d358b44d', '2026-02-20 12:54:31.219257', '2026-02-23 12:54:31.218966');
INSERT INTO public.sessions VALUES (103, 100001, 'e4cf9347-eb5c-4248-8dde-705eef265fce', '2026-02-20 12:54:44.192573', '2026-02-23 12:54:44.192202');
INSERT INTO public.sessions VALUES (104, 100005, '4475367b-9b22-400d-b2ca-dac800516189', '2026-02-20 12:55:02.128662', '2026-02-23 12:55:02.128395');


--
-- TOC entry 5705 (class 0 OID 32426)
-- Dependencies: 217
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5925 (class 0 OID 33217)
-- Dependencies: 225
-- Data for Name: universes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.universes VALUES ('CoordiNote_testingGroup', true, NULL, 400000);
INSERT INTO public.universes VALUES ('LisboaFunfacts', false, NULL, 400001);
INSERT INTO public.universes VALUES ('GeoTech252627', true, NULL, 400002);
INSERT INTO public.universes VALUES ('RestaurantReviewsLisbon', false, NULL, 400003);
INSERT INTO public.universes VALUES ('SunsetViewpoints', false, NULL, 400004);
INSERT INTO public.universes VALUES ('Erasmus2026summer', false, NULL, 400005);
INSERT INTO public.universes VALUES ('Swifties', false, NULL, 400006);
INSERT INTO public.universes VALUES ('LisbonRepair', false, NULL, 400007);
INSERT INTO public.universes VALUES ('LostAndFound', false, NULL, 400008);
INSERT INTO public.universes VALUES ('LisbonEvents', false, NULL, 400009);


--
-- TOC entry 5937 (class 0 OID 33450)
-- Dependencies: 237
-- Data for Name: unlocked; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 5936 (class 0 OID 33430)
-- Dependencies: 236
-- Data for Name: user_univ; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_univ VALUES (100000, 400000);
INSERT INTO public.user_univ VALUES (100000, 400001);
INSERT INTO public.user_univ VALUES (100000, 400002);
INSERT INTO public.user_univ VALUES (100000, 400003);
INSERT INTO public.user_univ VALUES (100001, 400004);
INSERT INTO public.user_univ VALUES (100001, 400005);
INSERT INTO public.user_univ VALUES (100001, 400006);
INSERT INTO public.user_univ VALUES (100002, 400007);
INSERT INTO public.user_univ VALUES (100002, 400008);
INSERT INTO public.user_univ VALUES (100002, 400009);
INSERT INTO public.user_univ VALUES (100005, 400004);
INSERT INTO public.user_univ VALUES (100005, 400006);
INSERT INTO public.user_univ VALUES (100005, 400008);
INSERT INTO public.user_univ VALUES (100005, 400007);
INSERT INTO public.user_univ VALUES (100005, 400005);
INSERT INTO public.user_univ VALUES (100005, 400009);


--
-- TOC entry 5927 (class 0 OID 33229)
-- Dependencies: 227
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('$2b$12$bl0BgxfDQwiIdf/rEDGC2.yje7O5qyCQzPqD51b3WGauNIr/u6W6S', 'marie_tr', 100000);
INSERT INTO public.users VALUES ('$2b$12$6HdsPu6xJTpFIEk44lJoy.nl1f0riYq1oJMvK77JB2nbDakoYpK6m', 'bekirbeko', 100001);
INSERT INTO public.users VALUES ('$2b$12$chqhLpGcE3JHD2VFMZA45ekYEiGbONOw3Pg.b5IIRkpZhHGBWznu.', 'wilmadora', 100002);
INSERT INTO public.users VALUES ('$2b$12$3aB7yIE1FDzKsClWsnmBZeYB2kHTIP/jd/LbSTRqidY6t2h2rXSI6', 'jacobvanmeer', 100003);
INSERT INTO public.users VALUES ('$2b$12$9vevClUbWCR7fkseB/bQn.vCQS7zHlaw7iMGD8qHPYBwz3vHbJYZm', 'lindaelfriede', 100004);
INSERT INTO public.users VALUES ('$2b$12$DUZ8IIjn2WTylCTNXdrrE.bL0PwCQRKey3TrwYIKt4dUyfRihc.Ga', 'rikostryko', 100005);
INSERT INTO public.users VALUES ('$2b$12$NqZXGBPgPLYJ.6KDotvsGOzar0qjYb.6F.8EYyoRSdreDMuvhnLUm', 'anda', 100006);
INSERT INTO public.users VALUES ('$2b$12$Aqxt/9fO1G.VMITVfM9QauntZkbTm99Rt8w4awGGHtDfpIAkop8y6', 'anda', 100007);


--
-- TOC entry 5951 (class 0 OID 0)
-- Dependencies: 222
-- Name: locations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.locations_id_seq', 900000, false);


--
-- TOC entry 5952 (class 0 OID 0)
-- Dependencies: 229
-- Name: messages_m_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_m_id_seq', 700011, true);


--
-- TOC entry 5953 (class 0 OID 0)
-- Dependencies: 234
-- Name: poll_options_option_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.poll_options_option_id_seq', 900000, false);


--
-- TOC entry 5954 (class 0 OID 0)
-- Dependencies: 238
-- Name: poll_p_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.poll_p_id_seq', 800000, false);


--
-- TOC entry 5955 (class 0 OID 0)
-- Dependencies: 231
-- Name: sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sessions_session_id_seq', 104, true);


--
-- TOC entry 5956 (class 0 OID 0)
-- Dependencies: 226
-- Name: universe_uni_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.universe_uni_id_seq', 400009, true);


--
-- TOC entry 5957 (class 0 OID 0)
-- Dependencies: 228
-- Name: users_us_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_us_id_seq', 100007, true);


-- Completed on 2026-02-20 16:17:44

--
-- PostgreSQL database dump complete
--

\unrestrict UFrUiiGnfSxen6an594NTwkOsB9iQmm7FbdVJO6s1l4s2gsXzwskBgvkxsb44zB

