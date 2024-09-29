#!/bin/bash

source .env

wget -O trimet.json "https://developer.trimet.org/ws/V1/stops/?ll=$LONGITUDE,$LATITUDE&meters=400&showRoutes=true&json=true&appID=$TRIMET_APPID"
json_pp < trimet.json
