#!/gearlock/bin/bash


energized_dir="/data/.energized"

if [[ -f "${energized_dir}/config.jax" ]];then

read -p "Do you want to remove pack installation [Y/n]:" prompt

case $prompt in
	y|Y) rm /etc/hosts.bak;;
	*)echo "
[-] Skipping Host Removal";;
esac

fi
echo ""

rm "${energized_dir}/" -r




