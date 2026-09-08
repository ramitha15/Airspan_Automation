*** Settings ***
Library         SSHLibrary
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
${du_path}     EMPTY
${cu_path}     EMPTY
*** Keywords ***
Ansible_PC
    [Arguments]    ${ip}    ${username}=airspan   ${password}=localadmin   ${port}=22
    Open Connection    ${ip}    port=${port}    alias=ANSIBLE_IP
    Login    ${username}    ${password}
#   Set Client Configuration    prompt=$
    Log To Console    \n===============Ansible pc is logged in successfully new logging inside Ansible_PC============\n

Process DU Helm
    Ansible_PC     ${ANSIBLE_IP}
    ${output}=    Execute Command    ls -lart ${du_path}
    Log To Console    \n===================================${output} ==========\n
    Execute Command    cp ${du_path}/*helm.tgz ~/Builds/
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    ${output}=    Execute Command    rm -rf ~/helm_orig/airspan_du_s72_x86*
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    ls -t ~/Builds/*.tgz | head -n1
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    tar -xvzf $(ls -t ~/Builds/*.tgz | head -n1) -C /home/airspan/helm_orig/
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    ${output}=    Execute Command    rm -rf ~/helm_out/*
    ${output}=    Execute Command    ls -lart ~/helm_out/
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    python3 ~/helm_mods/value_1.py --source /home/airspan/helm_orig --target /home/airspan/helm_out --yaml ~/helm_mods/setup1.yaml
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    ls -lart ~/helm_out/
    Log To Console    \n===================================${output} ==========\n
    Log To Console    \n============${release_folder} ==========\n
    Log To Console    \n============End of DU Helm==========\n
Process CU Helm
    Ansible_PC     ${ANSIBLE_IP}
    ${output}=    Execute Command    ls -lart ${cu_path}
    Log To Console    \n===================================${output} ==========\n
    Execute Command    cp ${cu_path}/*helm.tgz ~/Builds/
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    ${output}=    Execute Command    rm -rf ~/helm_orig/airspan_cu*
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    Log To Console    \n===================================${output} ==========\n
    ${cp_output}=    Execute Command    ls -t ~/Builds/airspan_cucp_x86*-helm.tgz | head -n1
    ${up_output}=    Execute Command    ls -t ~/Builds/airspan_cuup_x86*-helm.tgz | head -n1
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    tar -xvzf ${cp_output} -C /home/airspan/helm_orig/
    ${output}=    Execute Command    tar -xvzf ${up_output} -C /home/airspan/helm_orig/
    ${output}=    Execute Command    ls -lart ~/helm_orig/
    ${output}=    Execute Command    rm -rf ~/helm_out/*
    ${output}=    Execute Command    ls -lart ~/helm_out/
    Log To Console    \n===================================${output} ==========\n
    Log To Console    \n============${release_folder} ==========\n
    Log To Console    \n============End of CU Helm==========\n
#   Copy the modified files on supermaster
    
Copy modified files
    Ansible_PC  ${ANSIBLE_IP}
    ${output}=    Execute Command    python3 ~/helm_mods/value_1.py --source /home/airspan/helm_orig --target /home/airspan/helm_out --yaml ~/helm_mods/setup1.yaml
    Log To Console    \n===================================${output} ==========\n
    ${output}=    Execute Command    ls -lart ~/helm_out/
    Log To Console    \n===================================${output} ==========\n
    Execute Command    sshpass -p gbss2test ssh admin@10.80.0.9 "mkdir -p /home/admin/helm/${release_folder}"
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss2/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss3/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss7/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss8/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss6/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
    Execute Command    sshpass -p gbss2test scp -r ~/helm_out/gbss1/ admin@10.80.0.9:/home/admin/helm/${release_folder}/ 
#   Copy the modified files on 3ru Marshal master
    Execute Command    sshpass -p gogo2021 ssh admin@10.80.1.121 "mkdir -p /home/admin/helm/${release_folder}"
    Execute Command    sshpass -p gogo2021 scp -r ~/helm_out/wi02-marshall-5162-cu1/ admin@10.80.1.121:/home/admin/helm/${release_folder}/



Process_helm
#   Check if you are connected to VPN for the script to run 
    Ansible_PC  ${ANSIBLE_IP}
    ${output}=    Execute Command    ls -lart /at/k
 
    Log To Console    \n===============Ansible pc :${output} ============\n
    Run Keyword If     '${du_path}' != ''   Process DU Helm

    Run Keyword If    '${cu_path}' != ''    Process CU Helm


    Copy modified files

    Log To Console    \n===================================Testcase completed==========\n


*** Test Cases *** 
Helm update procedure
    [Documentation]   Test case to update helm file to all the servers 
    [Tags]    Ansible
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================\n
    Log To Console    \n===================================Inside Helm update procedure:${START_TIME}==========\n
    Log To Console    \n===================================After ${ANSIBLE_IP} ==========\n ${ANSIBLE_IP}
    Process_helm
    Log To Console    \n===================================End of the TC==========\n
    Sleep    2s



