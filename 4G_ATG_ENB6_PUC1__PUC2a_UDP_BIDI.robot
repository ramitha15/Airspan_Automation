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

4G_ATG_ENB6_PUC1_UDP_BIDI
    [Tags]    4G_ATG_ENB6_PUC1_UDP_BIDI
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip1}=   Set Variable    10.80.6.247
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start enb6 PUC1 UE log collection_usernameSVG     ${pi_ip1}
    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    Start_Non_Commercial_CE     ${pi_ip1}     4G_ATG_ENB6_PUC1_UDP_BIDI
    ${ue_state1}=    UDP BIDI    ${pi_ip1}

    ${pi_ip2}=   Set Variable    10.80.0.12
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start UE log collection_usernameSWUSER     ${pi_ip2}

    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_RSRP SWEEP
    Start_Non_Commercial_CE     ${pi_ip2}     4G_ATG_ENB6_RSRP SWEEP
    ${ue_state2}=    UDP BIDI   ${pi_ip2}

    Sleep     10s
   
    Log    UE1 state: ${ue_state1} | UE2 state: ${ue_state2}
    IF    '13' in """${ue_state1}""" and '13' in """${ue_state2}"""
           #ATG_4G_CLI LOG_TA FULL SWEEP
           ATG_4G_CLI LOG_TA FW SWEEP
    ELSE
        Log To Console    =======================================================
        IF    '13' not in """${ue_state1}"""
            Log With Color    ============ UE1 (10.80.6.247) is not attached ============    red
        END
        IF    '13' not in """${ue_state2}"""
            Log With Color    ============ UE2 (10.80.0.12) is not attached ============    red
        END
        Log To Console    =======================================================
    END
    Stop UE log collection_usernameSWUSER      ${pi_ip2}
    Stop enb8 UE log collection_usernameSVG      ${pi_ip1}
    ATG_4G_bs Log Collection    ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    #ATG_4G_RU_bs Log Collection    ${RU_eNB6}    4G_ATG_ENB6_PUC1_TA_SWEEP
    ATG_4G_L1 log collection      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB6}      4G_ATG_ENB6_PUC1_TA_SWEEP
    SSHLibrary.Close All Connections










