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

	energized_dir="/data/.energized"

	# Defining Important Variables
	config_file="${energized_dir}/config.jax"
	hosts_file="/etc/hosts"
	hosts_bakup="/etc/hosts.bak"
	manifest_file="${energized_dir}/manifest.json"
	whitelist_file="/sdcard/energized-whitelist.txt"
	blacklist_file="/sdcard/energized-blacklist.txt"
	temp_blacklist="${energized_dir}/tmp_bk.txt"
	temp_whitelist="${energized_dir}/tmp_wh.txt"



	if [[ -f "$config_file" ]];then
		if [[ ! -z $(cat "$config_file") ]];then
			source "$config_file"
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

	wget "$link" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | dialog --title "Download in progress" --gauge "Downloading $packname hosts ($size) .. Please wait..." 9 80
	(pv -n hosts > "$hosts_file") 2>&1 | dialog --gauge "Merging host" 8 80
	rm hosts
	dialog --title "Success" --colors --msgbox "Successfully installed \Zb\Z4$packname\Zn pack" 6 60
	echo "export current_pack=\"$packname\"
export installedon=\"$(date)\"" > "$config_file"
	InitSystem
	RebootNotify
	MainMenu
else
	dialog --title "Failed" --msgbox 'No Internet Connection' 6 60
	MainMenu
fi

}

function Updatenotice() {


	dialog --title "Notice" --msgbox "This feature is being Developed and will be added in the next update.

For now, You can use the other options" 10 60
MainMenu
}

function InstallPack() {

 	dialog --infobox "Loading Manifest file" 5 50

	packinformation=$(cat "${manifest_file}" | jq ".packs[].${1}[]")
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
	ext_version_code=$(cat $manifest_file | jq '.dev[].versioncode' -r)


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
    done < <( cat $manifest_file | jq '.packs[] | keys[]' -r )
    readpackname=$(dialog --clear --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    readpack=$(cat $manifest_file | jq '.packs[] | keys[]' -r | sed "${readpackname}!d")
    InstallPack "$readpack"
else
	MainMenu
fi



}

function RebootNotify() {


	dialog --title "Notice" --msgbox "Changes has made to your system.
Reboot now or later" 7 40


}

function Restorehost() {

if [[ $current_pack != "NONE" ]];then
		dialog --clear --yes-label "Remove" --no-label "Back" --colors --title "Remove and Restore $1" \
--backtitle "Confirmation" \
--yesno "Are you sure want to remove \Zb\Z4$current_pack\Zn and restore previous host

Note : You need to download again to install Pack" 10 70

	if [[ $? -eq 0 ]];then

		rm $config_file
		rm $hosts_file
		mv $hosts_bakup $hosts_file

		dialog --title "Success" --colors --msgbox "Removed \Zb\Z4$current_pack\Zn pack and restored to previous state" 7 60
		RebootNotify
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


function CurrentPack() {

dialog --infobox "Loading Manifest file" 5 50

packinformation=$(cat "${manifest_file}" | jq ".packs[].${current_pack}[]")
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

	HEIGHT=17
    WIDTH=80
    CHOICE_HEIGHT=23
    BACKTITLE="Developed by Jaxparrow"
    TITLE="$current_pack"
    MENU="Options to configure"
    
    OPTIONS=(
	1 "Update Pack"
	2 "Add domain to host"
	3 "View Pack Info"
	)

    mainmenu=$(dialog --clear --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    case $mainmenu in
        1)



check_connectivity

if [[ $? -eq 0 ]];then
	if [[ -f hosts ]];then
		rm hosts
	fi

	if [[ $hosts_file ]];then
		rm hosts_file
	fi

	wget "$link" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | dialog --title "Update in progress" --gauge "Downloading $current_pack hosts ($size) .. Please wait..." 10 80
	(pv -n hosts > "$hosts_file") 2>&1 | dialog --gauge "Merging host" 8 80
	rm hosts
	dialog --title "Success" --colors --msgbox "Successfully Updated \Zb\Z4${current_pack}\Zn pack" 6 60
	echo "export current_pack=\"$current_pack\"
export installedon=\"$(date)\"" > "$config_file"
	InitSystem
	MainMenu
else
	dialog --title "Failed" --msgbox 'No Internet Connection' 6 60
	MainMenu
fi


        ;;

        2)

if [[ -f $temp_blacklist ]];then
	rm "$temp_blacklist"
fi
	dialog --title "Info" --colors --msgbox "You will be taken to nano

\ZuShortcuts\Zn
Press \Zb\Z4Ctrl+O\Zn to Save
Press \Zb\Z4Ctrl+X\Zn to Exit

Press enter to continue" 12 60
echo "# 1 domain per line" >> $temp_blacklist
nano $temp_blacklist
for domain in $(cat $temp_blacklist);do
	echo "0.0.0.0 $domain" >> "$hosts_file"
done

rm $temp_blacklist

dialog --title "Info" --colors --msgbox "Blacklisted domains added to hosts file" 6 60
CurrentPack        
;;

        3)
dialog --clear --colors --msgbox "Pack Information for $current_pack

Blocked Domains : \Z4\Zb${domains}\Zn
Sources : ${sources}
Type : ${type}
Device : ${device}

Download Size : \Zb\Z4${size}\Zn
Last updated on device : $installedon" 17 70
CurrentPack
        ;;

    esac
else
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
    
	if [[ $current_pack == "NONE" ]];then
	    OPTIONS=(
	1 "Install Pack"
	2 "Whitelist"
	3 "Blacklist"
	4 "Remove Pack"
	5 "About"
	)
	else

	    OPTIONS=(
	1 "Current Pack"
	2 "Whitelist"
	3 "Blacklist"
	4 "Remove Pack"
	5 "About"
	)
	fi

    mainmenu=$(dialog --clear --cancel-label "Exit" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    case $mainmenu in
        1) 	if [[ $current_pack == "NONE" ]];then
        		SelectPack
    		else
    			CurrentPack
    		fi

        ;;

        2) Updatenotice;;

        3)
		   Updatenotice;;

	   4) Restorehost;;

        5)


if [[ $ext_contributors != "NONE" ]];then
	merging_txt="
Contributors:
$(cat $manifest_file | jq '.dev[].contributors[]' -r)"
else
	merging_txt=""
fi

dialog --title "About" --colors --msgbox "

Developed by SupremeGamers ( https://supreme-gamers.com )

This extension can be used to block Adware, Malware, Porn and unwanted websites.

Maintained and Developed : $maintainer - Supreme Gamers

Last updated : \Zb\Z4$manifest_updated\Zn

\Zu\ZbVersion info :\Zn
Version : $ext_version
Version Code : $ext_version_code
$merging_txt

Leave a review on the Website if you like this
" 18 80



MainMenu
        ;;

    esac
else
    exit
fi

}
InitSystem
InitManifest
MainMenu