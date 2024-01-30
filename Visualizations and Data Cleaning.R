library(tidyverse)
library(ggplot2)
library(hockeyR)

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
  select(-firstName, -lastName, -id)

bedard_info <-
  for_info %>% 
  filter(Name == "Connor Bedard")

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

# Rookie season information
rookie_seasons <- 
  for_game_log %>% 
  group_by(playerId, seasonId) %>%
  summarise(gp_season = sum(games)) %>% 
  mutate(gp_career = cumsum(gp_season)) %>% 
  filter(gp_career <= 82) %>% # Filter only the rookie seasons and stats
  ungroup() %>%               
  select(-gp_career)

# Rookie stats for the first 39 games since Connor Bedard has only played 39
# games as of the time writing this on 01/27/24
rookie_stats <- 
  for_game_log %>% 
  semi_join(rookie_seasons, by = c("playerId", "seasonId"))%>% 
  group_by(playerId, seasonId) %>% 
  slice(1:39) %>% 
  summarise_if(is.numeric, sum) %>%  
  mutate(ppg = points / games,
         gpg = goals / games,
         apg = assists / games,
         spg = shots / games) %>% 
  arrange(desc(points)) %>% 
  inner_join(for_info %>% select(playerId, Name), by = "playerId") %>% 
  relocate(Name, .after = playerId)

# Rookie Stats for the 2023-2024 season
rookie_stats %>% 
  filter(seasonId == 20232024)

bedard_stats <-
  rookie_stats %>% 
  filter(playerId == bedard_info$id)

# Get the NHL game results data from 2005-2006 to 2023-2024
seasons <- 2006:2024
game_ids <- list()
for (i in 1:length(seasons)) {
    game_ids[[i]] <- get_game_ids(season = seasons[i])
}


# Points per Game Scatterplot
ppg_plot <-
  ggplot(rookie_stats %>% filter(games >= 20), aes(x = games, y = ppg)) +
  geom_point() + 
  labs(title = "Scatterplot of PPG vs GP",
       x = "Games Played (GP)", y = "Points per Game (PPG)")

# Goals per Game Scatterplot
gpg_plot <-
  ggplot(rookie_stats %>% filter(games >= 20), aes(x = games, y = gpg)) +
  geom_point() + 
  labs(title = "Scatterplot of GPG vs GP",
       x = "Games Played (GP)", y = "Goals per Game (GPG)")

# Assists per Game Scatterplot
apg_plot <-
  ggplot(rookie_stats %>% filter(games >= 20), aes(x = games, y = apg)) +
  geom_point() + 
  labs(title = "Scatterplot of APG vs GP",
       x = "Games Played (GP)", y = "Assists per Game (APG)")

# Plus-Minus Scatterplot
pm_plot <-
  ggplot(rookie_stats %>% filter(games >= 20), aes(x = games, y = plusMinus)) +
  geom_point() + 
  labs(title = "Scatterplot of PlusMinus vs GP",
       x = "Games Played (GP)", y = "PlusMinus")

