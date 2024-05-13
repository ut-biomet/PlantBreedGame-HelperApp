#!/usr/bin/env sh

Help()
{
   echo "Launch PlantBreedGame-Helper application"
   echo
   echo "Syntax: plantBreedGameHelperApp [-p|--port port] [-H|--host host] [-h|--help]"
   echo "options:"
   echo "-p --port      The TCP port that the application should listen on."
   echo "-H --host      The IPv4 address that the application should listen on."
   echo "-h --help      Show this help message and exit"
   echo
}


app_dir="."
port=""
host="127.0.0.1"

while [ "$1" != "" ]; do
  case $1 in
    -h | --help ) shift
      Help && exit 0
      ;;
    -p | --port ) shift
      port=$1
      ;;
    -H | --host ) shift
      host=$1
      ;;
    * )  echo "error: Bad argument $1"; exit 1
  esac
  shift
done


runApp_args="appDir = \"$app_dir\", host = \"$host\""

if [ "$port" != "" ]; then
  runApp_args="$runApp_args, port = $port"
fi


Rscript --vanilla -e "shiny::runApp($runApp_args)"

