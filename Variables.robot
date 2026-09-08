*** Variables ***
${RESOURCES}    /home/kvramesh/automation/Latest/Regression/
${QCI6}          0x88
${QCI7}          0xb8
${QCI9}          0x1c
${AC_IP}         192.168.4.51
${AC_USER}       admin
${AC_PASS}       4gSW3PCd5KsPDrPH
${HO_DURATION}     1800
${MME_IP}        10.80.0.7
${MME_USER}      iperf-user
${MME_PASS}      localadmin
${MME_PORT}      22
${ENB1_IP}       10.80.6.75
${ENB1_USER}     root
${ENB1_PASS}     root
${ENB1_PORT}     22
${attach_cmd}    set 8[1]2=1
${dettach_cmd}    set 8[1]2=0
${get_cmd}    get -vv 10
${UE_State_cmd}     get 10[1]1
${enb6_pi}      10.80.0.12
${CE_IP}      10.80.100.201
${CE_username}      pi
${CE_password}      !@#4ir$p4N
${eNB6}     10.80.5.249
${RU_eNB6}     10.80.6.64
${enb6_pi}      10.80.0.12
${enb7_pi}      10.80.1.26
${enb9_pi}      10.80.1.51
${pi_swuser_username}       swuser
${pi_swuser_password}       sw_grp2
${pi_admin_username}       admin
${pi_admin_password}       toor
${pi_ssingh_username}       santoshsingh
${pi_ssingh_password}       localadmin
@{UES} =
...    1    13.12.7.2    13.12.8.2    10.80.6.164
...    2    13.12.7.10   13.12.8.10   10.80.6.168
#...    3    13.12.7.18   13.12.8.18   10.80.6.198
...    4    13.12.7.6    13.12.8.6    10.80.6.165
...    5    13.12.7.14   13.12.8.14   10.80.6.169
#...    6    13.12.7.22   13.12.8.22   10.80.6.202
${MME_TUN_IP1}    13.12.5.1
${MME_TUN_IP2}    13.12.6.1
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
${base_port}       8000
${RACK_username}    svg
${RACK_password}    !@#4ir$p4N
${INTERVAL}        40s
${CLI_INTERVAL}    5s
${eNB8}            10.80.6.17
${eNB9}            10.80.5.235
${eNB1}            10.80.6.75
${eNB4}            10.80.5.233
${RU_eNB8}         10.80.6.84
${RU_eNB9}         10.80.6.166
${RU_eNB4}         10.80.6.59
${RU_username}     admin
${RU_password}     4gSW3PCd5KsPDrPH
${enb8_pi1}    10.80.6.247
${pi_svg_username}     svg
${pi_svg_password}     !@#4ir$p4N
${pi_airspan_username}     airspan
${pi_airspan_password}     localadmin
${BASE_DIR}        /home/kvramesh/automation/Latest/Results
${acp_url}=    https://10.80.1.23/
${enb1_pi1}    10.80.6.164
${enb1_pi2}    10.80.6.168
${enb1_pi3}    10.80.6.198
${enb1_pi4}    10.80.6.165
${enb1_pi5}    10.80.6.169
${enb1_pi6}    10.80.6.202
