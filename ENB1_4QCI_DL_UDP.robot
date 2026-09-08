*** Settings ***
Library    SSHLibrary
Resource    ../../../Resources/ATG/Variables.robot
Resource    ${RESOURCES}/ATG/RaspberryPi_Aircard_SSH.robot
Library    yaml
Library    BuiltIn
Library    OperatingSystem
Library    Collections
Library    String
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
*** Test Cases ***
Perform ENB1 6CELL 6UE Attach and RUN DL UDP
    [Documentation]    Test to create SSH connection, check UE status, and run set command.
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}  IN    @{UEs}
        ${UE}=    Set Variable    UE${index}
        Login RaspberryPi    ${pi_ip}
        Login UE tnet
        Run command at UE   ${attach_cmd}    ${UE}
        Sleep    ${5}
        Verify UE status    get -vv 10    ${UE}
    END
    Log To Console    \n============================================================================
    Log With Color    \n============= Now Starting DL UDP 4QCI data for ${DURATION} seconds ============\n    pink
    Log To Console      ============================================================================\n
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== DL UDP START TIME: ${START_TIME} =====\n    green
    Log To Console    ==============================================\n
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
       ${port1}=    Set Variable    5091
       ${port2}=    Evaluate    ${port1}+1
       ${port3}=    Evaluate    ${port1}+2
       ${port4}=    Evaluate    ${port1}+3
       Log With Color    \n========== Running UE${index} DL UDP iPerf Test ==========\n
       Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
       ${iperf_Client_mme}=    Catenate
        ...    iperf -u -c ${ue_ip1} -p ${port1} -S ${QCI6} -b 5M -t ${DURATION} &
        ...    iperf -u -c ${ue_ip2} -p ${port2} -S ${QCI6} -b 2M -t ${DURATION} &
        ...    iperf -u -c ${ue_ip2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} &
        ...    iperf -u -c ${ue_ip2} -p ${port4} -S ${QCI9} -b 4M -t ${DURATION}
       Write    ${iperf_Client_mme}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} DL UDP 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client connecting to below UDP port ==========\n${status}    green
    END
    Log To Console    \n==================================================================================
    Log With Color    \n=============== Now Startting to fetch DL Throughput RLS DATA from Aircard ============\n    pink
    Log To Console    ====================================================================================\n
    Sleep    ${120}
    ${acp_url}=     Set Variable    https://10.80.1.23/
    ${bearer_token}=    Generate ACP Authorization Token     ${acp_url}
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
        Log With Color     ==============================================================================================    magenta
        Log To Console    ${UE_AC} Average DL Throughput over ${DURATION} second = ${avg} Kbps
        IF    ${avg} >= ${THRESHOLD}
            Log With Color    \n============= PASS ${UE_AC}: Avg DL Throughput >= ${THRESHOLD} ==============\n    green
        ELSE
            Log With Color    \n=========== FAIL ${UE_AC}: Avg DL Throughput < ${THRESHOLD} ===================\n    red
            Log With Color    ==========================================================================================    magenta
        END
    END
    Close All Connections
    ${END_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== DL UDP END TIME: ${END_TIME} =====\n    green
    Log To Console    ==============================================
