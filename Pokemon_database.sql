# 1. CREATE DATABASE

CREATE SCHEMA Pokedex;
USE Pokedex;

# 2. CREATE LOOKUP TABLES

CREATE TABLE Generation (
    generation_id INT PRIMARY KEY,
    generation_name VARCHAR(50)
);

CREATE TABLE LevelUpGroup (
    group_id INT PRIMARY KEY,
    group_name VARCHAR(50)
);

CREATE TABLE Stat (
    stat_id INT PRIMARY KEY,
    stat_name VARCHAR(50)
);

CREATE TABLE ptypes (
    type_id INT PRIMARY KEY,
    type_name VARCHAR(50)
);

CREATE TABLE egg_groups (
    egg_id INT PRIMARY KEY,
    egg_group_name VARCHAR(50)
);


# 3. CREATE MAIN ENTITY TABLE

CREATE TABLE Pokemon (
    pokemon_id INT PRIMARY KEY,
    name VARCHAR(100),
    color VARCHAR(50),
    generation_id INT,
    group_id INT,
    FOREIGN KEY (generation_id) REFERENCES Generation(generation_id),
    FOREIGN KEY (group_id) REFERENCES LevelUpGroup(group_id)
);

# 4. CREATE RELATIONSHIP TABLES

# Pokemon - Types
CREATE TABLE Pokemon_Type (
    pokemon_id INT,
    type_id INT,
    PRIMARY KEY (pokemon_id, type_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id),
    FOREIGN KEY (type_id) REFERENCES ptypes(type_id)
);

# Pokemon - Stats
CREATE TABLE Pokemon_Stat (
    pokemon_id INT,
    stat_id INT,
    value INT,
    PRIMARY KEY (pokemon_id, stat_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id),
    FOREIGN KEY (stat_id) REFERENCES Stat(stat_id)
);

# Pokemon - Egg Groups
CREATE TABLE Pokemon_EggGroup (
    pokemon_id INT,
    egg_id INT,
    PRIMARY KEY (pokemon_id, egg_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id),
    FOREIGN KEY (egg_id) REFERENCES egg_groups(egg_id)
);

# 5. CREATE STAGING TABLES

# raw dataset for stats and types
CREATE TABLE raw_pokemon (
    number INT,
    name TEXT,
    type1 TEXT,
    type2 TEXT,
    hp INT,
    attack INT,
    defense INT,
    sp_attack INT,
    sp_defense INT,
    speed INT
);

# raw dataset for color, egg groups, and level-up groups
CREATE TABLE raw_extra (
    number INT,
    name TEXT,
    color TEXT,
    egg_group1 TEXT,
    egg_group2 TEXT,
    level_up_group TEXT
);

#Test 1
SELECT * FROM raw_pokemon LIMIT 10;
SELECT * FROM raw_extra LIMIT 10;                    

# 6. INSERT LOOKUP TABLE DATA

# inserting generation_id and generation_name into Generation
INSERT INTO Generation VALUES
(1, 'Kanto'), (2, 'Johto'), (3, 'Hoenn'), (4, 'Sinnoh'),
(5, 'Unova'), (6, 'Kalos'), (7, 'Alola'), (8, 'Galar'),
(9, 'Hisui'), (10, 'Paldea');

# inserting stat_id and stat_name into Stat
INSERT INTO Stat VALUES
(1, 'Health Points'),
(2, 'Attack'),
(3, 'Defense'),
(4, 'Special Attack'),
(5, 'Special Defense'),
(6, 'Speed');

# inserting egg_id and egg_group_name into egg_groups
INSERT INTO egg_groups VALUES
(1, 'Amorphous'), (2, 'Bug'), (3, 'Dragon'), (4, 'Fairy'),
(5, 'Field'), (6, 'Flying'), (7, 'Grass'), (8, 'Human-Like'),
(9, 'Mineral'), (10, 'Monster'), (11, 'Water 1'),
(12, 'Water 2'), (13, 'Water 3'), (14, 'Ditto'),
(15, 'Undiscovered');

# inserting group_id and group_name into LevelUpGroup
INSERT INTO LevelUpGroup VALUES
(1, 'Erratic'), (2, 'Fast'), (3, 'Medium Fast'),
(4, 'Medium Slow'), (5, 'Slow'), (6, 'Fluctuating');

# inserting type_id and type_name into ptypes
INSERT INTO ptypes VALUES
(1, 'Normal'), (2, 'Fire'), (3, 'Water'), (4, 'Grass'),
(5, 'Electric'), (6, 'Ice'), (7, 'Fighting'), (8, 'Poison'),
(9, 'Ground'), (10, 'Flying'), (11, 'Psychic'), (12, 'Bug'),
(13, 'Rock'), (14, 'Ghost'), (15, 'Dragon'),
(16, 'Dark'), (17, 'Steel'), (18, 'Fairy');

# 7. INSERT POKEMON DATA

# inserting pokemon basic information from raw_pokemon
INSERT INTO Pokemon (pokemon_id, name, color, generation_id, group_id)
SELECT number, name, 'Unknown', 1, 3
FROM raw_pokemon;


# 8. INSERT TYPE RELATIONSHIPS

# inserting primary types
INSERT INTO Pokemon_Type (pokemon_id, type_id)
SELECT r.number, t.type_id
FROM raw_pokemon r
JOIN ptypes t ON r.type1 = t.type_name;

# inserting secondary types if they exist
INSERT INTO Pokemon_Type (pokemon_id, type_id)
SELECT r.number, t.type_id
FROM raw_pokemon r
JOIN ptypes t ON r.type2 = t.type_name
WHERE r.type2 IS NOT NULL AND r.type2 <> '';

# 9. INSERT STAT RELATIONSHIPS

# inserting all stat values
INSERT INTO Pokemon_Stat (pokemon_id, stat_id, value)
SELECT number, 1, hp FROM raw_pokemon
UNION ALL
SELECT number, 2, attack FROM raw_pokemon
UNION ALL
SELECT number, 3, defense FROM raw_pokemon
UNION ALL
SELECT number, 4, sp_attack FROM raw_pokemon
UNION ALL
SELECT number, 5, sp_defense FROM raw_pokemon
UNION ALL
SELECT number, 6, speed FROM raw_pokemon;

# 10. INSERT EGG GROUP RELATIONSHIPS
# inserting primary egg groups
INSERT INTO Pokemon_EggGroup (pokemon_id, egg_id)
SELECT r.number, e.egg_id
FROM raw_extra r
JOIN egg_groups e ON r.egg_group1 = e.egg_group_name;

# inserting secondary egg groups if they exist
INSERT INTO Pokemon_EggGroup (pokemon_id, egg_id)
SELECT r.number, e.egg_id
FROM raw_extra r
JOIN egg_groups e ON r.egg_group2 = e.egg_group_name
WHERE r.egg_group2 IS NOT NULL AND r.egg_group2 <> '';

# 11. UPDATE POKEMON DATA           
SET SQL_SAFE_UPDATES = 0;
# updating pokemon with correct generation based on pokedex number
UPDATE Pokemon
SET generation_id =
    CASE
        WHEN pokemon_id <= 151 THEN 1
        WHEN pokemon_id <= 251 THEN 2
        WHEN pokemon_id <= 386 THEN 3
        WHEN pokemon_id <= 493 THEN 4
        WHEN pokemon_id <= 649 THEN 5
        WHEN pokemon_id <= 721 THEN 6
        WHEN pokemon_id <= 809 THEN 7
        WHEN pokemon_id <= 898 THEN 8
        WHEN pokemon_id <= 905 THEN 9
        ELSE 10
    END;

# updating pokemon color from raw_extra
UPDATE Pokemon p
JOIN raw_extra r ON p.pokemon_id = r.number
SET p.color = r.color;

# assigning correct level-up groups from raw_extra
UPDATE Pokemon p
JOIN raw_extra r ON p.pokemon_id = r.number
JOIN LevelUpGroup lg ON r.level_up_group = lg.group_name
SET p.group_id = lg.group_id;

           
# 12. TEST COUNTS
             
# show number of Pokemon
SELECT COUNT(*) AS total_pokemon
FROM Pokemon;

# count number of stat entries
SELECT COUNT(*) AS total_stat_entries
FROM Pokemon_Stat;

# count number of type relationships
SELECT COUNT(*) AS total_type_relationships
FROM Pokemon_Type;

# count number of egg group relationships
SELECT COUNT(*) AS total_egg_group_relationships
FROM Pokemon_EggGroup;

# count level-up group distribution
SELECT lg.group_name, COUNT(*) AS total_pokemon
FROM Pokemon p
JOIN LevelUpGroup lg ON p.group_id = lg.group_id
GROUP BY lg.group_name
ORDER BY total_pokemon DESC;

SELECT COUNT(*) AS raw_pokemon_count
FROM raw_pokemon;

#drop tables containing infromation from csv files
drop table raw_extra;
drop table raw_pokemon;
# Testing

# BASIC COUNTS

# show number of Pokémon
SELECT COUNT(*) 
FROM pokemon;

# count number of stat entries
SELECT COUNT(*) 
FROM Pokemon_Stat;

# count number of type relationships
SELECT COUNT(*) 
FROM Pokemon_Type;

# count number of egg group relationships
SELECT COUNT(*) 
FROM Pokemon_EggGroup;

# SIMPLE QUERIES

# all red Pokémon
SELECT name
FROM pokemon
WHERE color = 'Red';

# Pokémon Lucario's stats
SELECT p.pokemon_id, p.name, ps.value, s.stat_name
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN stat s ON ps.stat_id = s.stat_id
WHERE p.name = 'Lucario'
ORDER BY s.stat_id;

# Pokémon Mewtwo's stats
SELECT p.pokemon_id, p.name, ps.value, s.stat_name 
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN stat s ON ps.stat_id = s.stat_id
WHERE p.pokemon_id = 150
ORDER BY s.stat_id;

# FILTERED STAT QUERIES

# pink Pokémon with lowest special defense
SELECT p.pokemon_id, p.name, ps.value AS special_defense
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
WHERE p.color = 'Pink'
AND ps.stat_id = 5
ORDER BY ps.value ASC
LIMIT 5;

# special defense in generation 2
SELECT p.pokemon_id, p.name, ps.value AS special_defense
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN stat s ON ps.stat_id = s.stat_id
WHERE s.stat_name = 'Special Defense'
AND p.generation_id = 2
ORDER BY ps.value DESC
LIMIT 10;

# EGG GROUP + STAT QUERIES

# purple Pokémon with highest defense in undiscovered egg group
SELECT p.pokemon_id, p.name, ps.value AS defense
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN Pokemon_EggGroup pe ON p.pokemon_id = pe.pokemon_id
WHERE p.color = 'Purple'
AND ps.stat_id = 3
AND pe.egg_id = 15
ORDER BY ps.value DESC
LIMIT 15;

# highest attack Pokémon that is yellow or red in bug egg group from generation 5 (Unova)
SELECT p.pokemon_id, p.name, ps.value AS attack
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN Pokemon_EggGroup pe ON p.pokemon_id = pe.pokemon_id
WHERE p.color IN ('Yellow', 'Red')
AND ps.stat_id = 2
AND pe.egg_id = 2
AND p.generation_id = 5
ORDER BY ps.value DESC
LIMIT 15;

# AGGREGATION QUERIES

# highest total stats
SELECT p.pokemon_id, p.name, SUM(ps.value) AS total_stats
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
GROUP BY p.pokemon_id, p.name
ORDER BY total_stats DESC
LIMIT 10;

# dual-type Pokémon
SELECT p.pokemon_id, p.name
FROM pokemon p
JOIN Pokemon_Type pt ON p.pokemon_id = pt.pokemon_id
GROUP BY p.pokemon_id, p.name
HAVING COUNT(*) = 2;

# fastest Pokémon
SELECT p.pokemon_id, p.name, ps.value AS speed
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
WHERE ps.stat_id = 6
ORDER BY ps.value DESC
LIMIT 10;

# COMPLEX MULTI-CONDITION QUERIES

# lowest speed Pokémon with multiple conditions (using IDs)
SELECT DISTINCT p.pokemon_id, p.name, ps.value AS speed
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN Pokemon_EggGroup pe ON p.pokemon_id = pe.pokemon_id
JOIN Pokemon_Type pt ON p.pokemon_id = pt.pokemon_id
JOIN levelupgroup lg ON p.group_id = lg.group_id
WHERE p.color IN ('Blue', 'Pink')
AND ps.stat_id = 6
AND pe.egg_id IN (11, 10, 5)
AND p.generation_id IN (1, 2)
AND pt.type_id IN (11, 3, 9)
AND lg.group_id = 3
ORDER BY ps.value ASC
LIMIT 15;

# lowest health Pokémon with multiple conditions (using names)
SELECT DISTINCT p.pokemon_id, p.name, ps.value AS health_points
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
JOIN stat s ON ps.stat_id = s.stat_id
JOIN Pokemon_EggGroup pe ON p.pokemon_id = pe.pokemon_id
JOIN egg_groups e ON pe.egg_id = e.egg_id
JOIN Pokemon_Type pt ON p.pokemon_id = pt.pokemon_id
JOIN ptypes t ON pt.type_id = t.type_id
JOIN generation g ON p.generation_id = g.generation_id
JOIN levelupgroup lg ON p.group_id = lg.group_id
WHERE p.color = 'Brown'
AND s.stat_name = 'Health Points'
AND g.generation_name IN ('Kanto', 'Hoenn')
AND e.egg_group_name IN ('Mineral', 'Field')
AND t.type_name IN ('Ghost', 'Ground', 'Bug')
AND lg.group_name = 'Erratic'
ORDER BY ps.value ASC
LIMIT 15;

# Finding what egg group Pikachu belongs in and showing all
# the Pokémon in the same group
SELECT DISTINCT p2.pokemon_id, p2.name, e.egg_group_name
FROM pokemon p1
JOIN Pokemon_EggGroup pe1 
    ON p1.pokemon_id = pe1.pokemon_id
JOIN egg_groups e 
    ON pe1.egg_id = e.egg_id
JOIN Pokemon_EggGroup pe2 
    ON e.egg_id = pe2.egg_id
JOIN pokemon p2 
    ON pe2.pokemon_id = p2.pokemon_id
WHERE p1.name = 'Pikachu'
ORDER BY e.egg_group_name, p2.name;

#Checking to see if Aerodactyl is faster than Greninja
SELECT p.pokemon_id, p.name, ps.value AS speed
FROM pokemon p
JOIN Pokemon_Stat ps ON p.pokemon_id = ps.pokemon_id
WHERE ps.stat_id = 6
AND p.name IN ('Greninja', 'Aerodactyl')
ORDER BY ps.value DESC;