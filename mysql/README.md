# Create bash scripts for restore DB from a dump file in docker

First you need to set the parameters
## Parameters:
```
db_url="db_server_address" - address DB server
db_name="name_db" - name db
db_user="name_user_db" - create user db
db_pass="pass_user_db" - create pass for user db
root_pass="root_pass_mysql" - root password DB server
name_dump="name_dump_file.sql" - name file dump
```
```
name_net_docker="stend_default" - name docker network
name_image="mysql:5.7" - name docker image mysql
```

After running the script, several scripts will be created for different stages. 
You need to run script all.sh - it runs them sequentially.
```
bash all.sh
```

Script tools.sh shows a list of databases on the server
```
bash tools.sh 
```
