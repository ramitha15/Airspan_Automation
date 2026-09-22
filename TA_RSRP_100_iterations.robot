*** settings ***
Resource    /home/kvramesh/automation/Latest/Regression/Variables.robot
Resource    /home/kvramesh/automation/Latest/Regression/RaspberryPi_Aircard_SSH.robot
#Resource    ../Resources/ATG/keyword.robot
Library    Process
Library    SSHLibrary
Library    yaml
Library    BuiltIn
Library    OperatingSystem
Library    Collections
Library    String
Library    RequestsLibrary
Library    JSONLibrary
Library    Process
Library    RequestsLibrary
Library    JSONLibrary
Library    DateTime
Suite Teardown    Terminate All Processes

*** Variables ***
${DURATION}     21100
${CE_IP}      10.80.100.201
${CE_username}      pi
${CE_password}      !@#4ir$p4N
${eNB6}     10.80.5.249
${RU_eNB6}     10.80.6.64
${enb6_pi}      10.80.0.12

#*** Test Cases ***
#4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms
#    [Tags]    4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms
    
#    ${CURRENT}=     Get Current Date
#    ${start_time}=    Get Current Date
#    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
 #   ${pi_ip}=   Set Variable    10.80.0.12
 #   ${time}=     Get Current Date    result_format=%H-%M
 #   ${RESULT_PATH}=     ATG_4G_Create Log Path
     
 #   Start UE log collection_usernameSWUSER     ${pi_ip}
    
 #   Start_Non_Commercial_CE     ${pi_ip}     4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms

    #${ue_state}=    TCP BIDI    ${pi_ip}     ${base_port}
  #  ${ue_state}=    UDP BIDI   ${pi_ip}
  #  Sleep    10s
  #  Log    ${ue_state}
  #  IF    '13' in """${ue_state}"""
         
  #         ATG_4G_CLI_TA_RSRP_100_iterations_90_110_kms 
  #  ELSE
   #     Log To Console    =======================================================
   #     Log With Color    ================== UE is not attached ==================    red
    #    Log To Console    =======================================================
    #END


    #Stop UE log collection_usernameSWUSER      ${pi_ip}
    #ATG_4G_bs Log Collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms
    #ATG_4G_L1 log collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms
   # ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_90_110_kms

    #SSHLibrary.Close All Connections
*** Test Cases ***
4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms
    [Tags]    4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms
    
    ${CURRENT}=     Get Current Date
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${pi_ip}=   Set Variable    10.80.0.12
    ${time}=     Get Current Date    result_format=%H-%M
    ${RESULT_PATH}=     ATG_4G_Create Log Path
     
    Start UE log collection_usernameSWUSER     ${pi_ip}
    
    Start_Non_Commercial_CE     ${pi_ip}     4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms

    #${ue_state}=    TCP BIDI    ${pi_ip}     ${base_port}
    ${ue_state}=    UDP BIDI   ${pi_ip}
    Sleep    10s
    Log    ${ue_state}
    IF    '13' in """${ue_state}"""
         
           ATG_4G_CLI_TA_RSRP_100_iterations_240_260_kms 
    ELSE
        Log To Console    =======================================================
        Log With Color    ================== UE is not attached ==================    red
        Log To Console    =======================================================
    END


    Stop UE log collection_usernameSWUSER      ${pi_ip}
    ATG_4G_bs Log Collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms
    ATG_4G_L1 log collection    ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms
    ATG_4G_L1 log clear      ${eNB6}      4G_ATG_ENB6_TA SWEEP_PUC2a_240_260_kms

    SSHLibrary.Close All Connections

*** Keywords ***
ATG_4G_CLI_TA_RSRP_100_iterations_90_110_kms
    [Documentation]    For each attenuation in ${atten_list}, sets ports 8 and 9 to that
    ...    attenuation and then runs ${cycles} cycles of FW TA sweep (90 -> 110 km)
    ...    followed by reverse TA sweep (110 -> 90 km) on the CE at constant speed
    ...    ${speed}. Expects the CE tmux session (alias CE) to be already opened by
    ...    Start_Non_Commercial_CE.
    [Tags]    ATG_4G_CLI_TA_RSRP_100_iterations_90_110_kms
    [Arguments]    ${rack_pi_ip}=10.80.6.247    ${cycles}=5    ${step_interval}=10    ${speed}=1200

    @{atten_list}=    Create List        ${25}    ${30}    ${33}   ${35}    ${38}

    # One persistent connection to the rack pi for the attenuation settings
    Login Pi    ${rack_pi_ip}
    ${rack_conn}=    Get Connection

    FOR    ${att}    IN    @{atten_list}
        Switch Connection    ${rack_conn.index}
        Log With Color    \n===== Setting attenuation ${att} dB on ports 8 and 9 =====\n    green
        Write    cd ~/ps_scripts; ./setGain1port.sh ${att} 8; ./setGain1port.sh ${att} 9
        Read    delay=3s
        FOR    ${cycle}    IN RANGE    1    ${cycles} + 1
            Log With Color    \n===== Atten ${att} dB, Cycle ${cycle}/${cycles}: FW TA sweep 90 -> 110 km =====\n    green
            Switch Connection    CE
            FOR    ${km}    IN RANGE    90    111
                Write    tmux send-keys -t chanemu "configure_mimo_mode ${km} ${speed}" C-m
                Sleep    ${step_interval}
            END
            Log With Color    \n===== Atten ${att} dB, Cycle ${cycle}/${cycles}: Reverse TA sweep 110 -> 90 km =====\n    yellow
            Switch Connection    CE
            FOR    ${km}    IN RANGE    110    89    -1
                Write    tmux send-keys -t chanemu "configure_mimo_mode ${km} ${speed}" C-m
                Sleep    ${step_interval}
            END
        END
        Log With Color    \n===== Completed ${cycles} FW+Reverse cycles at attenuation ${att} dB =====\n    green
    END
    Log With Color    \n===== Completed all attenuations: @{atten_list} =====\n    green

ATG_4G_CLI_TA_RSRP_100_iterations_240_260_kms
    [Documentation]    For each attenuation in ${atten_list}, sets ports 8 and 9 to that
    ...    attenuation and then runs ${cycles} cycles of FW TA sweep (90 -> 110 km)
    ...    followed by reverse TA sweep (110 -> 90 km) on the CE at constant speed
    ...    ${speed}. Expects the CE tmux session (alias CE) to be already opened by
    ...    Start_Non_Commercial_CE.
    [Tags]    ATG_4G_CLI_TA_RSRP_100_iterations_240_260_kms
    [Arguments]    ${rack_pi_ip}=10.80.6.247    ${cycles}=5   ${step_interval}=10    ${speed}=1200

    @{atten_list}=    Create List    ${25}    ${30}    ${33}   ${35}    ${38}

    # One persistent connection to the rack pi for the attenuation settings
    Login Pi    ${rack_pi_ip}
    ${rack_conn}=    Get Connection

    FOR    ${att}    IN    @{atten_list}
        Switch Connection    ${rack_conn.index}
        Log With Color    \n===== Setting attenuation ${att} dB on ports 8 and 9 =====\n    green
        Write    cd ~/ps_scripts; ./setGain1port.sh ${att} 8; ./setGain1port.sh ${att} 9
        Read    delay=3s
        FOR    ${cycle}    IN RANGE    1    ${cycles} + 1
            Log With Color    \n===== Atten ${att} dB, Cycle ${cycle}/${cycles}: FW TA sweep 240 -> 260 km =====\n    green
            Switch Connection    CE
            FOR    ${km}    IN RANGE    240    261
                Write    tmux send-keys -t chanemu "configure_mimo_mode ${km} ${speed}" C-m
                Sleep    ${step_interval}
            END
            Log With Color    \n===== Atten ${att} dB, Cycle ${cycle}/${cycles}: Reverse TA sweep 260 -> 240 km =====\n    yellow
            Switch Connection    CE
            FOR    ${km}    IN RANGE    260    239       -1
                Write    tmux send-keys -t chanemu "configure_mimo_mode ${km} ${speed}" C-m
                Sleep    ${step_interval}
            END
        END
        Log With Color    \n===== Completed ${cycles} FW+Reverse cycles at attenuation ${att} dB =====\n    green
    END
    Log With Color    \n===== Completed all attenuations: @{atten_list} =====\n    green
