#!/bin/bash
#
# add asset tags from Snipe to devices in Watchman Monitoring Client 


# Watchman API Key & URI
watch_key='UW_bE14wUmaHfC4RLJDjvjbnmdKZsYiENZVJEA'
watch_URI='https://metroeast.monitoringclient.com/v2.5/computers'

# Snipe IT API Key
Snipe_API_key='eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIxIiwianRpIjoiNWI5Njk3M2U1NGQwZTVlMjdhZDIxOGY5N2M1YTEwYWRhZmRjNjZkZWUzNzFkMmQ1YjNkZjlkZWQ5YzUyYWZmN2Y2OWIyYWU2MjYxYjBkNjYiLCJpYXQiOjE2MTQ2NDY4NDQsIm5iZiI6MTYxNDY0Njg0NCwiZXhwIjoyMjQ1Nzk4ODQ0LCJzdWIiOiIxIiwic2NvcGVzIjpbXX0.uoxI615Iv28MamV9qvvcVN6sbKrVmsFGFj1dsJb_bQBAgSyOYRCjeThmF5FAMENotL7HMMbbIIMrvS7dEV-ceGCErD2CK6TJdnBPFLBaJehjnDtufjBbIt_dg2suIovuo-SkGL7RL58nc3LJuGEYbE32_UcVbSjcJLrHi8fhkShxwSCGjwz34E7Fh9IITBCVP7F5ag6Btsni_L1T6CiSMpVWfsaGmFaPLN2cCkKXOUZ62PPAeNI4lv67pnueo5R3x6-00A6YoWEJGBG7Sq7YedEoZ1BcFjuGDCCuyrsGmQ4-RD0Z786OyZOeJc3MzgmXdfcl04I0pXvZDEDOKG_CSPaUbe1fR-PvOIPewvd8mn1tthjNMXxDPla8gm9qE2o-MdOxS7jmh_ATA_aqIsrx5aDl4PGRuF8OoB9dgp2gIllrbxdFZxx5xuOj4Ud1J1FxViAZp5KhvpbYDHqTAb4Ri7DoygyVf0wR9iYaYEECj5oqyRd9DtOxtRXY4cb82FD-CMGEBzBZtszvnj5FJ25MSbdef5u3qy4rFaSzEle7wXmI187HuwdBiZjs5ZAgK2Qhz4bLkWReWqD0VFSYj5IrvHf9dODSyzozC2ca-imWT0w7HcIVbo4xKM8XM53V87qHEYkR09eYKh88HW-SMcTAK3YX35PIvr9loOZz0cXqxmg'

SNIPE_SERVER='metroeast.snipe-it.io'
HEAD_key="Authorization: Bearer $Snipe_API_key"
HEAD_acc='Accept: application/json'
HEAD_typ='Content-Type: application/json'

VERBOSE=0

## Get asset tag from Snipe
function get_asset ()
{

  serial="$1"
  
  asset_info=$(curl -s --header "$HEAD_key" --header "$HEAD_acc" --header "$HEAD_typ" "https://$SNIPE_SERVER/api/v1/hardware?search=$serial")

  asset_tag=$(jq '.rows[0].asset_tag' <<< "$asset_info")
  if [ "$asset_tag" == "" ]
  then
    return '$asset_tag'
  fi
  [ "$VERBOSE" -gt 0 ] && printf "asset_tag: %s\n" "$asset_tag"


}

###  get raw json from Watchman
watchman_info=$(curl -get "$watch_URI?page=1&per_page=100&api_key=$watch_key")

## loop through ids
while read this_id
do

	read this_serial
  	printf "Watchman serial: %s\n" "$this_serial"
  	printf "Watchman id: %s\n" "$this_id"
  	this_serial="${this_serial//\"/}"
  	this_id="${this_id//\"/}"
  	
  	get_asset "$this_serial"
  	printf "Snipe asset: %s\n" "$asset_tag"
  	asset_tag="${asset_tag//\"/}"

  	
  	if [ "$asset_tag" != "null" ]
  	then 
  	  # send to watchman monitoring client record
  	  output=$(curl -X PUT --header "Content-Type: application/x-www-form-urlencoded" \
               -d "api_key=$watch_key" \
               -d "computer[asset_id]=$asset_tag" \
               "$watch_URI/$this_id")
    fi
    [ "$VERBOSE" -gt 0 ] && printf "%s\n" "$output"


done < <(
  ## parse out id & serial
  jq '.[] | {id: .watchman_id, serial: .serial_number} | .id, .serial' <<< "$watchman_info" 
)