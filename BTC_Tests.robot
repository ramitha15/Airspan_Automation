*** Settings ***
Resource    ../Resources/ATG/5GVariables.robot
Library     ../Resources/ATG/ThroughputLib.py
Library     yaml
Library     BuiltIn
Library     OperatingSystem
Library     Collections
Library     String
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
Library    ../Resources/ATG/BTCLogLibrary.py 
*** Variables ***
${failure_count}    0
${ACP_IP}   10.80.5.47
${KF}   10.80.0.84
${Robost}   10.80.0.93
${Yettaman}   10.80.0.99
${Everest}   10.80.0.65

${Morgan}   192.168.15.15
${Badabing}   192.168.15.16
${Glenfidditch}   192.168.15.17
${BP}   192.168.15.19
${test}  192.168.14.11
${test_pass}  "4gSW3PCd5KsPDrPH" 
${RU_pass}   "QBSjPdvuNjzU6rU3"
*** Keywords ***
  
ACP_login
    [Arguments]    ${ip}    ${username}=admin   ${password}=localadmin   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=ACP_IP
    Login    ${username}    ${password}

RU_login
    [Arguments]    ${ip}    ${username}=root   ${password}=QBSjPdvuNjzU6rU3   ${port}=22
    Log To Console    \n===============Inside RU_login for : ${ip}============\n
    Open Connection    ${ip}    port=${port}    alias=RU_IP

    Login    ${username}    ${password}
#   Set Client Configuration    prompt=$

Process direct RU 

    FOR    ${ip}    IN    ${KF}    ${Everest}    ${Robost}    ${Yettaman}
        RU_login    ${ip}
        Log To Console  processing outband RU : ${ip} 
        ${output}=    Execute Command    zgrep "L BTC:" /bsdata/archive/*
        Log To Console    ${output}
        ${count}    ${files}=    Count Failures    ${output}
        Log To Console    Total FAIL count: ${count}
        Log To Console    FAIL files: ${files}

    END


Process inband RU 
    FOR    ${ip}    IN   ${Morgan}	${Badabing}	${Glenfidditch} 	${BP} 
        ACP_login      ${ACP_IP}
        ${ru_login_str}=    Set Variable   sshpass -p QBSjPdvuNjzU6rU3 ssh ${user_inband}@${ip}
        Log To Console  processing inband RU : ${ip} 
        Write    ${ru_login_str}
        ${output}=     Read Until   \#

        Write    zgrep "L BTC:" /bsdata/archive/*
        ${output}=     Read Until   \#
        Log To Console    ${output}
        ${count}    ${files}=    Count Failures    ${output}
        Log To Console    Total FAIL count: ${count}
        Log To Console    FAIL files: ${files}
    END


      
*** Test Cases ***
Process Direct RUs
    [Documentation]   Test case to check BTC  on direct RUs 
    [Tags]    RU BTC
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Process direct RU
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s

Process Inband RUs
    [Documentation]   Test case to check BTC on inband RUs 
    [Tags]    RU BTC
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Process inband RU
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s


