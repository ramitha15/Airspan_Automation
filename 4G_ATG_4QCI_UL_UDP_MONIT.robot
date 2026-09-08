*** Settings ***
Library         SSHLibrary
Resource    ../../Resources/ATG/Variables.robot
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
Monitor UL Throughput
    [Arguments]    ${ENB}    ${username}    ${password}    ${port}
    ...            ${samples}=6    ${interval}=5    ${threshold}=4.3

    Open Connection    ${ENB}    port=${port}    alias=ENB
    Login    ${username}    ${password}

    Write    cd /bs/ && ./lteCli
    Sleep    2s

    &{pdcp_dict}=    Create Dictionary

    FOR    ${i}    IN RANGE    ${samples}
        Write    ue show rateul
        Sleep    1s
        ${output}=    Read Until   Cell Total

        @{lines}=    Split To Lines    ${output}

        FOR    ${line}    IN    @{lines}

          # Skip headers & separators
          Run Keyword If    'RNTI' in '${line}'          Continue For Loop
          Run Keyword If    'CCUs' in '${line}'          Continue For Loop
          Run Keyword If    'Cell Total' in '${line}'   Continue For Loop
          Run Keyword If    '---' in '${line}'           Continue For Loop
          Run Keyword If    '===' in '${line}'           Continue For Loop

    # Valid UE rows always start with |
          Run Keyword If    not '${line}'.startswith('|')    Continue For Loop

          ${line}=    Replace String Using Regexp    ${line}    \\s+    ${SPACE}
          @{cols}=    Split String    ${line}    |

    # cols index safety check
          ${len}=    Get Length    ${cols}
          Run Keyword If    ${len} < 4    Continue For Loop

          ${rnti}=        Strip String    ${cols}[2]
          ${pdcp_raw}=    Strip String    ${cols}[3]

    # Skip if PDCP is not numeric
          Run Keyword If    not 'M' in '${pdcp_raw}'    Continue For Loop
#          and not 'K' in '${pdcp_raw}'

          ${num}=    Replace String    ${pdcp_raw}    M    ${EMPTY}
#          ${num}=    Replace String    ${num}          K    ${EMPTY}

          ${pdcp}=    Evaluate    float(${num})

          ${exists}=    Run Keyword And Return Status
           ...    Dictionary Should Contain Key    ${pdcp_dict}    ${rnti}

          IF    ${exists}
             Append To List    ${pdcp_dict}[${rnti}]    ${pdcp}
          ELSE
             @{lst}=    Create List    ${pdcp}
             Set To Dictionary    ${pdcp_dict}    ${rnti}=${lst}
        END

    END


        Sleep    ${interval}
    END

    # ---- Calculate average per UE ----
    FOR    ${rnti}    IN    @{pdcp_dict.keys()}
        ${values}=    Get From Dictionary    ${pdcp_dict}    ${rnti}
        ${sum}=       Evaluate    sum(${values})
        ${avg}=       Evaluate    round(${sum} / len(${values}), 3)

        Log To Console    UE ${rnti} --> Avg PDCP UL = ${avg} Mbps

        Run Keyword If    ${avg} < ${threshold}
        ...    Fail    UE ${rnti} PDCP UL ${avg} Mbps below threshold ${threshold}
    END


*** Test Cases ***
Perform ENB1 6CELL 6UE Attach
    [Documentation]    Test to create SSH connection, check UE status, and run set command.
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
        ${UE}=    Set Variable    UE${index}
        Login RaspberryPi    ${pi_ip}
        Login UE tnet
        Run command at UE    ${attach_cmd}    ${UE}
        Sleep    ${5}
        Verify UE status    get -vv 10    ${UE}
    END
Run UL UDP 4QCI data at ENB1 6CELL 6 UE
    [Documentation]    Test to create SSH connection with MME PI and Aircard and UL UDP run iperf command.
    [Tags]    UL
    ${START_TIME}=    Get Time    format=%Y-%m-%d %H:%M:%S
    Log To Console    \n==============================================
    Log With Color    \n===== UL UDP START TIME: ${START_TIME} =====\n    green
    Log To Console    ==============================================
    Log With Color    \n========== Starting UL UDP 4QCI data at ENB1 6 CELL 6 UE for ${DURATION} seconds ==========\n    green
    FOR    ${index}    ${ue_ip1}    ${ue_ip2}    ${pi_ip}    IN    @{UES}
       ${port1}=    Set Variable    5091
       ${port2}=    Evaluate    ${port1}+1
       ${port3}=    Evaluate    ${port1}+2
       ${port4}=    Evaluate    ${port1}+3
       Log With Color    \n========== Running UE${index} UL UDP iPerf Test ==========\n
    #Running Client cmd at Aircard for management APN1
       Login RaspberryPi    ${pi_ip}
       Login Aircard
       ${UL_UDP_1QCI_AC_Client}=    Set Variable    iperf -u -c ${MME_TUN_IP1} -p ${port1} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip1}
       Write    ${UL_UDP_1QCI_AC_Client}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} UDP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
       Sleep    ${1}
    #Running Client cmd at RaspberryPi for internet APN2
       Login RaspberryPi    ${pi_ip}
       ${UL_UDP_3QCI_Pi_Client}=    Catenate
       ...    iperf -u -c ${MME_TUN_IP2} -p ${port2} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip2} &
       ...    iperf -u -c ${MME_TUN_IP2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} -B ${ue_ip2} &
       ...    iperf -u -c ${MME_TUN_IP2} -p ${port4} -S ${QCI9} -b 2M -t ${DURATION} -B ${ue_ip2} && pkill -9 iperf
       Write    ${UL_UDP_3QCI_Pi_Client}
       ${status}=    Read    delay=10s
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Running UE${index} UDP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
       Log With Color    ===========================================================================    green
       Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
    END

        Log With Color    ============= UL UDP Started now sleeping for ${DURATION} seconds==========

PER UE UL UDP THROUGHPUT
        Monitor UL Throughput   ${ENB1_IP}    ${ENB1_USER}    ${ENB1_PASS}    ${ENB1_PORT}


