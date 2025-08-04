# `linux-cis-compliance`

## Description
Scripts or instructions that ensure CIS compliance (for linux, on the distro independent benchmark). Please check thoroughly, and run with root permissions.

## Repository Structure
If you only want to apply single fixes, open the `single-scripts` folder and open the corresponding folder with the CIS ID of your vulnerability. All items are sorted via CIS vulnerablity report ID, either like: `000000` or with a range `000000 - 000001` which indicates that the fix is similar or the same with changes to the input only

Open `group-fixes` for fixes in bulk that belong to one "group", e.g. for `ssh`, configuring `auditd`, etc.

Open & run `comprehensive-fix.sh` to run and achieve full CIS compliance in one script.