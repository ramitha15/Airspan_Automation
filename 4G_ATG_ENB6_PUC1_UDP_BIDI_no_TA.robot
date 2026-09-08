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
${enb6_pi}      10.80.0.12cd 

*** Test Cases ***

4G_ATG_ENB6_PUC1_UDP_BIDI
    [Tags]    4G_ATG_ENB6_PUC1_UDP_BIDI
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.6.247
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start enb6 PUC1 UE log collection_usernameSVG     ${pi_ip}
    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    Start_Non_Commercial_CE     ${pi_ip}     4G_ATG_ENB6_PUC1_UDP_BIDI
    ${ue_state}=    UDP BIDI    ${pi_ip}

    Sleep     ${DURATION}
    #Log    ${ue_state}
    #IF    '13' in """${ue_state}"""
           #ATG_4G_CLI LOG_TA FULL SWEEP
    #       ATG_4G_CLI LOG_TA FW SWEEP
    #ELSE
    #   Log To Console    =======================================================
    #    Log With Color    ================== UE is not attached ==================    red
    #    Log To Console    =======================================================
    #END
    Stop enb8 UE log collection_usernameSVG      ${pi_ip}
    ATG_4G_bs Log Collection    ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    #ATG_4G_RU_bs Log Collection    ${RU_eNB6}    4G_ATG_ENB6_PUC1_TA_SWEEP
    ATG_4G_L1 log collection      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_PUC1_UDP_BIDI
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB6}      4G_ATG_ENB6_PUC1_TA_SWEEP
    SSHLibrary.Close All Connections










