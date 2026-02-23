-- CoordiNote Database
-- Run this file once on a clean database to set up the full schema and load test data
-- Encoding: UTF8
-- PostgreSQL version: 16.11

-- EXTENSIONS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgrouting;

-- SETTINGS
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
SET default_tablespace = '';
SET default_table_access_method = heap;


-- SCHEMA

CREATE TABLE public.locations (
    location_id integer NOT NULL,
    l_name text,
    category text,
    geom public.geometry(Geometry,4326)
);

CREATE SEQUENCE public.locations_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.location_id;
ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_id_seq'::regclass);
ALTER TABLE ONLY public.locations ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);
CREATE UNIQUE INDEX unique_location ON public.locations USING btree (l_name, category, geom);


CREATE TABLE public.universes (
    uni_name character varying(150) NOT NULL,
    access boolean DEFAULT false NOT NULL,
    descri text,
    uni_id integer NOT NULL
);

CREATE SEQUENCE public.universe_uni_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.universe_uni_id_seq OWNED BY public.universes.uni_id;
ALTER TABLE ONLY public.universes ALTER COLUMN uni_id SET DEFAULT nextval('public.universe_uni_id_seq'::regclass);
ALTER TABLE ONLY public.universes ADD CONSTRAINT universe_pkey PRIMARY KEY (uni_id);
ALTER TABLE ONLY public.universes ADD CONSTRAINT unique_uni_name UNIQUE (uni_name);
CREATE UNIQUE INDEX unique_universe_name_ci ON public.universes USING btree (lower((uni_name)::text));


CREATE TABLE public.users (
    pwd text NOT NULL,
    us_name text NOT NULL,
    us_id integer NOT NULL
);

CREATE SEQUENCE public.users_us_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.users_us_id_seq OWNED BY public.users.us_id;
ALTER TABLE ONLY public.users ALTER COLUMN us_id SET DEFAULT nextval('public.users_us_id_seq'::regclass);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_pkey PRIMARY KEY (us_id);
CREATE UNIQUE INDEX unique_username_ci ON public.users USING btree (lower(us_name));


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

CREATE SEQUENCE public.messages_m_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.messages_m_id_seq OWNED BY public.messages.m_id;
ALTER TABLE ONLY public.messages ALTER COLUMN m_id SET DEFAULT nextval('public.messages_m_id_seq'::regclass);
ALTER TABLE ONLY public.messages ADD CONSTRAINT messages_pkey PRIMARY KEY (m_id);


CREATE TABLE public.poll_options (
    option_id integer NOT NULL,
    m_id integer,
    option_text text NOT NULL
);

CREATE SEQUENCE public.poll_options_option_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.poll_options_option_id_seq OWNED BY public.poll_options.option_id;
ALTER TABLE ONLY public.poll_options ALTER COLUMN option_id SET DEFAULT nextval('public.poll_options_option_id_seq'::regclass);
ALTER TABLE ONLY public.poll_options ADD CONSTRAINT poll_options_pkey PRIMARY KEY (option_id);
CREATE INDEX idx_poll_options_message ON public.poll_options USING btree (m_id);


CREATE TABLE public.poll_votes (
    option_id integer NOT NULL,
    us_id integer NOT NULL,
    voted_at timestamp without time zone DEFAULT now() NOT NULL,
    m_id integer NOT NULL
);

ALTER TABLE ONLY public.poll_votes ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (option_id, us_id);
ALTER TABLE ONLY public.poll_votes ADD CONSTRAINT one_vote_per_user_per_poll UNIQUE (us_id, m_id);
CREATE INDEX idx_poll_votes_option ON public.poll_votes USING btree (option_id);


CREATE TABLE public.seen (
    m_id integer NOT NULL,
    us_id integer NOT NULL,
    seen_at timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY public.seen ADD CONSTRAINT seen_pkey PRIMARY KEY (m_id, us_id);


CREATE TABLE public.sessions (
    session_id integer NOT NULL,
    us_id integer NOT NULL,
    token text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.sessions_session_id_seq
    AS integer START WITH 1 INCREMENT BY 1
    NO MINVALUE NO MAXVALUE CACHE 1;

ALTER SEQUENCE public.sessions_session_id_seq OWNED BY public.sessions.session_id;
ALTER TABLE ONLY public.sessions ALTER COLUMN session_id SET DEFAULT nextval('public.sessions_session_id_seq'::regclass);
ALTER TABLE ONLY public.sessions ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);
ALTER TABLE ONLY public.sessions ADD CONSTRAINT sessions_token_key UNIQUE (token);


CREATE TABLE public.user_univ (
    us_id integer NOT NULL,
    uni_id integer NOT NULL
);

ALTER TABLE ONLY public.user_univ ADD CONSTRAINT us_uni_id PRIMARY KEY (us_id, uni_id);


-- FOREIGN KEYS

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT location_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_creator_fkey FOREIGN KEY (creator) REFERENCES public.users(us_id) NOT VALID;

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_message FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.poll_options(option_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id);


-- DATA
-- Insert order: locations + universes + users first, then messages, then the rest

INSERT INTO public.universes (uni_name, access, descri, uni_id) VALUES
('CoordiNote_testingGroup', true, 'We are the developers behind CoordiNote. Currently testing our project.', 400000),
('LisboaFunfacts', false, 'Funfacts about the city of Lisbon.', 400001),
('GeoTech252627', true, 'Universe for all GeoTech students.', 400002),
('RestaurantReviewsLisbon', false, 'Users reviews of restaurants in Lisbon.', 400003),
('SunsetViewpoints', false, 'Best viewpoints to watch the sunset in Lisbon.', 400004),
('Erasmus2026summer', false, 'Erasmus student network for the summer semester of 2026.', 400005),
('Swifties', false, 'Universe for all Taylor Swift fans worldwide. <3', 400006),
('LisbonRepair', false, 'Real-time sharing of information about locations in Lisbon that need construction or maintenance work.', 400007),
('LostAndFound', false, 'Universe for sharing information about lost and found items in Lisbon.', 400008),
('LisbonEvents', false, 'Universe for sharing information about events happening in Lisbon.', 400009),
('climbing crew <3', true, 'Best climbers in the city! Climbing, drinking coffee, chilling.', 400010);


INSERT INTO public.users (pwd, us_name, us_id) VALUES
('$2b$12$bl0BgxfDQwiIdf/rEDGC2.yje7O5qyCQzPqD51b3WGauNIr/u6W6S', 'marie_tr', 100000),
('$2b$12$6HdsPu6xJTpFIEk44lJoy.nl1f0riYq1oJMvK77JB2nbDakoYpK6m', 'bekirbeko', 100001),
('$2b$12$chqhLpGcE3JHD2VFMZA45ekYEiGbONOw3Pg.b5IIRkpZhHGBWznu.', 'wilmadora', 100002),
('$2b$12$3aB7yIE1FDzKsClWsnmBZeYB2kHTIP/jd/LbSTRqidY6t2h2rXSI6', 'jacobvanmeer', 100003),
('$2b$12$9vevClUbWCR7fkseB/bQn.vCQS7zHlaw7iMGD8qHPYBwz3vHbJYZm', 'lindaelfriede', 100004),
('$2b$12$DUZ8IIjn2WTylCTNXdrrE.bL0PwCQRKey3TrwYIKt4dUyfRihc.Ga', 'rikostryko', 100005),
('$2b$12$uZcPTdqwGH5nh2Ue4CTv5uU7Z6d0jJ51t8Xrw1uKE2NbCG4OEzaNC', 'Johana', 100009),
('$2b$12$3eFlgYnaFlwMewG8p0BOueR8GcRJMgx5LvmUx5KWWQ3trZOySmLD2', 'anda', 100012),
('$2b$12$/MrRk6mL9BpvK2WNYJ1sd.MUoTGFjS7hX7AWP2WhEJtsErqa8GiIe', 'tilak', 100015);


-- Test locations in Lisbon (linked to test messages below)
INSERT INTO public.locations (location_id, l_name, category, geom) VALUES
(911585, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1393, 38.7169), 4326)),
(911586, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1399, 38.7223), 4326)),
(911587, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1334, 38.7140), 4326)),
(911588, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1480, 38.7100), 4326)),
(911589, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1480, 38.7100), 4326)),
(911590, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1610, 38.7155), 4326)),
(911591, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1610, 38.7155), 4326)),
(911592, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1610, 38.7155), 4326)),
(911593, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1387, 38.7139), 4326)),
(911594, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1387, 38.7139), 4326)),
(911595, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1450, 38.7200), 4326)),
(911596, NULL, NULL, ST_SetSRID(ST_MakePoint(-9.1450, 38.7200), 4326));


INSERT INTO public.messages (m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, location_id, m_id) VALUES
('text', 30, '2026-02-20 14:55:26.053355', false, 'Hello everyone! Testing the connection', 100000, 400000, 911585, 700000),
('text', 30, '2026-02-20 14:57:23.480188', true,  'There was an earthquake in Lisbon on 19th February 2026.', 100000, 400001, 911586, 700001),
('text', 50, '2026-02-20 14:58:39.857498', true,  'Start learning programming now!! haha', 100000, 400002, 911587, 700002),
('text', 20, '2026-02-20 15:01:56.605253', false, 'Let''s go to the karaoke!', 100000, 400002, 911588, 700003),
('text', 20, '2026-02-20 15:02:30.264845', false, 'I want to eat sushiiii. If you want to join me, call me.', 100000, 400002, 911589, 700004),
('text', 20, '2026-02-20 15:04:31.868744', false, 'This sidewalk has this huge hole since forever!', 100002, 400007, 911590, 700005),
('text', 20, '2026-02-20 15:04:48.126684', false, 'Floods everywhere in this area. :((', 100002, 400007, 911591, 700006),
('text', 30, '2026-02-20 15:05:10.313883', false, 'This lamp is not working since 20. 2. 2026. Please fix it.', 100002, 400007, 911592, 700007),
('text', 30, '2026-02-20 15:06:01.926179', false, 'Found a ring under this bench, contact me if you''ve lost it. Describe how it looked. (+420 777 999 000)', 100002, 400008, 911593, 700008),
('text', 30, '2026-02-20 15:07:05.902114', false, 'I''ve lost my glasses on my way home! If anyone has found it, let me know!! pleaseeee. (ig: wilmimi)', 100002, 400008, 911594, 700009),
('text', 30, '2026-02-20 15:08:36.142456', true,  'Brazilian DJs in the town. Sunset b2b set, this Friday!! COME! <3', 100002, 400009, 911595, 700010),
('text', 30, '2026-02-20 15:09:09.942073', true,  'Only 3 days until carnival! Don''t skip Bairro Alto.', 100002, 400009, 911596, 700011);


INSERT INTO public.user_univ (us_id, uni_id) VALUES
(100000, 400000),
(100000, 400001),
(100000, 400002),
(100000, 400003),
(100001, 400004),
(100001, 400005),
(100001, 400006),
(100002, 400007),
(100002, 400008),
(100002, 400009),
(100005, 400004),
(100005, 400005),
(100005, 400006),
(100005, 400007),
(100005, 400008),
(100005, 400009),
(100002, 400010);


INSERT INTO public.seen (m_id, us_id, seen_at) VALUES
(700010, 100005, '2026-02-20 15:18:42.612073');


-- SEQUENCE RESET
-- Set sequences to continue from where test data left off
SELECT pg_catalog.setval('public.locations_id_seq', 911596, true);
SELECT pg_catalog.setval('public.messages_m_id_seq', 700011, true);
SELECT pg_catalog.setval('public.poll_options_option_id_seq', 900000, false);
SELECT pg_catalog.setval('public.sessions_session_id_seq', 104, true);
SELECT pg_catalog.setval('public.universe_uni_id_seq', 400010, true);
SELECT pg_catalog.setval('public.users_us_id_seq', 100015, true);
