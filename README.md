# CHIA - blockchain db sync tests

Ansible Roles to help automate blockchain syncs using real world peers.

## Steps done

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

**Reports with interesting findings are uploaded to 
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
ANSIBLE_HOME_PATH|"/home/chia/chia-sync-test"|Ansible repo clone path
ANSIBLE_LOG_PATH|"/home/chia/chia-sync-test/log"|Log dir Path
ANSIBLE_LOG_FILENAME|"/home/chia/chia-sync-test/log/ansible_playbook.log"|Logfile Path
ANSIBLE_CALLBACKS_ENABLED|"profile_roles"|Ansible Callbacks
ANSIBLE_STDOUT_CALLBACK|"debug"|Ansible stdout

### Setup chia-sync-test

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

### Check Testcases/Scenarios

Available testcases and scenarios are defined in `config/testcase_definition.json`.

Some testcases are only meant as baseline or for fun (like drop ALL indexes, or certain obscure page sizes).

JSON Section|Description
---|---
.SCENARIO|Defintion of all available scenarios
.DEFAULT|Default values from branch 1.2.11
.AUTOTEST*|Changes per testcase to default

### Configure Testcases

Open file `config/active_testcases.json` and create JSON list with testcases.

e.g. if you want to test testcases AUTOTEST1, AUTOTEST3 and AUTOTEST45 then the config file should look like:
```
{
  "ACTIVE_TESTCASES": [
      "AUTOTEST1",
      "AUTOTEST3",
      "AUTOTEST45"
    ]
}
```

### Configure Scenarios

Open file `config/active_scenario.yml` and create yml variable entry.

e.g. if you want to test scenario DUSTSTORM1 then the config file should look like:
```
---
SCENARIO: "DUSTSTORM1"
```

##### Available Scenarios

 Scenario | DB Height | Scenario Start Height | Scenario End Height | Description
 --- | --- | --- | --- | --- |
 FULLSYNC | 0 | 225696 | _dynamic_ | sync until first mainnet transaction and then until peak
 DUSTSTORM1 | 1069664 | 1070016 | 1080000 | First dust storm (end Oct 2021)
 DUSTSTORM2 | 1303062 | 1304608 | 1316352 | Second dust storm (mid Dec 2021)
 TRANSACTION_START | 223648 | 225696 | 228000 | Transaction start on mainnet
 TRANSACTION_PEAK | 739202 | 740738 | 772930 | Some transactions peaks in (Aug 2021)

##### SQLite Database

For every Scenario, except for FULLSYNC, one initially fresh synced chia db was prepared as follows:
* synced until mentioned "DB Height"
* droped all indexes, except the following:
  * peak on block_records(is_peak) where is_peak=1
  * full_block_height on full_blocks(height)
  * hint_index on hints(hint)
* finally vacuumed the db
* compressed using zip

If you want to use a db for production, please use Scenario FULLSYNC.

##### Necessary steps to use db after FULLSYNC

1. Shutdown all chia processes, if not already done
2. If Device=RAMDISK, move DB to persistent storage
3. Remove ~/chia-blockchain SW and reinstall using [chia install instructions](https://github.com/Chia-Network/chia-blockchain/wiki/INSTALL)
4. Start node -> this will recreate all missing indexes

### Start Test

After completing setup and configuration start the test.

```
./run_synctest.sh
```

## Process Sequence

1. Create Log Directories
2. Download DB from dropbox
3. Unpack DB
4. Setup CHIA with given branch
5. Run testcases for given scenario
   - start sadc data gathering
   - stop chia processes (`chia stop all -d`) and cleanup old db files
   - copy unpacked db file
   - change special sqlite parameters according to testcase and execute vacuum afterwards
     - page_size
     - auto_vacuum
   - change SW files according to testcase and local configuration
   - clear FS cache (echo 1)
   - start chia full node
   - actively reconnect to peers until a minimum of 15 is reached (loop until sadc process is killed)
   - sync until defined end height is reached
   - stop chia processes (`chia stop all -d`)
   - get sqlite db size
   - kill sadc process
   - create sar csv and svg output files

## Logging

The logfiles are located in **{{ ANSIBLE_LOG_PATH }}**

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

## Testcase documentation

The most reasonable testcases are

Testcase|Description|Why?
---|---|---
AUTOTEST1|No Changes from branch|Baseline
AUTOTEST3|From Block Store, only use fullblocks height and peak index; Drop all coin store indexes|Best Index related sync performance
AUTOTEST5|Only full blocks height + peak index; plus max num workers for block chain consensus|Best pre-validation times (important for RPi)
AUTOTEST45|Only full blocks height + peak index; locking_mode=exclusive, synchronous=OFF, journal_mode=off, increase coin_records lru cache * 100, cache_spill=false, uncommited=true, max blockchain consensus threads|Best sync performance overall

## Other performance improvements

- If applicable, place the blockchain db on ramdisk during fullsync

# Possible further sync improvements

- create separate `long sync` job
  - `chia start node fullsync` to sync from scratch and sync using special connection pragmas
  - only create the 2 needed indexes during fullsync
  - [allow more than 32 blocks](https://github.com/Chia-Network/chia-blockchain/blob/13ff7489b606d38b8294ed8c256d0177d39eb4bb/chia/consensus/default_constants.py#L52) per request for `long sync` 
- [remove cpu thread limitation](https://github.com/Chia-Network/chia-blockchain/pull/9709#issue-1092109095)
- increase coin store cache size times 100, instead of [60000](https://github.com/Chia-Network/chia-blockchain/blob/13ff7489b606d38b8294ed8c256d0177d39eb4bb/chia/full_node/coin_store.py#L28) use 6000000. suggestion was not calculated but tested with signifcant improvement (at RPi as well).

# Known Issues

- The ansible [async task](https://github.com/neurosis69/chia-sync-test/blob/ad41a66e2a626e9aef92404602a4462143574c49/roles/execute_sync_tests/tasks/main.yml#L135) to keep enough valid peers connected is not working on my Ubuntu RPi Setup, but is working on Clear Linux Setup .. _still investigating_.

  Workaround: Execute the shell commands separately.
