*** settings ***
Resource    /home/kvramesh/automation/Latest/Regression/Variables.robot
Resource    /home/kvramesh/automation/Latest/Regression/RaspberryPi_Aircard_SSH.robot
#Resource    ../Resources/ATG/keyword.robot
Library    Process
Library    SSHLibrary
Library    yaml
Library    BuiltIn
Library    OperatingSystem
Library    Collections
Library    String
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
Library    RequestsLibrary
Library    JSONLibrary
Library    DateTime
Suite Teardown    Terminate All Processes

*** Variables ***
${DURATION}     1800
${CE_IP}      10.80.100.201
${CE_username}      pi
${CE_password}      !@#4ir$p4N
${eNB6}     10.80.5.249
${RU_eNB6}     10.80.6.64
${enb6_pi}      10.80.0.12

*** Test Cases ***

4G_ATG_ENB4_UDP_BIDI
    [Tags]    4G_ATG_ENB4_UDP_BIDI
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.6.247
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start UE log collection_usernameSVG     ${pi_ip}
    ${ue_state}=    UDP BIDI    ${pi_ip}
    Start Intr_enb_HO     ${pi_ip}

    Sleep     ${DURATION}
    Stop UE log collection_usernameSVG      ${pi_ip}
    ATG_4G_bs Log Collection    ${eNB9}      4G_ATG_ENB4_UDP_BIDI
    #ATG_4G_RU_bs Log Collection    ${RU_eNB9}    4G_ATG_ENB9_TA_SWEEP
    ATG_4G_L1 log collection      ${eNB9}      4G_ATG_ENB4_UDP_BIDI
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB9}      4G_ATG_ENB9_TA_SWEEP
    SSHLibrary.Close All Connections


*** Keywords ***
Start Intr_enb_HO
     [Arguments]    ${pi_ip}
     Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip}Starting HO script =========

     COUNT=0
     END_TIME=$(( $(date +%s) + ${DURATION} ))

     while [ $(date +%s) -lt ${END_TIME} ]; do
     Write    ./setGain.sh 16 4
     COUNT=$((COUNT + 1))
     Log to console    == "setGain count: $COUNT"==

     sleep 20

     [ $(date +%s) -ge ${END_TIME} ] && break

     Write    ./setGain.sh 30 4
     COUNT=$((COUNT + 1))
     Log to console    == "setGain count: $COUNT" ==

     sleep 20
     done

     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}

Start UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     ${set_ENB4_gain}=    Set variable    cd ps_scripts; ./setGain.sh 20 2; ./setGain.sh 30 4;
     Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Writing the set enb4 gain settings with ${set_ENB4_gain}==========
     Write    ${set_ENB4_gain}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}


Stop UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    Write    ${dettach_cmd}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${files}=    Execute Command    ls /tmp/${pi_ip}*.log
    @{file_list}=    Split String    ${files}
    FOR    ${file}    IN    @{file_list}
       ${time}=     Get Current Date    result_format=%H-%M
       ${DEST}=    Set Variable    ${RESULT_PATH}/${pi_ip}_${time}_ac.log
       SSHLibrary.Get File    ${file}    ${DEST}
    END

    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log





