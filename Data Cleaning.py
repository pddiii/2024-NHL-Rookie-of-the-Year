import json, ast, requests, os
import pandas as pd
from pandas import json_normalize

# Read the json containing the names of every NHL team to exist
teams_df = pd.read_json('/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/teams.json')
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
file_names = os.listdir(folder_path)
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

for season in seasons:
    skaters_url = f"https://api.nhle.com/stats/rest/en/skater/summary?limit=-1&sort=points&cayenneExp=seasonId={season}"
    skaters_response = requests.get(skaters_url)

    with open(f"skaters_stats_{season}.json", 'w') as skaters_file:
        json.dump(skaters_response.json(), skaters_file)

    goalies_url = f"https://api.nhle.com/stats/rest/en/goalie/summary?limit=-1&sort=wins&cayenneExp=seasonId={season}"
    goalies_response = requests.get(goalies_url)

    with open(f"goalies_stats_{season}.json", 'w') as goalies_file:
        json.dump(goalies_response.json(), goalies_file)

# Store the path to the folder directory
skaters_path = '/Users/PeterDePaul/Downloads/2024-NHL-Rookie-of-the-Year/STATS/Skaters/json Files'
# Extract the names of all files existing in the folder except the '.DS_Store' file
file_names = [file for file in os.listdir(skaters_path) if file != '.DS_Store']
# Initialize an empty list for the skaters (Forwards & Defensmen)
skaters_list =[]

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