DELETE FROM namebasics;
-- DELETE 8430404

DELETE FROM titleakas;
-- DELETE 10222934

DELETE FROM titlebasics;
-- DELETE 6460644

DELETE FROM titlecrew;
-- DELETE 6460644

DELETE FROM titleepisode;
-- DELETE 4558317

DELETE FROM titleprincipals;
-- DELETE 19273403

DELETE FROM titleratings;
-- DELETE 1012651

\COPY titleBasics FROM '/Users/yonghengzhang/Desktop/title.basics.tsv' HEADER csv DELIMITER E'\t' Null '\N' QUOTE '|';
-- COPY 6460644

\COPY titleratings FROM '/Users/yonghengzhang/Desktop/title.ratings.tsv' HEADER csv DELIMITER E'\t' Null '\N';
-- COPY 1012651

\COPY titlecrew FROM '/Users/yonghengzhang/Desktop/title.crew.tsv' HEADER csv DELIMITER E'\t' Null '\N';
-- COPY 6460644

\COPY titleepisode FROM '/Users/yonghengzhang/Desktop/title.episode.tsv' HEADER csv DELIMITER E'\t' Null '\N';
-- COPY 4558317

\COPY titleprincipals FROM '/Users/yonghengzhang/Desktop/title.principals.tsv' HEADER csv DELIMITER E'\t' NULL '\N' QUOTE '{';
-- COPY 19273403

\COPY titleakas FROM '/Users/yonghengzhang/Desktop/title.akas.tsv' HEADER csv DELIMITER E'\t' NULL '\N';
-- COPY 10222934

\COPY namebasics FROM '/Users/yonghengzhang/Desktop/name.basics.tsv' HEADER csv DELIMITER E'\t' NULL '\N';
-- COPY 8430404

-- Creating new tables
CREATE TABLE ratings(
userid INTEGER,
movieid INTEGER,
rating NUMERIC,
timestamp INTEGER);
-- CREATE TABLE

CREATE TABLE tags(
userid INTEGER,
movieid INTEGER,
tag VARCHAR,
timestamp INTEGER);
-- CREATE TABLE

CREATE TABLE movies(
movieid INTEGER,
titile VARCHAR,
genre VARCHAR);
-- CREATE TABLE

CREATE TABLE links(
movieid INTEGER,
imdbid INTEGER,
tmdbid INTEGER);
-- CREATE TABLE

-- Load the data
\COPY ratings FROM '/Users/yonghengzhang/Desktop/ml-latest/ratings.csv' HEADER csv DELIMITER ',' Null '';
-- COPY 27753444

\COPY tags FROM '/Users/yonghengzhang/Desktop/ml-latest/tags.csv' HEADER csv DELIMITER ',' Null '';
-- COPY 1108997

\COPY movies FROM '/Users/yonghengzhang/Desktop/ml-latest/movies.csv' HEADER csv DELIMITER ',' Null '';
-- COPY 58098

\COPY links FROM '/Users/yonghengzhang/Desktop/ml-latest/links.csv' HEADER csv DELIMITER ',' Null '';
-- COPY 58098

-- a) one piece of MovieLens information that’s currently embedded in a place where it doesn’t belong
CREATE VIEW QUESTION3a AS
SELECT movieid,
CASE
	WHEN RIGHT(TRIM(trailing ')' from TRIM(title)),2) ~ '\d\d' THEN (SELECT LEFT(TRIM(title),-6))
	--WHEN RIGHT(TRIM(trailing ')' from TRIM(title)),2) ~ '\w\w' THEN (SELECT title)
	ELSE (SELECT title)
END 
AS title,
CASE
	WHEN LEFT(RIGHT(TRIM(title),6),1) = '(' AND RIGHT(TRIM(title),1) = ')' AND RIGHT(TRIM(trailing ')' from TRIM(title)),2) ~ '\d\d' THEN (SELECT LEFT(TRIM(LEADING'(' FROM RIGHT(TRIM(title),6)),-1) )
	--WHEN RIGHT(TRIM(title),1) = ')' AND RIGHT(TRIM(trailing ')' from TRIM(title)),2) ~ '\w\w' THEN (SELECT '')
	ELSE (SELECT '')
END
AS year,
genres
FROM movies;

-- b) extracting (“lifting”) the contents of one field into a few separate fields for subsequent use and analysis.
CREATE VIEW QUESTION3b AS
SELECT nconst,substring(primaryname from '[^\s]+') AS firstname,TRIM(substring(primaryname from ' [^\s]+ ')) AS middlename,
CASE 
	WHEN LENGTH(N.primaryname) - LENGTH(REPLACE(N.primaryname, ' ', '')) + 1 =2 THEN (SELECT RIGHT(substring(N.primaryname from ' .*'),-1))
	WHEN LENGTH(N.primaryname) - LENGTH(REPLACE(N.primaryname, ' ', '')) + 1 =3 THEN (SELECT t.value[1]                                                                       
		FROM regexp_matches(N.primaryname, '[^\s]+' , 'g') with ordinality as t(value,idx)                                          
		where t.idx = 3) 	
END
AS lastname,
birthyear,deathyear,primaryprofession,knownfortitles
FROM namebasics N


-- c) Create views for the two tables that show the timestamp values in a "human readable" format.
CREATE VIEW QUESTION3c_ratings AS
SELECT userid,movieid,rating, TO_TIMESTAMP(timestamp) AT TIME ZONE 'UTC' AS time
FROM ratings


CREATE VIEW QUESTION3c_tags AS
SELECT userid,movieid,tag, TO_TIMESTAMP(timestamp) AT TIME ZONE 'UTC' AS time
FROM tags



-- d) how (and why) one might choose to aggregate its ratings if one wanted it to potentially be combinable with the IMDB rating information.
CREATE VIEW QUESTION3d AS
SELECT movieid,count(movieid) AS numvotes, ROUND((SUM(rating)/count(movieid)),1) AS averagerating
FROM ratings
GROUP BY movieid


-- By doing number of votes and average rating for each movie,
-- We can combine the rating file with the title.ratings file
-- in the IMDB table

-- e) The movies table, as provided, would likely be the most problematic MovieLens data set to analyze with SQL in its current form.
-- The year of the movies is embedded in a wrong place called title
-- The column called genre is not atomic

CREATE VIEW QUESTION3e AS
SELECT movieid,LEFT(title,-6) AS title, LEFT(TRIM(LEADING'(' FROM RIGHT(title,6)),-1) AS year,genre
FROM movies, UNNEST(string_to_array(genres,'|')) AS genre
ORDER BY movieid



-- f)
-- i) Which is the TMDB ID that is not missing (or null) and repeats the most?
SELECT tmdbid,COUNT(*) AS count 
FROM links 
WHERE tmdbid IS NOT NULL 
GROUP BY tmdbid 
ORDER BY count DESC 1;

-- tmdbid 141971 repeats the most

-- ii) What movie names are associated with that ID in the MovieLens dataset?
SELECT *
FROM links l, movies m
WHERE l.tmdbid = 141971 AND l.movieid = m.movieid;

-- iii) Why are TMDB IDs not unique here
-- Maybe the tmdbid stays the same when the movie names have
-- different production years and different genres, but same names.

-- iv) other information
SELECT * 
FROM titlebasics 
WHERE tconst ='tt1180333' OR tconst ='tt0844666' OR tconst ='tt0822791';

-- g) creating a view whose columns include an id (e.g., the tconst) and title for each movie along with review information (in separate columns) from both IMDB and MovieLens.
CREATE VIEW QUESTION3g AS
SELECT movieid,imdbid,tmdbid,concat('tt', repeat('0',(7-length(cast(imdbid as varchar)))),imdbid) AS tconst
FROM links;

CREATE VIEW QUESTION3g_ANS AS
WITH table1 AS(
SELECT B.tconst, Q.movieid, B.primarytitle,Q.numvotes AS Movielens_numvotes, 2*Q.averagerating AS Movielens_averagerating, R.numvotes AS IMDB_numvotes, R.averagerating AS IMDB_averagerating, (ROUND((2*Q.averagerating+ R.averagerating)/2,1)) AS Combined_Review
FROM titlebasics B,Question3d Q, titleratings R,Question3a U,QUESTION3g L
WHERE U.movieid = L.movieid AND L.tconst = B.tconst AND Q.movieid = L.movieid AND R.tconst = B.tconst),

table2 AS(
SELECT B.tconst, B.primarytitle, R.numvotes AS IMDB_numvotes, R.averagerating AS IMDB_averagerating, 
R.averagerating AS Combined_Review                                                                       
FROM titlebasics B,titleratings R                                                                                             
WHERE B.tconst not in (SELECT L.tconst FROM QUESTION3g L) AND B.tconst = R.tconst),

Table3 AS(  
SELECT U.movieid, U.title, Q.numvotes AS Movielens_numvotes, 2*Q.averagerating AS Movielens_averagerating,
2*Q.averagerating AS Combined_Review
FROM Question3d Q,Question3a U
WHERE U.movieID not in (SELECT L.movieid from QUESTION3g L) AND U.movieid = Q.movieid)
                                                                                  

SELECT * 
FROM table1

UNION ALL

SELECT tconst, NULL movieid, primarytitle, NULL Movielens_numvotes, NULL Movielens_averagerating,  IMDB_numvotes,IMDB_averagerating,Combined_Review    
FROM table2
 
UNION ALL

SELECT NULL tconst, movieid, title, Movielens_numvotes, Movielens_averagerating,  NULL IMDB_numvotes,NULL IMDB_averagerating,Combined_Review 
FROM TABLE3;

-- h) Materialize each of the views for future use
CREATE TABLE question3a_table(
movieid INTEGER,
title VARCHAR,
year VARCHAR,
genres VARCHAR);
INSERT INTO question3a_table SELECT * FROM question3a;

CREATE TABLE question3b_table(
nconst VARCHAR,
firstname VARCHAR,
middlename VARCHAR,
lastname VARCHAR,
birthyear INTEGER,
deathyear INTEGER,
primaryprofession VARCHAR(100),
knownfortitles VARCHAR(100));
INSERT INTO question3b_table SELECT * FROM question3b;

CREATE TABLE QUESTION3c_ratings_table(
userid INTEGER,
movieid INTEGER,
rating NUMERIC,
time TIMESTAMP);
INSERT INTO QUESTION3c_ratings_table SELECT * FROM QUESTION3c_ratings;

CREATE TABLE QUESTION3c_tags_TABLE(
userid INTEGER,
movieid INTEGER,
tag VARCHAR,
time TIMESTAMP);
INSERT INTO QUESTION3c_tags_table SELECT * FROM QUESTION3c_tags;

CREATE TABLE Question3d_table(
movieid INTEGER,
numvotes BIGINT,
averagerating NUMERIC);
INSERT INTO question3d_table SELECT * FROM question3d;

CREATE TABLE QUESTION3e_table(
movieid INTEGER,
title VARCHAR,
year VARCHAR,
genre VARCHAR);
INSERT INTO question3e_table SELECT * FROM question3e;

CREATE TABLE QUESTION3g_ANS_TABLE(
tconst VARCHAR,
movieid INTEGER,
primarytitle VARCHAR,
movielens_numvotes BIGINT,
movielens_averagerating NUMERIC,
iMDB_numvotes INTEGER,
iMDB_averagerating NUMERIC,
combined_review NUMERIC);
INSERT INTO question3g_ANS_table SELECT * FROM question3g_ANS;
