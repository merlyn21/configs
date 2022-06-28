#!/bin/bash


db_url="db_server_address"
db_name="name_db"
db_user="name_user_db"
db_pass="pass_user_db"
root_pass="root_pass_mysql"
name_dump="name_dump_file.sql"

name_net_docker="stend_default"
name_image="mysql:5.7"

# create_user.sh
echo "#!/bin/bash" > create_user.sh
echo "mysql -t -vvv -h $db_url -u root -p$root_pass < create_user.sql" >> create_user.sh

# create_user.sql
echo "CREATE USER '$db_user'@'%' IDENTIFIED BY '$db_pass';" > create_user.sql
echo "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';" >> create_user.sql
echo "FLUSH PRIVILEGES;" >> create_user.sql

# drop_create.sh
echo "#!/bin/bash" > drop_create.sh
echo "mysql -t -vvv -h $db_url -u root -p$root_pass < drop_create.sql" >> drop_create.sh

# drop_create.sql
echo "DROP DATABASE IF EXISTS $db_name;" > drop_create.sql
echo "CREATE DATABASE IF NOT EXISTS $db_name;" >> drop_create.sql

# restore_db.sh
echo "#!/bin/bash" > restore_db.sh
echo "mysql -t -vvv -h $db_url -u root -p$root_pass $db_name < $name_dump" >> restore_db.sh

# tools
echo "docker run --rm --network=$name_net_docker $name_image mysql -h $db_url -u root -p$root_pass -e 'show databases;'" > tools.sh

#all.sh

cat << EOF > all.sh
#!/bin/bash

echo "create db"
docker run --rm --network=$name_net_docker -v "\$(pwd):/root/build" -w "/root/build" $name_image bash drop_create_db.sh
echo "create user"
docker run --rm --network=$name_net_docker -v "\$(pwd):/root/build" -w "/root/build" $name_image bash create_user.sh
echo "restore db from dump file"
docker run --rm --network=$name_net_docker -v "\$(pwd):/root/build" -w "/root/build" $name_image bash restore_db.sh

EOF
