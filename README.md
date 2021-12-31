# CHIA - db sync performance tests

Ansible playbook (for local execution) to start a chia db `long sync` for some predefined Scenarios.

The scenarios are chosen to reflect high transaction volumes like Transaction Start or Dust Storms.

***Current Testcases are prepared for chia version 1.2.11 only.*** 

## SQLite Databases

For every Scenario one initially fresh synced chia db is prepared as follows:
* synced until mentioned "DB Height"
* droped all indexes, except the following:
  * peak on block_records(is_peak) where is_peak=1
  * full_block_height on full_blocks(height)
  * hint_index on hints(hint)
* finally vacuumed the db

## Testcase/Scenario Configuration

All testcases are db related.

Some of them are only as baseline or for fun (like drop ALL indexes, or certain obscure page sizes).

The testcases eligible for the current execution are configured in the `ACTIVE_TESTCASES` json Section in [testcases.json](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/testcases.json)

#### Reasonable Testcases

More reasonable testscases are limited to the following:

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

 | Scenario | DB Height | Scenario Start Height | Scenario End Height | Description |
 | --- | --- | --- | --- | --- |
 | DUSTSTORM1 | 1069664 | 1070016 | 1080000 | First dust storm (end Oct 2021) |
 | DUSTSTORM2 | 1303062 | tbd | tbd | Second dust storm (mid Dec 2021) |
 | TRANSACTION_START | 223648 | 225696 | 228000 | Transaction start on mainnet |
 | TRANSACTION_PEAK | 739202 | tbd | tbd | Some transactions peaks in (Aug 2021) |

## Variables
 | Script | Parameter | Values | Description |
 | --- | --- | --- | --- |
 | [run_synctest.sh](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/run_synctest.sh) | ANSIBLE_LOG_FOLDER | _<custom_path>_ | base path to the log directory |
 | [run_synctest.sh](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/run_synctest.sh) | ANSIBLE_REMOTE_TEMP | _<custom_path>_ | path to ansible temp directory to stage files for downloads etc |
 | [synctest.yml](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/synctest.yml) | CHIA_BRANCH | 1.2.11 | dependency to role templates |
 | [synctest.yml](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/synctest.yml) | SCENARIO | TRANSACTION_START | Testscenario covering the heights of first chia transactions |
 | [synctest.yml](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/synctest.yml) | SCENARIO | DUSTSTORM1 | Testscenario covering the heights of first dust storms (end Oct 2020) |
 | [synctest.yml](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/synctest.yml) | SADC_BIN_PATH | /usr/lib64/sa | for Clear Linux |
 | [synctest.yml](https://github.com/neurosis69/chia-sync-test/blob/0e177a34ebddab7d1d3a56f7d6c00a2fe3c37275/synctest.yml) | SADC_BIN_PATH | /usr/lib/sysstat | for Ubuntu Linux |

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
