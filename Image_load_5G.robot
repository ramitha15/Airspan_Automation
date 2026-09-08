*** Settings ***

Resource    /home/kvramesh/automation/Latest/Regression/5GVariables.robot
Resource    /home/kvramesh/automation/Latest/Regression/RaspberryPi_Aircard_SSH.robot
Library     yaml
Library     BuiltIn
Library     OperatingSystem
Library     Collections
Library     String
Library     SSHLibrary
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
*** Variables ***
${du_path}    ${EMPTY}
${cu_path}    ${EMPTY}

${DU_FILE}    ${EMPTY}
${CUCP_FILE}    ${EMPTY}
${CUUP_FILE}    ${EMPTY} 
${L1_needed}    ${EMPTY}
*** Keywords ***
Ansible_PC
    [Arguments]    ${ip}    ${username}=airspan   ${password}=localadmin   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=ANSIBLE_IP
    Login    ${username}    ${password}
#   Set Client Configuration    prompt=$
    Log To Console    \n===============Ansible pc is logged in successfully new logging inside Ansible_PC============\n

Process DU Image

    Ansible_PC  ${ANSIBLE_IP}
    Log To Console    \n===============Inside Process DU Image :${du_path} ============\n
    ${output}=    Execute Command    ls -lart ${du_path}
    Log To Console    \n===================================${output} ==========\n
    Execute Command    cp ${du_path}/*docker.tgz ~/Builds/
    Log To Console    \n===================================${output} ==========\n
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    tar -xvzf $(ls -t ~/Builds/*.tgz | head -n1) -C /home/airspan/Builds/
    ${l1docker_name}=    Execute Command    ls -t ~/Builds/airspan_du_l1s72*.tgz | head -n1
    ${l2docker_name}=    Execute Command    ls -t ~/Builds/airspan_du_l2s72*.tgz | head -n1
    Log To Console    \n===================================${l1docker_name}==========\n
    Log To Console    \n===================================${l2docker_name}==========\n

#   Derive l2image name from s72docker
    ${DU_FILE}=    Replace String    ${l2docker_name}    du_s72    du_l2s72
    Log To Console    \n===================================${DU_FILE} ==========\n
    ${DU_FILE}=    Execute Command    basename ${DU_FILE}
    ${L1_FILE}=    Execute Command    basename ${l1docker_name}
    Log To Console    \n===================================${DU_FILE} ==========\n
    Run Keyword If     '${L1_needed}' != ''    Execute Command     /home/airspan/ansible/image_update.sh /home/airspan/Builds/ /home/admin/Builds/ ${DU_FILE} ${L1_FILE}
    #${output}=   Execute Command     /home/airspan/ansible/image_update.sh /home/airspan/Builds/ /home/admin/Builds/ ${DU_FILE} ${L1_FILE} 
    ...     ELSE       Execute Command     /home/airspan/ansible/image_update.sh /home/airspan/Builds/ /home/admin/Builds/ ${DU_FILE}
    Log To Console    \n===================================${output} ==========\n

#   Remove Images after the load operation
    Execute Command    rm -rf ${l1docker_name} ${l2docker_name}

Process CU Image

    Ansible_PC  ${ANSIBLE_IP}
    Log To Console    \n===============Inside process CU Image :${cu_path} ============\n
    Log To Console    \n===============Ansible pc :${cu_path} ============\n
    ${output}=    Execute Command    ls -lart ${cu_path}
    Log To Console    \n===================================${output} ==========\n
    Execute Command    cp ${cu_path}/*docker.tgz ~/Builds/
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    tar -xvzf $(ls -t ~/Builds/*.tgz | head -n1) -C /home/airspan/Builds/
    ${cucp_output}=    Execute Command    ls -t ~/Builds/airspan_cucp_app*.tgz | head -n1
    ${cuup_output}=    Execute Command    ls -t ~/Builds/airspan_cuup_app*.tgz | head -n1
    Log To Console    \n===================================${cucp_output} ==========\n
    Log To Console    \n===================================${cuup_output} ==========\n

    ${CUCP_FILE}=    Execute Command    basename ${cucp_output}
    ${CUUP_FILE}=    Execute Command    basename ${cuup_output}
    Log To Console    \n===================================${CUCP_FILE}==========\n
    Log To Console    \n===================================${CUUP_FILE}==========\n

    ${output}=   Execute Command     /home/airspan/ansible/image_update.sh /home/airspan/Builds/ /home/admin/Builds/ ${CUCP_FILE} ${CUUP_FILE} 
    Log To Console    \n===================================${output} ==========\n
#   Remove Images after the load operation
    Execute Command    rm -rf ${CUCP_FILE} ${CUUP_FILE}
Process_Images
#   Check if you are connected to VPN for the script to run 

    Ansible_PC  ${ANSIBLE_IP}
    ${output}=    Execute Command    ls -lart /at/k

    Log To Console    \n===============Ansible pc :${output} ============\n
    Run Keyword If     '${du_path}' != ''   Process DU Image
  
    Run Keyword If    '${cu_path}' != ''    Process CU Image

    Log To Console    \n===================================Testcase completed==========\n
    



*** Test Cases ***
Image update procedure
    [Documentation]   Test case to update docker images to all the servers 
    [Tags]    Ansible
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Log To Console    \n===================================Inside Helm update procedure:${START_TIME}==========\n
    Log To Console    \n===================================After ${ANSIBLE_IP} ==========\n ${ANSIBLE_IP}
    Process_Images 
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s



