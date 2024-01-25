import json, ast, requests
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