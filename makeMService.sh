#!/bin/bash

set -e

if [ -d "$1" ]; then
   echo "a directory with the same name as the one that sould be created exists already, continue with overwriting Y/N ?"	
   read answer
   
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

docker build -t $1:$2 .

#r=$(docker ps -q)
#if [ ! -z "$r" ]; then
#    docker stop $(docker ps -q) > /dev/null  2>&1
#fi

echo "stopping and removing any existing forge container .." 

docker stop forge > /dev/null 2>&1

docker rm forge > /dev/null 2>&1

echo "starting a forge container"

docker run -d --name forge  -p 8080:8080 $1:$2

echo "waiting for the web app context loading .."

sleep 5 

echo "checking the app with a curl"

curl localhost:8080/$1/hello

#create a github repo and push generated sources

cd $1

echo "create a git repo"

git init

echo "adding sources to repo"

git add .

echo "commiting .."

git commit -m "first commit"


echo "creating a repo on github"

curl -k -u 'Arsene07:BlaClaSlaGit.321' https://api.github.com/user/repos -d '{"name":"'$1'"}'

echo "adding a remote .."

git remote add origin https://github.com/Arsene07/$1.git

echo "and .. pushing"

git push -u origin master

cd ..

echo -e "\nchecking the app with a curl .. \n"

echo -e "\n ################### \n"

curl localhost:8080/$1/hello

echo -e "\n\n ################### \n"

echo "delete repos on GitHub Y/N  ?"
read delete

if [ "$delete" == "Y" ]; then
	echo "deleting repo on GitHub .."
	curl -k -X "DELETE" -u 'Arsene07:BlaClaSlaGit.321' https://api.github.com/repos/Arsene07/$1

else
        echo "creating a jenkins job .."
        # copy template to jenkins jobs folder
        rm -rf ~/Tools/jenkins/jenkins/jobs/$1 > /dev/null 2>&1
        cp -R -f /applis/forge/templates/jenkins/mytemplate/ ~/Tools/jenkins/jenkins/jobs/$1

        #sed -i bak  "s|URL_TO_REPO_ON_GITHUB|https://github.com/Arsene07/$1.git|g" ~/Tools/jenkins/jenkins/jobs/$1/config.xml
		sed   "s|URL_TO_REPO_ON_GITHUB|https://github.com/Arsene07/$1.git|g" config_template.xml > config.xml
		
		CRUMB=$(curl -s 'http://admin:admin@localhost:49001/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
		
		echo "creating jenkins job"		
		curl -s -X POST -H "$CRUMB" 'http://admin:admin@localhost:49001/createItem?name='$1'' --data-binary @config.xml -H "Content-Type:text/xml"
		
		echo "starting the jenkins job"
		curl -X POST -H "$CRUMB"  http://localhost:49001/job/$1/build?delay=0sec --user admin:admin				
	#echo "restart jenkins container ..."
	#docker restart youthful_shannon
	
	#echo "waiting for jenkins to start .."
	#sleep 30
	
	
	# launch build ..	
	#curl http://localhost:49001/job/$1/build?delay=0sec
	#CRUMB=$(curl -s 'http://admin:admin@localhost:49001/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)')
	#curl -X POST http://localhost:49001/job/$1/build?delay=0sec --user admin:admin
	#curl -X POST -H "$CRUMB"  http://localhost:49001/job/$1/build?delay=0sec --user admin:admin
fi 

echo "The End !"