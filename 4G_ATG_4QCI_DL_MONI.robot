*** Settings ***
Library         SSHLibrary
Resource    ../../../Resources/ATG/Variables.robot
Resource    ${RESOURCES}/ATG/RaspberryPi_Aircard_SSH.robot
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
@{Aircard} =
...    1    5170026922    ue1_AC1    13.12.7.2
...    2    5170026720   ue2_AC3   13.12.7.10
...    3    5170026673   ue3_AC9   13.12.7.18
...    4    5170026664    ue4_AC2    13.12.7.6
...    5    5170026538   ue5_AC4   13.12.7.14
...    6    5170026688   ue6_AC10   13.12.7.22
*** Keywords ***
Generate ACP Authorization Token
    [Documentation]    Generate and Resturn ACP authorization Token
    [Arguments]    ${acp_url}
    ${CONTENT_TYPE}=    Set Variable    application/json
    ${json_string}=    Set Variable     { "Username": "automation", "Password": "svgautomation" }
    ${api}    Set Variable    /api/authenticate
    TRY
        ${json_dict}=    Evaluate    json.loads('''${json_string}''')    json
        ${headers}    create dictionary    Content-Type=${CONTENT_TYPE}    User-Agent=RobotFramework
        create session    mysession    ${acp_url}
        ${response}    POST On Session    mysession    ${api}    json=${json_dict}    headers=${headers}
        ${status_code}    convert to string    ${response.status_code}
        ${token}    Set Variable    ${response.content}
        Log    ${response.content}
        Should Be True    '${status_code}' == '200'
    EXCEPT
#        Update Test Results
        ...    test_status=FAIL
        ...    actual_results= Getting Token Data
        ...    keyword_name= Generate Token
        FAIL   Generate Token
    END
    [Return]    ${token}

Fetch Aircard RLS Data
    [Documentation]    Fetch and Resturns RLS taking input as node name and ACP URL
    [Arguments]      ${AC_Name}     ${acp_url}
    ${bearer_token}     Generate ACP Authorization Token    https://10.80.1.23/
    ${id}=    Fetch Aircard Rest ID    ${AC_Name}     ${acp_url}
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/aircardRls/
#    ${node_name}=   Set Variable    name=Node%3A7CE243P8V2
    ${params}=           Create Dictionary    id=${id}
    ${headers}=          Create Dictionary      Authorization=Bearer ${bearer_token}
#    ${response}=         GET On Session       mysession   ${api}  params=${node_name}   headers=${headers}
    ${response}=         GET On Session       mysession   ${api}  params=${params}   headers=${headers}
    log    ${response.status_code}
    ${response_flag}=    Run Keyword And Return Status    Should Be Equal As Integers    ${response.status_code}    ${200}
    IF    ${response_flag}
        ${nodes_det}=    Evaluate    json.loads('''${response.content}''')    json
    END


    
#    ${id}=    set variable    ${nodes_det}[0][id]
#    ${managedMode}=    set variable    ${nodes_det}[0][enbConfig][enbRuMappings][enbRuRestId]
#    ${managedMode}=    set variable    ${nodes_det}[0][enbRuSnmpDetails][0][snmpDetail][snmpPort]
    RETURN    ${nodes_det}

Fetch Aircard Rest ID
    [Documentation]    Fetch and Resturns Rest ID taking input as node name and ACP URL
    [Arguments]    ${AC_Name}     ${acp_url}
    ${bearer_token}     Generate ACP Authorization Token    https://10.80.1.23/
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/aircardRls/
#    ${node_name}=   Set Variable    name=Node%3A7CE243P8V2
    ${params}=           Create Dictionary    name=${AC_Name}
    ${headers}=          Create Dictionary      Authorization=Bearer ${bearer_token}
#    ${response}=         GET On Session       mysession   ${api}  params=${node_name}   headers=${headers}
    ${response}=         GET On Session       mysession   ${api}  params=${params}   headers=${headers}
    Should Be Equal As Integers    ${response.status_code}    200
    ${nodes_det}=    Evaluate    json.loads('''${response.content}''')    json
    ${id}=    set variable    ${nodes_det}[0][id]
#    ${managedMode}=    set variable    ${nodes_det}[0][enbConfig][enbRuMappings][enbRuRestId]
#    ${managedMode}=    set variable    ${nodes_det}[0][enbRuSnmpDetails][0][snmpDetail][snmpPort]
    RETURN    ${id}

Monitor DL Throughput
    [Arguments]    ${AC_Name}    ${acp_url}
    Set Variable    ${THRESHOLD}        7000
    ${SAMPLE_INTERVAL}=    Convert To Integer    5
    ${DURATION}=           Convert To Integer    300
    Set Variable    ${RESULT_FILE}      dl_throughput_samples.txt
    ${samples}=    Create List
    ${start_time}=    Get Time    epoch
    FOR    ${index}    IN RANGE    9999
        FOR    ${AC_Name}    IN    @{AC_Name}
            ${nodes_det}=    Fetch Aircard RLS Data    ${AC_Name}    ${acp_url}
            ${throughput}=    Set Variable    ${nodes_det[0]['data']['dlThroughputKbps']}
            Log To Console    Sample ${index}: DL Throughput = ${throughput} Kbps
            Append To List    ${samples}    ${throughput}
            Append To File    ${RESULT_FILE}    ${throughput}\n
            Sleep    ${SAMPLE_INTERVAL}
            ${elapsed}=    Evaluate    time.time() - ${start_time}    time
            Run Keyword If    ${elapsed} >= ${DURATION}    Exit For Loop
        END
    END
    ${avg}=    Evaluate    sum(${samples})/len(${samples})
    Log To Console    Average DL Throughput over 5 min = ${avg} Kbps
    Run Keyword If    ${avg} >= ${THRESHOLD}    Log To Console    PASS: Avg DL Throughput >= ${THRESHOLD}
    Run Keyword If    ${avg} < ${THRESHOLD}     Log To Console    FAIL: Avg DL Throughput < ${THRESHOLD}
    RETURN    ${avg}
Verify UE status
    [Arguments]    ${get_cmd}
    Write    ${get_cmd}
    ${get_cmd_output}=    Read Until Prompt
    Log To Console    \n========== OUTPUT for: ${get_cmd} ==========\n${get_cmd_output}
    Log    ${get_cmd_output}
    # UE state check with colors
    IF    'established' in """${get_cmd_output}"""
        Log With Color    ================== UE is established ==================    green
    ELSE IF    'idle' in """${get_cmd_output}"""
        Log With Color    ================== UE is in idle ==================    red
    ELSE IF    'establishing' in """${get_cmd_output}"""
        Log With Color    ================== UE is establishing ==================    yellow
    ELSE
        Log With Color    UE state not found in output    blue
    END
Login UE tnet
    Write    ssh ${AC_USER}@${AC_IP}
    Read Until    password:
    Write    ${AC_PASS}
    Read Until    $
    Write    cd /bs/ && ./tnet
    Write    info -x
    Sleep    ${1}
*** Test Cases ***
Perform ENB1 6CELL 6UE Attach
    [Documentation]    Test to create SSH connection, check UE status, and run set command.
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
        Login RaspberryPi    ${pi_ip}
        Login UE tnet
        Write    ${attach_cmd}
        ${cmd_output}=    Read Until Prompt
        Log To Console    \n========== UE OUTPUT for: ${attach_cmd} ==========\n${cmd_output}
        Log    ${cmd_output}
        Sleep    ${5}
        Verify UE status    get -vv 10
    END
Run DL TCP 4QCI data at ENB1 6CELL 6 UE
    [Documentation]    Test to create SSH connection with MME PI and Aircard and DL TCP run iperf command.
    [Tags]    DL
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== DL TCP START TIME: ${START_TIME} =====\n    green
    Log To Console    ==============================================
    Log With Color    \n========== Starting DL TCP 4QCI data at ENB1 6 CELL 6 UE for ${DURATION} seconds ==========\n    green
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
       ${port1}=    Set Variable    5091
       ${port2}=    Evaluate    ${port1}+1
       ${port3}=    Evaluate    ${port1}+2
       ${port4}=    Evaluate    ${port1}+3
       Log With Color    \n========== Running UE${index} DL TCP iPerf Test ==========\n
    #Running Listening cmd at Aircard for management APN1
       Login RaspberryPi    ${pi_ip}
       Login Aircard
       ${DL_TCP_1QCI_AC_Server}=    Set Variable    iperf -s -p ${port1} -t ${DURATION}
       Write    ${DL_TCP_1QCI_AC_Server}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} TCP listening cmd at Aircard for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
       Sleep    ${1}
    #Running Listening cmd at RaspberryPi for internet APN2
       Login RaspberryPi    ${pi_ip}
       ${DL_TCP_3QCI_Pi_Server}=    Catenate
       ...    iperf -s -p ${port2} -t ${DURATION} &
       ...    iperf -s -p ${port3} -t ${DURATION} &
       ...    iperf -s -p ${port4} -t ${DURATION} && pkill -9 iperf
       Write    ${DL_TCP_3QCI_Pi_Server}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} TCP listening cmd at raspberrypi for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
    #Running Client cmd at mme
       Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
       ${iperf_Client_mme}=    Catenate
       ...    iperf -c ${ue_ip1} -p ${port1} -S ${QCI6} -P 5 -t ${DURATION} &
       ...    iperf -c ${ue_ip2} -p ${port2} -S ${QCI6} -P 5 -t ${DURATION} &
       ...    iperf -c ${ue_ip2} -p ${port3} -S ${QCI7} -P 5 -t ${DURATION} &
       ...    iperf -c ${ue_ip2} -p ${port4} -S ${QCI9} -P 5 -t ${DURATION}
       Write    ${iperf_Client_mme}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} DL TCP 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
    END
    Log With Color    ============= DL TCP Started now sleeping for ${DURATION} seconds==========
PER UE DL TCP THROUGHPUT
    ${bearer_token}=    Generate ACP Authorization Token     https://10.80.1.23/
    ${acp_url}=     Set Variable    https://10.80.1.23/
    ${samples_by_ac}=    Create Dictionary
    FOR    ${i}    ${AC_Name}    ${UE_AC}    ${AC_IP}    IN    @{Aircard}
        ${lst}=    Create List
        Set To Dictionary    ${samples_by_ac}    ${AC_Name}=${lst}
    END
    Log To Console    ${samples_by_ac}
    Set Variable    ${THRESHOLD}        9000
    ${SAMPLE_INTERVAL}=    Convert To Integer    5
    ${DURATION}=           Convert To Integer    120
    Set Variable    ${RESULT_FILE}      dl_throughput_samples.txt
    ${start_time}=    Get Time    epoch
    FOR    ${index}    IN RANGE    1    9999
        Log To Console    \n==============================================
        Log With Color    \n===== Collecting Sample ${index} of all 6 Aircard =====\n    green
        Log To Console    ==============================================
        FOR    ${i}    ${AC_Name}    ${UE_AC}    ${AC_IP}    IN    @{Aircard}
            ${nodes_det}=    Fetch Aircard RLS Data    ${AC_Name}    ${acp_url}
            ${throughput}=    Set Variable    ${nodes_det[0]['data']['dlThroughputKbps']}
            Log To Console    ${UE_AC} Sample ${index}: DL Throughput = ${throughput} Kbps
            Append To List    ${samples_by_ac['${AC_Name}']}    ${throughput}
            Append To File    ${RESULT_FILE}    ${AC_Name} ${throughput}\n
            Sleep    ${SAMPLE_INTERVAL}
        END
        ${elapsed}=    Evaluate    time.time() - ${start_time}    time
        Run Keyword If    ${elapsed} >= ${DURATION}    Exit For Loop
    END
    # Compute per‑UE averages
    FOR    ${i}    ${AC_Name}    ${UE_AC}    ${AC_IP}     IN    @{Aircard}
        ${list}=    Set Variable    ${samples_by_ac['${AC_Name}']}
        ${avg}=     Evaluate    sum(${list})/len(${list})
        Log To Console    ==============================================================================================
        Log To Console    ${UE_AC} Average DL Throughput over ${DURATION} second = ${avg} Kbps
        IF    ${avg} >= ${THRESHOLD}
            Log With Color    \n============= PASS ${UE_AC}: Avg DL Throughput >= ${THRESHOLD} ==============\n    green
        ELSE
            Log With Color    \n=========== FAIL ${UE_AC}: Avg DL Throughput < ${THRESHOLD} ===================\n    red
            Log To Console    ==========================================================================================
        END
#        RETURN    ${UE_AC}${avg}
    END
    Close All Connections
    ${END_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== DL TCP END TIME: ${END_TIME} =====\n    green
    Log To Console    ==============================================
