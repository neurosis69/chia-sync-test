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

## Logging


The logfiles are located in **{{ ANSIBLE_LOG_PATH }}** 

For the current run, there is a softlink **{{ ANSIBLE_LOG_PATH }}/current**

Logfiles in **{{ ANSIBLE_LOG_PATH }}/current** are
* ansible run details: {{ ansible_hostname }}\_ansible\_run.csv (constantly written)
* sar csv: {{ ansible_hostname }}\_ansible_run\_{{ TESTCASE }}.sa.csv (written after Testcase)
* sar svg: {{ ansible_hostname }}\_ansible_run\_{{ TESTCASE }}.sa.svg (written after Testcase)

Logfiles in **{{ ANSIBLE_LOG_PATH }}/current/chia** are
* logfile known as debug.log: {{ ansible_hostname }}\_chia_debug\_{{ TESTCASE }}.log

sadc raw data in **{{ ANSIBLE_LOG_PATH }}/current/sa** are:
* {{ ansible_hostname }}\_{{ ansible_date_time.epoch }}\_{{ TESTCASE }}.sa.data
