# CHIA - db sync performance tests

Ansible playbook (for local execution) to start a chia db `long sync` for some predefined Scenarios.

The scenarios are chosen to reflect high transaction volumes like Transaction Start or Dust Storms.

***Current Testcases are prepared for chia version 1.2.11 only.*** 

## Get started

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

### Configure local host variables

Change Variables in file `config/local_config.yml` according to your local system.

Variable|Example
---|---
CHIA_OS_USER| chia
CHIA_OS_GROUP| chia
CHIA_GIT_REPO| https://github.com/Chia-Network/chia-blockchain.git
CHIA_BRANCH| 1.2.11
CUSTOM_LOGGING| info
ANSIBLE_REMOTE_TEMP| /chia_temp1/.ansible/tmp
SADC_BIN_PATH| /usr/lib64/sa
BLOCKCHAIN_DB_NAME| blockchain_v1_mainnet.sqlite
BLOCKCHAIN_DB_PATH| /chia_temp1/Blockchain_DB
OS_USER_HOME| /home/chia
CHIA_SW_PATH| /home/chia/chia-blockchain
ANSIBLE_HOME_PATH| /home/chia/chia-sync-test
ANSIBLE_LOG_PATH| /home/chia/chia-sync-test/log

***Variable values must not depend on other variables.***

For instance, using `ANSIBLE_HOME_PATH: "{{ OS_USER_HOME }}/chia-sync-test"` will not work!

Variable|Additional Information
---|---
CUSTOM_LOGGING|all chia log levels are valid. choose the log level you want to use for additional logging for _block pre validation time_, _block receive time_ or _DB write time_. Depending on your system and the chosen scenario, this will generate a lot of log entries. (FULLSYNC > 100M).
ANSIBLE_REMOTE_TEMP|Path to the directory where the db file will be staged during download/unpack
SADC_BIN_PATH|directory path to the binary sadc

### Setup chia-sync-test

```
cd ~/chia-sync-test
ansible-playbook setup.yml
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
 TRANSACTION_PEAK | 739202 | 740736 | 772928 | Some transactions peaks in (Aug 2021)

##### SQLite Databases

For every Scenario one initially fresh synced chia db is prepared as follows:
* synced until mentioned "DB Height"
* droped all indexes, except the following:
  * peak on block_records(is_peak) where is_peak=1
  * full_block_height on full_blocks(height)
  * hint_index on hints(hint)
* finally vacuumed the db

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

- If applicable, place the blockchain db on ramdisk
