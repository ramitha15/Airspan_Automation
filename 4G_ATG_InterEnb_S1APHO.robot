*** Settings ***
Resource    ../Resources/ATG/Variables.robot
Resource    ../Resources/ATG/RaspberryPi_Aircard_SSH.robot
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

*** Variables ***

*** Test Cases ***
4G_ATG_Inter_eNB_S1APHO
    [Tags]    4G_ATG_Inter_eNB_S1APHO
    ${pi_ip}=   Set Variable    10.80.6.189
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${UE_LOGFILE}=    Set Variable    ${RESULT_PATH}\\${pi_ip}_${time}_UE_Serial.log
    ${aircard_login}=   Set Variable    sshpass -p 4gSW3PCd5KsPDrPH ssh admin@192.168.4.51
    Login To Pi_userAirspan    ${pi_ip}
    write   ${aircard_login}
    Write    sshpass -p 4gSW3PCd5KsPDrPH sudo bash
    Write    minicom -D /dev/ttyPS1 -b 921600
#    Attach Single UE    ${pi_ip}     svg     !@#4ir$p4N      22
#    Set Client Configuration    prompt=REGEXP:.*[@#]$271
    ${UE_LOG1}=      Read   delay=1m
#    Log CLI Output With Timestamp    ${UE_LOGFILE}    ${UE_LOG1}
    IF    'Welcome to minicom 2.7.1' in """${UE_LOG1}"""
           Attach Single UE    10.80.6.189     airspan     localadmin      22
           Login To Pi_userAirspan    ${pi_ip}
           write   ${aircard_login}
           Write    sshpass -p 4gSW3PCd5KsPDrPH sudo bash
           Write    minicom -D /dev/ttyPS1 -b 921600
           ${UE_LOG2}=      Read    delay=1m
           Log CLI Output With Timestamp    ${UE_LOGFILE}    ${UE_LOG2}
    ELSE
        Log To Console    =======================================================
        Log With Color    ================== UE is not attached ==================    red
        Log To Console    =======================================================
    END
#    ${UE_LOG}=      Read    delay=1m
#    Log CLI Output With Timestamp    ${UE_LOGFILE}    ${UE_LOG}
    SSHLibrary.Close Connection
*** Keywords ***
