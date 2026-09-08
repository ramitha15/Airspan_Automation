*** Settings ***
Library    SSHLibrary
Resource    ../../../Resources/ATG/Variables.robot
Resource    ${RESOURCES}/ATG/RaspberryPi_Aircard_SSH.robot
Library     yaml
Library     BuiltIn
Library     OperatingSystem
Library     Collections
Library     String
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
*** Test Cases ***
Perform ENB1 6CELL 6UE Attach
    [Documentation]    Test to create SSH connection, check UE status, and run set command.
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}  IN    @{UEs}
        ${UE}=    Set Variable    UE${index}
        Login RaspberryPi    ${pi_ip}
        Login UE tnet
        Run command at UE   ${attach_cmd}    ${UE}
        Sleep    ${5}
        Verify UE status    get -vv 10    ${UE}
    END
#Run UL TCP 4QCI data at ENB1 6CELL 6 UE
    Log To Console    \n============================================================================
    Log With Color    \n============= Now Starting UL TCP 4QCI data for ${DURATION} seconds ============\n    pink
    Log To Console      ============================================================================\n
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== UL TCP START TIME: ${START_TIME} =====\n    green
    Log To Console    ==============================================\n
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
       ${port1}=    Evaluate    5060 + ${index}*4
       ${port2}=    Evaluate    ${port1}+1
       ${port3}=    Evaluate    ${port1}+2
       ${port4}=    Evaluate    ${port1}+3
       Log With Color    \n========== Running UE${index} UL TCP iPerf Test ==========\n
#Running Listening cmd at mme
       Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
       ${iperf_Server_mme}=    Catenate
       ...    iperf -s -p ${port1} -t ${DURATION} &
       ...    iperf -s -p ${port2} -t ${DURATION} &
       ...    iperf -s -p ${port3} -t ${DURATION} &
       ...    iperf -s -p ${port4} -t ${DURATION}
       Write    ${iperf_Server_mme}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} UL TCP 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
#Running Client cmd at RaspberryPi for internet APN2
       Login RaspberryPi    ${pi_ip}
       ${UL_TCP_3QCI_Pi_Client}=    Catenate
       ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port2} -t ${DURATION} -S ${QCI6} &
       ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port3} -t ${DURATION} -S ${QCI7} &
       ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port4} -t ${DURATION} -S ${QCI9} && pkill -9 iperf
       Write    ${UL_TCP_3QCI_Pi_Client}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} TCP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
#Running Client cmd at Aircard for management APN1
       Login RaspberryPi    ${pi_ip}
       Login Aircard
       ${UL_TCP_1QCI_AC_Client}=    Set Variable    iperf -c ${MME_TUN_IP1} -B ${ue_ip1} -P 5 -p ${port1} -t ${DURATION} -S ${QCI6} && pkill -9 iperf
       Write    ${UL_TCP_1QCI_AC_Client}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} TCP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
    END
    Log To Console    \n==================================================================================
    Log With Color    \n=============== Now Startting to monitor UL TCP ============\n    pink
    Log To Console    ====================================================================================\n
    Sleep    ${1}
PER UE UL UDP THROUGHPUT
        Monitor UL Throughput   ${ENB1_IP}    ${ENB1_USER}    ${ENB1_PASS}    ${ENB1_PORT}


