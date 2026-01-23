SELECT * FROM nba_player_stats.all_players;
/*Sections 1 : Player Performance Analysis
========================================================
Rank players in each season by points, rebounds, assists per game.

Identify most improved players across seasons (biggest jump in points/rebounds/assists).
*/

-- Rank players in each season by points, rebounds, assists per game.
SELECT * 
FROM(
     SELECT player_name,
			pts, season,
			RANK() OVER(PARTITION BY season ORDER BY pts DESC) AS pts_rank
	 FROM all_players) AS pts_rank
WHERE pts_rank <= 10;
-- The result as Points_Rank
SELECT * 
FROM(
     SELECT player_name,
			reb, season,
			RANK() OVER(PARTITION BY season ORDER BY reb DESC) AS reb_rank
	 FROM all_players) AS reb_rank
WHERE reb_rank <= 10;
-- The result as Rbounds_Rank
SELECT * 
FROM(
     SELECT player_name,
			ast, season,
			RANK() OVER(PARTITION BY season ORDER BY ast DESC) AS ast_rank
	 FROM all_players) AS ast_rank
WHERE ast_rank <= 10;
-- The result as Assists_Rank

-- Identify most improved players across seasons (biggest jump in points/rebounds/assists).
-- The most improved player in points  
SELECT *
FROM (
	SELECT season, player_name,
		   ROUND(pts_next_season - pts_previous_season,2) AS pts_improvments,
		   RANK() OVER(PARTITION BY season ORDER BY ROUND(pts_next_season - pts_previous_season,2) DESC) AS rank_improvment
	FROM(
		SELECT player_name,
			   season, pts AS pts_previous_season,
			   LAG(pts) OVER(PARTITION BY player_name ORDER BY season) AS pts_next_season
			FROM all_players
		 ) AS pts_improvment
	WHERE pts_next_season IS NOT NULL
      )   AS rank_improvments
WHERE rank_improvment = 1 ;

-- The most improved player in rebounds
SELECT *
FROM (
	SELECT season, player_name,
		   ROUND(reb_next_season - reb_previous_season,2) AS reb_improvments,
		   RANK() OVER(PARTITION BY season ORDER BY ROUND(reb_next_season - reb_previous_season,2) DESC) AS rank_improvment
	FROM(
		SELECT player_name,
			   season, reb AS reb_previous_season,
			   LAG(reb) OVER(PARTITION BY player_name ORDER BY season) AS reb_next_season
			FROM all_players
		 ) AS reb_improvment
	WHERE reb_next_season IS NOT NULL
      )   AS rank_improvments
WHERE rank_improvment = 1 ;

-- The most improved player in assists
SELECT *
FROM (
	SELECT season, player_name,
		   ROUND(ast_next_season - ast_previous_season,2) AS reb_improvments,
		   RANK() OVER(PARTITION BY season ORDER BY ROUND(ast_next_season - ast_previous_season,2) DESC) AS rank_improvment
	FROM(
		SELECT player_name,
			   season, ast AS ast_previous_season,
			   LAG(ast) OVER(PARTITION BY player_name ORDER BY season) AS ast_next_season
			FROM all_players
		 ) AS ast_improvment
	WHERE ast_next_season IS NOT NULL
      )   AS rank_improvments
WHERE rank_improvment = 1 ;

/* Section 2 : Era & Team Comparisons
=============================================================================
Compare average player size (height/weight) between 1990s, 2000s, 2010s, and 2020s.

Identify which teams consistently produce top-performing players.

Look at rookies vs veterans - how do their contributions differ?
*/

-- Compare average player size (height/weight) between 1990s, 2000s, 2010s, and 2020s
ALTER TABLE all_players
ADD COLUMN decade VARCHAR(50) AFTER season;

UPDATE all_players
SET decade = substring(season,3,1);

ALTER TABLE all_players
ADD COLUMN era VARCHAR(50) AFTER decade;

UPDATE all_players
SET era = CASE
    WHEN decade = 9 THEN '1990s'
    WHEN decade = 0 THEN '2000s'
    WHEN decade = 1 THEN '2010s'
    WHEN decade = 2 THEN '2020s'
END;

SELECT era,
       ROUND(AVG(player_height),2) AS avg_height,
       ROUND(AVG(player_weight),2) AS avg_weight
FROM all_players
GROUP BY era;
/*
In 1990s the player average height is 200.86 centimeters, and the average weight is 100.54 kg;
In 2000s the player average height is 201.04 centimeters, and the average weight is 101.36 kg;
In 1990s the player average height is 200.6 centimeters, and the average weight is 100.01 kg;
In 1990s the player average height is 198.82 centimeters, and the average weight is 97.78 kg.
*/

-- Identify which teams consistently produce top-performing players.
SELECT team_abbreviation,
       count(team_abbreviation) AS top_players_count
FROM(
		SELECT season,
			   player_name,
			   team_abbreviation,
               net_rating,
			   RANK() OVER(PARTITION BY season ORDER BY net_rating DESC) AS rank_performance
		FROM all_players
	) AS rank_performance
WHERE rank_performance <= 5
GROUP BY team_abbreviation
ORDER BY top_players_count DESC
;
/*
The teams which consistently produce top players are : MIA(11 players), CLE(8 players), MEM(8 players),
POR(7 players), CHI(6 players).
*/

-- Look at rookies vs veterans - how do their contributions differ?
ALTER TABLE all_players
ADD COLUMN playing_year VARCHAR(50) AFTER season;

UPDATE all_players
SET playing_year = substring_index(season,'-',1);

SELECT ROUND(AVG(pts),2) AS rookie_avg_pts,
       ROUND(AVG(reb),2) AS rookie_avg_reb,
       ROUND(AVG(ast),2) AS rookie_avg_ast
FROM all_players
WHERE draft_year = playing_year;

SELECT ROUND(AVG(pts),2) AS veteran_avg_pts,
       ROUND(AVG(reb),2) AS veteran_avg_reb,
       ROUND(AVG(ast),2) AS veteran_avg_ast
FROM all_players
WHERE draft_year != playing_year;
/*
The rookies' contributions are : average points 5.68, average rebounds 2.59, average assists 1.2;
The veteran's contributions are : average points 8.48, average rebounds 3.66, average assists 1.89.
*/

