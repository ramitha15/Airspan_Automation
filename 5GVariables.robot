*** Settings ***
Library    SSHLibrary  timeout=30s
#Library    SSHLibrary

*** Variables ***
${RESOURCES}    /home/kvramesh/automation/Latest/Resources/
${QCI6}          0x88
${QCI7}          0xb8
${QCI9}          0x1c
${AC_IP}         192.168.4.51
${AC_USER}       admin
${Amari_PASS}    toor   
${DURATION}      64800
${ANSIBLE_IP}        10.80.0.5
${ANSIBLE_USER}      airspan
${ANSIBLE_PASS}      localadmin
${MME_IP}        10.80.0.7
${MME_USER}      iperf-user
${MME_PASS}      localadmin
${MME_PORT}      22
${MARSHAL_IP}       10.80.1.121
${MARSHAL_USER}     admin
${MARSHAL_PASS}     gogo2021
${MARSHAL_PORT}     22
${amari_ue1_ip}	10.80.1.25	
${attach_cmd}    power_on
${pdn_cmd}    pdn_connect 1 int
${sudo}		sudo -s
${dettach_cmd}   power_off
${get_cmd}    get -vv 10
${ul_tp}    40m
@{UES} =
...    1    13.12.3.2    13.12.4.2   10.80.6.168  
#...    2    13.12.4.2   13.12.8.10   10.80.6.168
#...    3    13.12.7.18   13.12.8.18   10.80.6.198
#...    4    13.12.7.6    13.12.8.6    10.80.6.165
#...    5    13.12.7.14   13.12.8.14   10.80.6.169
#...    6    13.12.7.22   13.12.8.22   10.80.6.202
${MME_TUN_IP1}    13.12.7.1
${MME_TUN_IP2}    13.12.8.1
${THRESHOLD}      9000
${SAMPLE_INTERVAL}    5s
${RESULT_FILE}    dl_throughput_samples.txt
@{Aircard} =
...    1    5170026922    UE1_AC1    13.12.7.2
...    2    5170026720   UE2_AC3   13.12.7.10
...    3    5170026673   UE3_AC9   13.12.7.18
...    4    5170026664    UE4_AC2    13.12.7.6
...    5    5170026538   UE5_AC4   13.12.7.14
...    6    5170026688   UE6_AC10   13.12.7.22
${BBU_username}    root
${BBU_password}    root
${SSH_port}        22
${RACK_IP}         10.80.6.247
${RACK_username}    svg
${RACK_password}    !@#4ir$p4N
${INTERVAL}        40s
${CLI_INTERVAL}    5s
${eNB8}            10.80.6.17
${eNB4}            10.80.5.233
${RU_eNB8}         10.80.6.84
${RU_eNB4}         10.80.6.59
${RU_username}     admin
${RU_password}     4gSW3PCd5KsPDrPH
${pi_svg_username}     svg
${pi_svg_password}     !@#4ir$p4N
${user_inband}     root
${password_inband}        QBSjPdvuNjzU6rU3
${BASE_DIR}        C:\\Users\\Administrator\\PycharmProjects
 

*** Keywords ***
Login Inband_RU
    [Arguments]    ${ip}
	SSHLibrary.Open Connection    ${ip}
	Login    ${user_inband}    ${password_inband}    login_timeout=60s
        Set Client Configuration    prompt=>
