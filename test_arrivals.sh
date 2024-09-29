#!/bin/bash

source .env

wget -O trimet.json "https://developer.trimet.org/ws/V1/arrivals/?locIDs=$LOCS&json=true&appID=$TRIMET_APPID"
json_pp < trimet.json
