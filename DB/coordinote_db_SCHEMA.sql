--
-- PostgreSQL database dump
--

\restrict PpUCAnRIknPPw2gkeDmEaheo8sXb2EJIEeLXTdGS1BRvh0u0EDgioEZ17T6SS2N

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
-- TOC entry 5721 (class 2606 OID 33520)
-- Name: universes unique_universe_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.universes
    ADD CONSTRAINT unique_universe_name UNIQUE (uni_name);


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

\unrestrict PpUCAnRIknPPw2gkeDmEaheo8sXb2EJIEeLXTdGS1BRvh0u0EDgioEZ17T6SS2N

