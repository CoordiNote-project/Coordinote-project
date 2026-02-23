--------------SEE ALL LOCATIONS
SELECT location_id
FROM locations
LIMIT 44;


------------------ADD MESSAGE TO THIS LOCATION
INSERT INTO messages (m_txt, location_id)
VALUES ('OLAAAAA', 150);


--------SEE ALL MESSAGES
SELECT m.m_id, m_txt, l_name
FROM messages m
JOIN locations l ON m.location_id = l.location_id;


------ BUFFER QUERY
SELECT m.m_id, m_txt
FROM messages m
JOIN locations l ON m.location_id = l.location_id
WHERE ST_DWithin(
    l.geom,
    ST_SetSRID(ST_MakePoint(-9.1393, 38.7223), 4326), -------  9.1393, 38.7223 user's location
    100
);
------------------
