import json
import ast
import requests
import os
import time
import logging
import pandas as pd
from pandas import json_normalize

# Read the json containing the names of every NHL team to exist
teams_df = pd.read_json('/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/Rosters/teams.json')
# Extract the important data from the json
teams_df = json_normalize(teams_df['data'])
# Sort the team information by their 'id' 
teams_df = teams_df.sort_values('id')
# Extract the current team ids
current_ids = [list(range(start, end + 1)) for start, end in [(1, 10), (12, 26), (28, 30), (52, 55)]]
# Subset the current teams from the teams_df
current_teams = pd.concat([teams_df.query("id in @teams_id") for teams_id in current_ids])
# Extract the team triCodes
team_codes = current_teams.sort_values('triCode').triCode

# For team_code from the above triCodes extracted
for team_code in team_codes:
    # Create a url for each respective team_code
    url = f"https://api-web.nhle.com/v1/roster/{team_code}/20232024"
    # query the NHL API for the json for each url
    url_response = requests.get(url)
    # Create a json file for each current teams roster
    with open(f"{team_code}_roster.json", 'w') as file_name:
        json.dump(url_response.json(), file_name)

# Store the path to the folder directory
folder_path = '/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/Rosters'
# Extract the names of all files existing in the folder
file_names = [file for file in os.listdir(folder_path) if file not in ['teams.json', 'current_teams.json']]
# Initialize an empty list for each of the NHL position groups: Forwards, Defensemen, and Goalies
forwards_list = []
defensemen_list = []
goalies_list =[]

for file_name in file_names:
    file_path = os.path.join(folder_path, file_name)

    with open(file_path) as file:
        # Load the roster json
        roster_json = json.load(file)
        # For each of the position groups create a pandas DataFrame
        forwards = pd.DataFrame(roster_json['forwards'])
        defensemen = pd.DataFrame(roster_json['defensemen'])
        goalies = pd.DataFrame(roster_json['goalies'])
    # Append to the list for each position group for each team's roster
    forwards_list.append(forwards)
    defensemen_list.append(defensemen)
    goalies_list.append(goalies)

# Create one large data frame for each position
forwards_df = pd.concat(forwards_list)
defensemen_df = pd.concat(defensemen_list)
goalies_df = pd.concat(goalies_list)


start_year = [str(year) for year in range(2003, 2024)]
end_year = [str(year) for year in range(2004, 2025)]
seasons = [str(start) + str(finish) for start, finish in zip(start_year, end_year)]
seasons = [season for season in seasons if season != '20042005']

##### *******DO NOT RE-RUN (ABOUT 3500 json FILES)*****
logging.basicConfig(level=logging.INFO)
# Get the game logs for all forwards for each possible season
for season in seasons:
    for forwards_id in forwards_df['id']:
        try: 
            url = f"https://api-web.nhle.com/v1/player/{forwards_id}/game-log/{season}/2"
            response = requests.get(url)
            response.raise_for_status()
            data = response.json()
        
            with open(f"skater_{forwards_id}_stats_{season}.json", 'w') as file:
                json.dump(data, file)
            
            logging.info(f"Successful for {forwards_id} for {season}")
        except Exception as e: 
            logging.error(f"Error for {forwards_id} for {season}")
          
test_id = defensemen_df['id']        
url = f"https://api-web.nhle.com/v1/player/8480196/game-log/20082009/2"
response = requests.get(url)
int(response.headers['Content-Length'])
response.raise_for_status()
data = response.json()         
          
            
for season in seasons:
    for defensemen_id in defensemen_df['id']:
        try: 
            url = f"https://api-web.nhle.com/v1/player/{defensemen_id}/game-log/{season}/2"
            response = requests.get(url)
            response.raise_for_status()
            response_length = int(response.headers['Content-Length'])
            if response_length >= 50:
                data = response.json()
                with open(f"defensemen_{defensemen_id}_stats_{season}.json", 'w') as file:
                    json.dump(data, file)
                
                logging.info(f"Successful for {defensemen_id} for {season}")
            else:
                logging.warning(f"File too small for {defensemen_id} for {season}")
        except Exception as e: 
            logging.error(f"Error for {defensemen_id} for {season}")
            
for season in seasons:
    for goalies_id in goalies_df['id']:
        try: 
            url = f"https://api-web.nhle.com/v1/player/{goalies_id}/game-log/{season}/2"
            response = requests.get(url)
            response.raise_for_status()
            response_length = int(response.headers['Content-Length'])
            if response_length >= 75:
                data = response.json()
                with open(f"goalies_{goalies_id}_stats_{season}.json", 'w') as file:
                    json.dump(data, file)
                
                logging.info(f"Successful for {goalies_id} for {season}")
            else:
                logging.warning(f"File too small for {goalies_id} for {season}")
        except Exception as e: 
            logging.error(f"Error for {goalies_id} for {season}")

for season in seasons:
    skaters_url = f"https://api-web.nhle.com/v1/skater-stats-leaders/{season}/2?limit=-1"
    skaters_response = requests.get(skaters_url)
    skaters_data = skaters_response.json()

    with open(f"skaters_stats_{season}.json", 'w') as skaters_file:
        json.dump(skaters_data, skaters_file)

    goalies_url = f"https://api-web.nhle.com/v1/goalie-stats-leaders/{season}/2?limit=-1"
    goalies_response = requests.get(goalies_url)
    goalies_data = goalies_response.json()

    with open(f"goalies_stats_{season}.json", 'w') as goalies_file:
        json.dump(goalies_data, goalies_file)

# Store the path to the folder directory
skaters_path = '/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/STATS/Skaters/json Files'
# Extract the names of all files existing in the folder except the '.DS_Store' file
file_names = [file for file in os.listdir(skaters_path) if file != '.DS_Store']
# Initialize an empty list for the skaters (Forwards & Defensmen)
skaters_list =[]


logging.basicConfig(level=logging.INFO)
forwards_stats = []
# Load the json files for each forwards game logs for each season played
for season in seasons:
    for forwards_id in forwards_df['id']:
        try:
            with open(f"/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/skater_{forwards_id}_stats_{season}.json") as file:
                data = json.load(file)
                data_df = pd.DataFrame(data['gameLog']) # create the DataFrame
                data_df['seasonId'] = season # add a seasonId variable
                data_df['playerId'] = forwards_id # add a playerId variable
                forwards_stats.append(data_df) # Append these DataFrames to the list
            # If it works print statement
            logging.info(f"Successful for {forwards_id} for {season}")
        except Exception as e: 
            # If it doesn't work print this error
            logging.error(f"Error for {forwards_id} for {season}")
# Combine the list into a large DataFrame
forwards_stats_df = pd.concat(forwards_stats)
# forwards_stats_df.to_csv('forwards_game_logs.csv')

logging.basicConfig(level=logging.INFO)
defensemen_stats = []
# Load the json files for each defensemen game logs for each season played
for season in seasons:
    for defensemen_id in defensemen_df['id']:
        try:
            with open(f"/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/defensemen_{defensemen_id}_stats_{season}.json") as file:
                data = json.load(file)
                data_df = pd.DataFrame(data['gameLog']) # create the DataFrame
                data_df['seasonId'] = season # add a seasonId variable
                data_df['playerId'] = defensemen_id # add a playerId variable
                defensemen_stats.append(data_df) # Append these DataFrames to the list
            # If it works print statement
            logging.info(f"Successful for {defensemen_id} for {season}")
        except Exception as e: 
            # If it doesn't work print this error
            logging.error(f"Error for {defensemen_id} for {season}")
# Combine the list into a large DataFrame
defensemen_stats_df = pd.concat(defensemen_stats)
# defensemen_stats_df.to_csv('defensemen_game_logs.csv')

logging.basicConfig(level=logging.INFO)
goalies_stats = []
# Load the json files for each goalies game logs for each season played
for season in seasons:
    for goalies_id in goalies_df['id']:
        try:
            with open(f"/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/goalies_{goalies_id}_stats_{season}.json") as file:
                data = json.load(file)
                data_df = pd.DataFrame(data['gameLog']) # create the DataFrame
                data_df['seasonId'] = season # add a seasonId variable
                data_df['playerId'] = goalies_id # add a playerId variable
                goalies_stats.append(data_df) # Append these DataFrames to the list
            # If it works print statement
            logging.info(f"Successful for {goalies_id} for {season}")
        except Exception as e: 
            # If it doesn't work print this error
            logging.error(f"Error for {goalies_id} for {season}")
# Combine the list into a large DataFrame
goalies_stats_df = pd.concat(goalies_stats)
goalies_stats_df.to_csv('goalies_game_logs.csv')

for file_name in file_names:
    file_path = os.path.join(skaters_path, file_name)

    stats_json = pd.read_json(file_path)
    stats_df = pd.DataFrame(json_normalize(stats_json['data']))
    # Append to the list for all skaters each season
    skaters_list.append(stats_df)

# Create one large data frame for skaters
skaters_df = pd.concat(skaters_list)

# Store the path to the folder directory
goalies_path = '/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/STATS/Goalies/json Files'
# Extract the names of all files existing in the folder except the '.DS_Store' file
file_names = [file for file in os.listdir(goalies_path) if file != '.DS_Store']
# Initialize an empty list for the goalies
goalies_list =[]

for file_name in file_names:
    file_path = os.path.join(goalies_path, file_name)

    stats_json = pd.read_json(file_path)
    stats_df = pd.DataFrame(json_normalize(stats_json['data']))
    # Append to the list for all goalies each season
    goalies_list.append(stats_df)

# Create one large data frame for goalies
goalies_df = pd.concat(goalies_list)
goalies_list