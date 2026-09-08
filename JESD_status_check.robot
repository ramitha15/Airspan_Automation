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
Library    ../Resources/ATG/RTCMeasurementsLibrary.py
Library    ../Resources/ATG/FileNameExtractor.py
Library    ../Resources/ATG/Scp_RU_files.py
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
${ansible_ip}     10.80.0.5
${ansible_user}     airspan
${ansible_passwd}     localadmin
${BASE_DIR}       /home/airspan/RTC
${RTC_FILE}    /home/kvramesh/automation/Latest/Regression/RTC_results.txt


*** Keywords ***
#Helm update main function
#    [Arguments]    ${ANSIBLE_IP}    ${username}=airspan   ${password}=localadmin   ${port}=22
#    Open Connection    ${ANSIBLE_IP}    port=${port}    alias=GNB
#    Login    ${username}    ${password}
  
*** Keywords ***
  
ACP_login
    [Arguments]    ${ip}    ${username}=admin   ${password}=localadmin   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=ACP_IP
    Login    ${username}    ${password} 


Process RU 
        ACP_login      ${ACP_IP}
        ${output}=    Execute Command      grep -r "L BTC: FAIL" /tmp/jesd/*
        Log To Console   BTC failed files are  
        Log To Console    ${output}
        ${output}=    Execute Command      grep -r "illegal packet size" /tmp/jesd/*
        Log To Console   illegal packet size instances are :
        Log To Console    ${output}
        ${output}=    Execute Command      grep -r "Error illegal packet size" /tmp/jesd/*
        Log To Console   Error illegal packet size instances are :
        Log To Console    ${output}
       # ${output}=    Execute Command      grep -r "Azimuth delta" /tmp/jesd/*
       # Log To Console    Antenna Orientation :  
       # Log To Console    ${output}
        ${output}=    Execute Command      find /tmp/jesd -type f -name "*.csv" | while read -r file; do echo "==> $file <=="; cut -d',' -f3,4 "$file"|grep -E ,'[1-9][0-9]*'; done
        Log To Console    RTC Results :  
        Log To Console    ${output}
        Create File      ${RTC_FILE}      ${output}


      
*** Test Cases ***
Process Direct RUs
    [Documentation]   Test case to check BTC  on direct RUs 
    [Tags]    RU BTC
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Process RU
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s
