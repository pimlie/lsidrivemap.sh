#!/usr/bin/env bash

# adjust the disk mapping below to your situation
# mapping is  on controllerNumber,portNumber
diskMap="
1,4 1,0 0,4 0,0
1,5 1,1 0,5 0,1
1,6 1,2 0,6 0,2
1,7 1,3 0,7 0,3
"

# you can specificy the path to sas2ircu below, otherwise
# we expect the command to be avaiable within the path
lsiCmd=$(command -v sas2ircu)

# optional, specify location of smartctl
#smartCmd=$(command -v smartctl)

#######################################################################

while [ $# -gt 0 ]; do
  case "$1" in
    -c)
      lsiCmd="$2"
      shift
      ;;
    -d)
      portInfo="type"
      ;;
    -f)
      portInfo="firmware"
      ;;
    -s)
      portInfo="state"
      ;;
    --smart)
      portInfo="smart"
      smartValue=$2
      shift
      ;;
    -n|-sn)
      portInfo="serial"
      ;;
    -t)
      portInfo="smart"
      smartValue=194
      ;;
    -w)
      portInfo="wwn"
      ;;
    -h|--help|*)
      echo "Usage: $0 [-c] <path> [option]

option information:
  -c <path>     The path to the sas2ircu configuration utility
  -d            Show the disk type
  -f            Show the firmware of the drive
  -s            Show the disk state
  --smart <num> Show the specified smart attribute
  -n|-sn        Show the drive serial number
  -t            Show the temperature of the drive, alias for --smart 194
  -w            Show the world wide name (wwn) of the drive
  -h            Display this message
"
      exit
      ;;
  esac
  shift
done

if [ ! -f "$lsiCmd" ] || [ ! -x "$lsiCmd" ] || [ -z "$($lsiCmd 2>/dev/null)" ]; then 
  echo "LSI Corporation SAS2 IR Configuration Utility (sas2ircu) not found or not executable, please put the location of the executable in the path or pass the location with -s /path_to_sas2ircu" 
  exit 1 
fi

numControllers=$($lsiCmd list | grep -c "Index")
if [ -z "$numControllers" ] || [ "$numControllers" -eq 0 ]; then 
  echo "No LSI Corporation SAS2 Controllers found" 
  exit 
fi

if [ -z "$portInfo" ]; then portInfo="disk"; 
elif [ "$portInfo" = "smart" ]; then
  if [ -z "$smartValue" ]; then
    echo "You have to supply the smart id of the attribute you want to show"
    exit;
  fi
  if [ -z "$smartCmd" ]; then smartCmd=$(command -v smartctl); fi
  if [ ! -x "$smartCmd" ]; then 
    echo "Cannot find smartctl in the path, please install smartctl or specify the location" 
    exit 1 
  fi
fi

IFS="
"

declare -A disks
cellLength=1

for controllerNum in $(seq 0 $((numControllers - 1))); do
  controllerInfo=$($lsiCmd "$controllerNum" display)

  #portsPerController[$controllerNum]=$(echo "$controllerInfo" | grep "Numslots" | cut -d":" -f 2)
  
  awkDiskInfo='
BEGIN { separator="|"; diskNum = -1 }
{
type = gensub(/[ \t]+/,"","g",$1);
value = gensub(/((^[ \t]+)|([ \t]+$))/,"","g",$2);

if (type=="Slot#") {
  diskNum = value;
} else if (diskNum > -1 && (type=="" || substr(type, 0, 6)=="------")) {
  print diskNum separator disk["GUID"] separator disk["SerialNo"] separator disk["ModelNumber"] separator disk["State"] separator disk["FirmwareRevision"];
  diskNum = -1;
  delete disk;
}

if (diskNum > -1) {
  disk[type] = value;
}
}'
  
  for diskInfo in $(echo "$controllerInfo" | awk -F":" "$awkDiskInfo"); do
    IFS="|"
    read -r -a disk <<< "$diskInfo"
    diskNum=${disk[0]}
    
    case "$portInfo" in
      "wwn")
        value=${disk[1]}
        ;;
      "serial")
        value=${disk[2]}
        ;;
      "type")
        value=${disk[3]}
        ;;
      "state")
        value=${disk[4]}
        ;;
      "firmware")
        value=${disk[5]}
        ;;
      "disk")
        value=$(basename "$(readlink "/dev/disk/by-id/wwn-0x${disk[1]}")")
        ;;
      "smart")
        value=$($smartCmd -A "/dev/disk/by-id/wwn-0x${disk[1]}" | grep "^\s*$smartValue " | awk '{print $10}')
        ;;
    esac
    
    disks[$controllerNum,$diskNum]=$value
    if [ ${#value} -gt $cellLength ]; then cellLength=${#value}; fi
  done
  
  IFS="
"
done

rows=$(echo "$diskMap" | awk 'NF > 0' | wc -l)
columns=$(( ($(echo "$diskMap" | wc -w) + rows - 1) / rows ))
tableLength=$(( (cellLength + 3) * columns + 1))
line=$(printf '%'$tableLength's' | tr ' ' -)

echo "$line"
for row in $diskMap; do
  IFS=" "

  for column in $row; do
    printf '| %'"$cellLength"'s ' "${disks[$column]}"
  done
  echo "|"
done
echo "$line"
