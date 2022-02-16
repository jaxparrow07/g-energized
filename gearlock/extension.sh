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

	if [[ ! -f $whitelist_file ]];then

		echo "# --------------------------------------------
# W H I T E L I S T E D   D O M A I N S
# --------------------------------------------
#" > $whitelist_file

		echo -e "# These domains won't be blocked by  hosts ( Will take effect automatically when updating / installing a pack or you can apply manually from menu too )\n# One domain per line ( e.g trusteddomain.com ) \n# Include '#' anywhere in the domain line to ignore it.\n#\n" >> $whitelist_file
	fi

	if [[ ! -f $blacklist_file ]];then

		echo "# --------------------------------------------
# B L A C K L I S T E D   D O M A I N S
# --------------------------------------------
#" > $blacklist_file

		echo -e "# These domains will be blocked by hosts ( Will take effect automatically when updating / installing a pack or you can apply manually from menu too )\n# One domain per line ( e.g sussy-domain.com ) \n# Include '#' anywhere in the domain line to ignore it.\n#\n" >> $blacklist_file
	fi


}

function check_connectivity() {

	wget -q --spider http://google.com
	return $?

}


function MergeLists() {

	if [[ -z $1 ]] || [[ $1 == "blist" ]];then

		local bnum=$(cat $blacklist_file | grep -v "#" | grep "\S" | wc -l)

		if [[ $bnum -gt 0 ]];then

			echo "
# --------------------------------------------
# B L A C K L I S T
# --------------------------------------------
" >> $hosts_file

			for domain in $(cat $blacklist_file | grep -v "#" | grep "\S" );do
				echo -e "0.0.0.0 $domain" >> "$hosts_file"
			done
		fi

		if [[ ! -z $1 ]];then
			return $bnum
		fi

	fi

	if [[ -z $1 ]] || [[ $1 == "wlist" ]];then

		local wnum=$(cat $whitelist_file | grep -v "#" | grep "\S" | wc -l)

		if [[ $wnum -gt 0 ]];then

			for domain in $(cat $whitelist_file | grep -v "#" | grep "\S" );do
				sed -i "/$domain/d" "$hosts_file"
			done

		fi

		if [[ ! -z $1 ]];then
			return $wnum
		fi



	fi

	if [[ -z $1 ]] && [[ $wnum -ne 0 ]] || [[ $bnum -ne 0 ]];then

		dialog --title "Info" --colors --msgbox "

$bnum domain/s from Blacklist added to hosts file ( \Z1\ZbBlocked\Zn )
$wnum domain/s from Whitelist removed from hosts file ( \Z2\ZbUnblocked\Zn )" 10 80

	fi

}

function CoreInstall() {

check_connectivity

if [[ $? -eq 0 ]];then

	if [[ -f hosts ]];then
		rm hosts
	fi

	if [[ -f "$hosts_file" ]];then
		mv "$hosts_file" "$hosts_backup"
	fi

	wget "$link" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | dialog --title "Download in progress" --gauge "Downloading $packname hosts ($size) .. Please wait..." 9 80
	(pv -n hosts > "$hosts_file") 2>&1 | dialog --gauge "Merging host" 8 80
	rm hosts
	dialog --title "Success" --colors --msgbox "Successfully installed \Zb\Z4$packname\Zn pack" 6 60
	echo "export current_pack=\"$packname\"
export installedon=\"$(date '+%T %D')\"" > "$config_file"
	MergeLists
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

	packinformation=$(cat "${manifest_file}" | jq ".packs.${1}")
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
   		0)packname="$1";CoreInstall;;
   		1) SelectPack;;
   		255) MainMenu;;
		esac
}

function InitManifest() {

	ext_contributors=$(cat $manifest_file | jq '.dev.contributors' -r)
	ext_version=$(cat $manifest_file | jq '.dev.version' -r)
	manifest_updated=$(cat $manifest_file | jq '.dev.lastupdated' -r)
	maintainer=$(cat $manifest_file | jq '.dev.maintainedby' -r)
	ext_version_code=$(cat $manifest_file | jq '.dev.versioncode' -r)


}

function WhitelistMenu() {

	local dom_count=$(cat $whitelist_file | grep -v "#" | grep "\S" | wc -l )

	HEIGHT=17
    WIDTH=80
    CHOICE_HEIGHT=23
    BACKTITLE="Maintained By $maintainer | Version : $ext_version | Updated on : $manifest_updated"
    TITLE="Domain Whitelist"
    MENU="File location : \Zb$whitelist_file\Zn ( Main Storage )
Domains : \Zb$dom_count\Zn"
    
    OPTIONS=(
	1 "View Whitelist"
	2 "Add Domain to Whitelist"
	3 "Edit Whitelist"
	4 "Apply Whitelist"
	5 "Clear Whitelist"
	)

    opt=$(dialog --clear --colors --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    case $opt in

        1)

	if [[ $dom_count -ne 0 ]];then
		local domains=$(cat $whitelist_file | grep -v "#" | grep "\S" | nl )

		dialog --title "Domains ( $dom_count ) - $whitelist_file" --colors --msgbox "
		$domains" 18 80
	else

		dialog --title "Info" --colors --msgbox "Empty Whitelist" 7 40

	fi

	WhitelistMenu;;

	2)
	local single_domain=$(dialog --title "Add domain to Whitelist" \
         --inputbox "Enter domain:" 8 40 \
  3>&1 1>&2 2>&3 3>&-)

	if  [[ $? -ne 0 ]] || [[ -z $single_domain ]];then
		dialog --title "Info" --colors --msgbox "Domain not added to Whitelist" 7 40
	else
		echo -e "\n$single_domain" >> $whitelist_file
		dialog --title "Info" --colors --msgbox "Domain ($single_domain) added to Whitelist" 7 40
	fi
	WhitelistMenu
	;;

		3)
	dialog --title "Info" --colors --msgbox "You will be taken to nano

\ZuShortcuts\Zn
Press \Zb\Z4Ctrl+O\Zn to Save
Press \Zb\Z4Ctrl+X\Zn to Exit

Press \Zb[Enter]\Zn to continue" 12 40
	nano $whitelist_file
	dialog --title "Info" --colors --msgbox "Updated" 7 40
	WhitelistMenu;;


		4)
	if [[ $dom_count -ne 0 ]];then

		MergeLists "wlist"
		dialog --title "Info" --colors --msgbox "$? domain/s from Whitelist removed from hosts file ( \Z2\ZbUnblocked\Zn )" 7 80
	else

		dialog --title "Info" --colors --msgbox "Empty Whitlist" 7 40

	fi

	WhitelistMenu;;

		5)
	rm $whitelist_file
	dialog --title "Info" --colors --msgbox "Cleared Whitelist file" 6 70
	InitSystem
	WhitelistMenu;;


    esac
else
    MainMenu
fi

}

function BlacklistMenu() {

	local dom_count=$(cat $blacklist_file | grep -v "#" | grep "\S" | wc -l )

	HEIGHT=17
    WIDTH=80
    CHOICE_HEIGHT=23
    BACKTITLE="Maintained By $maintainer | Version : $ext_version | Updated on : $manifest_updated"
    TITLE="Domain Blacklist"
    MENU="File location : \Zb$blacklist_file\Zn ( Main Storage )
Domains : \Zb$dom_count\Zn"
    
    OPTIONS=(
	1 "View Blacklist"
	2 "Add Domain to Whitelist"
	3 "Edit Blacklist"
	4 "Apply Blacklist"
	5 "Clear Blacklist"
	)

    opt=$(dialog --clear --colors --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

if [ $? -eq 0 ]; then # Exit with OK
    case $opt in

        1)

	if [[ $dom_count -ne 0 ]];then
		local domains=$(cat $blacklist_file | grep -v "#" | grep "\S" | nl )

		dialog --title "Domains ( $dom_count ) - $blacklist_file" --colors --msgbox "
		$domains" 18 80
	else

		dialog --title "Info" --colors --msgbox "Empty Blacklist" 7 40

	fi

	BlacklistMenu;;


	2)

	local single_domain=$(dialog --title "Add domain to Blacklist" \
         --inputbox "Enter domain:" 8 40 \
  3>&1 1>&2 2>&3 3>&-)

	if  [[ $? -ne 0 ]] || [[ -z $single_domain ]];then
		dialog --title "Info" --colors --msgbox "Domain not added to Blacklist" 7 40
	else
		echo -e "\n$single_domain" >> $blacklist_file
		dialog --title "Info" --colors --msgbox "Domain ($single_domain) added to Blacklist" 7 40
	fi
	BlacklistMenu
	;;

		3)
	dialog --title "Info" --colors --msgbox "You will be taken to nano

\ZuShortcuts\Zn
Press \Zb\Z4Ctrl+O\Zn to Save
Press \Zb\Z4Ctrl+X\Zn to Exit

Press \Zb[Enter]\Zn to continue" 12 40
	nano $blacklist_file
	dialog --title "Info" --colors --msgbox "Updated" 7 40
	BlacklistMenu;;

		4)
	if [[ $dom_count -ne 0 ]];then

		MergeLists "wlist"
		dialog --title "Info" --colors --msgbox "$? domain/s from Blacklist added to hosts file ( \Z1\ZbBlocked\Zn )" 7 80
	else

		dialog --title "Info" --colors --msgbox "Empty Blacklist" 7 40

	fi

	BlacklistMenu;;

		5)
	rm $blacklist_file
	dialog --title "Info" --colors --msgbox "Cleared Blacklist file" 6 70
	InitSystem
	BlacklistMenu;;

    esac
else
    MainMenu
fi

}

function SelectPack() {

	if [[ $current_pack != "NONE" ]];then

		dialog --title "Warning" --colors --msgbox "It looks like you already installed \Zb\Z4$current_pack\Zn pack\nRestore to install another Pack" 7 60
		MainMenu
	fi

	HEIGHT=15
    WIDTH=80
    CHOICE_HEIGHT=20
    BACKTITLE="Maintained By $maintainer | Version : $ext_version | Updated on : $manifest_updated"
    TITLE="List of Available Packs"
    MENU="Select Any Pack"
    
    let i=0
    OPTIONS=()
    while read -r line; do
    let i=$i+1
    OPTIONS+=($i "$line")
    done < <( cat $manifest_file | jq '.packs | keys[]' -r )

    readpackname=$(dialog --clear --cancel-label "Back" \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)

	if [ $? -eq 0 ]; then # Exit with OK
    	readpack=$(cat $manifest_file | jq '.packs | keys[]' -r | sed "${readpackname}!d")
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
			mv $hosts_backup $hosts_file

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

function BlockDomains() {

	if [[ -f $temp_blacklist ]];then
		rm "$temp_blacklist"
	fi

	dialog --title "Info" --colors --msgbox "You will be taken to nano
\ZuShortcuts\Zn
Press \Zb\Z4Ctrl+O\Zn to Save
Press \Zb\Z4Ctrl+X\Zn to Exit

( instructions available in the editor too )

Note : Current installation only - Use blacklist if you want to apply this to every pack installation

Press \Zb[Enter]\Zn to continue" 18 70
	echo "# DOMAIN BLOCK ( Current installation only ) - Use blacklist if you want to apply this to every pack installation
# Specified domains will be added to hosts file
#
# 1 domain per line
# Press Ctrl+O to save
# Press Ctrl+X to exit/quit
#" >> $temp_blacklist

	nano $temp_blacklist

	local dom_num=$(cat $temp_blacklist | grep -v "#" | grep "\S" | wc -l)

	if [[ $dom_num -eq 0 ]];then
		local dom_num="No"
		local dom_txt=" domains"
	elif [[ $dom_num -eq 1 ]];then
		local dom_txt=" domain"
	else
		local dom_txt=" domains"
	fi

	if [[ $dom_num -gt 0 ]];then

		echo "
# --------------------------------------------
# C U S T O M : $(date '+%T %D')
# --------------------------------------------
" >> $hosts_file
		for domain in $(cat $temp_blacklist | grep -v "#" | grep "\S" );do
			echo -e "0.0.0.0 $domain" >> "$hosts_file"
		done

	fi


	rm $temp_blacklist

	dialog --title "Info" --colors --msgbox "$dom_num$dom_txt blocked ( added to hosts )" 6 60
	CurrentPack  

}

function UnBlockDomains() {

	if [[ -f $temp_whitelist ]];then
		rm "$temp_whitelist"
	fi

	dialog --title "Info" --colors --msgbox "You will be taken to nano

\ZuShortcuts\Zn
Press \Zb\Z4Ctrl+O\Zn to Save
Press \Zb\Z4Ctrl+X\Zn to Exit

( instructions available in the editor too )

Note : Current installation only - Use whitelist if you want to apply this to every pack installation

Press \Zb[Enter]\Zn to continue" 18 70
	echo "# DOMAIN UNBLOCK ( Current installation only ) - Use whitelist if you want to apply this to every pack installation
# Specified domains will be removed from hosts file
#
# 1 domain per line
# Press Ctrl+O to save
# Press Ctrl+X to exit/quit
#" >> $temp_whitelist
	
	nano $temp_whitelist

	local dom_num=$(cat $temp_whitelist | grep -v "#" | grep "\S" | wc -l)

	if [[ $dom_num -eq 0 ]];then
		local dom_num="No"
		local dom_txt=" domains"
	elif [[ $dom_num -eq 1 ]];then
		local dom_txt=" domain"
	else
		local dom_txt=" domains"
	fi

	if [[ $dom_num -gt 0 ]];then

		for domain in $(cat $temp_whitelist | grep -v "#" | grep "\S" );do
			sed -i "/$domain/d" "$hosts_file"
		done

	fi

	rm $temp_whitelist

	dialog --title "Info" --colors --msgbox "$dom_num$dom_txt unblocked ( removed from hosts )" 6 60
	CurrentPack        

}


function CurrentPack() {

	dialog --infobox "Loading Manifest file" 5 50

	packinformation=$(cat "${manifest_file}" | jq ".packs.${current_pack}")
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
    BACKTITLE="Maintained By $maintainer | Version : $ext_version | Updated on : $manifest_updated"
    TITLE="$current_pack"
    MENU="Options to configure"
    
    OPTIONS=(
	1 "Update Pack"
	2 "Block Domains"
	3 "Unblock Domains"
	4 "View Pack Info"
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
		rm $hosts_file
	fi

	wget "$link" 2>&1 | stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | dialog --title "Update in progress" --gauge "Downloading $current_pack hosts ($size) .. Please wait..." 10 80
	(pv -n hosts > "$hosts_file") 2>&1 | dialog --gauge "Merging host" 8 80
	rm hosts
	dialog --title "Success" --colors --msgbox "Successfully Updated \Zb\Z4${current_pack}\Zn pack" 6 60
	echo "export current_pack=\"$current_pack\"
export installedon=\"$(date '+%T %D')\"" > "$config_file"
	MergeLists
	InitSystem
	MainMenu
else
	dialog --title "Failed" --msgbox 'No Internet Connection' 6 60
	MainMenu
fi        ;;

        2)BlockDomains;;

		3)UnBlockDomains;;

        4)
	dialog --clear --colors --msgbox "Pack Information for $current_pack

Blocked Domains : \Z4\Zb${domains}\Zn
Sources : ${sources}
Type : ${type}
Device : ${device}

Download Size : \Zb\Z4${size}\Zn
Last updated on device : $installedon" 17 70
	CurrentPack;;

    esac
else
    MainMenu
fi

}

function About() {

	if [[ $ext_contributors != "NONE" ]];then
		merging_txt="
Contributors:
\Zb$(cat $manifest_file | jq '.dev.contributors[]' -r)\Zn"
	else
		merging_txt=""
	fi

	dialog --title "About" --colors --msgbox "

Developed by SupremeGamers ( https://supreme-gamers.com )

This extension can be used to block Adware, Malware, Porn and unwanted websites.

Maintained by : \Zb$maintainer\Zn - Supreme Gamers

Last updated : \Zb\Z4$manifest_updated\Zn

\Zu\ZbVersion info :\Zn
Version : $ext_version
Version Code : $ext_version_code
$merging_txt

Leave a review on the Website if you like this
" 18 80

	MainMenu

}

function MainMenu() {

	InitSystem

    HEIGHT=17
    WIDTH=80
    CHOICE_HEIGHT=23
    BACKTITLE="Maintained By $maintainer | Version : $ext_version | Updated on : $manifest_updated"
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

        2)WhitelistMenu;;

        3)BlacklistMenu;;

	   	4)Restorehost;;

        5)About;;

    esac
else
    exit
fi

}
InitSystem
InitManifest
MainMenu