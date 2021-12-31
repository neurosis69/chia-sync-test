# CHIA - db sync performance tests

(Local) ansible playbook to start a chia db `long sync` for given Scenarios (Heights).

The scenarios are chosen to reflect high transaction volumes like Transaction Start or Dust Storms.

## SQLite Databases

For every scenario one fresh synced chia db is prepared as follows:
* synced until mentioned "DB Height"
* droped all indexes except:
  * peak on block_records(is_peak) where is_peak=1
  * full_block_height on full_blocks(height)
  * hint_index on hints(hint)
* vacuumed

## Testcase/Scenario Configuration

All testcases are db related.

Some of them are only as baseline or for fun (like drop ALL indexes, or certain obscure page sizes).

The testcases for the current execution are configured in: `testcases.json`

#### Reasonable Testcases

The following testcases 

```json
  "ACTIVE_TESTCASES": [
      "AUTOTEST1",
      "AUTOTEST3",
      "AUTOTEST5",
      "AUTOTEST7",
      "AUTOTEST12",
      "AUTOTEST13",
      "AUTOTEST15",
      "AUTOTEST16",
      "AUTOTEST24",
      "AUTOTEST25",
      "AUTOTEST26",
      "AUTOTEST28"
    ]
```

## Scenarios

* DUSTSTORM1
  * DB Height: 1069664
  * Start Height: 1070016
  * End Height: 1080000

* DUSTSTORM2 (currently not available)
  * DB Height: 1303062
  * Start Height: tbd
  * End Height: tbd

* TRANSACTION_START
  * DB Height: 223648
  * Start Height: 225696
  * End Height: 228000

* TRANSACTION_PEAK (currently not available)
  * DB Height: 739202
  * Start Height: tbd
  * End Height: tbd

## Variables
#### run_synctest.sh

* **ANSIBLE_LOG_FOLDER**: base path to the log directory

* **ANSIBLE_REMOTE_TEMP**: path to ansible temp directory to stage files for downloads etc

#### sycntest.yml

* **CHIA_BRANCH**: 1.2.11 (dependency to role templates)

* **SCENARIO**: TRANSACTION_START or DUSTSTORM1

* **SADC_BIN_PATH**: 
  * Clear Linux: /usr/lib64/sa
  * Ubuntu: /usr/lib/sysstat

## Dependencies/Prerequisites

* ansible
* sysstat packages: sadc, sadf
* sudo
* dig

## Start 

After checking all files and changing variables and paths:

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
