lsidrivemap.sh
======================

This script provides  similar functionality as [louwrentius/lsidrivemap](http://github.com/louwrentius/lsidrivemap), but for LSI controllers that use the sas2ircu configuration utility instead of megacli (e.g. Dell H200 and LSI 9211-8i controllers)

Example output (I have one missing drive):
```
root@server:~# lsidrivemap.sh -h
Usage: /usr/local/bin/lsidrivemap.sh [-c] <path> [option]

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

root@server:~# lsidrivemap.sh
-------------------------
| sdq | sdm | sdi | sdc |
| sdp | sdl | sdh | sdf |
| sdo | sdk |     | sde |
| sdn | sdj | sdg | sdd |
-------------------------
root@server:~# lsidrivemap.sh -t
---------------------
| 37 | 35 | 34 | 33 |
| 37 | 36 | 32 | 30 |
| 38 | 32 |    | 29 |
| 32 | 31 | 30 | 29 |
---------------------
root@server:~# lsidrivemap.sh --smart 5
-----------------
| 0 | 0 | 0 | 0 |
| 0 | 0 | 0 | 0 |
| 0 | 0 |   | 0 |
| 0 | 0 | 0 | 0 |
-----------------
```

Install
----------------------
- Download the sas2ircu utility from the LSI/Avago website and copy the utility to e.g. /usr/local/bin
- Save the lsidrivemap.sh script also in e.g. /usr/local/bin
- Edit the script and adjust the driveMap to your situation. The numbers used are the controller numbers & drive numbers retured by the sas2ircu utility (run `sas2ircu info` to list the controllers and `sas2ircu <controller_number> display` to show the driver numbers)

Requirements
----------------------
You need to have udev installed to populate /dev/disk/by-id/wwn-0xXXXXXXXXXXXX. The sas2ircu utility returns the WWN / GUID and we use that to retrieve the device mapping (/dev/sdX) and run smartctl commands on. Surprisingly you also need smartctl if you want to return smart values.

Tested
----------------------
Tested on Ubuntu 14.04.3 LTS, 16.04 LTS with Dell H200A & H200I controllers both flashed to LSI 9211-8i P20 firmware


