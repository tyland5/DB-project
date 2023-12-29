Instructions for running our webapp

Create a folder in your environment (VSCODE in this case). Within that folder in your environment, create a directory / file called .streamlit. Within the .streamlit file, 
you need to create another .toml file called secrets.toml. The file will look like this and the host, port, dbname, user and password will be required to be entered to create 
a connection to the database.

[connections.postgresql]
[postgres]
host = "localhost"
port = 
dbname = "FarmersMarket"
user = 
password = 

The .streamlit file will contain the secrets.toml file and other than that, the folder will have the webapp.py file and the requirements.txt file. 
Once this is done, the command (streamlit run webapp.py) can be used in the terminal and the website will be deployed on localhost.