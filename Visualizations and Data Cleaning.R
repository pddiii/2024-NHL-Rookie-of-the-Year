library(tidyverse)
library(ggplot2)
library(hockeyR)

# Load in the standings information for each team by season
# Standings are as of 01/30/2024
standings <- 
  read_csv('standings.csv') %>% 
  select(date, gamesPlayed, c(goalDifferential:homeWins),
         losses, otLosses, c(pointPctg:shootoutWins), teamAbbrev,
         ties, winPctg, wins) %>% 
  relocate(c(seasonId, teamAbbrev, points, wins),
           .before = date) %>% 
  mutate(teamAbbrev = str_replace(teamAbbrev, "^\\{'default':\\s", ""),
         teamAbbrev = str_extract(teamAbbrev, "[[:alpha:]]+"),
         teamAbbrev = as.factor(teamAbbrev),
         seasonId = as.factor(seasonId))


# Load in the forward info
for_info <- 
  read_csv('/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/Player Info/forwards.csv') %>% 
  select(-1)

for_info <- 
  for_info %>% 
  # Remove the "{'default': " at the beginning of the names
  mutate(firstName = str_replace(firstName, "^\\{'default':\\s", ""),
         lastName = str_replace(lastName, "^\\{'default':\\s", "")) %>% 
  # Extract only the names themselves (using alphabet characters)
  mutate(firstName = str_extract(firstName, "[[:alpha:]]+"),
         lastName = str_extract(lastName, "[[:alpha:]]+")) %>% 
  # Create a Name variable which contains the full name "firstName lastName" 
  # of a player
  mutate(Name = str_c(firstName, lastName, sep = " "), .before = firstName) %>%
  mutate(playerId = as.factor(id), .before = id) %>% 
  select(-firstName, -lastName, -id, -headshot)

# Load in the forwards game_log
for_game_log <- 
  read_csv('/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/STATS/Skaters/forwards_game_logs.csv')

for_game_log <- for_game_log %>% 
  select(-1, -commonName, -opponentCommonName) %>% # remove the index column
  # Move the seasonId and playerId variable to the front of data set
  relocate(c(seasonId, playerId), .before = "gameId") %>%
  relocate(opponentAbbrev, .after = "teamAbbrev") %>% 
  # Encode the "Id" variables as factors
  mutate(seasonId = as.factor(seasonId),
         playerId = as.factor(playerId),
         gameId = as.factor(gameId),
         games = rep(1, nrow(for_game_log))) 

# Load in the defensemen info
def_info <- 
  read_csv('Player Info/defensmen.csv') %>% 
  select(-1)

def_info <- 
  def_info %>% 
  # Remove the "{'default': " at the beginning of the names
  mutate(firstName = str_replace(firstName, "^\\{'default':\\s", ""),
         lastName = str_replace(lastName, "^\\{'default':\\s", "")) %>% 
  # Extract only the names themselves (using alphabet characters)
  mutate(firstName = str_extract(firstName, "[[:alpha:]]+"),
         lastName = str_extract(lastName, "[[:alpha:]]+")) %>% 
  # Create a Name variable which contains the full name "firstName lastName" 
  # of a player
  mutate(Name = str_c(firstName, lastName, sep = " "), .before = firstName) %>%
  mutate(playerId = as.factor(id), .before = id) %>% 
  select(-firstName, -lastName, -id, -headshot)

# Load in the defensemen game_log
def_game_log <- 
  read_csv('STATS/Skaters/defensemen_game_logs.csv')

def_game_log <- def_game_log %>% 
  select(-1, -commonName, -opponentCommonName) %>% # remove the index column
  # Move the seasonId and playerId variable to the front of data set
  relocate(c(seasonId, playerId), .before = "gameId") %>%
  relocate(opponentAbbrev, .after = "teamAbbrev") %>% 
  # Encode the "Id" variables as factors
  mutate(seasonId = as.factor(seasonId),
         playerId = as.factor(playerId),
         gameId = as.factor(gameId),
         games = rep(1, nrow(def_game_log))) 

# Create a dataframe of the skaters info
skaters_info <- 
  bind_rows(for_info, def_info) %>% 
  mutate(positionCode = as.factor(ifelse(
    positionCode == "L", "LW", # "LW" = "Left Wing"
    ifelse(positionCode == "R", "RW", positionCode) # "RW" = "Right Wing"
  )))

# Create a data frame for all Skaters (Forwards (Left Wing, Right Wing, Center), 
# and Defensemen)
skaters_game_log <- 
  bind_rows(for_game_log, def_game_log) %>% 
  mutate(toi = ((hour(toi) * 60) + minute(toi)) / 60 )

# Rookie season information
rookie_seasons <- 
  skaters_game_log %>% 
  group_by(playerId, seasonId) %>%
  summarise(gp_season = sum(games)) %>% # sum of games by season
  mutate(gp_career = cumsum(gp_season)) %>% # sum of career games
  filter(gp_career <= 82) %>% # Filter only the rookie seasons and stats
  ungroup() %>%               
  select(-gp_career)

# Rookie stats for the first 39 games since Connor Bedard has only played 39
# games as of the time writing this on 01/27/24
rookie_stats <- 
  skaters_game_log %>% 
  semi_join(rookie_seasons, by = c("playerId", "seasonId")) %>% 
  group_by(playerId, seasonId, teamAbbrev) %>%  
  summarise_if(is.numeric, sum) %>%  
  mutate(ppg = points / games, # points (goals + assists) per game
         gpg = goals / games, # goals per game
         apg = assists / games, # assists per game
         spg = shots / games, # shot attempts per game
         toi = toi / games) %>% 
  arrange(desc(points)) %>% 
  # Add the skater's names and positions to the dataframe
  inner_join(skaters_info %>% select(playerId, Name, positionCode), 
             by = "playerId") %>% 
  relocate(Name, .after = playerId) %>% 
  # Add the skater's team, team_points, and team_wins for their rookie season
  inner_join(standings %>% select(seasonId, teamAbbrev, points, wins), 
             by = c("seasonId", "teamAbbrev")) %>% 
  rename(points = points.x, # player points
         team_points = points.y,
         team_wins = wins) %>% 
  ungroup()

# Projected point total for Chicago Blackhawks as of 01/30/2024
rookie_stats[77, "team_points"] <- 49

# write_csv(rookie_stats, "rookie_stats.csv")

# Subset the rookie stats to those who have played at least 35 games
# Bedard has played 39 games
rookie_subset <-
  rookie_stats %>% 
  filter(games >= 35) %>% 
  arrange(desc(ppg)) %>%  
  group_by(seasonId) %>% 
  mutate(std_ppg = (ppg - mean(ppg)) / sd(ppg) ) %>% 
  ungroup() %>% 
  arrange(desc(std_ppg))

# write_csv(rookie_subset, "rookie_subset_stats.csv")

bedard_stats <- 
  rookie_subset %>% 
  filter(Name == "Connor Bedard")

# Points per Game Scatterplot
ppg_plot <-
  ggplot(rookie_stats %>% filter(games >= 35, ppg >= bedard_stats$ppg), 
         aes(x = team_points, y = ppg)) +
  geom_point() + 
  labs(title = "Scatterplot of PPG vs Team Points",
       x = "Team Standing points", y = "Points per Game (PPG)")

ppg_plot_w_names <- 
  ppg_plot +
  geom_point(data = subset(rookie_stats, Name == "Connor Bedard"),
             aes(color = "Connor Bedard")) +
  geom_point(data = subset(rookie_stats, Name == "Alex Ovechkin"),
             aes(color = "Alex Ovechkin")) +
  geom_point(data = subset(rookie_stats, Name == "Sidney Crosby"),
             aes(color = "Sidney Crosby")) +
  geom_point(data = subset(rookie_stats, Name == "Connor McDavid"),
             aes(color = "Connor McDavid")) +
  geom_point(data = subset(rookie_stats, Name == "Patrick Kane"),
             aes(color = "Patrick Kane")) +
  scale_color_manual(values = c("Connor Bedard" = "red", 
                                "Alex Ovechkin" = "blue", 
                                "Sidney Crosby" = "gold", 
                                "Connor McDavid" = "orange",
                                "Patrick Kane" = "green"),
                     name = "Player")

# Goals per Game Scatterplot
gpg_plot <-
  ggplot(rookie_stats %>% filter(games >= 35, gpg >= bedard_stats$gpg), 
         aes(x = team_points, y = gpg)) +
  geom_point() + 
  labs(title = "Scatterplot of GPG vs Team Points",
       x = "Team Standing Points", y = "Goals per Game (GPG)")

gpg_plot_w_names <- 
  gpg_plot +
  geom_point(data = subset(rookie_stats, Name == "Connor Bedard"),
             aes(color = "Connor Bedard")) +
  geom_point(data = subset(rookie_stats, Name == "Alex Ovechkin"),
             aes(color = "Alex Ovechkin")) +
  geom_point(data = subset(rookie_stats, Name == "Sidney Crosby"),
             aes(color = "Sidney Crosby")) +
  geom_point(data = subset(rookie_stats, Name == "Connor McDavid"),
             aes(color = "Connor McDavid")) +
  geom_point(data = subset(rookie_stats, Name == "Auston Matthews"),
             aes(color = "Auston Matthews")) +
  scale_color_manual(values = c("Connor Bedard" = "red", 
                                "Alex Ovechkin" = "blue", 
                                "Sidney Crosby" = "gold", 
                                "Connor McDavid" = "orange",
                                "Auston Matthews" = "green"),
                     name = "Player")

# Assists per Game Scatterplot
apg_plot <-
  ggplot(rookie_stats %>% filter(games >= 35, apg >= bedard_stats$apg), 
         aes(x = team_points, y = apg)) +
  geom_point() + 
  labs(title = "Scatterplot of APG vs Team Points",
       x = "Team Standing Points", y = "Assists per Game (APG)")

apg_plot_w_names <- 
  apg_plot +
  geom_point(data = subset(rookie_stats, Name == "Connor Bedard"),
             aes(color = "Connor Bedard")) +
  geom_point(data = subset(rookie_stats, Name == "Alex Ovechkin"),
             aes(color = "Alex Ovechkin")) +
  geom_point(data = subset(rookie_stats, Name == "Sidney Crosby"),
             aes(color = "Sidney Crosby")) +
  geom_point(data = subset(rookie_stats, Name == "Connor McDavid"),
             aes(color = "Connor McDavid")) +
  geom_point(data = subset(rookie_stats, Name == "Patrick Kane"),
             aes(color = "Patrick Kane")) +
  scale_color_manual(values = c("Connor Bedard" = "red", 
                                "Alex Ovechkin" = "blue", 
                                "Sidney Crosby" = "gold", 
                                "Connor McDavid" = "orange",
                                "Patrick Kane" = "green"),
                     name = "Player")

# Plus-Minus Scatterplot
pm_plot <-
  ggplot(rookie_stats %>% filter(games >= 35), 
         aes(x = team_points, y = plusMinus)) +
  geom_point() + 
  labs(title = "Scatterplot of PlusMinus vs Team Points",
       x = "Team Standing Points", y = "PlusMinus")

pm_plot_w_names <- 
  pm_plot +
  geom_point(data = subset(rookie_stats, Name == "Connor Bedard"),
             aes(color = "Connor Bedard")) +
  geom_point(data = subset(rookie_stats, Name == "Alex Ovechkin"),
             aes(color = "Alex Ovechkin")) +
  geom_point(data = subset(rookie_stats, Name == "Sidney Crosby"),
             aes(color = "Sidney Crosby")) +
  geom_point(data = subset(rookie_stats, Name == "Connor McDavid"),
             aes(color = "Connor McDavid")) +
  geom_point(data = subset(rookie_stats, Name == "Patrick Kane"),
             aes(color = "Patrick Kane")) +
  scale_color_manual(values = c("Connor Bedard" = "red", 
                                "Alex Ovechkin" = "blue", 
                                "Sidney Crosby" = "gold", 
                                "Connor McDavid" = "orange",
                                "Patrick Kane" = "green"),
                     name = "Player")

# Plot for time on ice (toi) per game
toi_plot <-
  ggplot(rookie_stats %>% filter(games >= 35, toi >= 15), 
         aes(x = toi, y = plusMinus)) +
  geom_point() + 
  labs(title = "Scatterplot of PlusMinus vs Time on Ice",
       x = "Time on Ice (toi)", y = "PlusMinus")

toi_plot_w_names <- 
  toi_plot +
  geom_point(data = subset(rookie_stats, Name == "Connor Bedard"),
             aes(color = "Connor Bedard")) +
  geom_point(data = subset(rookie_stats, Name == "Alex Ovechkin"),
             aes(color = "Alex Ovechkin")) +
  geom_point(data = subset(rookie_stats, Name == "Sidney Crosby"),
             aes(color = "Sidney Crosby")) +
  geom_point(data = subset(rookie_stats, Name == "Connor McDavid"),
             aes(color = "Connor McDavid")) +
  geom_point(data = subset(rookie_stats, Name == "Patrick Kane"),
             aes(color = "Patrick Kane")) +
  scale_color_manual(values = c("Connor Bedard" = "red", 
                                "Alex Ovechkin" = "blue", 
                                "Sidney Crosby" = "gold", 
                                "Connor McDavid" = "orange",
                                "Patrick Kane" = "green"),
                     name = "Player")

## Load Calder Candidate leaders as of 02/09/2023 game logs
## for EDA and Discussion Purposes

calder_odds <-
  data.frame(playerId = as.factor(c(8482079, 8482122, 8482684, 8484144, 8484166)),
             odds = c("+1200", "+350", "+750", "-190", "+1400"))
calder_odds <-
  calder_odds %>% 
  mutate(win_probability = round(ifelse(playerId == 8484144, abs(as.numeric(odds)) / (abs(as.numeric(odds)) + 100), 
                                      100 / (as.numeric(odds) + 100)), 4)) %>% 
  arrange(desc(win_probability))

calder_games <- read_csv("/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/STATS/Skaters/calder_candidates.csv")
calder_games <- 
  calder_games %>% 
  select(-1, -commonName, -opponentCommonName) %>% # remove the index column
  # Move the seasonId and playerId variable to the front of data set
  relocate(c(seasonId, playerId), .before = "gameId") %>%
  relocate(opponentAbbrev, .after = "teamAbbrev") %>% 
  # Encode the "Id" variables as factors
  mutate(seasonId = as.factor(seasonId),
         playerId = as.factor(playerId),
         gameId = as.factor(gameId),
         games = rep(1, nrow(calder_games))) 
# Stats for the Calder Candidates as of 02/09/2024
calder_stats <- 
  calder_games %>% 
  group_by(playerId) %>% 
  summarise_if(is.numeric, sum) %>% 
  inner_join(skaters_info %>% select(playerId, Name), by = "playerId") %>% 
  inner_join(calder_odds, by = "playerId") %>% 
  relocate(Name, .after = playerId) %>% 
  arrange(desc(win_probability)) %>% 
  mutate(gpg = round(goals / games, 4),
         apg = round(assists / games, 4),
         ppg = round(points / games, 4),
         spg = round(shots / games, 4)) %>% 
  rename(Odds = odds,
         `Implied Probability` = win_probability) %>% 
  mutate(`Implied Probability` = `Implied Probability` * 100,
         `Implied Probability` = str_c(as.character(`Implied Probability`), "%"))


# Remove variables not needed for the article
rm(apg_plot, bedard_stats, calder_games, calder_odds, def_game_log, for_game_log,
   def_info, for_info, gpg_plot, pm_plot, ppg_plot, rookie_seasons, rookie_subset,
   skaters_game_log, skaters_info, standings, toi_plot)