#!/bin/bash

set -e

if [ -d "$1" ]; then
   echo "a directory with the same name as the one that sould be created exists already, continue with overwriting Y/N ?"	
   read answer
   echo $answer
   if [ "$answer" == "N" ]; then 
       echo "Stopping the script"
       exit 1
   fi
fi

#call the forge to generate the composant sources ..

echo "generartin $1 μservice"
HOST=localhost
PORT=8082
PROJECT_NAME=$1
curl $HOST:$PORT/starter.tgz -d applicationName=$1 -d name=$1 -d dependencies=web,actuator -d language=java -d type=maven-project -d baseDir=$1 -d artifactId=$1 -d groupId=fr.enedis.$1 | tar -xzvf -

# build the project with maven

cd $1

mvn clean package

cd ..

#build the docker images

artifact_id_name="$1/target/$1-0.0.1-SNAPSHOT.jar"

echo "artifactid name = $artifact_id_name"

rm Dockerfile > /dev/null 2>&1

sed  "s|ARTIFACT_ID_JAR|$artifact_id_name|g" Dockerfile_Template > Dockerfile

image_name=$1$2
echo "build an $image_name image with the generated composant"

docker build -t $1/$2 .

docker run -d  -p 8080:8080 $1/$2

#run a container
echo "starting a container"

#do curl on the running app
echo "checking the app with a curl"

echo "sleeping"

sleep 10

curl localhost:8080/hello-world/hello2

#create a github repo and push generated sources

cd $1

echo "create a git repo"

git init

echo "adding sources to repo"

git add *

echo "commiting .."

git commit -m "first commit"


echo "creating a repo on github"

curl -k -u 'Arsene07:BlaClaSlaGit.321' https://api.github.com/user/repos -d '{"name":"'$1'"}'

echo "adding a remote .."

git remote add origin https://github.com/Arsene07/$1.git

echo "and .. pushing"

git push -u origin master