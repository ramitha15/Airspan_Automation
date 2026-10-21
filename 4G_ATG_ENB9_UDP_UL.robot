*** settings ***
Resource    /home/kvramesh/automation/Latest/Regression/Variables.robot
Resource    /home/kvramesh/automation/Latest/Regression/RaspberryPi_Aircard_SSH.robot
Resource    /home/kvramesh/automation/Latest/Regression/UKVM_Log_Collection.robot
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

4G_ATG_ENB9_TA_SWEEP_UDP_UL
    [Tags]    4G_ATG_ENB9_TA_SWEEP_UDP_UL
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.6.198
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start UE log collection_usernameAIRSPAN     ${pi_ip}
    ${ue_state}=    UDP UL    ${pi_ip}
    Sleep     ${DURATION}
    UK_VM Stop UE log collection      ${pi_ip}
    UK_VM bs log collection    ${eNB9}      4G_ATG_ENB9_TA_SWEEP_UDP_UL
    #ATG_4G_RU_bs Log Collection    ${RU_eNB9}    4G_ATG_ENB9_TA_SWEEP
    UK_VM L1 log collection      ${eNB9}      4G_ATG_ENB9_TA_SWEEP_UDP_UL
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB9}      4G_ATG_ENB9_TA_SWEEP
    SSHLibrary.Close All Connections





