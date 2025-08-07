# `linux-cis-compliance`

Developed by Ivan Ng in coordination with Hundred Plus Global Ltd.

Fixes left: 142 - 17 = 125

## Description
Scripts that ensure CIS compliance on Linux according to the CIS Linux Distribution Independent benchmark v2.0.0. **Note that this project is still work in progress**, these scripts have not been tested thoroughly yet. Feel free to use these scripts, but beware of the risks posed to the system. You were warned. A spec of this CIS Linux Distribution Independent benchmark v2.0.0 can be found [here](https://github.com/skylens/CIS/blob/master/CIS_Distribution_Independent_Linux_Benchmark_v2.0.0.pdf).

## Usage
Each script has their own descriptive filename which indicates the areas of the system that aforementioned script will harden. To customize, change the number values associated with the variable at the top level of the file. Most of them are simply switching the value from 1 and 0, but there are special variables which do not follow that rule, they should be annotated by the comments beside it.

## Roadmap
Here is the roadmap for this project
1. - [ ] Complete ALL fixes listed in the benchmark
2. - [ ] Improve logging of the scripts to include colored output and separate functions for logging
3. - [ ] Use `JSON` for configuration
4. - [ ] Implement the system for translating the `JSON` into the `variable_name=value` for shell scripts.
5. - [ ] Improve logic of the scripts to reduce repeated code
6. - [ ] Testing on a virtual machine to see if the desired fixes are applied

## Testing
Below is a table of the scripts that have been tested
| Script | Test Status | Additional Comments |
|--------|-------------|---------------------|
| `ssh-fixes.sh` | | |
| `netconfig.sh` | | |
| `harden-files.sh` | |
| `filesystem-harden.sh` | | |