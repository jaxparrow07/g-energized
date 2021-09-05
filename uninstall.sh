#!/gearlock/bin/bash


energized_dir="/data/.energized"

if [[ -f "${energized_dir}/config.jax" ]];then

read -p "Do you want to remove pack installation [Y/n]:" prompt

case $prompt in
	y|Y) rm /etc/hosts && mv /etc/hosts.bak /etc/hosts
echo "
[+] Removed Host changes";;

	*)echo "
[-] Skipping Host Removal";;
esac

fi
echo ""

rm "${energized_dir}/" -r




