#!/bin/bash

#---CONFIG START---

#does not really matter
userAgent="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:27.0) Gecko/20100101 Firefox/27.0"

#this is my cookie, there are many like it, but this one is mine
#HOW TO OBTAIN YOUR OWN:
#Firefox:	1, log in to gog.com with your user/pass
#		2, open Firebug -> Net tab
#		3, click on something so a request will show up
#		4, click on the request and find the "Request Headers" section and then copy the "Cookie" header value
cookie=""

#game selection and mutators to buy
#HOW TO CONFIGURE:
#Firefox:	1, go to http://www.gog.com/mutator
#		2, log in and select the games and the mutators you want to buy
#		3, open Firebug -> Console tab, click on Presist
#		4, click on "CHECKOUT NOW" button on the gog webpage
#		5, in Firebug click on the "POST http://www.gog.com/createPromoOrder" entry, click on the POST tab and copy the source
gameCombo='{"product_ids":["1207660413","1207658806","1207660353"],"mutator_count":3}'

#file containing the list of the possible games
#a row must consist of the game name and the release date
#get the current one from http://www.gog.com/forum/general/mutator_promo_how_to_get_a_clue_about_mutator_games/page1
dataFile='release_dates_r3.txt'

#names of the games you want
desiredGames=("Unrest" "Guacamelee" "Alcatraz" "Federation" "Smugglers" "Vertical")

#min and max value of the sleep timer in minutes
minSleepTime=60
maxSleepTime=90


#MUTATOR promo specific - do not change
dataPattern='"title":"\K([^"]*)|"from":{"date":"\K([^"]*) '
checkoutRequestURL='http://www.gog.com/createPromoOrder'

#---CONFIG END---

function mine {
	echo "---running----"
	getCheckoutSource checkoutData
	findMutatorsFromHTML "$checkoutData"
}

function getCheckoutSource() {
	local  __resultvar=$1
	#get checkout url
        local response=$(curl -s -A "$userAgent" -b "$cookie" --request POST "$checkoutRequestURL" --data "$gameCombo")
	#echo "$response" > response.txt	#DEBUG
        if [[ $response != *https* ]]
            then
            echo "ERROR - refresh cookie or gameCombo"
            exit 1
          fi
        #clean up response
        checkoutURL=$(echo "$response" | sed 's/\\//g' | grep -o "https[^\"]*")
	echo "$checkoutURL"
        #request checkout
        sleep 3
        local checkoutSource=$(curl -s -A "$userAgent" -b "$cookie" "$checkoutURL")
	#echo "$checkoutSource" > checkoutsource.txt	#DEBUG
	eval "$__resultvar=\$checkoutSource"
}

function findMutatorsFromHTML() {
        echo "Mutators:"
        while read -r line ; do
                #echo "Processing $line"        #DEBUG
                if [[ $line == *Mutator* ]]
                then
			local mutatorDate=$(echo "$line" | awk -F"|" '{print $1}')
                        local mutatorName=$(grep "$mutatorDate" "$dataFile")
                        if [ $? -eq 1 ]
                                then
                                echo "Unknown date: $mutatorDate"
                                else
                                echo "$mutatorName"
                                checkForRequiredGames "$mutatorName"
                        fi
                fi
        done  < <(echo "$1" | grep -oP "$dataPattern" | sed 'N;s/ \n/|/')
}

function checkForRequiredGames() {
        for var in "${desiredGames[@]}"
        do
          echo "$1" | grep -oiq "${var}"
          if [ $? -eq 0 ]
            then
            echo "Found: $1"
            echo -e "Found: $1\nThe checkout URL is: $checkoutURL" > found.txt
            exit 0
          fi
        done
}



while true
do
	mine
	sleep $((RANDOM%$maxSleepTime+$minSleepTime))m
done



