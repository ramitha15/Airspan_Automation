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
4G_ATG_ENB6_TA SWEEP
    [Tags]    4G_ATG_ENB6_TA SWEEP
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.0.12
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start UE log collection_usernameSWUSER     ${pi_ip}

    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_TA SWEEP
    #Start_Non_Commercial_CE     ${pi_ip}     4G_ATG_ENB6_TA SWEEP
    Start_Non_Commercial_CE_Additional_Attenuation       ${pi_ip}     4G_ATG_ENB6_TA SWEEP
    #${ue_state}=    TCP DL    ${pi_ip}
    ${ue_state}=    UDP BIDI   ${pi_ip}
    Sleep    ${DURATION}
    #Log With Color    ================== Contents of ue_state :  ${ue_state}==================
    #Log    ${ue_state}
    #IF    '13' in """${ue_state}"""
    #       #ATG_4G_CLI LOG_TA FULL SWEEP
    #       ATG_4G_CLI LOG_TA FW SWEEP
    #ELSE
    #    Log To Console    =======================================================
    #    Log With Color    ================== UE is not attached ==================    red
    #    Log To Console    =======================================================
    #END
    Stop UE log collection_usernameSWUSER      ${pi_ip}
    ATG_4G_bs Log Collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP
    ATG_4G_L1 log collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP
    #ATG_4G_RU_bs Log Collection  ${RU_eNB6}   4G_ATG_ENB6_TA SWEEP
    #Fetch_eNB_TASWEEP_STATS      ${start_time}   ${end_time}
    SSHLibrary.Close All Connections

*** Keywords ***
Start UE log collection_usernameSWUSER
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo nc -u -l 192.168.4.1 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     Login Pi    ${pi_ip}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for swuser:
     Write    ${pi_swuser_password}

Start UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     Login Pi    ${pi_ip}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}

Stop UE log collection_usernameSWUSER
    [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
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
    Read Until    password for swuser:
    Write    ${pi_swuser_password}
    #Now kill the channel emulator Session
    Switch Connection    CE
    Write    tmux kill-session -t chanemu

Stop UE log collection
    [Arguments]    ${pi_ip}
#    Login To Pi_userSVG    ${pi_ip}
    Login Pi   ${pi_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${files}=    Execute Command    ls /tmp/${pi_ip}*.log
    @{file_list}=    Split String    ${files}
    FOR    ${file}    IN    @{file_list}
       SSHLibrary.Get File    ${file}    ${RESULT_PATH}\\
    END
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    Read Until    password for svg:
    Write    ${pi_svg_password}



