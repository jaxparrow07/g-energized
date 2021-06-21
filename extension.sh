#!/gearlock/bin/bash

# Dialog Colors
#
# 1 Red
# 2 Green
# 3 Yellow
# 4 Blue
# 5 Purple
# 6 Dark Green

function InitSystem() {

	# Defining Important Variables
	config_file="config.jax"
	hosts_file="out/hosts"
	hosts_bakup="out/hosts.bak"
	manifest_file=manifest.json



	if [[ -f "$config_file" ]];then
		if [[ ! -z $(cat "$config_file") ]];then
			current_pack="$(cat $config_file)"
		else
			current_pack="NONE"
		fi
	else
		current_pack="NONE"
	fi


}

function check_connectivity() {

	wget -q --spider http://google.com
	return $?

}


function coreinstall() {

check_connectivity

if [[ $? -eq 0 ]];then
	if [[ -f hosts ]];then
		rm hosts
	fi

	if [[ $hosts_file ]];then
		mv "$hosts_file" "$hosts_bakup"
	fi

	wget "$link" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | dialog --title "Download in progress" --gauge "Downloading $packname hosts ($size) .. Please wait..." 10 80
	(pv -n hosts > "$hosts_file") 2>&1 | dialog --gauge "Merging host" 8 80
	rm hosts
	dialog --title "Success" --colors --msgbox "Successfully installed \Zb\Z4$packname\Zn pack" 6 60
	echo "$packname" > "$config_file"
	InitSystem
	MainMenu
else
	dialog --title "Failed" --msgbox 'No Internet Connection' 6 60
	MainMenu
fi

}

function InstallPack() {

 	dialog --infobox "Loading Manifest file" 5 50

	packinformation=$(cat manifest.json | jq ".packinfo[].${1}[]")
	domains=$(echo $packinformation | jq '.domains' -r)
	type=$(echo $packinformation | jq '.type' -r)
	sources=$(echo $packinformation | jq '.sources' -r)
	size=$(echo $packinformation | jq '.size' -r)
	device=$(echo $packinformation | jq '.device' -r)
	link=$(echo $packinformation | jq '.link' -r)

	case $device in
		"low")
			device="\Zb\Z2Low End Friendly\Zn";;
		"high")
			device="\Zb\Z1High End Friendly\Zn";;
		"mid")
			device="\Zb\Z3Mid End Friendly\Zn";;
	esac


	dialog --clear --yes-label "Install" --no-label "Back" --colors --title "Install $1" \
--backtitle "Pack information" \
--yesno "
Pack Information for $1

Blocked Domains : \Z4\Zb${domains}\Zn
Sources : ${sources}
Type : ${type}
Device : ${device}

Download Size : \Zb\Z4${size}\Zn

" 15 70

response=$?
case $response in
   0)packname="$1";coreinstall;;
   1) SelectPack;;
   255) MainMenu;;
esac




}

function InitManifest() {

	ext_contributors=$(cat $manifest_file | jq '.dev[].contributors' -r)
	ext_version=$(cat $manifest_file | jq '.dev[].version' -r)
	manifest_updated=$(cat $manifest_file | jq '.dev[].lastupdated' -r)
	maintainer=$(cat $manifest_file | jq '.dev[].maintainedby' -r)

}

function SelectPack() {

	if [[ $current_pack != "NONE" ]];then

		dialog --title "Warning" --colors --msgbox "It looks like you already installed \Zb\Z4$current_pack\Zn pack\nRestore to install another Pack" 7 60
		MainMenu
	fi

	HEIGHT=15
    WIDTH=80
    CHOICE_HEIGHT=20
    BACKTITLE="Made By Jaxparrow"
    TITLE="List of Available Packs"
    MENU="Select Any Pack"
    
    let i=0
    OPTIONS=()
    while read -r line; do
    let i=$i+1
    OPTIONS+=($i "$line")
    done < <( cat $manifest_file | jq '.packs[]' -r )
    readpackname=$(dialog --clear --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    readpack=$(cat $manifest_file | jq '.packs[]' -r | sed "${readpackname}!d")
    InstallPack "$readpack"
else
	MainMenu
fi



}


function Restorehost() {

if [[ $current_pack != "NONE" ]];then
		dialog --clear --yes-label "Restore" --no-label "Back" --colors --title "Remove and Restore $1" \
--backtitle "Confirmation" \
--yesno "Are you sure want to remove \Zb\Z4$current_pack\Zn and restore previous host

Note : You need to download again to install Pack" 10 70

	if [[ $? -eq 0 ]];then

		rm $config_file
		rm $hosts_file
		mv $hosts_bakup $hosts_file

		dialog --title "Success" --colors --msgbox "Removed \Zb\Z4$current_pack\Zn pack and restored to previous state" 7 60
		MainMenu
	else
		dialog --title "Info" --msgbox "Okay, As your wish" 7 60
	fi
else

	dialog --title "Oops" --msgbox "It looks like you don't have any pack installed right now.
You can install them using the 1st option in the menu." 7 70
MainMenu
fi


}

function MainMenu() {

	InitSystem

    HEIGHT=17
    WIDTH=80
    CHOICE_HEIGHT=23
    BACKTITLE="Developed by Jaxparrow"
    TITLE="Energized Protection"
    MENU="Current Pack : $current_pack
Version : $ext_version"
    
    OPTIONS=(
1 "Install Pack"
2 "Whitelist"
3 "Blacklist"
4 "Restore Hosts"
5 "About"
)
    mainmenu=$(dialog --clear --cancel-label "Exit" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    case $mainmenu in
        1)
        SelectPack
        ;;

        2)
        AppRestore
        ;;

        3)
        HelpMenu
        ;;

        4)
        Restorehost
        ;;

    esac
else
    exit
fi

}
InitSystem
InitManifest
MainMenu