#!/bin/zsh
#
# synchronize asset tags from SnipeIT to macOS devices in Watchman Monitoring Client 


# add Watchman API key & URI
watch_key=''
watch_URI=''

# add Snipe IT API key & URI
Snipe_API_key=''
SNIPE_SERVER=''

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

exit 0