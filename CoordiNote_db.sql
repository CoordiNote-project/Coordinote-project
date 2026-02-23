--
-- PostgreSQL database dump
--
\restrict EQgHwqImbPcKXR5L5dOgOqY6vVj4DZE3lHzJI4dv5LLPySuZsd0nOjcrKLgpMR5


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


----------------------------------------
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--

CREATE TABLE public.locations (
    location_id integer NOT NULL,
    l_name text,
    category text,
    geom public.geometry(Geometry,4326)
);


ALTER TABLE public.locations OWNER TO postgres;

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

ALTER SEQUENCE public.locations_id_seq OWNED BY public.locations.location_id;


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

CREATE SEQUENCE public.messages_m_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.messages_m_id_seq OWNER TO postgres;

--

ALTER SEQUENCE public.messages_m_id_seq OWNED BY public.messages.m_id;


--

CREATE TABLE public.poll_options (
    option_id integer NOT NULL,
    m_id integer,
    option_text text NOT NULL
);


ALTER TABLE public.poll_options OWNER TO postgres;

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

ALTER SEQUENCE public.poll_options_option_id_seq OWNED BY public.poll_options.option_id;


--


CREATE TABLE public.poll_votes (
    option_id integer NOT NULL,
    us_id integer NOT NULL,
    voted_at timestamp without time zone DEFAULT now() NOT NULL,
    m_id integer NOT NULL
);


ALTER TABLE public.poll_votes OWNER TO postgres;

--

CREATE TABLE public.seen (
    m_id integer NOT NULL,
    us_id integer NOT NULL,
    seen_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.seen OWNER TO postgres;

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


CREATE SEQUENCE public.sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sessions_session_id_seq OWNER TO postgres;

--

ALTER SEQUENCE public.sessions_session_id_seq OWNED BY public.sessions.session_id;


--

CREATE TABLE public.universes (
    uni_name character varying(150) NOT NULL,
    access boolean DEFAULT false NOT NULL,
    descri text,
    uni_id integer NOT NULL
);


ALTER TABLE public.universes OWNER TO postgres;

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


ALTER SEQUENCE public.universe_uni_id_seq OWNED BY public.universes.uni_id;


--


CREATE TABLE public.user_univ (
    us_id integer NOT NULL,
    uni_id integer NOT NULL
);


ALTER TABLE public.user_univ OWNER TO postgres;

--

CREATE TABLE public.users (
    pwd text NOT NULL,
    us_name text NOT NULL,
    us_id integer NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

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

ALTER SEQUENCE public.users_us_id_seq OWNED BY public.users.us_id;


--

ALTER TABLE ONLY public.locations ALTER COLUMN location_id SET DEFAULT nextval('public.locations_id_seq'::regclass);


--

ALTER TABLE ONLY public.messages ALTER COLUMN m_id SET DEFAULT nextval('public.messages_m_id_seq'::regclass);


--

ALTER TABLE ONLY public.poll_options ALTER COLUMN option_id SET DEFAULT nextval('public.poll_options_option_id_seq'::regclass);


--

ALTER TABLE ONLY public.sessions ALTER COLUMN session_id SET DEFAULT nextval('public.sessions_session_id_seq'::regclass);


--


ALTER TABLE ONLY public.universes ALTER COLUMN uni_id SET DEFAULT nextval('public.universe_uni_id_seq'::regclass);


--


ALTER TABLE ONLY public.users ALTER COLUMN us_id SET DEFAULT nextval('public.users_us_id_seq'::regclass);


--


ALTER TABLE ONLY public.locations
    ADD CONSTRAINT locations_pkey PRIMARY KEY (location_id);


--


ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (m_id);


--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT one_vote_per_user_per_poll UNIQUE (us_id, m_id);


--


ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (option_id);


--


ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (option_id, us_id);


--

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_pkey PRIMARY KEY (m_id, us_id);


--


ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);


--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_token_key UNIQUE (token);


--


ALTER TABLE ONLY public.universes
    ADD CONSTRAINT unique_uni_name UNIQUE (uni_name);


--


ALTER TABLE ONLY public.universes
    ADD CONSTRAINT unique_universe_name UNIQUE (uni_name);


--


ALTER TABLE ONLY public.universes
    ADD CONSTRAINT universe_pkey PRIMARY KEY (uni_id);


--


ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT us_uni_id PRIMARY KEY (us_id, uni_id);


--


ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (us_id);


--


CREATE INDEX idx_poll_options_message ON public.poll_options USING btree (m_id);


--


CREATE INDEX idx_poll_votes_option ON public.poll_votes USING btree (option_id);


--


CREATE UNIQUE INDEX unique_location ON public.locations USING btree (l_name, category, geom);


--


CREATE UNIQUE INDEX unique_universe_name_ci ON public.universes USING btree (lower((uni_name)::text));


--


CREATE UNIQUE INDEX unique_username_ci ON public.users USING btree (lower(us_name));


--


ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT fk_message FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT location_fkey FOREIGN KEY (location_id) REFERENCES public.locations(location_id);


--


ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_creator_fkey FOREIGN KEY (creator) REFERENCES public.users(us_id) NOT VALID;


--


ALTER TABLE ONLY public.messages
    ADD CONSTRAINT m_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;


--


ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--


ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_option_id_fkey FOREIGN KEY (option_id) REFERENCES public.poll_options(option_id) ON DELETE CASCADE;


--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


--

ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_m_id_fkey FOREIGN KEY (m_id) REFERENCES public.messages(m_id) ON DELETE CASCADE;


--


ALTER TABLE ONLY public.seen
    ADD CONSTRAINT seen_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


-----------

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id) ON DELETE CASCADE;


--

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_uni_id_fkey FOREIGN KEY (uni_id) REFERENCES public.universes(uni_id) NOT VALID;


--

ALTER TABLE ONLY public.user_univ
    ADD CONSTRAINT user_uni_us_id_fkey FOREIGN KEY (us_id) REFERENCES public.users(us_id);

--

\unrestrict EQgHwqImbPcKXR5L5dOgOqY6vVj4DZE3lHzJI4dv5LLPySuZsd0nOjcrKLgpMR5

