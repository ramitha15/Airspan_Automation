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
*** Keywords ***
#Helm update main function
#    [Arguments]    ${ANSIBLE_IP}    ${username}=airspan   ${password}=localadmin   ${port}=22
#    Open Connection    ${ANSIBLE_IP}    port=${port}    alias=GNB
#    Login    ${username}    ${password}
  
*** Keywords ***
#Helm update main function
#    [Arguments]    ${ANSIBLE_IP}    ${username}=airspan   ${password}=localadmin   ${port}=22
#    Open Connection    ${ANSIBLE_IP}    port=${port}    alias=GNB
#    Login    ${username}    ${password}
  
Ansible_login
    [Arguments]    ${ip}    ${file}   ${ru_ip}  ${username}=airspan   ${password}=localadmin   ${port}=22  
    Open Connection    ${ip}    port=${port}    alias=Ansible_IP
    Login    ${username}    ${password}
    Log To Console     file in Ansible_login: ${file}
    #${temp}=     Set Variable   sshpass -p QBSjPdvuNjzU6rU3 scp ${user_inband}@${Robost}:${file}   /home/airspan/RTC/
    ${target_dir}=    Set Variable    ${BASE_DIR}/${ru_ip}
    ${exists}=    Run Keyword And Return Status    SSHLibrary.Directory Should Exist    ${target_dir}
    #Run Keyword Unless    ${exists}    Create Directory    ${target_dir}
    Log To Console     printing exists: ${exists}
    IF   not $exists
        Create Directory    ${target_dir}
    END
    
    
    ${temp}=     Set Variable   sshpass -p QBSjPdvuNjzU6rU3 scp -o StrictHostKeyChecking=no ${user_inband}@${ru_ip}:${file}  ${BASE_DIR}/${ru_ip}
    Write    ${temp} 

ACP_login
    [Arguments]    ${ip}    ${username}=admin   ${password}=localadmin   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=ACP_IP
    Login    ${username}    ${password}

RU_login
    [Arguments]    ${ip}    ${username}=root   ${password}=QBSjPdvuNjzU6rU3   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=RU_IP
    Login    ${username}    ${password}
#   Set Client Configuration    prompt=$

Process direct RU 

    FOR    ${ip}    IN    ${KF}    ${Everest}    ${Robost}    ${Yettaman}
        RU_login    ${ip}
        Log To Console  processing outband RU : ${ip} 
        ${output}=    Execute Command    zgrep "L BTC:" /bsdata/archive/*
 

        ${files}=    Extract File Names    ${output}

        # Call library for scp files from RU to ansible pc at /home/airspan/RU

           
        FOR    ${f}    IN    @{files}
           Log To Console    ${f}
           Ansible_login    ${ansible_ip}  ${f}  ${ip}
           #${results}=    Analyze RTC Measurements    ${f}
          # FOR    ${item}    IN    @{results}
          #    Log To Console    File: ${item}[0], Non-zero count: ${item}[1]
          # END
        END
         
        

    END


#Process inband RU 
#    FOR    ${ip}    IN   ${Morgan}	${Badabing}	${Glenfidditch} 	${BP} 
#        ACP_login      ${ACP_IP}
#        ${ru_login_str}=    Set Variable   sshpass -p QBSjPdvuNjzU6rU3 ssh ${user_inband}@${ip}
#        Log To Console  processing inband RU : ${ip} 
#        Write    ${ru_login_str}
#        ${output}=     Read Until   \#
#
#        Write    zgrep "L BTC:" /bsdata/archive/*
##        ${output}=     Read Until   \#
#        Log To Console    ${output}
#        ${count}    ${files}=    Count Failures    ${output}
#        Log To Console    Total FAIL count: ${count}
#        Log To Console    FAIL files: ${files}
#    END


      
*** Test Cases ***
Process Direct RUs
    [Documentation]   Test case to check BTC  on direct RUs 
    [Tags]    RU BTC
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Process direct RU
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s

#Process Inband RUs
#    [Documentation]   Test case to check BTC on inband RUs 
#    [Tags]    RU BTC
#    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
#    Log To Console    \n==============================================\n
#    Process inband RU
#    Log To Console    \n===================================End of the TC==========\n
#    Sleep    2s

