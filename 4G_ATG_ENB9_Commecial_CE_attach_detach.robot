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
${DURATION}     2500
${CE_IP}      10.80.100.201
${CE_username}      pi
${CE_password}      !@#4ir$p4N
${eNB6}     10.80.5.249
${RU_eNB6}     10.80.6.64
${enb6_pi}      10.80.0.12
${cycles}      15    

*** Test Cases ***

4G_ATG_ENB9_TA_SWEEP_UDP_UL
    [Tags]    4G_ATG_ENB9_TA_SWEEP_UDP_UL
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.1.51
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start UE log collection_usernameSSINGH     ${pi_ip}
    attach_detach_during_TA_RSRP    ${pi_ip}    ${cycles}
    Stop UE log collection_usernameSSINGH      ${pi_ip}
    ATG_4G_bs Log Collection    ${eNB9}      4G_ATG_ENB9_TA_SWEEP_UDP_UL
    #ATG_4G_RU_bs Log Collection    ${RU_eNB9}    4G_ATG_ENB9_TA_SWEEP
    ATG_4G_L1 log collection      ${eNB9}      4G_ATG_ENB9_TA_SWEEP_UDP_UL
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB9}      4G_ATG_ENB9_TA_SWEEP
    SSHLibrary.Close All Connections





