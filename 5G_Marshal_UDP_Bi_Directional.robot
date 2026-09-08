*** Settings ***
Library         SSHLibrary
Resource    ../Resources/ATG/5GVariables.robot
Resource    ../Resources/ATG/Amari_ssh.robot
Library     ../Resources/ATG/ThroughputLib.py
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
@{Amari} =
...    1    5170026922    ue1_SDR0    13.12.3.2
...    2    5170026720   ue2_SDR1   13.12.4.2
...    3    5170026673   ue3_SDR2   13.12.5.2
*** Keywords ***
Monitor Bi-Directional Throughput
    [Arguments]    ${GNB}    ${username}    ${password}    ${port}
    ...            ${samples}=20    ${interval}=5
    ...            ${ul_threshold}=40    ${dl_threshold}=70
    Open Connection    ${GNB}    port=${port}    alias=GNB
    Login    ${username}    ${password}

    Write    l2ssh wi02-marshall-5162-cu1
    Write    cd application/DU/bin/
    Write    ./nrCli
    Sleep    2s

    &{ul_dict}=    Create Dictionary
    &{dl_dict}=    Create Dictionary

    FOR    ${i}    IN RANGE    ${samples}

        # --------DL &  UL --------
        Write    ue show rate
        Sleep    1s
        ${output}=    Read Until    Connected
        @{lines}=     Split To Lines    ${output}

        ${dl_avg}    ${ul_avg}=    Calculate Average Throughput    ${output}
        
        Log To Console    --> UL Avg=${ul_avg} Mbps | DL Avg=${dl_avg} Mbps
	

        Run Keyword If    ${ul_avg} < ${ul_threshold}
        ...    Fail     UL below threshold

        Run Keyword If    ${dl_avg} < ${dl_threshold}
        ...    Fail     DL below threshold
    END



*** Test Cases ***
Perform UE attach on Marshal
    [Documentation]    Test to create SSH connection, check UE status, and run set command.
    #FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
    Log To Console    \n====================================Before AmariUE1 KVR==========\n
        Login AmariUE1    ${amari_ue1_ip}
    Log To Console    \n====================================After AmariUE1 KVR==========\n
        Login UE tnet
        Write    ${attach_cmd}
        Sleep    ${2}
        Write   ${pdn_cmd} 
        ${cmd_output}=    Read Until Prompt
        Log To Console    \n========== UE OUTPUT for: ${attach_cmd} ==========\n${cmd_output}
        Log    ${cmd_output}
        Sleep    ${10}
        Verify UE status    ue 3
    #END
#Run UL UDP 3QCI data at Marshal 3 RU setup 3 UE
#    [Documentation]    Test to create SSH connection with MME  and Amari and UL UDP run iperf command.
#    [Tags]    UL
#    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
#    Log To Console    \n==============================================
#    Log With Color    \n===== UL UDP START TIME: ${START_TIME} =====\n    green
#    Log To Console    ==============================================
#    Log With Color    \n========== Starting UL UDP UE on MGT APN for ${DURATION} seconds ==========\n    green
#    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
#       ${port1}=    Set Variable    5091
#      ${port2}=    Evaluate    ${port1}+1
#       ${port3}=    Evaluate    ${port1}+2
#       ${port4}=    Evaluate    ${port1}+3
#       Log With Color    \n========== Running UE${index} UL UDP iPerf Test ==========\n
#    #Running Client cmd at Amari for management APN1
#      Login AmariUE1    ${amari_ue1_ip}
#      Write    ${sudo} 
#      Write    ${Amari_PASS}
#       ${UL_UDP_1QCI_Client}=    Set Variable    iperf -u -c ${MME_IP} -p ${port1}  -b${ul_tp} -t ${DURATION} -B ${ue_ip1}
#       #${UL_UDP_1QCI_Client}=    Set Variable    iperf -u -c ${MME_IP} -p ${port1} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip1}
#
#       Log    ${UL_UDP_1QCI_Client}
#       Sleep  ${10}
#       Write    ${UL_UDP_1QCI_Client}
#       ${status}=    Read    delay=30s
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Running UE${index} UDP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
#       Sleep    ${1}
#   #Running Client cmd at Amari for internet APN2
#      Login AmariUE1    ${amari_ue1_ip}
#      Write    ${sudo} 
#      Write    ${Amari_PASS}
#       ${UL_UDP_3QCI_Client}=    Catenate
#       ...    iperf -u -c ${MME_IP} -p ${port2} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip2} &
#       ...    iperf -u -c ${MME_IP} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} -B ${ue_ip2} &
#       ...    iperf -u -c ${MME_IP} -p ${port4} -S ${QCI9} -b 2M -t ${DURATION} -B ${ue_ip2} && pkill -9 iperf
#       Write    ${UL_UDP_3QCI_Client}
#       ${status}=    Read    delay=10s
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Running UE${index} UDP Client cmd at Amari for ${DURATION} seconds ==========\n    green
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
#    END
#
#       Log With Color    ============= UL UDP Started now sleeping for ${DURATION} seconds==========
#Run DL TCP 4QCI data at ENB1 6CELL 6 UE
#    [Documentation]    Test to create SSH connection with MME PI and Aircard and DL TCP run iperf command.
#    [Tags]    DL
#    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
#    Log To Console    \n==============================================
#    Log With Color    \n===== DL TCP START TIME: ${START_TIME} =====\n    green
#    Log To Console    ==============================================
#    Log With Color    \n========== Starting DL TCP 4QCI data at ENB1 6 CELL 6 UE for ${DURATION} seconds ==========\n    green
#    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
#       ${port1}=    Set Variable    5091
#       ${port2}=    Evaluate    ${port1}+1
#       ${port3}=    Evaluate    ${port1}+2
#       ${port4}=    Evaluate    ${port1}+3
#       Log With Color    \n========== Running UE${index} DL TCP iPerf Test ==========\n
#    #Running Listening cmd at Aircard for management APN1
#       Login RaspberryPi    ${pi_ip}
#       Login Aircard
#       ${DL_TCP_1QCI_AC_Server}=    Set Variable    iperf -s -p ${port1} -t ${DURATION}
#       Write    ${DL_TCP_1QCI_AC_Server}
#       ${status}=    Read    delay=10s
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Running UE${index} TCP listening cmd at Aircard for ${DURATION} seconds ==========\n    green
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
#       Sleep    ${1}
#    #Running Listening cmd at RaspberryPi for internet APN2
#       Login RaspberryPi    ${pi_ip}
#       ${DL_TCP_3QCI_Pi_Server}=    Catenate
#       ...    iperf -s -p ${port2} -t ${DURATION} &
#       ...    iperf -s -p ${port3} -t ${DURATION} &
#       ...    iperf -s -p ${port4} -t ${DURATION} && pkill -9 iperf
#       Write    ${DL_TCP_3QCI_Pi_Server}
#       ${status}=    Read    delay=10s
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Running UE${index} TCP listening cmd at raspberrypi for ${DURATION} seconds ==========\n    green
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
#    #Running Client cmd at mme
#       Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
#       ${iperf_Client_mme}=    Catenate
#       ...    iperf -c ${ue_ip1} -p ${port1} -S ${QCI6} -P 5 -t ${DURATION} &
#       ...    iperf -c ${ue_ip2} -p ${port2} -S ${QCI6} -P 5 -t ${DURATION} &
#       ...    iperf -c ${ue_ip2} -p ${port3} -S ${QCI7} -P 5 -t ${DURATION} &
#       ...    iperf -c ${ue_ip2} -p ${port4} -S ${QCI9} -P 5 -t ${DURATION}
#       Write    ${iperf_Client_mme}
#       ${status}=    Read    delay=10s
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Running UE${index} DL TCP 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
#       Log With Color    ===========================================================================    green
#       Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
#    END
#    Log With Color    ============= DL TCP Started now sleeping for ${DURATION} seconds==========
#PER UE UDP THROUGHPUT
#        Monitor Bi-Directional Throughput   ${MARSHAL_IP}    ${MARSHAL_USER}    ${MARSHAL_PASS}    ${MARSHAL_PORT}


