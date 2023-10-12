-- Analysing the top spotify songs of 2023
-- For this project, i used the Most Streamed Spotify Songs 2023 dataset which I found from Kaggle: https://www.kaggle.com/datasets/nelgiriyewithana/top-spotify-songs-2023

/* 
In this project, I will be answering the following questions:
  1.  Which artist has the most songs in the top streamed list of 2023?
  2. What is the average number of streams for songs released in each month of 2023?
  3. Are songs with higher danceability percentages generally more popular (i.e. have more streams)?
  4. What percentage of songs in the 'Top Spotify Songs 2023' were actually released in 2023?
*/

-- Step zero: Data Exploration
SELECT *
FROM emilio-playground.raw.top_spotify_songs_2023
LIMIT 50;

-- Step one: Clean the data

-- I expect streams and artists names not to be null, but let's check.
SELECT COUNT(*)
FROM emilio-playground.raw.top_spotify_songs_2023
WHERE streams IS NULL OR artist_s__name IS NULL;
-- Output: 0 null values, great!

-- Finally, I would like to normalise the text data, get rid of capital letters, and simplify column names on a staging layer.

SELECT
LOWER(track_name) AS track_name,
LOWER(artist_s__name) AS artist_name,
artist_count,
released_year,
released_month,
released_day,
in_spotify_playlists,
in_spotify_charts,
CAST(streams AS INT64) AS streams,
danceability__ AS danceability,
FROM table;

-- Step two: Analyse the data

-- Question one: Which artist has the most songs in the top streamed list of 2023?
SELECT 
  artist_name
  , COUNT(*) as song_count
FROM emilio-playground.raw.top_spotify_songs_2023
WHERE released_year = 2023
GROUP BY artist_name
ORDER BY song_count DESC
LIMIT 1;

/* 
Output: Morgan Wallen
Personally, I was a little shocked to not see Tyalor Swift rein the charts this year during her Eras tour, but it appears another country singer managed to win even more crowds than her. Bravo!
*/

-- Quesiton two:  What is the average number of streams for songs released in each month of 2023?

SELECT
released_month
, ROUND(AVG(streams),2) as avg_streams
FROM emilio-playground.raw.top_spotify_songs_2023
WHERE released_year = 2023
GROUP BY released_month
ORDER BY released_month;

/* 
Output: 
January: 287635463.79 streams
February: 231191625.48 streams
March: 170092261.59 streams
April: 150805435.90 streams
May: 94420746.38 streams
June: 70200253.44 streams
July: 41504665.57 streams

Unsurprisingly, January is the month with the highest number of streams, as many festivities continue into the month of January. However, I imagine as the year progresses that the streams will rise around 
the holidays in 2023 as well.
*/

-- Quesiton three:  Are songs with higher danceability percentages generally more popular (i.e. have more streams)?

SELECT
CASE
WHEN danceability <= 25 THEN '0-25%'
WHEN danceability <= 50 THEN '26-50%'
WHEN danceability <= 75 THEN '51-75%'
ELSE '76-100%'
END AS danceability_group,
AVG(SAFE_CAST(streams AS INT64)) as avg_streams
FROM emilio-playground.raw.top_spotify_songs_2023
GROUP BY danceability_group
ORDER BY avg_streams DESC;

/*
Output: The danceability percentage with the most streams is between 26-50%. However, there does need seem to be a correlation between danceability percemtage and streams.

26-50%: 626777453.61
51-75%: 520031631.98
76-100%: 455962557.01
0-25%: 452250817.67
*/


-- Question four: What percentage of songs in the 'Top Spotify Songs 2023' were actually released in 2023?

WITH SongCounts AS 
(SELECT
COUNT(*) AS total_count,
SUM(CASE WHEN released_year = 2023 THEN 1 ELSE 0 END) AS count_2023
FROM emilio-playground.raw.top_spotify_songs_2023)
SELECT
(count_2023 * 100.0 / total_count) AS percentage_released_in_2023
FROM SongCounts;

/*

Output: only 18% of songs were actually released in the year 2023. This is once again unsurprising as many popular playlists include throwback songs, 
and superfans will continue to listen to their favourite artists old songs


-- Step three: Conclusions
Firstly, this dataset shows that the country singer Morgan Wallen is the artist with the most songs to make the top streamed list, with 8 of his songs from his newest album making the charts. 
Secondly, Janaury is the month with the most streams so far this year.
Thirdly, danceability does not correlate to the popularity of a song, but 26-50% danceability did have the most streams.
Finally, only 18% of the top songs of 2023 were actually released in 2023.

Thank you for reading my first SQL project, I appreciate it!
