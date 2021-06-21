#!/gearlock/bin/bash

get_base_dir

energized_dir="/data/.energized"

if [[ ! -d "$energized_dir" ]];then
	mkdir "$energized_dir" -p
fi

echo "[*] Placing Important Files"
cp "${BD}/jq" "/system/bin/jq"
cp "${BD}/manifest.json" "${energized_dir}/manifest.json"


