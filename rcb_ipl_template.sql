/* =====================================================================
   RCB IPL STRATEGY — STUDENT ANSWER TEMPLATE
   SUBMISSION BY : SURENDRA SINGH JODHA
   PROJECT : IPL STRATEGY FOR RCB
   BATCH DATA SCIENCE COURCE MAY 2026
   ===================================================================== */

USE ipl;


/* =====================================================================
   OBJECTIVE QUESTIONS
   ===================================================================== */

-- O1
-- List the different dtypes of columns in table "ball_by_ball" (using
-- information schema)

SELECT 
    column_name, 
    Data_type
FROM 
    information_schema.columns
WHERE 
    table_name = 'ball_by_ball';

-- O2
-- What is the total number of runs scored in 1st season by RCB (bonus: also
-- include the extra runs using the extra runs table)

SELECT 
    SUM(bs.Runs_Scored) AS bat_runs,
    COALESCE(SUM(er.Extra_Runs), 0) AS extra_runs,
    SUM(bs.Runs_Scored) + COALESCE(SUM(er.Extra_Runs), 0) AS total_with_extras
FROM Matches m
JOIN Ball_by_Ball b ON m.Match_Id = b.Match_Id
JOIN Team t ON b.Team_Batting = t.Team_Id
LEFT JOIN Batsman_Scored bs 
    ON b.Match_Id = bs.Match_Id 
   AND b.Over_Id = bs.Over_Id 
   AND b.Ball_Id = bs.Ball_Id 
   AND b.Innings_No = bs.Innings_No
LEFT JOIN Extra_Runs er 
    ON b.Match_Id = er.Match_Id 
   AND b.Over_Id = er.Over_Id 
   AND b.Ball_Id = er.Ball_Id 
   AND b.Innings_No = er.Innings_No
WHERE m.Season_Id = 1 
  AND t.Team_Name = 'Royal Challengers Bangalore';

-- O3
-- How many players were more than the age of 25 during season 2014?

SELECT 
    COUNT(DISTINCT pm.Player_Id) AS players_over_25_in_2014
FROM Player_Match pm
JOIN Matches m ON pm.Match_Id = m.Match_Id
JOIN Player p ON pm.Player_Id = p.Player_Id
WHERE m.Match_Date LIKE '2014%' 
  AND TIMESTAMPDIFF(YEAR, p.DOB, m.Match_Date) > 25;

-- O4
-- How many matches did RCB win in 2013?

SELECT COUNT(*) AS rcb_wins_2013
FROM Matches m
JOIN Team t ON m.Match_Winner = t.Team_Id
WHERE YEAR(m.Match_Date) = 2013
  AND t.Team_Name = 'Royal Challengers Bangalore';

-- O5
-- List the top 10 players according to their strike rate in the last 4
-- seasons

SELECT
    p.Player_Name,
    SUM(bs.Runs_Scored) AS runs,
    COUNT(*) AS balls_faced,
    ROUND(100.0 * SUM(bs.Runs_Scored) / NULLIF(COUNT(*),0), 2) AS strike_rate
FROM Ball_by_Ball bb
JOIN Batsman_Scored bs
  ON bb.Match_Id = bs.Match_Id
 AND bb.Over_Id = bs.Over_Id
 AND bb.Ball_Id = bs.Ball_Id
 AND bb.Innings_No = bs.Innings_No
JOIN Matches m ON bb.Match_Id = m.Match_Id
JOIN Player p ON bb.Striker = p.Player_Id
WHERE YEAR(m.Match_Date) BETWEEN 2013 AND 2016
GROUP BY p.Player_Id, p.Player_Name
ORDER BY strike_rate DESC
LIMIT 10;

-- O6
-- What are the average runs scored by each batsman considering all the
-- seasons?

WITH BatsmanStats AS (
    SELECT 
        b.Striker AS Player_Id,
        SUM(bs.Runs_Scored) AS total_runs,
        COUNT(DISTINCT b.Match_Id) AS matches
    FROM Ball_by_Ball b
    JOIN Batsman_Scored bs 
        ON b.Match_Id = bs.Match_Id 
       AND b.Over_Id = bs.Over_Id 
		   AND b.Ball_Id = bs.Ball_Id 
		   AND b.Innings_No = bs.Innings_No
		GROUP BY b.Striker
	)
	SELECT 
    p.Player_Name,
    bs.total_runs,
    bs.matches,
    ROUND(bs.total_runs / bs.matches, 2) AS avg_runs_per_match
FROM BatsmanStats bs
JOIN Player p ON bs.Player_Id = p.Player_Id
ORDER BY avg_runs_per_match DESC;

-- O7
-- What are the average wickets taken by each bowler considering all the
-- seasons?

SELECT
    p.Player_Name,
    COUNT(*) AS total_wickets,
    COUNT(DISTINCT bb.Match_Id) AS matches,
    ROUND(COUNT(*) /
          NULLIF(COUNT(DISTINCT bb.Match_Id),0), 2) AS avg_wickets_per_match
FROM Wicket_Taken wt
JOIN Ball_by_Ball bb
  ON wt.Match_Id = bb.Match_Id
 AND wt.Over_Id = bb.Over_Id
 AND wt.Ball_Id = bb.Ball_Id
 AND wt.Innings_No = bb.Innings_No
JOIN Matches m ON wt.Match_Id = m.Match_Id
JOIN Player p ON bb.Bowler = p.Player_Id
WHERE YEAR(m.Match_Date) BETWEEN 2013 AND 2016
  AND wt.Kind_Out NOT IN (3,5,9)
GROUP BY p.Player_Id, p.Player_Name
ORDER BY total_wickets DESC;

-- O8
-- List all the players who have average runs scored greater than the overall
-- average and who have taken wickets greater than the overall average

WITH batting AS (
    SELECT p.Player_Id, p.Player_Name,
           SUM(bs.Runs_Scored) / NULLIF(COUNT(DISTINCT bb.Match_Id),0) AS avg_runs
    FROM Ball_by_Ball bb
    JOIN Batsman_Scored bs
      ON bb.Match_Id=bs.Match_Id AND bb.Over_Id=bs.Over_Id
     AND bb.Ball_Id=bs.Ball_Id AND bb.Innings_No=bs.Innings_No
    JOIN Matches m ON bb.Match_Id=m.Match_Id
    JOIN Player p ON bb.Striker=p.Player_Id
    WHERE YEAR(m.Match_Date) BETWEEN 2013 AND 2016
    GROUP BY p.Player_Id, p.Player_Name
),
bowling AS (
    SELECT p.Player_Id,
           COUNT(*) / NULLIF(COUNT(DISTINCT bb.Match_Id),0) AS avg_wkts
    FROM Wicket_Taken wt
    JOIN Ball_by_Ball bb
      ON wt.Match_Id=bb.Match_Id AND wt.Over_Id=bb.Over_Id
     AND wt.Ball_Id=bb.Ball_Id AND wt.Innings_No=bb.Innings_No
    JOIN Matches m ON wt.Match_Id=m.Match_Id
    JOIN Player p ON bb.Bowler=p.Player_Id
    WHERE YEAR(m.Match_Date) BETWEEN 2013 AND 2016
      AND wt.Kind_Out NOT IN (3,5,9)
    GROUP BY p.Player_Id
),
overall AS (
    SELECT (SELECT AVG(avg_runs) FROM batting) AS overall_avg_runs,
           (SELECT AVG(avg_wkts) FROM bowling) AS overall_avg_wkts
)
SELECT b.Player_Name, ROUND(b.avg_runs,2) AS avg_runs,
       ROUND(w.avg_wkts,2) AS avg_wkts
FROM batting b
JOIN bowling w ON b.Player_Id=w.Player_Id
CROSS JOIN overall o
WHERE b.avg_runs > o.overall_avg_runs
  AND w.avg_wkts > o.overall_avg_wkts
ORDER BY b.avg_runs DESC;

-- O9
-- Create a table rcb_record table that shows the wins and losses of RCB in an
-- individual venue.

CREATE TABLE rcb_record AS

SELECT

    m.Venue_Id,
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner=2 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN m.Match_Winner IS NOT NULL
              AND m.Match_Winner<>2 THEN 1 ELSE 0 END) AS losses
FROM Matches m
JOIN Venue v ON m.Venue_Id=v.Venue_Id
WHERE (m.Team_1=2 OR m.Team_2=2)
  AND YEAR(m.Match_Date) BETWEEN 2013 AND 2016
GROUP BY m.Venue_Id, v.Venue_Name;
SELECT * FROM rcb_record ORDER BY Venue_Id;

-- O10
-- What is the impact of bowling style on wickets taken?

SELECT bs.Bowling_skill, COUNT(wt.Player_Out) AS Wickets_Taken
FROM player p
INNER JOIN bowling_style bs ON p.Bowling_skill = bs.Bowling_Id
INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Bowler
INNER JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id
AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
GROUP BY bs.Bowling_skill
ORDER BY Wickets_Taken DESC;

-- O11
-- Write the SQL query to provide a status of whether the performance of the
-- team is better than the previous year's performance on the basis of the
-- number of runs scored by the team in the season and the number of
-- wickets taken

WITH season_runs AS (
    SELECT YEAR(m.Match_Date) Season_Year, SUM(bs.Runs_Scored) runs
    FROM Ball_by_Ball bb
    JOIN Batsman_Scored bs ON bb.Match_Id=bs.Match_Id
      AND bb.Over_Id=bs.Over_Id AND bb.Ball_Id=bs.Ball_Id
      AND bb.Innings_No=bs.Innings_No
    JOIN Matches m ON bb.Match_Id=m.Match_Id
    WHERE bb.Team_Batting=2 AND YEAR(m.Match_Date) BETWEEN 2013 AND 2016
    GROUP BY YEAR(m.Match_Date)
),
season_wkts AS (
    SELECT YEAR(m.Match_Date) Season_Year, COUNT(*) wkts
    FROM Wicket_Taken wt
    JOIN Ball_by_Ball bb ON wt.Match_Id=bb.Match_Id
      AND wt.Over_Id=bb.Over_Id AND wt.Ball_Id=bb.Ball_Id
      AND wt.Innings_No=bb.Innings_No
    JOIN Matches m ON wt.Match_Id=m.Match_Id
    WHERE bb.Team_Bowling=2 AND YEAR(m.Match_Date) BETWEEN 2013 AND 2016
      AND wt.Kind_Out NOT IN (3,5,9)
    GROUP BY YEAR(m.Match_Date)
),
x AS (
    SELECT r.Season_Year, r.runs, w.wkts
    FROM season_runs r JOIN season_wkts w ON r.Season_Year=w.Season_Year
),
c AS (
    SELECT Season_Year, runs, wkts,
           runs-LAG(runs) OVER(ORDER BY Season_Year) runs_vs_prev,
           wkts-LAG(wkts) OVER(ORDER BY Season_Year) wkts_vs_prev
    FROM x
)
SELECT Season_Year, runs, wkts, runs_vs_prev, wkts_vs_prev,
       CASE
         WHEN runs_vs_prev IS NULL THEN 'N/A'
         WHEN runs_vs_prev>0 AND wkts_vs_prev>0 THEN 'Better'
         WHEN runs_vs_prev<0 AND wkts_vs_prev<0 THEN 'Worse'
         ELSE 'Mixed'
       END performance_status
FROM c
ORDER BY Season_Year;

-- O12
-- Can you derive more KPIs for the team strategy?

SELECT 
    s.Season_Year,
    COUNT(m.Match_Id) AS played,
    SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS wins,
    ROUND(SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) * 100.0 / COUNT(m.Match_Id), 2) AS win_pct
FROM Matches m
JOIN Season s ON m.Season_Id = s.Season_Id
JOIN Team t ON t.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id
GROUP BY s.Season_Year;

SELECT 
    ROUND(
        SUM(CASE WHEN bs.Runs_Scored IN (4, 6) THEN bs.Runs_Scored ELSE 0 END) * 100.0 / SUM(bs.Runs_Scored), 
        2
    ) AS pct_runs_from_boundaries
FROM Ball_by_Ball b
JOIN Batsman_Scored bs ON b.Match_Id = bs.Match_Id AND b.Over_Id = bs.Over_Id AND b.Ball_Id = bs.Ball_Id AND b.Innings_No = bs.Innings_No
JOIN Team t ON b.Team_Batting = t.Team_Id
WHERE t.Team_Name = 'Royal Challengers Bangalore';

SELECT 
    p.Player_Name,
    SUM(bs.Runs_Scored) AS runs
FROM Ball_by_Ball b
JOIN Batsman_Scored bs ON b.Match_Id = bs.Match_Id AND b.Over_Id = bs.Over_Id AND b.Ball_Id = bs.Ball_Id AND b.Innings_No = bs.Innings_No
JOIN Team t ON b.Team_Batting = t.Team_Id
JOIN Player p ON b.Striker = p.Player_Id
WHERE t.Team_Name = 'Royal Challengers Bangalore'
GROUP BY p.Player_Id, p.Player_Name
ORDER BY runs DESC
LIMIT 5;

-- O13
-- Using SQL, write a query to find out the average wickets taken by each
-- bowler in each venue. Also, rank the gender according to the average
-- value.

WITH each_venue_BowlerWickets AS (
    SELECT bb.Bowler, p.Player_Name, v.venue_name,
           COUNT(DISTINCT bb.Match_Id, bb.Over_Id, bb.Ball_Id, bb.Innings_No) AS Total_Wickets,
           COUNT(DISTINCT bb.Match_Id, bb.Innings_No) AS Matches_Played
    FROM player p
    JOIN player_match pm ON p.Player_Id = pm.Player_Id
    JOIN matches m ON pm.Match_Id = m.Match_Id
    JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Bowler
    JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id
                        AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY bb.Bowler, p.Player_Name, v.Venue_Name
)
SELECT Bowler AS Player_Id, Player_Name, Venue_Name,
       ROUND(Total_Wickets / Matches_Played, 1) AS Average_Wickets,
       DENSE_RANK() OVER (ORDER BY ROUND(Total_Wickets / Matches_Played, 1) DESC) AS 'Rank'
FROM each_venue_BowlerWickets
ORDER BY Average_Wickets DESC, 'Rank' DESC;

-- O14
-- Which of the given players have consistently performed well in past
-- seasons? (will you use any visualization to solve the problem)

SELECT p.Player_Id,p.Player_Name,s.Season_Year,SUM(bs.Runs_Scored) AS Total_Runs
FROM player p
JOIN player_match pm ON p.Player_Id = pm.Player_Id
JOIN matches m ON pm.Match_Id = m.Match_Id
JOIN batsman_scored bs ON m.Match_Id = bs.Match_Id
JOIN season s ON m.Season_Id = s.Season_Id  -- Join with season table
WHERE pm.Role_Id = 1  -- Assuming Role_Id for batsmen is 1; adjust if necessary
GROUP BY p.Player_Id, p.Player_Name, s.Season_Year
ORDER BY p.Player_Name, s.Season_Year DESC;

-- O15
-- Are there players whose performance is more suited to specific venues or
-- conditions? (how would you present this using charts?)

SELECT p.Player_Name,v.Venue_Name,
       SUM(bs.Runs_Scored) runs,
       COUNT(*) balls,
       ROUND(100*SUM(bs.Runs_Scored)/NULLIF(COUNT(*),0),2) strike_rate
FROM Ball_by_Ball bb
JOIN Batsman_Scored bs ON bb.Match_Id=bs.Match_Id
 AND bb.Over_Id=bs.Over_Id AND bb.Ball_Id=bs.Ball_Id
 AND bb.Innings_No=bs.Innings_No
JOIN Matches m ON bb.Match_Id=m.Match_Id
JOIN Player p ON bb.Striker=p.Player_Id
JOIN Venue v ON m.Venue_Id=v.Venue_Id
WHERE YEAR(m.Match_Date) BETWEEN 2013 AND 2016
GROUP BY p.Player_Id,p.Player_Name,v.Venue_Id,v.Venue_Name
HAVING COUNT(*)>=60
ORDER BY strike_rate DESC
LIMIT 25;


/* =====================================================================
   SUBJECTIVE QUESTIONS
   ===================================================================== */

-- S1
-- How does the toss decision affect the result of the match? (which
-- visualizations could be used to present your answer better) And is the
-- impact limited to only specific venues?

SELECT 
    CASE 
        WHEN Toss_Winner = Match_Winner THEN 'Toss Won & Match Won'
        ELSE 'Toss Won but Match Lost'
    END AS Toss_Impact,
    COUNT(*) AS Match_Count
FROM matches
WHERE Outcome_type = 1
GROUP BY Toss_Impact;

--------------

WITH match_winner_count AS (
    SELECT toss_winner, COUNT(*) AS match_win_count
    FROM matches
    WHERE toss_winner = match_winner
    GROUP BY toss_winner
    ORDER BY match_win_count DESC
),
toss_winner_count AS (
    SELECT toss_winner, COUNT(*) AS total_toss_win_count
    FROM matches
    GROUP BY toss_winner
)
SELECT t.team_name, mwc.match_win_count, twc.total_toss_win_count,
       ROUND((mwc.match_win_count / twc.total_toss_win_count) * 100, 1) AS toss_win_match_win_percentage
FROM match_winner_count mwc
JOIN toss_winner_count twc ON mwc.toss_winner = twc.toss_winner
JOIN team t ON mwc.toss_winner = t.team_id
ORDER BY toss_win_match_win_percentage DESC;

------------

WITH Toss_Win_Stats AS (
    SELECT v.Venue_Name, td.Toss_Name AS Toss_Decision, COUNT(*) AS Total_Matches,
           SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS Matches_Won_After_Toss,
           (SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY v.Venue_Name, td.Toss_Name
)
SELECT Venue_Name, Toss_Decision, Total_Matches, Matches_Won_After_Toss, Win_Percentage
FROM Toss_Win_Stats
WHERE Total_Matches >= 10;

-- S2
-- Suggest some of the players who would be best fit for the team.

--- Top 5 score rank in each season--players and number of times they are in the top 5 in the last 3 seasons.----

WITH player_match_runs AS (
    SELECT 
        bb.match_id, 
        bb.striker, 
        SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball bb
    JOIN batsman_scored bs 
      ON bb.match_id = bs.match_id 
     AND bb.innings_no = bs.innings_no 
     AND bb.over_id = bs.over_id 
     AND bb.ball_id = bs.ball_id
    GROUP BY bb.match_id, bb.striker
),
result AS (
    SELECT 
        pmr.striker AS player_id, 
        s.season_year, 
        SUM(pmr.total_runs) AS runs_scored,
        DENSE_RANK() OVER (PARTITION BY s.season_year ORDER BY SUM(pmr.total_runs) DESC) AS season_runs_rank
    FROM player_match_runs pmr
    JOIN matches m ON pmr.match_id = m.match_id
    JOIN season s ON m.season_id = s.season_id
    GROUP BY pmr.striker, s.season_year
),
top_run_player AS (
    SELECT * 
    FROM result
    WHERE season_runs_rank BETWEEN 1 AND 5 
      AND season_year BETWEEN 2014 AND 2016
)
SELECT 
    trp.player_id, 
    p.player_name, 
    COUNT(trp.player_id) AS no_of_times_in_top5
FROM top_run_player trp
JOIN player p ON trp.player_id = p.player_id
GROUP BY trp.player_id, p.player_name
ORDER BY no_of_times_in_top5 DESC
LIMIT 10;

------------ Top 10 players with the highest strike rate and minimum 1500 runs scored.------

with runs_scored as (
    select bb.striker, p.player_name, sum(bs.runs_scored) as total_runs
    from player p 
    join player_match pm on p.player_id = pm.player_id
    join ball_by_ball bb on pm.player_id = bb.striker and pm.match_id = bb.match_id
    join batsman_scored bs on bb.match_id = bs.match_id 
                          and bb.over_id = bs.over_id 
                          and bb.ball_id = bs.ball_id
    group by bb.striker, p.player_name 
    having sum(bs.runs_scored) >= 1500
),
balls_faced as (
    select bb.striker, p.player_name, count(bs.runs_scored) as total_ball_faced
    from player p 
    join player_match pm on p.player_id = pm.player_id
    join ball_by_ball bb on pm.player_id = bb.striker and pm.match_id = bb.match_id
    join batsman_scored bs on bb.match_id = bs.match_id 
                          and bb.over_id = bs.over_id 
                          and bb.ball_id = bs.ball_id
    group by bb.striker, p.player_name 
)
select rs.striker as player_id, 
       rs.player_name, 
       rs.total_runs, 
       bf.total_ball_faced, 
       (rs.total_runs * 100.0 / bf.total_ball_faced) as strike_rate
from runs_scored rs 
join balls_faced bf on rs.striker = bf.striker
order by strike_rate desc
limit 10;

------ Top 10 bowlers taken highest wicket.-------

select bb.bowler,p.player_name,count(wt.player_out) as number_of_wickets
from player p join player_match pm on p.player_id=pm.player_id
join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id
join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
                    and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
group by bb. bowler,p.player_name order by number_of_wickets desc
limit 10;

-------	Top 10 bowlers with best economy, minimum 100 overs bowled.-------

WITH total_runs_conceded AS (
    SELECT 
        bb.bowler AS player_id, 
        p.player_name, 
        SUM(bs.runs_scored) AS runs_conceded
    FROM player p 
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.player_id = bb.bowler AND pm.match_id = bb.match_id
    JOIN batsman_scored bs ON bb.match_id = bs.match_id 
                          AND bb.innings_no = bs.innings_no 
                          AND bb.over_id = bs.over_id 
                          AND bb.ball_id = bs.ball_id
    GROUP BY bb.bowler, p.player_name
),
total_overs_bowled AS (
    SELECT 
        bb.bowler AS player_id, 
        COUNT(DISTINCT bb.match_id, bb.innings_no, bb.over_id) AS total_overs
    FROM player p 
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.player_id = bb.bowler AND pm.match_id = bb.match_id
    GROUP BY bb.bowler
)
SELECT 
    trc.*, 
    tob.total_overs, 
    (trc.runs_conceded / tob.total_overs) AS economy
FROM total_runs_conceded trc 
JOIN total_overs_bowled tob ON trc.player_id = tob.player_id
WHERE tob.total_overs > 100
ORDER BY economy 
LIMIT 10;


-- S3
-- What are some of the parameters that should be focused on while selecting
-- the players?



-- S4
-- Which players offer versatility in their skills and can contribute
-- effectively with both bat and ball? (can you visualize the data for the
-- same)

WITH top_bowler AS (
    SELECT bb.bowler, p.player_name, COUNT(wt.player_out) AS number_of_wickets
    FROM player p
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.player_id = bb.bowler AND pm.match_id = bb.match_id
    JOIN wicket_taken wt ON bb.match_id = wt.match_id 
                        AND bb.over_id = wt.over_id 
                        AND bb.ball_id = wt.ball_id 
                        AND bb.innings_no = wt.innings_no
    GROUP BY bb.bowler, p.player_name
), 
top_batsman AS (
    SELECT bb.striker, p.player_name, SUM(bs.runs_scored) AS total_runs
    FROM player p
    JOIN player_match pm ON p.player_id = pm.player_id
    -- Properly bring in ball_by_ball to connect the player to their runs
    JOIN ball_by_ball bb ON pm.player_id = bb.striker AND pm.match_id = bb.match_id
    JOIN batsman_scored bs ON bb.match_id = bs.match_id 
                          AND bb.over_id = bs.over_id 
                          AND bb.ball_id = bs.ball_id 
                          AND bb.innings_no = bs.innings_no
    GROUP BY bb.striker, p.player_name
)
SELECT tb.bowler AS player_id, tb.player_name, tb.number_of_wickets, tbs.total_runs
FROM top_bowler tb
JOIN top_batsman tbs ON tb.bowler = tbs.striker
WHERE tb.number_of_wickets >= 12 AND tbs.total_runs > 500;

-- S5
-- Are there players whose presence positively influences the morale and
-- performance of the team? (justify your answer using visualization)


------- Man of the Match as a Morale Indicator----

SELECT  p.Player_Name,
        COUNT(m.Man_of_the_Match) AS MOTM_Count
FROM matches m
JOIN player p ON m.Man_of_the_Match=p.Player_Id
GROUP BY p.Player_Name
ORDER BY MOTM_Count DESC;

------- Performance Comparison---

SELECT 
    p.Player_Name,
    SUM(CASE WHEN m.Outcome_type=1 THEN bs.Runs_Scored ELSE 0 END) AS Runs_in_Wins,
    SUM(CASE WHEN m.Outcome_type<>1 THEN bs.Runs_Scored ELSE 0 END) AS Runs_in_Losses
FROM batsman_scored bs
JOIN matches m ON bs.Match_Id=m.Match_Id
JOIN player p ON bs.over_id=p.Player_Id
GROUP BY p.Player_Name
HAVING Runs_in_Wins > Runs_in_Losses
ORDER BY Runs_in_Wins DESC;


-- S6
-- What would you suggest to RCB before going to the mega auction?

----- Man of the Match from RCB---

SELECT 
    p.Player_Name,
    COUNT(m.Man_of_the_Match) AS MOTM_Count
FROM matches m
JOIN player p ON m.Man_of_the_Match = p.Player_Id
JOIN team t ON m.Match_Winner = t.Team_Id
WHERE t.Team_Name = 'Royal Challengers Bangalore'
GROUP BY p.Player_Name
ORDER BY MOTM_Count DESC;

----- Performance in Winning Matches ----

SELECT 
    p.Player_Name,
    SUM(bs.Runs_Scored) AS Runs_in_wins,
    COUNT(DISTINCT m.Match_Id) AS Matches_Won
FROM batsman_scored bs
JOIN matches m 
    ON bs.Match_Id = m.Match_Id
JOIN ball_by_ball bb 
    ON bb.match_id = bs.match_id 
    AND bb.over_id = bs.over_id 
    AND bb.ball_id = bs.ball_id
JOIN player p 
    ON bb.striker = p.Player_Id -- Replace 'striker' with your actual column name for the batsman
WHERE 
    m.Outcome_type = 1 
    AND bb.Team_Batting <> (
        SELECT Team_Id FROM team WHERE Team_Name = 'Royal Challengers Bangalore'
    )
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT m.Match_Id) >= 20
ORDER BY Runs_in_wins DESC
LIMIT 10;

-- S7
-- What do you think could be the factors contributing to the high-scoring
-- matches and the impact on viewership and team strategies

SELECT 
    v.Venue_Name,
    ROUND(SUM(bs.Runs_Scored)/COUNT(bs.Ball_Id),2) AS Avg_Runs_Per_Ball
FROM batsman_scored bs
JOIN matches m ON bs.Match_Id=m.Match_Id
JOIN venue v ON m.Venue_Id=v.Venue_Id
GROUP BY v.Venue_Name
ORDER BY Avg_Runs_Per_Ball DESC;

-------


WITH match_scores AS (
    SELECT m.match_id, v.venue_name, SUM(bs.runs_scored) AS total_runs,
        COUNT(CASE WHEN bs.runs_scored = 4 THEN 1 END) AS total_fours,
        COUNT(CASE WHEN bs.runs_scored = 6 THEN 1 END) AS total_sixes
    FROM matches m
    JOIN batsman_scored bs ON m.match_id = bs.match_id
    JOIN venue v ON m.venue_id = v.venue_id
    GROUP BY m.match_id, v.venue_name ),
venue_analysis AS (
    SELECT venue_name, COUNT(match_id) AS total_matches, AVG(total_runs) AS avg_runs_per_match,
        SUM(total_fours) AS total_fours_hit,
        SUM(total_sixes) AS total_sixes_hit
    FROM match_scores
    GROUP BY venue_name )
SELECT venue_name, total_matches, avg_runs_per_match, total_fours_hit, total_sixes_hit
FROM venue_analysis
ORDER BY avg_runs_per_match DESC
LIMIT 10;

-- S8
-- Analyze the impact of home-ground advantage on team performance and
-- identify strategies to maximize this advantage for RCB.

WITH total_win_venue AS (
    SELECT m.venue_id, v.venue_name, COUNT(*) AS total_win
    FROM matches m
    JOIN venue v ON m.venue_id = v.venue_id
    JOIN team t ON t.team_id = m.match_winner
    WHERE t.team_name = 'Royal Challengers Bangalore'
    GROUP BY m.venue_id, v.venue_name
),
total_played_venue AS (
    SELECT venue_id, COUNT(*) AS total_played_matches
    FROM matches
    WHERE team_1 = '2' OR team_2 = '2'
    GROUP BY venue_id
)
SELECT twv.*, tpv.total_played_matches, (twv.total_win / tpv.total_played_matches) * 100 AS win_percentage
FROM total_win_venue twv
JOIN total_played_venue tpv ON twv.venue_id = tpv.venue_id
ORDER BY total_played_matches DESC;

-- S9
-- Come up with a visual and analytical analysis of the RCB's past season's
-- performance and potential reasons for them not winning a trophy.

WITH RCB_Performance AS (
    SELECT m.Season_Id, COUNT(m.Match_Id) AS Matches_Played,
        SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Matches_Won,
        SUM(CASE WHEN m.Match_Winner != t.Team_Id THEN 1 ELSE 0 END) AS Matches_Lost,
        (SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) / COUNT(m.Match_Id)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN team t ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    WHERE t.Team_Name = 'Royal Challengers Bangalore'
    GROUP BY m.Season_Id
)
SELECT s.Season_Year, rp.Matches_Played, rp.Matches_Won, rp.Matches_Lost, rp.Win_Percentage
FROM RCB_Performance rp
INNER JOIN season s ON rp.Season_Id = s.Season_Id
ORDER BY s.Season_Year;

-- S10
-- How would you approach this problem, if the objective and subjective
-- questions weren't given?



-- S11
-- In the "Match" table, some entries in the "Opponent_Team" column are
-- incorrectly spelled as "Delhi_Capitals" instead of "Delhi_Daredevils".
-- Write an SQL query to replace all occurrences of "Delhi_Capitals" with
-- "Delhi_Daredevils".-


SET SQL_SAFE_UPDATES = 0;

UPDATE team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Name = 'Delhi Capitals';

SET SQL_SAFE_UPDATES = 1; 

/* ===================================== END OF FILE ===================================== */
