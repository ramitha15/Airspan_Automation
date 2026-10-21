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
${eNB8}     10.80.6.17
${RU_eNB8}     10.80.6.84
${enb8_pi}      10.80.6.189
${AC8_pi}      10.80.6.247

*** Test Cases ***

4G_ATG_ENB8_UDP_BIDI
    [Tags]    4G_ATG_ENB8_UDP_BIDI
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.6.189
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    Start AC7 gains settings    ${AC8_pi}
    Start UE log collection_usernameAIRSPAN     ${pi_ip}
    ${ue_state}=    UDP BIDI    ${pi_ip}
    Sleep     10s
    Log    ${ue_state}
    IF    '13' in """${ue_state}"""
           Start InterHO script    ${AC8_pi}
    ELSE
        Log To Console    =======================================================
        Log With Color    ================== UE is not attached ==================    red
        Log To Console    =======================================================
    END
    # kvr_interHO.sh dies when its SSH session closes, so keep the connection open for the whole test
    Sleep     ${DURATION}
    UK_VM Stop UE log collection      ${pi_ip}
    UK_VM bs log collection    ${eNB8}      4G_ATG_ENB8_UDP_BIDI
    UK_VM bs log collection    ${eNB4}      4G_ATG_ENB8_UDP_BIDI
    #ATG_4G_RU_bs Log Collection    ${RU_eNB8}    4G_ATG_ENB8_TA_SWEEP
    UK_VM L1 log collection      ${eNB8}      4G_ATG_ENB8_UDP_BIDI
    #ATG_4G_MESSAGE LOG COLLECTION    ${eNB8}      4G_ATG_ENB8_TA_SWEEP
    SSHLibrary.Close All Connections










