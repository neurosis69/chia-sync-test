export CHIA_PASSPHRASE_SUPPORT=false
export ANSIBLE_CALLBACKS_ENABLED=profile_roles
export ANSIBLE_LOG_FOLDER=/home/chia/chia-sync-test
export ANSIBLE_STDOUT_CALLBACK=debug
ANSIBLE_REMOTE_TEMP=/chia_temp1/.ansible/tmp ansible-playbook synctest.yml 
