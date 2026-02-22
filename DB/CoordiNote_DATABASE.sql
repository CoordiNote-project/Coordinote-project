-- CoordiNote Database
-- Run this file once to set up the full database

-- EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

-- SCHEMA
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.11
-- Dumped by pg_dump version 18.0

-- Started on 2026-02-22 22:59:41

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
-- TOC entry 2 (class 3079 OID 32107)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5910 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 33188)
-- Name: locations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.locations (
    location_id integer NOT NULL,
    l_name text,
    category text,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE public.locations OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 33193)
-- Name: locations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.locations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.locations_id_seq OWNER TO postgres;

--
-- TOC entry 5911 (class 0 OID 0)
-- Dependencies: 222
-- Name: locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.location_id;


--
-- TOC entry 223 (class 1259 OID 33200)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    m_type text NOT NULL,
    unl_rad integer DEFAULT 30 NOT NULL,
    crt_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    view_once boolean DEFAULT false,
    m_txt text NOT NULL,
    creator integer NOT NULL,
    uni_id integer NOT NULL,
    location_id integer,
    m_id integer NOT NULL
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 33278)
-- Name: messages_m_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.messages_m_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_m_id_seq OWNER TO postgres;

--
-- TOC entry 5912 (class 0 OID 0)
-- Dependencies: 228
-- Name: messages_m_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.messages_m_id_seq OWNED BY public.messages.m_id;


--
-- TOC entry 232 (class 1259 OID 33347)
-- Name: poll_options; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.poll_options (
    option_id integer NOT NULL,
    m_id integer,
    option_text text NOT NULL
);


ALTER TABLE public.poll_options OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 33352)
-- Name: poll_options_option_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.poll_options_option_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.poll_options_option_id_seq OWNER TO postgres;

--
-- TOC entry 5913 (class 0 OID 0)
-- Dependencies: 233
-- Name: poll_options_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.poll_options_option_id_seq OWNED BY public.poll_options.option_id;


--
-- TOC entry 234 (class 1259 OID 33353)
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.poll_votes (
    option_id integer NOT NULL,
    us_id integer NOT NULL,
    voted_at timestamp without time zone DEFAULT now() NOT NULL,
    m_id integer NOT NULL
);


ALTER TABLE public.poll_votes OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 33297)
-- Name: seen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.seen (
    m_id integer NOT NULL,
    us_id integer NOT NULL,
    seen_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.seen OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 33331)
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    session_id integer NOT NULL,
    us_id integer NOT NULL,
    token text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 33330)
-- Name: sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_session_id_seq OWNER TO postgres;

--
-- TOC entry 5914 (class 0 OID 0)
-- Dependencies: 230
-- Name: sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sessions_session_id_seq OWNED BY public.sessions.session_id;


--
-- TOC entry 224 (class 1259 OID 33217)
-- Name: universes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.universes (
    uni_name character varying(150) NOT NULL,
    access boolean DEFAULT false NOT NULL,
    descri text,
    uni_id integer NOT NULL
);


ALTER TABLE public.universes OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 33222)
-- Name: universe_uni_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.universe_uni_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.universe_uni_id_seq OWNER TO postgres;

--
-- TOC entry 5915 (class 0 OID 0)
-- Dependencies: 225
-- Name: universe_uni_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.universe_uni_id_seq OWNED BY public.universes.uni_id;


--
-- TOC entry 235 (class 1259 OID 33430)
-- Name: user_univ; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_univ (
    us_id integer NOT NULL,
    uni_id integer NOT NULL
);


ALTER TABLE public.user_univ OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33229)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    pwd text NOT NULL,
    us_name text NOT NULL,
    us_id integer NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 33269)
-- Name: users_us_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_us_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_us_id_seq OWNER TO postgres;

--
-- TOC entry 5916 (class 0 OID 0)
-- Dependencies: 227
-- Name: users_us_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_us_id_seq OWNED BY public.users.us_id;


--
-- TOC entry 5697 (class 2604 OID 33395)
-- Name: locations location_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--
-- TOC entry 5701 (class 2604 OID 33396)
-- Name: messages m_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages ALTER COLUMN m_id SET DEFAULT nextval('public.messages_m_id_seq'::regclass);


--
-- TOC entry 5708 (class 2604 OID 33530)
-- Name: poll_options option_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_options ALTER COLUMN option_id SET DEFAULT nextval('public.poll_options_option_id_seq'::regclass);


--
-- TOC entry 5706 (class 2604 OID 33399)
-- Name: sessions session_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions ALTER COLUMN session_id SET DEFAULT nextval('public.sessions_session_id_seq'::regclass);


--
-- TOC entry 5703 (class 2604 OID 33400)
-- Name: universes uni_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universes ALTER COLUMN uni_id SET DEFAULT nextval('public.universe_uni_id_seq'::regclass);


--
-- TOC entry 5704 (class 2604 OID 33401)
-- Name: users us_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN us_id SET DEFAULT nextval('public.users_us_id_seq'::regclass);


--
-- TOC entry 5714 (class 2606 OID 33240)
-- Name: locations locations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--
-- TOC entry 5717 (class 2606 OID 33286)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (m_id);


--
-- TOC entry 5739 (class 2606 OID 33528)
-- Name: poll_votes one_vote_per_user_per_poll; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT one_vote_per_user_per_poll UNIQUE (us_id, m_id);


--
-- TOC entry 5736 (class 2606 OID 33366)
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (option_id);


--
-- TOC entry 5741 (class 2606 OID 33476)
-- Name: poll_votes poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (option_id, us_id);


--
-- TOC entry 5729 (class 2606 OID 33302)
-- Name: seen seen_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_pkey PRIMARY KEY (m_id, us_id);


--
-- TOC entry 5731 (class 2606 OID 33339)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 5733 (class 2606 OID 33341)
-- Name: sessions sessions_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--
-- TOC entry 5719 (class 2606 OID 33518)
-- Name: universes unique_uni_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universes
    ADD CONSTRAINT unique_uni_name UNIQUE (uni_name);


--
-- TOC entry 5724 (class 2606 OID 33252)
-- Name: universes universe_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universes
    ADD CONSTRAINT universe_pkey PRIMARY KEY (uni_id);


--
-- TOC entry 5743 (class 2606 OID 33434)
-- Name: user_univ us_uni_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT us_uni_id PRIMARY KEY (us_id, uni_id);


--
-- TOC entry 5727 (class 2606 OID 33277)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (us_id);


--
-- TOC entry 5734 (class 1259 OID 33373)
-- Name: idx_poll_options_message; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_poll_options_message ON public.poll_options USING btree (m_id);


--
-- TOC entry 5737 (class 1259 OID 33374)
-- Name: idx_poll_votes_option; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_poll_votes_option ON public.poll_votes USING btree (option_id);


--
-- TOC entry 5715 (class 1259 OID 33561)
-- Name: unique_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_location ON public.locations USING btree (l_name, category, geom);


--
-- TOC entry 5722 (class 1259 OID 33521)
-- Name: unique_universe_name_ci; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_universe_name_ci ON public.universes USING btree (lower((uni_name)::text));


--
-- TOC entry 5725 (class 1259 OID 33524)
-- Name: unique_username_ci; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_username_ci ON public.users USING btree (lower(us_name));


--
-- TOC entry 5751 (class 2606 OID 33375)
-- Name: poll_votes fk_message; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_message FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--
-- TOC entry 5744 (class 2606 OID 33257)
-- Name: messages location_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT location_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);


--
-- TOC entry 5745 (class 2606 OID 33477)
-- Name: messages m_creator_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_creator_fkey FOREIGN KEY (creator) REFERENCES public.users(us_id) NOT VALID;


--
-- TOC entry 5746 (class 2606 OID 33482)
-- Name: messages m_uni_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;


--
-- TOC entry 5750 (class 2606 OID 33546)
-- Name: poll_options poll_options_m_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--
-- TOC entry 5752 (class 2606 OID 33551)
-- Name: poll_votes poll_votes_m_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--
-- TOC entry 5753 (class 2606 OID 33556)
-- Name: poll_votes poll_votes_option_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.poll_options(option_id) ON DELETE CASCADE;


--
-- TOC entry 5754 (class 2606 OID 33390)
-- Name: poll_votes poll_votes_us_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


--
-- TOC entry 5747 (class 2606 OID 33303)
-- Name: seen seen_m_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--
-- TOC entry 5748 (class 2606 OID 33308)
-- Name: seen seen_us_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


--
-- TOC entry 5749 (class 2606 OID 33342)
-- Name: sessions sessions_us_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


--
-- TOC entry 5755 (class 2606 OID 33440)
-- Name: user_univ user_uni_uni_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;


--
-- TOC entry 5756 (class 2606 OID 33435)
-- Name: user_univ user_uni_us_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id);


-- Completed on 2026-02-22 22:59:42

--
-- PostgreSQL database dump complete
--



-- DATA
--
-- PostgreSQL database dump
--

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


COPY public.locations (location_id, l_name, category, geom) FROM stdin;
911585	\N	\N	0101000020E6100000D9CEF753E3A522C0EC51B81E856A4340
911586	\N	\N	0101000020E610000085EB51B81EA522C0713D0AD7A36C4340
911587	\N	\N	0101000020E6100000AE47E17A14A522C052B81E85EB694340
911588	\N	\N	0101000020E61000003D0AD7A370AB22C00AD7A3703D624340
911589	\N	\N	0101000020E61000003D0AD7A370AB22C00AD7A3703D624340
911590	\N	\N	0101000020E6100000F6285C8FC2B122C052B81E856B634340
911591	\N	\N	0101000020E6100000F6285C8FC2B122C052B81E856B634340
911592	\N	\N	0101000020E6100000F6285C8FC2B122C052B81E856B634340
911593	\N	\N	0101000020E6100000EC51B81E85EB22C05C8FC2F528684340
911594	\N	\N	0101000020E6100000EC51B81E85EB22C05C8FC2F528684340
911595	\N	\N	0101000020E61000007B14AE47E1FA22C0295C8FC2F5284340
911596	\N	\N	0101000020E61000007B14AE47E1FA22C0295C8FC2F5284340
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

