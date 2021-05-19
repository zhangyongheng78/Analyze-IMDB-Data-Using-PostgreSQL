CREATE TABLE titleBasics (                                                                                                       
tconst VARCHAR,
titleType VARCHAR,
primaryTitle VARCHAR,
originalTitle VARCHAR,
isAdult BOOLEAN,
startYear INTEGER,
endYear INTEGER,
runtimeMinutes INTEGER,
genres VARCHAR(100));

CREATE TABLE titleRatings(
tconst VARCHAR,
averageRating NUMERIC,
numVotes INTEGER);

CREATE TABLE titleCrew(
tconst VARCHAR,
directors VARCHAR,
writers VARCHAR);

CREATE TABLE titleEpisode(
tconst VARCHAR,
parentTconst VARCHAR
seasonNumber VARCHAR(5),
episodeNumber VARCHAR(5));

CREATE TABLE titlePrincipals(
tconst VARCHAR,
ordering INTEGER,
nconst VARCHAR,
category VARCHAR(20),
job VARCHAR,
characters VARCHAR);

CREATE TABLE titleAkas(
titledid VARCHAR,
ordering INTEGER,
title VARCHAR,
region VARCHAR,
language VARCHAR,
type VARCHAR,
attributes VARCHAR,
isOriginalTitle BOOLEAN);

CREATE TABLE nameBasics(
nconst VARCHAR,
primaryName VARCHAR,
birthYear INTEGER,
deathYear INTEGER,
primaryProfession VARCHAR(100),
knownForTitles VARCHAR(100));


\COPY titleBasics FROM '/Users/yonghengzhang/Desktop/title.basics.tsv' HEADER csv DELIMITER E'\t' Null '\N' QUOTE '|';
\COPY titleratings FROM '/Users/yonghengzhang/Desktop/title.ratings.tsv' HEADER csv DELIMITER E'\t' Null '\N'；
\COPY titlecrew FROM '/Users/yonghengzhang/Desktop/title.crew.tsv' HEADER csv DELIMITER E'\t’ Null '\N'；
\COPY titleepisode FROM '/Users/yonghengzhang/Desktop/title.episode.tsv' HEADER csv DELIMITER E'\t' Null '\N';
\COPY titleprincipals FROM '/Users/yonghengzhang/Desktop/title.principals.tsv' HEADER csv DELIMITER E'\t' NULL '\N' QUOTE '{';
\COPY titleakas FROM '/Users/yonghengzhang/Desktop/title.akas.tsv' HEADER csv DELIMITER E'\t' NULL '\N' ;
\COPY namebasics FROM '/Users/yonghengzhang/Desktop/name.basics.tsv' HEADER csv DELIMITER E'\t' NULL '\N';


a)
COPY (
SELECT COUNT(DISTINCT S.tconst) 
FROM titlebasics S) 
TO ‘/Users/yonghengzhang/Desktop/hw1ANS/a.txt';

b)
COPY (
SELECT S.startyear, COUNT(DISTINCT S.tconst) 
FROM titlebasics S 
WHERE S.startyear IS NOT NULL 
GROUP BY S.startyear) 
TO ‘/Users/yonghengzhang/Desktop/hw1ANS/b.txt';


c)
COPY (
SELECT S.startyear, COUNT(DISTINCT S.tconst),MIN(S.runtimeminutes),MAX(S.runtimeminutes),AVG(S.runtimeminutes)
FROM titlebasics S
WHERE S.startyear IS NOT NULL and S.runtimeminutes IS NOT NULL and S.startyear >= 2016
GROUP BY S.startyear) 
TO '/Users/yonghengzhang/Desktop/hw1ANS/c.txt';


d)
That means those titles are going to be played in the future

e)
COPY (
SELECT S.titletype,S.primarytitle,S.startyear,S.endyear,S.runtimeminutes,S.genres
FROM titlebasics S
WHERE S.runtimeminutes  = (SELECT MAX(S2.runtimeminutes) FROM titlebasics S2))
TO '/Users/yonghengzhang/Desktop/hw1ANS/e.txt';

f)
COPY(
SELECT COUNT(DISTINCT genres)
FROM titlebasics S
TO '/Users/yonghengzhang/Desktop/hw1ANS/f.txt';

g)
COPY(
SELECT S.tconst,S.primarytitle,string_to_array(S.genres,',')
FROM titlebasics S
WHERE S.runtimeminutes = 900)
TO '/Users/yonghengzhang/Desktop/hw1ANS/g.txt';

h)
COPY(
SELECT S.tconst,S.primarytitle,genre
FROM titlebasics S,UNNEST(string_to_array(S.genres,',')) AS genre
WHERE S.runtimeminutes = 900
ORDER BY S.tconst)
TO '/Users/yonghengzhang/Desktop/hw1ANS/h.txt';

i)
COPY(
SELECT COUNT(DISTINCT genre)
FROM titlebasics S, UNNEST(string_to_array(S.genres,',')) AS genre)
TO '/Users/yonghengzhang/Desktop/hw1ANS/i.txt';

j)
COPY(
SELECT genre,COUNT(DISTINCT S.tconst)
FROM titlebasics S, UNNEST(string_to_array(S.genres,',')) AS genre
GROUP BY genre
ORDER BY COUNT(DISTINCT S.tconst))
TO '/Users/yonghengzhang/Desktop/hw1ANS/j.txt';

k)
COPY(
SELECT N.nconst,N.primaryname,N.birthyear,N.deathyear,N.primaryprofession,N.knownfortitles
FROM namebasics N, split_part(N.primaryname, ' ', 1) AS col1, split_part(N.primaryname, ' ', 2) AS col2, split_part(N.primaryname, ' ', 3) AS col3
WHERE col1 = 'Trump' or col2= 'Trump' or col3 = 'Trump')
To '/Users/yonghengzhang/Desktop/hw1ANS/k.txt';


L)
COPY(
WITH TRUMP as (                                                                                                                      
SELECT N.primaryname,N.birthyear,N.knownfortitles                                                                                          
FROM namebasics N, split_part(N.primaryname, ' ', 1) AS col1, split_part(N.primaryname, ' ', 2) AS col2, split_part(N.primaryname, ' ', 3) AS col3                                                                                                                                    
WHERE col1 = 'Trump' or col2= 'Trump' or col3 = 'Trump')   

SELECT T.primaryname, S.titletype, S.primarytitle,S.startyear                                                                              
FROM TRUMP T,titlebasics S, UNNEST(string_to_array(T.knownfortitles,',')) AS title                                                         
WHERE T.birthyear<=1970 and title = S.tconst 
ORDER BY primaryname)
To '/Users/yonghengzhang/Desktop/hw1ANS/L.txt';


M)
COPY(
\timing
SELECT *
FROM titlebasics S
WHERE S.primarytitle = 'Spider-Man' and S.titleType = 'movie')
To '/Users/yonghengzhang/Desktop/hw1ANS/m1.txt';
Time: 3474.126 ms (00:03.474)

CREATE INDEX titlebasics_primarytitle
ON titlebasics(primarytitle);
CREATE INDEX
Time: 80586.375 ms (01:20.586)

SELECT *
FROM titlebasics S
WHERE S.primarytitle = 'Spider-Man' and S.titleType = 'movie'
Time: 0.597 ms

N)
COPY(
SELECT N.primaryname,N.birthyear,N.primaryprofession
FROM titlebasics S, namebasics N, unnest(string_to_array(N.knownfortitles, ',')) as knowntitle
WHERE N.primaryprofession = 'actress' and knowntitle = S.tconst and S.primarytitle = 'Spider-Man' and S.titleType = 'movie')
To '/Users/yonghengzhang/Desktop/hw1ANS/N.txt';

O)
COPY(
SELECT N.birthyear,COUNT(*)
FROM titlebasics S, namebasics N, unnest(string_to_array(N.knownfortitles, ',')) as knowntitle, unnest(string_to_array(N.primaryprofession, ',')) as primaryprof
WHERE primaryprof = 'actress' and knowntitle = S.tconst and S.primarytitle = 'Spider-Man' and S.titleType = 'movie' and N.birthyear IS NOT NULL
GROUP BY N.birthyear)
To '/Users/yonghengzhang/Desktop/hw1ANS/O.txt';
