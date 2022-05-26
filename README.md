# CHIA - blockchain db sync tests

Ansible Roles to help automate blockchain syncs using real world peers.

## Steps executed

1. Download a prepared sqlite db file for the chosen test scenario
2. Start sar activity data collector to gather performance statistics
3. Stop all chia processes on localhost
4. Remove old blockchain db files from location specified in vars/chia.yml
5. Prepare localhost (page_size, copy db file, clear caches, write logfiles)
6. Download and install chia (replace existing)
7. Start chia
8. Wait until specified testcase end-height is reached
9. Stop chia
10. Gather data and create reports (sar reports)

**Reports are uploaded to 
[my other repo](https://github.com/neurosis69/chia-sync-data).**

## Get started

This role is only used and tested on localhost target execution. 

### Install ansible

Ubuntu: `sudo apt install ansible`

Clear Linux: `sudo swupd bundle-add ansible`

Archlinux: `sudo pacman -S ansible`

### Other Dependencies/Prerequisites

* sysstat packages: sadc, sadf
* sudo
* dig

### Clone Repo
```
git clone https://github.com/neurosis69/chia-sync-test.git
```

### Chia Configuration (vars/chia.yml)

Variable|Default|Description
---|---|---
CHIA_GIT_REPO|"https://github.com/neurosis69/chia-blockchain.git" |Repo used for testcases
CHIA_BRANCH|"main"|Default branch for baseline
BLOCKCHAIN_DB_PATH|"/chia_temp1/synctest"|Path to blockchain db
BLOCKCHAIN_DB_NAME|"blockchain_v2_mainnet.sqlite"|blockchain db name
CHIA_OS_USER|"chia"|O/S user running chia
CHIA_OS_GROUP|"chia"|O/S group
OS_USER_HOME|"/home/chia"|O/S user home directory
CHIA_SW_PATH|"/home/chia/chia-blockchain"|Chia SW installation path 
CHIA_LOGGING|"info"|Chia Logging
CHIA_PASSPHRASE_SUPPORT|false|Disable Chia Passphrase

### Ansible Configuration (vars/ansible.yml)

Variable|Default|Description
---|---|---
ANSIBLE_REMOTE_TEMP|"/ramdisk/.ansible/tmp"|Ansible temp directory, size minimum 30G</br>used to stage downloaded files
ANSIBLE_HOME_PATH|"/home/chia/chia-sync-test"|Repo clone path
ANSIBLE_LOG_PATH|"/home/chia/chia-sync-test/log"|Log dir Path
ANSIBLE_LOG_FILENAME|"/home/chia/chia-sync-test/log/ansible_playbook.log"|Logfile Path
ANSIBLE_CALLBACKS_ENABLED|"profile_roles"|Ansible Callbacks
ANSIBLE_STDOUT_CALLBACK|"debug"|Ansible stdout

### Setup

```
cd ~/chia-sync-test
ansible-playbook setup.yml
```

* Install necessary O/S packages
* Create test start shell script `run_synctest.sh`

Content of `run_synctest.sh` using default variables
```shell
#!/bin/bash
export CHIA_PASSPHRASE_SUPPORT=False
export ANSIBLE_CALLBACKS_ENABLED=profile_roles
export ANSIBLE_LOG_PATH=/home/chia/chia-sync-test/log/ansible_playbook.log
export ANSIBLE_STDOUT_CALLBACK=debug
ANSIBLE_REMOTE_TEMP=/ramdisk/.ansible/tmp ansible-playbook synctest.yml
```

## Scenarios and Testcases

### Scenario Configuration (vars/scenario_definition.json)

A scenario defines the scope in which the selected testcases are executed.

<ins>Predefined Scenarios</ins>
Name|Start Height|What is it?|Schema
---|---|---|---
DUSTSTORM1|1069664|First Duststorm|v1
DUSTSTORM2|1303062|Second Duststorm|v1
TRANSACTION_START|223648|Transaction Start|v1
TRANSACTION_PEAK|739202|First Transaction Peak|v1
FULLSYNC|0|Full sync from genesis block|v1,v2
V2_DUSTSTORM|1528704|Persistent Duststorm|v2
V2_DUSTSTORM_EXT|1528704|Persistent Duststorm extended|v2
V2_DS_FULLSYNC|1528704|Persistent Duststorm up to peak|v2

<ins>Scenario Parameters</ins>
Parameter|Value
---|---
DB_BACKUP_NAME|Filename of blockchain backup
DB_BACKUP_URL|Dropbox URL to backup
DB_BACKUP_MD5SUM|currently not in use
SYNC_START_HEIGHT|Current height from backup file
DUST_START_HEIGHT|Intermediate height to get timings
DUST_END_HEIGHT|End height, abort sync

### Configure Active Scenario (vars/active_scenario.yml)

Select which scenario to use for the testrun.

```yaml
---
ACTIVE_SCENARIO: "V2_DS_FULLSYNC"
```

### Testcase Configuration (vars/testcase_definition.json)

A testcase defines which git branches will be used to sync in the selected scenario.

<ins>Example testcase definition</ins>
```json
{
  "DEFAULT": {
    "DESCRIPTION": "Main branch, no changes",
    "CHIA_BRANCH": "main",
    "CHANGE_PAGE_SIZE": false,
    "PAGE_SIZE": 4096
  },
  "AUTOTEST4": {
    "DESCRIPTION": "Drop all indexes except for height and main_chain on full_blocks",
    "CHIA_BRANCH": "main_scenario4",
    "CHANGE_PAGE_SIZE": false,
    "PAGE_SIZE": 4096
  }
}
```

### Configure Active Scenario (vars/active_testcases.json)

Select which testcases to use for the restrun.

```json
{
  "ACTIVE_TESTCASES": [
    "DEFAULT",
    "AUTOTEST4"
  ]
}
```

## Blockchain sqlite database

For every Scenario, except for FULLSYNC, one initially fresh synced chia db was prepared as follows.

If you plan to use a db for production, please use Scenario FULLSYNC and get a self verified database.

### Schema v1

* synced until mentioned "DB Height"
* droped all indexes, except the following:
  * peak on block_records(is_peak) where is_peak=1
  * full_block_height on full_blocks(height)
  * hint_index on hints(hint)
* finally vacuumed the db
* compressed using zip

### Schema v2

* synced until mentioned "DB Height"
* compressed using zip

### Start Test

After completing setup and configuration start the test.

```
./run_synctest.sh
```

## Logging

The logfiles are located in **{{ ANSIBLE_LOG_PATH }}** (default: `/home/chia/chia-sync-test/log`)

#### Directory Tree

```bash
.
├── 2022-01-02_01:28:13
│   ├── chia
│   │   ├── plotter1_chia_debug_AUTOTEST36.11.log
...
│   │   └── plotter1_chia_debug_AUTOTEST7.15.log
│   ├── plotter1_ansible_run_AUTOTEST36.11.sa.csv
...
│   ├── plotter1_ansible_run_AUTOTEST7.15.sa.svg
│   ├── plotter1_ansible_run.csv
│   └── sa
│       ├── plotter1_1641083293_AUTOTEST36.11.sa.data
...
│       └── plotter1_1641083293_AUTOTEST7.15.sa.data
├── ...
├── 2022-01-03_21:55:53
│   ├── chia
│   ├── plotter1_ansible_run.csv
│   └── sa
├── ansible_playbook.log
├── current -> /home/chia/chia-sync-test/log/2022-01-03_21:55:53
```

#### Important logfiles

- `log/current` always points to the current or most recent log directory
- `log/ansible_playbook.log` contains continuus log entries from playbook executions
- `log/YYYY-MM-DD_HH24:MI:SS/plotter1_ansible_run.csv` contains the summary timings of the plays
```csv
HOSTNAME,SCENARIO,TESTCASE,START_RUN,LOG_INITIATE_SYNC,LOG_START_SYNC,LOG_DUST_START_SYNC,LOG_DUST_STOP_SYNC,SQLITE_DB_SIZE_BYTES,DESCRIPTION
plotter1,DUSTSTORM1,AUTOTEST32,2022-01-01T09:44:10,2022-01-01T09:44:34,2022-01-01T09:45:44,2022-01-01T09:46:21,2022-01-01T10:23:24,22398107648,"Only full blocks height + peak index; increase coin_records lru cache * 500"
plotter1,DUSTSTORM1,AUTOTEST33,2022-01-01T10:23:39,2022-01-01T10:23:48,2022-01-01T10:24:56,2022-01-01T10:25:23,2022-01-01T11:02:02,22398107648,"Only full blocks height + peak index; locking_mode=exclusive, synchronous=OFF, journal_mode=off, uncommited=true, increase coin_records lru cache * 500"
```
- `log/YYYY-MM-DD_HH24:MI:SS/chia/plotter1_chia_debug_AUTOTEST36.11.log` redirected chia debug.log, one separate file per testcase
- `log/YYYY-MM-DD_HH24:MI:SS/sa/plotter1_1641083293_AUTOTEST36.11.sa.data` raw data written by sadc process during the sync of the testcase
- `log/YYYY-MM-DD_HH24:MI:SS/plotter1_ansible_run_AUTOTEST36.11.sa.csv` auto generated csv file from sar rawdata by predefined parameters
- `log/YYYY-MM-DD_HH24:MI:SS/plotter1_ansible_run_AUTOTEST36.11.sa.svg` auto generated svg file from sar rawdata by predefined parameters


## Other performance improvements

- If applicable, place the blockchain db on ramdisk during fullsync
