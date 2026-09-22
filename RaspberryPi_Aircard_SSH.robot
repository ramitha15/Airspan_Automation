*** Settings ***
Resource    ../Regression/Variables.robot
Library    SSHLibrary
Library    yaml
Library    BuiltIn
Library    OperatingSystem
Library    Collections
Library    String
Library    RequestsLibrary
Library    JSONLibrary
#Library    Process
Library    RequestsLibrary
Library    DateTime
*** Variables ***
${RESOURCES}    /home/kvramesh/automation/Latest/
${provide_lat_long}      "atgm alm data 0 32.033958 1 -86.945594 2 9000.0 3 0.0 4 0.0 5 0.0 6 0.0 7 0.0 8 0"
*** Keywords ***

Attach single UE
    [Arguments]    ${pi_ip}
    IF      $pi_ip == $enb8_pi1
            ${PI_USER}=    Set Variable    ${pi_svg_username}
            ${PI_PASS}=    Set Variable    ${pi_svg_password}
    ELSE IF     $pi_ip == $enb7_pi
            ${PI_USER}=    Set Variable    ${pi_admin_username}
            ${PI_PASS}=    Set Variable    ${pi_admin_password}
    ELSE IF     $pi_ip == $enb6_pi
            ${PI_USER}=    Set Variable    ${pi_swuser_username}
            ${PI_PASS}=    Set Variable    ${pi_swuser_password}
    ELSE IF     $pi_ip == $enb9_pi
            ${PI_USER}=    Set Variable    ${pi_ssingh_username}
            ${PI_PASS}=    Set Variable    ${pi_ssingh_password}
    ELSE
            ${PI_USER}=    Set Variable    ${pi_airspan_username}
            ${PI_PASS}=    Set Variable    ${pi_airspan_password}
    END
    LOG    Selected user: ${PI_USER}
    SSHLibrary.Open Connection    ${pi_ip}
    Login    ${PI_USER}    ${PI_PASS}
    Set Client Configuration    prompt=>
    Write    ssh ${AC_USER}@${AC_IP}
    Read Until    password:
    Write    ${AC_PASS}
    Read Until    $
    Write    cd /bs/ && ./tnet
    Write    info-x
    Read Until    tnet >
    #set 8[1]2=1
    ${syslog_enbale}=   Set Variable    set logging [1] 7=[08 00]

    Write    ${syslog_enbale}

    Write    ${provide_lat_long}
    #First detach if the UE was attached in the previous test run.
    Write    ${dettach_cmd}
    # Now perform fresh attach for this current TC.
    Write    ${attach_cmd}
    Sleep    20s
    ${attach_cmd_output}=    Read Until Prompt
#    Log To Console    \n========== OUTPUT for: ${attach_cmd} ==========\n${attach_cmd_output}
#    Log    ${attach_cmd_output}
    Write    info-x
    Read    delay=1s
    Write    ${get_cmd}
    ${get_cmd_output}=    Read Until Prompt
#    Write    ${UE_State_cmd}
#    ${UE_State}=    Read    delay=5s
#To get UE ip
    Write    get 10[1]2
    ${ip1_output}=    Read Until Prompt
    ${ue_ip1}=    Evaluate    re.search(r'\\d+\\.\\d+\\.\\d+\\.\\d+', """${ip1_output}""").group()    re
    Write    get 10[2]2
    ${ip2_output}=    Read Until Prompt
    ${ue_ip2}=    Evaluate    re.search(r'\\d+\\.\\d+\\.\\d+\\.\\d+', """${ip2_output}""").group()    re
#    ${ue_status}=    Read Until Prompt
#    Log To Console    \n========== OUTPUT for: ${get_cmd} ==========\n${get_cmd_output}

    IF    'established' in """${get_cmd_output}"""
        Log To Console    =======================================================
        Log With Color    ================== ${pi_ip} UE is established ==================    green
        Log To Console    =======================================================
    ELSE
        Log To Console    =======================================================
        Log With Color    ================== ${pi_ip} UE is not attached ==================    red
        Log To Console    =======================================================
    END
    RETURN    ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}

ATG_4G_Create Log Path
    Create Date Folder
    ${Result_Path}=     Create Tag Folder
    Log To Console    ${Result_Path}
    RETURN    ${Result_Path}

ATG_4G_SSH to BBU
    [Arguments]    ${BBU_IP}
    SSHLibrary.Open Connection    ${BBU_IP}    port=${SSH_port}    alias=BBU
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=$

ATG_4G_SSH to RU
    [Arguments]    ${RU_IP}
    SSHLibrary.Open Connection    ${RU_IP}    port=${SSH_port}    alias=RU
    Login     ${RU_username}    ${RU_password}
    Set Client Configuration    prompt=$

Create Date Folder
    ${date}=    Get Current Date    result_format=%Y-%m-%d
    ${date_path}=    Join Path    ${BASE_DIR}    ${date}
    IF    not os.path.isdir(r"${date_path}")
        Create Directory    ${date_path}
    END
    RETURN    ${date_path}

Create Tag Folder
    ${tag}=    Get From List    ${TEST TAGS}    0
    ${safe_tag}=    Replace String    ${tag}    ${SPACE}    _
    ${safe_tag}=    Replace String    ${safe_tag}    /    _
    ${tag_folder}=    Set Variable    ${safe_tag}
    ${DATE_PATH}=       Create Date Folder
    ${full_tag_path}=    Join Path    ${DATE_PATH}    ${tag_folder}
    IF    not os.path.isdir(r"${full_tag_path}")
        Create Directory    ${full_tag_path}
    END
    RETURN    ${full_tag_path}

ATG_4G_HO_Attenuation
    SSHLibrary.Open Connection    ${RACK_IP}    port=${SSH_port}    alias=RF_RACK
    Login    ${RACK_username}    ${RACK_password}
    Set Client Configuration    prompt=$
    Write    cd ps_scripts/ && pwd
    ${output_1}=        Read
    Log To Console    ${output_1}
    FOR    ${i}     IN RANGE    0   42  3
            Write    ./setGain.sh ${i} 0
            ${output}=        Read Until Prompt
            Log To Console    ${output}
            Sleep    1s
    END
    Sleep    5s
    FOR    ${i}     IN RANGE    42   -1  -3
            Write    ./setGain.sh ${i} 0
            ${output}=        Read Until Prompt
            Log To Console    ${output}
            Sleep    1s
    END

Fetch Inter ENB S1HO Stats
    [Arguments]    ${from}      ${to}
    ${bearer_token}     Generate ACP Authorization Token    https://10.80.1.23/
    Log    ${bearer_token}
    ${eNB_Rest_ID}=     Fetch ENB Rest ID    eNB8   https://10.80.1.23/
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/enbStatisticsHour/
    ${headers}=         Create Dictionary    Authorization=Bearer ${bearer_token}
    ${params}=           Create Dictionary    id=${eNB_Rest_ID}     from=${from}    to=${to}
    ${response}=         GET On Session       mysession   ${api}  params=${params}   headers=${headers}
    Should Be Equal As Integers    ${response.status_code}    200
    ${Complete_stats}=   Evaluate    json.loads('''${response.content}''')    json
    ${length}=      Get Length    ${Complete_stats}
    ${HO_prep_attempts}=     Create List
    ${Ho_prep_success}=     Create List
    ${Ho_exec_attempts}=     Create List
    ${Ho_exec_success}=     Create List
    FOR    ${item}      IN    @{Complete_stats}
           ${cell_kpi}=        Get From Dictionary     ${item}     cell
           ${HO_preparationAttempts}=   Get From Dictionary    ${cell_kpi}      hoS1InterEnbOutPrepAtt
           Append To List    ${HO_prep_attempts}      ${HO_preparationAttempts}
           ${HO_preparationSuccess}=    Get From Dictionary    ${cell_kpi}      hoS1InterEnbOutPrepSucc
           Append To List    ${Ho_prep_success}      ${HO_preparationSuccess}
           ${HO_executionAttempts}=    Get From Dictionary    ${cell_kpi}      hoS1InterEnbExecutionAtt
           Append To List    ${Ho_exec_attempts}      ${HO_executionAttempts}
           ${HO_executionSuccess}=    Get From Dictionary    ${cell_kpi}      hoS1InterEnbOutSucc
           Append To List    ${Ho_exec_success}      ${HO_executionSuccess}
           ${Total preparations attempts}=    Evaluate    sum(x for x in ${HO_prep_attempts})
           ${Total preparations success}=    Evaluate    sum(x for x in ${Ho_prep_success})
           ${Total execution attempts}=    Evaluate    sum(x for x in ${Ho_exec_attempts})
           ${Total execution success}=    Evaluate    sum(x for x in ${Ho_exec_success})
           ${S1HO Execution success rate} =    Evaluate    round((float(${Total execution success}) / float(${Total execution attempts})) * 100, 2)

    END

    Log To Console    Total S1HO Preparations attempts: ${Total preparations attempts}\n
    Log To Console    Total S1HO Preparations success: ${Total preparations success}\n
    Log To Console    Total S1HO Execution attempts: ${Total execution attempts}\n
    Log To Console    Total S1HO Execution success: ${Total execution success}\n
    Log To Console    S1HO Handover execution success rate is : ${S1HO Execution success rate}%

#Generate ACP Authorization Token
#    [Documentation]    Generate and Resturn ACP authorization Token
#    [Arguments]    ${acp_url}
#    ${CONTENT_TYPE}=    Set Variable    application/json
#    ${json_string}=    Set Variable     { "Username": "automation", "Password": "svgautomation" }
#    ${api}    Set Variable    /api/authenticate
#    TRY
#        ${json_dict}=    Evaluate    json.loads('''${json_string}''')    json
#        ${headers}    create dictionary    Content-Type=${CONTENT_TYPE}    User-Agent=RobotFramework
#        create session    mysession    ${acp_url}
#        ${response}    POST On Session    mysession    ${api}    json=${json_dict}    headers=${headers}
#        ${status_code}    convert to string    ${response.status_code}
#        ${token}    Set Variable    ${response.content}
#        Log    ${response.content}
#        Should Be True    '${status_code}' == '200'
#    EXCEPT
#        Log To Console    Token Generation Failed
#    END
#    [Return]    ${token}

Fetch eNB Rest ID
    [Documentation]    Fetch and Resturns Rest ID taking input as node name and ACP URL
    [Arguments]    ${node_name}     ${acp_url}
    ${bearer_token}     Generate ACP Authorization Token    https://10.80.1.23/
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/enb/
#    ${node_name}=   Set Variable    name=Node%3A7CE243P8V2
    ${params}=           Create Dictionary    name=${node_name}
    ${headers}=          Create Dictionary      Authorization=Bearer ${bearer_token}
#    ${response}=         GET On Session       mysession   ${api}  params=${node_name}   headers=${headers}
    ${response}=         GET On Session       mysession   ${api}  params=${params}   headers=${headers}
    Should Be Equal As Integers    ${response.status_code}    200
    ${nodes_det}=    Evaluate    json.loads('''${response.content}''')    json
    ${id}=    set variable    ${nodes_det}[0][id]
    RETURN    ${id}

4G_ATG_CellEnable_3cells
    [Documentation]    To enable mentioned 4G ATG node cell
    [Arguments]    ${first}     ${second}   ${third}
    ${acp_url}=     Set Variable    https://10.80.1.23/
    ${bearer_token}=    Generate ACP Authorization Token     https://10.80.1.23/
    ${id}=      Fetch ENB Rest ID   SVG_Red     https://10.80.1.23/
    Log    ${id}
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/enb/${id}
    ${headers}=          Create Dictionary      Authorization=Bearer ${bearer_token}
    ${response}=         GET On Session       mysession   ${api}    headers=${headers}
    Should Be Equal As Integers    ${response.status_code}    200
    ${nodes_det}=    Evaluate    json.loads('''${response.content}''')    json
    ${enbcfg}=       Get From Dictionary    ${nodes_det}   enbConfig
    ${celllist}=      Get From Dictionary    ${enbcfg}  lteCellList
    FOR     ${cells}    IN    @{celllist}
        IF    ${cells}[cellNumber] == ${first} or ${cells}[cellNumber] == ${second} or ${cells}[cellNumber] == ${third}
            ${keytoremove}=     Create List     embmsProfile    trafficManagementProfile    csfbCdma2kMobilityParam     prachRsi
            Remove From Dictionary    ${cells}      @{keytoremove}
            ${cellstate}=    Get From Dictionary    ${cells}     isEnabled
            IF      ${cellstate} == False
                    Set To Dictionary    ${cells}   isEnabled=True
            ELSE
                    Log To Console    "Cell is already enabled"
            END
        ELSE
            Log To Console    "No action needed"
        END
    END
    Set To Dictionary    ${enbcfg}      lteCellList=${celllist}
    ${keylist}=     Create List    faultManagementProfile     s1UDualIpAddress    s1UDualSubnetMask     isS1UDualInterfaceEnabled  s1CDualIpAddress   isS1CDualInterfaceEnabled   isS1USeGwInterfaceEnabled   isS1CSeGwInterfaceEnabled
    ${keylist2}=    Create List    isTwampSenderInterfaceEnabled   isM1InterfaceEnabled    isM2InterfaceEnabled    isCSonServerInterfaceEnabled  isPtpSlaveInterfaceEnabled     ptpSlaveIpAddress   ptpSlaveSubnetMask  interfaceToUseForPtpSlave   interfaceToUseForX2U
    ${keylist3}=    Create List    x2UIpAddress     x2USubnetMask   isX2UInterfaceEnabled   isX2CInterfaceEnabled   multiCellProfile
    Remove From Dictionary    ${enbcfg}      @{keylist}     @{keylist2}     @{keylist3}
    Set To Dictionary    ${nodes_det}      enbConfig=${enbcfg}
    ${headers}=          Create Dictionary     Content-Type=application/json    Authorization=Bearer ${bearer_token}
    Create Session    mysession    ${acp_url}
    ${response}=         PATCH On Session   mysession   ${api}  json=${nodes_det}    headers=${headers}


Log CLI Output With Timestamp
    [Arguments]    ${logfile}    ${text}
    # Remove ANSI escape sequences
    ${clean}=    Replace String Using Regexp
    ...    ${text}
    ...    \x1b\\[[0-9;?]*[a-zA-Z]
    ...

    ${lines}=    Split To Lines    ${clean}
    FOR    ${line}    IN    @{lines}
        ${line}=    Strip String    ${line}
        IF    '${line}' == ''
            CONTINUE
        END
        ${now}=    Get Current Date    result_format=%H:%M:%S.%f
        ${ts}=     Evaluate    '${now}'[:-3]
        Append To File    ${logfile}    ${ts} §${line}${\n}
    END

ATG_4G_Start CLI log collection
    [Arguments]    ${bbu_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ATG_4G_SSH To BBU    ${bbu_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE}=     Set Variable    ${RESULT_PATH}\\${bbu_ip}_${time}_cli.log
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${CLI_OUTPUT}=  Read    delay=3s
    Append To File    ${CLI_LOGFILE}    ${CLI_OUTPUT}
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    WHILE    '${CURRENT}' < '${end_time}'
              ${CURRENT}=    Get Current Date
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT1}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE}      ${CLI_OUTPUT1}
              Sleep    ${CLI_INTERVAL}
    END

ATG_4G_bs log collection
    [Arguments]    ${bbu_ip}    ${tag}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ATG_4G_SSH To BBU    ${bbu_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    Write    cd /var/log\r
    ${DEST}=    Set Variable    ${RESULT_PATH}/${bbu_ip}_${time}_bs.log
    ${SRC}=     Set Variable    \\var\\log\\bs.log
    SSHLibrary.Get File    /var/log/bs.log   ${DEST}

ATG_4G_message log collection
    [Arguments]    ${bbu_ip}    ${tag}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ATG_4G_SSH To BBU    ${bbu_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    Write    cd /var/log\r
    ${DEST}=    Set Variable    ${RESULT_PATH}/${bbu_ip}_${time}_messages.log
    ${SRC}=     Set Variable    \\var\\log\\messages
    SSHLibrary.Get File    /var/log/messages   ${DEST}
ATG_4G_L1 log clear
    [Arguments]    ${bbu_ip}    ${tag}
    ATG_4G_SSH To BBU    ${bbu_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${time}=     Get Current Date    result_format=%Y-%m-%d
    ${files}=    Execute Command    rm -rf /tmp/phy_logs/*
    Log to Console    \n========== All /tmp/phy_logs files are cleard ==========\n


ATG_4G_L1 log collection
    [Arguments]    ${bbu_ip}    ${tag}
    ATG_4G_SSH To BBU    ${bbu_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${time}=     Get Current Date    result_format=%Y-%m-%d
    ${files}=    Execute Command    ls /tmp/phy_logs/l1app_output_${time}* | tail -n 2
    @{file_list}=    Split String    ${files}
    FOR    ${file}    IN    @{file_list}
       Log to Console    \n========== File is ${file} ==========\n
       #${time}=     Get Current Date    result_format=%H-%M
       ${DEST}=    Set Variable    ${RESULT_PATH}/
       #${SRC}=     Set Variable    \\tmp\\phy_logs\\
       SSHLibrary.Get File    ${file}    ${DEST}
    END

ATG_4G_RU_bs log collection
    [Arguments]    ${ru_ip}     ${tag}
     ${RESULT_PATH}=     ATG_4G_Create Log Path
    ATG_4G_SSH To RU    ${ru_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    Write    cd /var/log\r
    ${DEST}=    Set Variable    ${RESULT_PATH}/${ru_ip}_${time}_RU_bs.log
    ${SRC}=     Set Variable    \\var\\log\\bs.log
    SSHLibrary.Get File    /var/log/bs.log   ${DEST}

Login To Pi_userSVG
    [Arguments]    ${ip}
    SSHLibrary.Open Connection    ${ip}    port=${SSH_port}
    Login    ${pi_svg_username}    ${pi_svg_password}
    Set Client Configuration    prompt=>

Login To Pi_userAirspan
    [Arguments]    ${ip}
    SSHLibrary.Open Connection    ${ip}    port=${SSH_port}
    Login    ${pi_airspan_username}    ${pi_airspan_password}
    Set Client Configuration    prompt=>

Login RaspberryPi
    [Arguments]    ${pi_ip}    ${username}=airspan    ${password}=localadmin    ${port}=22
    SSHLibrary.Open Connection    ${pi_ip}    port=${port}
    Login    ${username}    ${password}
    Set Client Configuration    prompt=>
Login Aircard
    Write    ssh ${AC_USER}@${AC_IP}
    Read Until    password:
    Write    ${AC_PASS}
    Read Until    $
    Write    sudo bash
    Read Until    Password:
    Write    ${AC_PASS}
Login UE tnet
    Write    ssh ${AC_USER}@${AC_IP}
    Read Until    password:
    Write    ${AC_PASS}
    Read Until    $
    Write    cd /bs/ && ./tnet
    Write    info-x
    Read Until    tnet >
Create SSH Connection with MME
    [Arguments]    ${MME_IP}    ${username}    ${password}    ${port}
    SSHLibrary.Open Connection    ${MME_IP}    port=${port}    alias=MME
    Login    ${username}    ${password}
    Set Client Configuration    prompt=$
Log With Color
    [Arguments]    ${message}    ${color}=reset
    ${esc}=    Set Variable    \u001b[
    ${reset}=    Set Variable    ${esc}0m
    Run Keyword If    '${color}'=='red'      Log To Console    ${esc}31m${message}${reset}
    ...    ELSE IF    '${color}'=='green'    Log To Console    ${esc}32m${message}${reset}
    ...    ELSE IF    '${color}'=='yellow'   Log To Console    ${esc}33m${message}${reset}
    ...    ELSE IF    '${color}'=='blue'     Log To Console    ${esc}34m${message}${reset}
    ...    ELSE IF    '${color}'=='magenta'    Log To Console    ${esc}95m${message}${reset}
    ...    ELSE IF    '${color}'=='pink'    Log To Console    ${esc}38;5;205m${message}${reset}
    ...    ELSE    Log To Console    ${message}
Verify UE status
    [Arguments]    ${get_cmd}    ${UE}
    Write    info-x
    Read    delay=1s
    Write    ${get_cmd}
    ${get_cmd_output}=    Read Until    tnet >
#    Log To Console    \n========== ${UE} OUTPUT for: ${get_cmd} ==========\n${get_cmd_output}
#    Log    ${get_cmd_output}
    # UE state check with colors
    IF    'established' in """${get_cmd_output}"""
        Log With Color    \n==========================================================    magenta
        Log With Color    ================== ${UE} is established ==================    green
        Log With Color    ==========================================================    magenta
    ELSE IF    'idle' in """${get_cmd_output}"""
        Log With Color    ================== ${UE} is in idle ==================    red
    ELSE IF    'establishing' in """${get_cmd_output}"""
        Log With Color    ================== ${UE} is establishing ==================    yellow
    ELSE
        Log With Color    ${UE} state not found in output    blue
    END
Run command at UE
    [Arguments]    ${attach_cmd}    ${UE}
    Write    ${attach_cmd}
    ${cmd_output}=    Read Until    tnet >
#    Log To Console    \n========== ${UE} OUTPUT for: ${attach_cmd} ==========\n${cmd_output}
#    Log    ${cmd_output}
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
    RETURN    ${token}

Fetch Aircard RLS Data
    [Documentation]    Fetch and Resturns RLS taking input as node name and ACP URL
    [Arguments]      ${AC_Name}     ${acp_url}
    ${bearer_token}     Generate ACP Authorization Token    ${acp_url}
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
    ${bearer_token}     Generate ACP Authorization Token    ${acp_url}
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

Monitor UL Throughput
    [Arguments]    ${ENB}    ${username}    ${password}    ${port}
    ...            ${samples}=6    ${interval}=5    ${threshold}=4.3
    SSHLibrary.Open Connection    ${ENB}    port=${port}    alias=ENB
    Login    ${username}    ${password}
    Write    cd /bs/ && ./lteCli
    Sleep    2s
    &{pdcp_dict}=    Create Dictionary
    FOR    ${i}    IN RANGE    ${samples}
        Write    ue show rateul
        Sleep    1s
        ${output}=    Read Until    Cell Total
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
          Run Keyword If    not 'M' in '${pdcp_raw}' and not 'K' in '${pdcp_raw}'
          ...    Continue For Loop
          ${num}=    Replace String    ${pdcp_raw}    M    ${EMPTY}
          ${num}=    Replace String    ${num}          K    ${EMPTY}
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
Stop UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
    Login Pi    ${pi_ip}
#    Login To Pi_userAirspan    ${pi_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${files}=    Execute Command    ls /tmp/${pi_ip}*.log
    @{file_list}=    Split String    ${files}
    FOR    ${file}    IN    @{file_list}
       SSHLibrary.Get File    ${file}    ${RESULT_PATH}\\
    END
    Sleep    10s
    IF    '${pi_ip}' == '${enb8_pi1}'
        Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
        Read Until    password for svg:
        Write    ${pi_svg_password}
    ELSE
        Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
        Read Until    password for airspan:
        Write    ${pi_airspan_password}
    END

#Login Pi
#    [Arguments]    ${pi_ip}
#    ${PI_USER}=    Set Variable    ${pi_airspan_username}
#    ${PI_PASS}=    Set Variable    ${pi_airspan_password}
#    # 🔥 Override only for enb8_pi1
#    IF    '${pi_ip}' == '${enb8_pi1}'
#        ${PI_USER}=    Set Variable    ${pi_svg_username}
#        ${PI_PASS}=    Set Variable    ${pi_svg_password}
#    ELSE IF    '${pi_ip}' == '${enb6_pi}'
#        ${PI_USER}=    Set Variable    ${pi_swuser_username}
#        ${PI_PASS}=    Set Variable    ${pi_swuser_password}
#    END
#    SSHLibrary.Open Connection    ${pi_ip}
#    Login    ${PI_USER}    ${PI_PASS}

Login Pi
    [Arguments]    ${pi_ip}
    IF      $pi_ip == $enb8_pi1
            ${PI_USER}=    Set Variable    ${pi_svg_username}
            ${PI_PASS}=    Set Variable    ${pi_svg_password}
    ELSE IF     $pi_ip == $enb6_pi
            ${PI_USER}=    Set Variable    ${pi_swuser_username}
            ${PI_PASS}=    Set Variable    ${pi_swuser_password}
    ELSE IF     $pi_ip == $enb7_pi
            ${PI_USER}=    Set Variable    ${pi_admin_username}
            ${PI_PASS}=    Set Variable    ${pi_admin_password}
    ELSE IF     $pi_ip == $enb9_pi
            ${PI_USER}=    Set Variable    ${pi_ssingh_username}
            ${PI_PASS}=    Set Variable    ${pi_ssingh_password}
    ELSE
            ${PI_USER}=    Set Variable    ${pi_airspan_username}
            ${PI_PASS}=    Set Variable    ${pi_airspan_password}
    END
    LOG    Selected user: ${PI_USER}
    SSHLibrary.Open Connection    ${pi_ip}
    Login    ${PI_USER}    ${PI_PASS}


Stop UE log collection
    [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${files}=    Execute Command    ls /tmp/${pi_ip}*.log
    @{file_list}=    Split String    ${files}
    FOR    ${file}    IN    @{file_list}
       SSHLibrary.Get File    ${file}    ${RESULT_PATH}\\
    END
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    Read Until    password for swuser:
    Write    ${pi_swuser_password}

TCP DL
   [Arguments]    ${pi_ip}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Set Variable    5091
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE${pi_ip} DL TCP iPerf Test ==========\n
#Running Listening cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${DL_TCP_1QCI_AC_Server}=    Set Variable    iperf -s -p ${port1} -t ${DURATION}
   Write    ${DL_TCP_1QCI_AC_Server}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP listening cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
   Sleep    ${1}
#Running Listening cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   IF    '${pi_ip}' == '${enb8_pi1}'
       Write    sudo ifconfig eno1:1 ${ue_ip2}
       ${status}    ${output}=    Run Keyword And Ignore Error    Read Until    ${PI_USER}:
       Run Keyword If    '${status}' == 'PASS'    Write    ${PI_PASS}
   ELSE
       Write    sudo ifconfig eth1:1 ${ue_ip2}
   END
   ${DL_TCP_3QCI_Pi_Server}=    Catenate
   ...    iperf -s -p ${port2} -t ${DURATION} &
   ...    iperf -s -p ${port3} -t ${DURATION} &
   ...    iperf -s -p ${port4} -t ${DURATION} && pkill -9 iperf
   Write    ${DL_TCP_3QCI_Pi_Server}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} TCP listening cmd at raspberrypi for ${DURATION} seconds ==========\n    green
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
   Log With Color    \n========== Running UE ${pi_ip} DL TCP 4QCI iPerf cmd at MME ${MME_IP} for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}
TCP BIDI
   [Arguments]    ${pi_ip}    ${base_port}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Set Variable    5091
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE ${pi_ip} TCP DL iPerf Test ==========\n
#Running Listening cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${DL_TCP_1QCI_AC_Server}=    Set Variable    iperf -s -p ${port1} -t ${DURATION}
   Write    ${DL_TCP_1QCI_AC_Server}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP listening cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
   Sleep    ${1}
#Running Listening cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   IF    '${pi_ip}' == '${enb8_pi1}'
       Write    sudo ifconfig eno1:1 ${ue_ip2}
       ${status}    ${output}=    Run Keyword And Ignore Error    Read Until    ${PI_USER}:
       Run Keyword If    '${status}' == 'PASS'    Write    ${PI_PASS}
   ELSE
       Write    sudo ifconfig eth1:1 ${ue_ip2}
   END
   ${DL_TCP_3QCI_Pi_Server}=    Catenate
   ...    iperf -s -p ${port2} -t ${DURATION} &
   ...    iperf -s -p ${port3} -t ${DURATION} &
   ...    iperf -s -p ${port4} -t ${DURATION} && pkill -9 iperf
   Write    ${DL_TCP_3QCI_Pi_Server}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP listening cmd at raspberrypi for ${DURATION} seconds ==========\n    green
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
   Log With Color    \n========== Running UE ${pi_ip} TCP DL 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green

   Log To Console    \n================================================================
   Log With Color    \n=========== TCP DL Started Now Running TCP UL ==================\n    green
   Log To Console     =================================================================
   Log With Color    \n========== Starting TCP UL 4QCI data for ${DURATION} seconds ==========\n    green
   ${port1}=    Evaluate    5060 + ${base_port}*4
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE ${pi_ip} TCP UL iPerf Test ==========\n
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
   Log With Color    \n========== Running UE ${pi_ip} TCP UL 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
#Running Client cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   ${UL_TCP_3QCI_Pi_Client}=    Catenate
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port2} -t ${DURATION} -S ${QCI6} &
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port3} -t ${DURATION} -S ${QCI7} &
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port4} -t ${DURATION} -S ${QCI9} && pkill -9 iperf
   Write    ${UL_TCP_3QCI_Pi_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
#Running Client cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${UL_TCP_1QCI_AC_Client}=    Set Variable    iperf -c ${MME_TUN_IP1} -B ${ue_ip1} -P 5 -p ${port1} -t ${DURATION} -S ${QCI6} && pkill -9 iperf
   Write    ${UL_TCP_1QCI_AC_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}
TCP UL
   [Arguments]    ${pi_ip}    ${base_port}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Evaluate    5060 + ${base_port}*4
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE ${pi_ip} UL TCP iPerf Test ==========\n
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
   Log With Color    \n========== Running UE ${pi_ip} UL TCP 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Server listening on TCP port ==========\n${status}    green
#Running Client cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   IF    '${pi_ip}' == '${enb8_pi1}'
       Write    sudo ifconfig eno1:1 ${ue_ip2}
       ${status}    ${output}=    Run Keyword And Ignore Error    Read Until    ${PI_USER}:
       Run Keyword If    '${status}' == 'PASS'    Write    ${PI_PASS}
   ELSE
       Write    sudo ifconfig eth1:1 ${ue_ip2}
   END
   ${UL_TCP_3QCI_Pi_Client}=    Catenate
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port2} -t ${DURATION} -S ${QCI6} &
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port3} -t ${DURATION} -S ${QCI7} &
   ...    iperf -c ${MME_TUN_IP2} -B ${ue_ip2} -P 5 -p ${port4} -t ${DURATION} -S ${QCI9} && pkill -9 iperf
   Write    ${UL_TCP_3QCI_Pi_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
#Running Client cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${UL_TCP_1QCI_AC_Client}=    Set Variable    iperf -c ${MME_TUN_IP1} -B ${ue_ip1} -P 5 -p ${port1} -t ${DURATION} -S ${QCI6} && pkill -9 iperf
   Write    ${UL_TCP_1QCI_AC_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE ${pi_ip} TCP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below TCP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}
ATG_4G_Start CLI log collection HO
    [Tags]    ATG_4G_Start CLI log collection HO
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    SSHLibrary.Open Connection    ${eNB8}    port=${SSH_port}    alias=ENB8
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=$
    SSHLibrary.Open Connection    ${eNB4}    port=${SSH_port}    alias=ENB4
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=$
    Switch Connection    ENB8
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    Switch Connection    ENB4
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB8}=     Set Variable    ${RESULT_PATH}\\${eNB8}_${time}_cli.log
    ${CLI_LOGFILE_ENB4}=     Set Variable    ${RESULT_PATH}\\${eNB4}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${HO_DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              ${CURRENT}=    Get Current Date
              Switch Connection    ENB8
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB8}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB8}      ${CLI_OUTPUT_ENB8}
              Switch Connection    ENB4
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB4}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB4}      ${CLI_OUTPUT_ENB4}
              Sleep    ${CLI_INTERVAL}
    END
UDP DL
   [Arguments]    ${pi_ip}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Set Variable    5091
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE${pi_ip} UDP DL iPerf Test ==========\n
   Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
   ${iperf_Client_mme}=    Catenate
    ...    iperf -u -c ${ue_ip1} -p ${port1} -S ${QCI6} -b 5M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port2} -S ${QCI6} -b 2M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port4} -S ${QCI9} -b 6M -t ${DURATION}
   Write    ${iperf_Client_mme}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP DL 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below UDP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}
UDP UL
   [Arguments]    ${pi_ip}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Set Variable    5091
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE${pi_ip} UDP UL iPerf Test ==========\n
#Running Client cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${UL_UDP_1QCI_AC_Client}=    Set Variable    iperf -u -c ${MME_TUN_IP1} -p ${port1} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip1}
   Write    ${UL_UDP_1QCI_AC_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
   Sleep    ${1}
#Running Client cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   IF    '${pi_ip}' == '${enb8_pi1}'
       Write    sudo ifconfig eno1:1 ${ue_ip2}
       ${status}    ${output}=    Run Keyword And Ignore Error    Read Until    ${PI_USER}:
       Run Keyword If    '${status}' == 'PASS'    Write    ${PI_PASS}
   ELSE
       Write    sudo ifconfig eth1:1 ${ue_ip2}
   END
   ${UL_UDP_3QCI_Pi_Client}=    Catenate
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port2} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip2} &
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} -B ${ue_ip2} &
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port4} -S ${QCI9} -b 6M -t ${DURATION} -B ${ue_ip2} && pkill -9 iperf
   Write    ${UL_UDP_3QCI_Pi_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}
ATG_4G_Start CLI log collection TPT
    [Tags]    ATG_4G_Start CLI log collection TPT
    [Arguments]    ${enb}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    SSHLibrary.Open Connection    ${enb}    port=${SSH_port}    alias=enb
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB}=     Set Variable    ${RESULT_PATH}\\${enb}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${HO_DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              ${CURRENT}=    Get Current Date
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB}      ${CLI_OUTPUT_ENB}
              Sleep    ${CLI_INTERVAL}
    END
UDP BIDI
   [Arguments]    ${pi_ip}
   ${ue_ip1}    ${ue_ip2}    ${PI_USER}    ${PI_PASS}=    Attach Single UE    ${pi_ip}
   ${port1}=    Set Variable    5091
   ${port2}=    Evaluate    ${port1}+1
   ${port3}=    Evaluate    ${port1}+2
   ${port4}=    Evaluate    ${port1}+3
   Log With Color    \n========== Running UE${pi_ip} UDP DL iPerf Test ==========\n
   Create SSH Connection with MME    ${MME_IP}    ${MME_USER}    ${MME_PASS}    ${MME_PORT}
   ${iperf_Client_mme}=    Catenate
    ...    iperf -u -c ${ue_ip1} -p ${port1} -S ${QCI6} -b 5M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port2} -S ${QCI6} -b 2M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} &
    ...    iperf -u -c ${ue_ip2} -p ${port4} -S ${QCI9} -b 6M -t ${DURATION}
   Write    ${iperf_Client_mme}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP DL 4QCI iPerf cmd at MME for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client connecting to below UDP port ==========\n${status}    green
   Log With Color    \n========== Running UE${pi_ip} UDP UL iPerf Test ==========\n
#Running Client cmd at Aircard for management APN1
   Login Pi    ${pi_ip}
   Login Aircard
   ${UL_UDP_1QCI_AC_Client}=    Set Variable    iperf -u -c ${MME_TUN_IP1} -p ${port1} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip1}
   Write    ${UL_UDP_1QCI_AC_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP Client cmd at Aircard for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
   Sleep    ${1}
   Log With Color    \n=========== UDP DL Started Now Running UDP UL ==================\n    green
#Running Client cmd at RaspberryPi for internet APN2
   Login Pi    ${pi_ip}
   ${UL_UDP_3QCI_Pi_Client}=    Catenate
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port2} -S ${QCI6} -b 1M -t ${DURATION} -B ${ue_ip2} &
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port3} -S ${QCI7} -b 2M -t ${DURATION} -B ${ue_ip2} &
   ...    iperf -u -c ${MME_TUN_IP2} -p ${port4} -S ${QCI9} -b 6M -t ${DURATION} -B ${ue_ip2} && pkill -9 iperf
   Write    ${UL_UDP_3QCI_Pi_Client}
   ${status}=    Read    delay=10s
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Running UE${pi_ip} UDP Client cmd at raspberrypi for ${DURATION} seconds ==========\n    green
   Log With Color    ===========================================================================    green
   Log With Color    \n========== Client Connecting to UDP port ==========\n${status}    green
   RETURN    ${ue_ip1}    ${ue_ip2}

ATG_4G_CLI LOG_RF RACK ATTEN
    [Tags]    ATG_4G_CLI LOG_RF RACK ATTEN
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    SSHLibrary.Open Connection    ${RACK_IP}    port=${SSH_port}    alias=RF_RACK
    Login    ${RACK_username}    ${RACK_password}
    Set Client Configuration    prompt=$
    Write    cd ps_scripts/ && pwd
    Read Until Prompt
    SSHLibrary.Open Connection    ${eNB8}    port=${SSH_port}    alias=ENB8
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=$
    SSHLibrary.Open Connection    ${eNB4}    port=${SSH_port}    alias=ENB4
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=$
    Switch Connection    ENB8
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    Switch Connection    ENB4
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB8}=     Set Variable    ${RESULT_PATH}\\${eNB8}_${time}_cli.log
    ${CLI_LOGFILE_ENB4}=     Set Variable    ${RESULT_PATH}\\${eNB4}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              Switch Connection    ENB8
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB8}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB8}      ${CLI_OUTPUT_ENB8}
              Switch Connection    RF_RACK
              FOR    ${i}    IN RANGE    0    42    3
                     Write    ./setGain.sh ${i} 0
                     Read Until Prompt
                     Sleep    1s
              END
              Switch Connection    ENB4
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB4}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB4}      ${CLI_OUTPUT_ENB4}
              Switch Connection    RF_RACK
              FOR    ${i}    IN RANGE    42    -1    -3
                     Write    ./setGain.sh ${i} 0
                     Read Until Prompt
                     Sleep    1s
              END
              ${CURRENT}=    Get Current Date
    END

Start_Non_Commercial_CE
    [Arguments]    ${pi_ip}    ${tag}
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    SSHLibrary.Open Connection    ${CE_IP}    port=${SSH_port}    alias=CE
    Login    ${CE_username}    ${CE_password}
    SSHLibrary.Set Client Configuration    timeout=40 second
    Stop Chanemu Session
    # Retry: first attempt can die while the killed CLI still holds the radio device
    Wait Until Keyword Succeeds    3x    5s    Start Chanemu Session

    #Set the frequency and rx/tx gains .
    Write    tmux send-keys -t chanemu "set_freq_rx01 895.27e6" C-m
    Write    tmux send-keys -t chanemu "set_freq_tx23 895.27e6" C-m
    Write    tmux send-keys -t chanemu "set_freq_rx23 850e6" C-m
    Write    tmux send-keys -t chanemu "set_freq_tx01 850e6" C-m
    Write    tmux send-keys -t chanemu "set_rx_gain_db 20 2" C-m
    Write    tmux send-keys -t chanemu "set_rx_gain_db 20 3" C-m
    Write    tmux send-keys -t chanemu "set_tx_gain_db 34 1" C-m
    Write    tmux send-keys -t chanemu "set_tx_gain_db 34 0" C-m
    Write    tmux send-keys -t chanemu "set_rx_gain_db 20 0" C-m
    Write    tmux send-keys -t chanemu "set_rx_gain_db 20 1" C-m
    Write    tmux send-keys -t chanemu "set_tx_gain_db 64 2" C-m
    Write    tmux send-keys -t chanemu "set_tx_gain_db 64 3" C-m
    Write    tmux send-keys -t chanemu "configure_mimo_mode 240 inf" C-m

    Log to console    "End of Initialization of CE and ready to do UE sign on"

Stop Chanemu Session
    # Kill the tmux session first so its child CLI gets terminated cleanly
    Execute Command    tmux kill-session -t chanemu >/dev/null 2>&1 || true
    # [c] matches the running binary but not this pkill command line itself
    Execute Command    sudo pkill -9 -f '[c]hannel_emulator_cli' >/dev/null 2>&1 || true
    # Wait until every old CLI instance is really gone (max ~10s)
    ${gone}=    Execute Command    for i in $(seq 1 10); do pgrep -f '[c]hannel_emulator_cli' >/dev/null || { echo GONE; break; }; sleep 1; done
    Should Contain    ${gone}    GONE    msg=Old channel_emulator_cli still running on CE

Start Chanemu Session
    Execute Command    tmux kill-session -t chanemu >/dev/null 2>&1 || true
    Execute Command    tmux new-session -d -s chanemu "sudo channel_emulator_cli"
    Sleep    2s
    # Session must still be alive, i.e. the CLI did not exit right away
    ${session_status}=    Execute Command    tmux has-session -t chanemu >/dev/null 2>&1 && echo PASS || echo FAIL
    Should Be Equal    ${session_status}    PASS    msg=chanemu tmux session died - channel_emulator_cli exited at startup



ATG_4G_CLI LOG_TA FULL SWEEP
    #[Arguments]    ${CE_IP}
    [Tags]    ATG_4G_CLI LOG_TA SWEEP

    ${RESULT_PATH}=     ATG_4G_Create Log Path
    #SSHLibrary.Open Connection    ${CE_IP}    port=${SSH_port}    alias=CE
    #Login    ${CE_username}    ${CE_password}
    #SSHLibrary.Set Client Configuration    timeout=40 second
    #Set Client Configuration    prompt=>
    #Write    mux send-keys -t chanemu "configure_mimo_mode 398 1200" C-m
    #Read Until Regexp    channel_emulator.*

    SSHLibrary.Open Connection    ${eNB6}    port=${SSH_port}    alias=ENB6
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB6}=     Set Variable    ${RESULT_PATH}\\${eNB6}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    ${FW_SWEEP_CMD}=     Set Variable    configure_mimo_mode 398 1200
    ${BW_SWEEP_CMD}=     Set Variable    configure_mimo_mode 0 1200
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              Switch Connection    CE
              Write    tmux send-keys -t chanemu "${FW_SWEEP_CMD}" C-m
              Sleep    1800
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              Switch Connection    CE
              Write    tmux send-keys -t chanemu "${BW_SWEEP_CMD}" C-m
              Sleep    1800
              ${CURRENT}=    Get Current Date
    END


Start fw rsrp sweep enb6ac
    [Arguments]    ${pi_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    ${set_enb6_fw_rsrp}=    Set variable    cd ~/ps_scripts; ./kvr_enb6_puc1_odd.sh
    #${set_enb6_fw_rsrp}=    Set variable    cd ~/ps_scripts; ./eNB6_PUC1_FW_RSRPsweep.sh
    
    Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Setting enb6 FW RSRP before starting UE log collection==========
     Write    ${set_enb6_fw_rsrp}

Start bw rsrp sweep enb6ac
    [Arguments]    ${pi_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    ${set_enb6_bw_rsrp}=    Set variable    cd ~/ps_scripts; ./kvr_enb6_reserse_puc1_odd.sh
    #${set_enb6_bw_rsrp}=    Set variable    cd ~/ps_scripts; ./eNB6_PUC1_REV_RSRPsweep.sh
    Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Setting enb6 BW RSRP before starting UE log collection==========
     Write    ${set_enb6_bw_rsrp}
    

ATG_4G_CLI LOG_TA FULL SWEEP_Latest
    [Tags]    ATG_4G_CLI LOG_TA SWEEP

    ${RESULT_PATH}=     ATG_4G_Create Log Path

    SSHLibrary.Open Connection    ${eNB6}    port=${SSH_port}    alias=ENB6
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB6}=     Set Variable    ${RESULT_PATH}\\${eNB6}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              # FW leg: towards 398 km, speed ramps 403->1200 in 50 even steps, 36s each (1800s)
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              Start fw rsrp sweep enb6ac    10.80.6.247
              Switch Connection    CE
              FOR    ${i}    IN RANGE    50
                    ${sweep_val}=    Evaluate    403 + round((1200 - 403) * ${i} / 49)
                    Write    tmux send-keys -t chanemu "configure_mimo_mode 398 ${sweep_val}" C-m
                    Sleep    36
              END
              # BW leg: back towards 0 km, same 403->1200 speed ramp
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}

              Start bw rsrp sweep enb6ac     10.80.6.247
              Switch Connection    CE
              FOR    ${i}    IN RANGE    50
                    ${sweep_val}=    Evaluate    403 + round((1200 - 403) * ${i} / 49)
                    Write    tmux send-keys -t chanemu "configure_mimo_mode 0 ${sweep_val}" C-m
                    Sleep    36
              END
              ${CURRENT}=    Get Current Date
    END

ATG_4G_CLI LOG_TA FW SWEEP
    #[Arguments]    ${CE_IP}
    [Tags]    ATG_4G_CLI LOG_TA SWEEP

    ${RESULT_PATH}=     ATG_4G_Create Log Path
    

    SSHLibrary.Open Connection    ${eNB6}    port=${SSH_port}    alias=ENB6
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB6}=     Set Variable    ${RESULT_PATH}\\${eNB6}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    
    ${HOLD_CMD}=     Set Variable    configure_mimo_mode 398 1200
    ${RAMP_DONE}=    Set Variable    ${FALSE}
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              Switch Connection    CE
              IF    not ${RAMP_DONE}
                    # Ramp 403->1200 in 50 even steps, 36s each (1800s total)
                    FOR    ${i}    IN RANGE    50
                          ${sweep_val}=    Evaluate    403 + round((1200 - 403) * ${i} / 49)
                          Write    tmux send-keys -t chanemu "configure_mimo_mode 398 ${sweep_val}" C-m
                          Sleep    36
                    END
                    ${RAMP_DONE}=    Set Variable    ${TRUE}
              ELSE
                    Write    tmux send-keys -t chanemu "${HOLD_CMD}" C-m
                    # Hold only for whatever is left of DURATION after the ramp
                    ${now}=    Get Current Date
                    ${remaining}=    Subtract Date From Date    ${end_time}    ${now}
                    IF    ${remaining} > 0
                          Sleep    ${remaining}
                    END
              END
              ${CURRENT}=    Get Current Date

    END

ATG_4G_CLI LOG_TA BW SWEEP
    #[Arguments]    ${CE_IP}
    [Tags]    ATG_4G_CLI LOG_TA SWEEP

    ${RESULT_PATH}=     ATG_4G_Create Log Path
    

    SSHLibrary.Open Connection    ${eNB6}    port=${SSH_port}    alias=ENB6
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB6}=     Set Variable    ${RESULT_PATH}\\${eNB6}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate
    
    ${HOLD_CMD}=     Set Variable    configure_mimo_mode 398 1200
    ${RAMP_DONE}=    Set Variable    ${FALSE}
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              Switch Connection    CE
              IF    not ${RAMP_DONE}
                    # Ramp 403->1200 in 50 even steps, 36s each (1800s total)
                    FOR    ${i}    IN RANGE    50
                          ${sweep_val}=    Evaluate    403 + round((1200 - 403) * ${i} / 49)
                          Write    tmux send-keys -t chanemu "configure_mimo_mode 0 ${sweep_val}" C-m
                          Sleep    36
                    END
                    ${RAMP_DONE}=    Set Variable    ${TRUE}
              ELSE
                    Write    tmux send-keys -t chanemu "${HOLD_CMD}" C-m
                    # Hold only for whatever is left of DURATION after the ramp
                    ${now}=    Get Current Date
                    ${remaining}=    Subtract Date From Date    ${end_time}    ${now}
                    IF    ${remaining} > 0
                          Sleep    ${remaining}
                    END
              END
              ${CURRENT}=    Get Current Date

    END
ATG_4G_CLI LOG_TA FW SWEEP_PO
    [Arguments]    ${PO_INTERVAL}=10
    [Tags]    ATG_4G_CLI LOG_TA SWEEP

    ${RESULT_PATH}=     ATG_4G_Create Log Path

    SSHLibrary.Open Connection    ${eNB6}    port=${SSH_port}    alias=ENB6
    Login    ${BBU_username}    ${BBU_password}
    Set Client Configuration    prompt=lte_cli:>>
    Write    cd /bs\r
    Write    ./lteCli\r
    ${time}=     Get Current Date    result_format=%H-%M
    ${CLI_LOGFILE_ENB6}=     Set Variable    ${RESULT_PATH}\\${eNB6}_${time}_cli.log
    ${CURRENT}=     Set Variable    0
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${CMD}=     Set Variable    ue show link
    ${CMD1}=     Set Variable    ue show ratedl
    ${CMD2}=     Set Variable    ue show rateul
    ${CMD3}=     Set Variable    qci show rate

    # Sweep is time-driven (no 36s blocking sleeps) so pdcch order can run every ${PO_INTERVAL}s
    ${RAMP_TIME}=    Set Variable    ${1800}
    ${LAST_SWEEP}=   Set Variable    ${0}
    Set Client Configuration    prompt=lte_cli:>>
    WHILE    '${CURRENT}' < '${end_time}'
              ${iter_start}=    Get Current Date
              Switch Connection    ENB6
              Write   ${CMD}\r${CMD1}\r${CMD2}\r${CMD3}\r
              ${CLI_OUTPUT_ENB6}=  Read    delay=3s
              Log CLI Output With Timestamp   ${CLI_LOGFILE_ENB6}      ${CLI_OUTPUT_ENB6}
              # UE rows of 'ue show link' look like: |   1| 104| 13/13|... -> RNTI is 2nd column
              ${rnti_list}=    Evaluate    re.findall(r'(?m)^\\|\\s*\\d+\\|\\s*(\\d+)\\|', $CLI_OUTPUT_ENB6)    re
              IF    ${rnti_list}
                    ${rnti}=    Set Variable    ${rnti_list}[-1]
                    Write    ue set pdcchorder cellIdx=0 rnti=${rnti}\r
                    ${PO_OUTPUT}=    Read    delay=1s
                    Log CLI Output With Timestamp    ${CLI_LOGFILE_ENB6}    ${PO_OUTPUT}
              ELSE
                    Log    No RNTI found in ue show link output, skipping pdcch order    WARN
              END
              # Same ramp as FW SWEEP: 403->1200 in 50 even steps of 36s, then hold at 1200
              ${now}=    Get Current Date
              ${elapsed}=    Subtract Date From Date    ${now}    ${start_time}
              IF    ${elapsed} < ${RAMP_TIME}
                    ${idx}=    Evaluate    min(int(${elapsed} // 36), 49)
                    ${sweep_val}=    Evaluate    403 + round((1200 - 403) * ${idx} / 49)
              ELSE
                    ${sweep_val}=    Set Variable    ${1200}
              END
              IF    ${sweep_val} != ${LAST_SWEEP}
                    Switch Connection    CE
                    Write    tmux send-keys -t chanemu "configure_mimo_mode 398 ${sweep_val}" C-m
                    ${LAST_SWEEP}=    Set Variable    ${sweep_val}
              END
              # Sleep only what is left of the interval after the CLI reads
              ${now}=    Get Current Date
              ${iter_elapsed}=    Subtract Date From Date    ${now}    ${iter_start}
              ${sleep_left}=    Evaluate    max(${PO_INTERVAL} - ${iter_elapsed}, 0)
              Sleep    ${sleep_left}
              ${CURRENT}=    Get Current Date
    END

Fetch_eNB_TASWEEP_STATS
    [Arguments]    ${from}      ${to}
    ${bearer_token}     Generate ACP Authorization Token    https://10.80.1.23/
    Log    ${bearer_token}
    ${eNB_Rest_ID}=     Fetch ENB Rest ID    eNB6   https://10.80.1.23/
    create session    mysession    ${acp_url}
    ${api}=     Set Variable    /api/22.0/enbStatisticsHour/
    ${headers}=         Create Dictionary    Authorization=Bearer ${bearer_token}
    ${params}=           Create Dictionary    id=${eNB_Rest_ID}     from=${from}    to=${to}
    ${response}=         GET On Session       mysession   ${api}  params=${params}   headers=${headers}
    Should Be Equal As Integers    ${response.status_code}    200
    ${Complete_stats}=   Evaluate    json.loads('''${response.content}''')    json
    ${length}=      Get Length    ${Complete_stats}
    ${cbra_attempts}=     Create List
    ${cbra_success}=     Create List
    ${cfra_attempts}=     Create List
    ${cfra_success}=     Create List
    FOR    ${item}      IN    @{Complete_stats}
           ${cell_kpi}=        Get From Dictionary     ${item}     cell
           ${cbra_rach_attempts}=   Get From Dictionary    ${cell_kpi}      rachContentionBasedPrachAtt
           Append To List    ${cbra_attempts}      ${cbra_rach_attempts}
           ${cbra_rach_success}=    Get From Dictionary    ${cell_kpi}      rachContentionBasedPrachSucc
           Append To List    ${cbra_success}      ${cbra_rach_success}
           ${cfra_rach_attempts}=   Get From Dictionary    ${cell_kpi}      rachContentionFreePrachAtt
           Append To List    ${cfra_attempts}      ${cfra_rach_attempts}
           ${cfra_rach_success}=    Get From Dictionary    ${cell_kpi}      rachContentionFreePrachSucc
           Append To List    ${cfra_success}      ${cfra_rach_success}
           ${Total cbra rach attempts}=    Evaluate    sum(x for x in ${cbra_attempts})
           ${Total cbra rach success}=    Evaluate    sum(x for x in ${cbra_success})
           ${Total cfra rach attempts}=    Evaluate    sum(x for x in ${cfra_attempts})
           ${Total cfra rach success}=    Evaluate    sum(x for x in ${cfra_success})
           ${CBRA RACH success rate} =    Evaluate    round((float(${Total cbra rach attempts}) / float(${Total cbra rach success})) * 100, 2)
           ${CFRA RACH success rate} =    Evaluate    round((float(${Total cfra rach attempts}) / float(${Total cfra rach success})) * 100, 2)

    END
    Log To Console    Total CBRA RACH attempts: ${Total cbra rach attempts}\n
    Log To Console    Total CBRA RACH success: ${Total cbra rach success}\n
    Log To Console    Total CFRA RACH attempts: ${Total cfra rach attempts}\n
    Log To Console    Total CFRA RACH success: ${Total cfra rach success}\n
    Log To Console    CBRA RACH success rate is : ${CBRA RACH success rate}%
    Log To Console    CFRA RACH success rate is : ${CFRA RACH success rate}%
    IF    ${CFRA RACH success rate} <   100
        Log To Console    TA sweep is FAIL
    ELSE
        Log To Console    TA sweep is PASS
    END
*** Keywords ***
Start UE log collection_usernameSWUSER
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo nc -u -l 192.168.4.1 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     Login Pi    ${pi_ip}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for swuser:
     Write    ${pi_swuser_password}
     Log to console    ========= Removing ${pi_ip}_*_UE_Serial.log before starting UE log collection==========
   
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log

Start UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     Login Pi    ${pi_ip}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}

Start enb6 PUC1 UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
    ${set_enb6_puc1_gain}=    Set variable    cd ~/ps_scripts; ./setGain.sh 0 14
    ${set_enb6_puc1_port8}=    Set variable    cd ~/ps_scripts; ./setGain.sh 0 8
    #${set_enb6_puc1_port0}=    Set variable    cd ~/ps_scripts; ./setGain.sh 110 0
    #${set_enb6_puc1_port2}=    Set variable    cd ~/ps_scripts; ./setGain.sh 110 2
    #${set_enb6_puc1_port4}=    Set variable    cd ~/ps_scripts; ./setGain.sh 110 4
    Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Setting enb6 PUC1 gains before starting UE log collection==========
     Write    ${set_enb6_puc1_gain}
     Write    ${set_enb6_puc1_port8}
     #Write    ${set_enb6_puc1_port0}
     #Write    ${set_enb6_puc1_port2}
     #Write    ${set_enb6_puc1_port4}
    
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}
     

Start enb8 UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     ${set_enb8_gain}=    Set variable    cd ~/ps_scripts; ./setGain.sh 25 0
     Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Writing the set enb8 gain settings with ${set_enb8_gain}==========
     Write    ${set_enb8_gain}
     Write   ${UE_log_cmd}
     ${prompt}=    Read Until    password for svg:
     Write    ${pi_svg_password}

Stop UE log collection_usernameSWUSER
    [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    #Kill the running nc command as the duration has completed.
    Write    sudo pkill -9 -f nc
    Read Until    password for swuser:
    Write    ${pi_swuser_password}

    ${RESULT_PATH}=     ATG_4G_Create Log Path
    ${largest_file}=    Execute Command    ls -S /tmp/${pi_ip}*.log | head -1
    ${time}=     Get Current Date    result_format=%H-%M
    ${DEST}=    Set Variable    ${RESULT_PATH}/${pi_ip}_${time}_ac.log
    SSHLibrary.Get File    ${largest_file}    ${DEST}
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    #Read Until    password for swuser:
    #Write    ${pi_swuser_password}
    Write    pkill -9 -f nc
    #Now kill the channel emulator Session
    Switch Connection    CE
    Write    tmux kill-session -t chanemu

Start UE log collection_usernameAIRSPAN
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     # Redirect to file, NOT tee: tee blocks after ~2MB fills the unread SSH channel
     ${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p514 > /tmp/${pi_ip}_${time}_UE_Serial.log

     Login Pi    ${pi_ip}
      Log to console    ========= Removing ${pi_ip}_*_UE_Serial.log before starting UE log collection==========
   
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
     Write   ${UE_log_cmd}

Start UE log collection_usernameADMIN
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     #${UE_log_cmd}=    Set Variable    sudo netcat -l -s 192.168.4.1 -u -p514 | tee /tmp/${pi_ip}_${time}_UE_Serial.log
     ${UE_log_cmd}=    Set Variable    sudo nc -u -l 192.168.4.1 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
    Login Pi    ${pi_ip}
    Log to console    ========= Removing ${pi_ip}_*_UE_Serial.log before starting UE log collection==========
   
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    Write   ${UE_log_cmd}

Start UE log collection_usernameSSINGH
    [Arguments]    ${pi_ip}
     ${time}=     Get Current Date    result_format=%H-%M
     # enb9 Pi has no netcat binary, only nc
     # Redirect to file, NOT tee: tee also writes to the SSH pty which Robot never reads,
     # so after ~2MB the channel window fills, tee blocks and nc stops logging
     ${UE_log_cmd}=    Set Variable    sudo nc -u -l 192.168.4.1 514 > /tmp/${pi_ip}_${time}_UE_Serial.log
     
    Login Pi    ${pi_ip}
    #Write    sudo pkill -9 -f netcat
    Log to console    ========= Removing ${pi_ip}_*_UE_Serial.log before starting UE log collection==========
   
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    # Answer the rm sudo prompt first, otherwise the netcat command is eaten as a password
    ${status}=    Run Keyword And Return Status    Read Until    password for santoshsingh:
    IF    ${status}
        Write    ${pi_ssingh_password}
    END
    Write   ${UE_log_cmd}
    ${status}=    Run Keyword And Return Status    Read Until    password for santoshsingh:
    IF    ${status}
        Write    ${pi_ssingh_password}
    END
    #Now set the Radio rack for port 20 and 21 to 0 gain for enb9ac before starting the UE log collection
    Set Radio Rack for enb9ac      10.80.6.247


Set Radio Rack for enb9ac
    [Arguments]    ${pi_ip}
    ${time}=     Get Current Date    result_format=%H-%M
    ${set_enb9_puc1_gain}=    Set variable    cd ~/ps_scripts; ./setGain.sh 0 20
    Login Pi    ${pi_ip}
     Log to console    ========= Inside pi ${pi_ip} Setting enb9 PUC1 gains before starting UE log collection==========
     Write    ${set_enb9_puc1_gain}
 
    
Stop UE log collection_usernameSSINGH
   [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    # Kill nc so the current log file is closed before copying
    Write    sudo pkill -9 -f 'nc -u -l'
    ${status}=    Run Keyword And Return Status    Read Until    password for santoshsingh:
    IF    ${status}
        Write    ${pi_ssingh_password}
    END
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    # Newest file only (ls -t sorts by modification time)
    ${latest_file}=    Execute Command    ls -t /tmp/${pi_ip}_*_UE_Serial.log | head -1
    ${latest_file}=    Strip String    ${latest_file}
    ${time}=     Get Current Date    result_format=%H-%M
    ${DEST}=    Set Variable    ${RESULT_PATH}/${pi_ip}_${time}_ac.log
    SSHLibrary.Get File    ${latest_file}    ${DEST}
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    
  

Stop UE log collection_usernameAIRSPAN
   [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    # Kill netcat so the current log file is closed before copying
    Write    sudo pkill -9 -f netcat
    ${status}=    Run Keyword And Return Status    Read Until    password for airspan:
    IF    ${status}
        Write    ${pi_airspan_password}
    END
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    # Newest file only (ls -t sorts by modification time)
    ${latest_file}=    Execute Command    ls -t /tmp/${pi_ip}_*_UE_Serial.log | head -1
    ${latest_file}=    Strip String    ${latest_file}
    ${time}=     Get Current Date    result_format=%H-%M
    ${DEST}=    Set Variable    ${RESULT_PATH}/${pi_ip}_${time}_ac.log
    SSHLibrary.Get File    ${latest_file}    ${DEST}
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    ${status}=    Run Keyword And Return Status    Read Until    password for airspan:
    IF    ${status}
        Write    ${pi_airspan_password}
    END
Stop enb8 UE log collection_usernameSVG
    [Arguments]    ${pi_ip}
    Login Pi   ${pi_ip}
    Write    ${dettach_cmd}
    # Kill netcat so the current log file is closed before copying
    Write    sudo pkill -9 -f netcat
    ${status}=    Run Keyword And Return Status    Read Until    password for svg:
    IF    ${status}
        Write    ${pi_svg_password}
    END
    ${RESULT_PATH}=     ATG_4G_Create Log Path
    # Newest file only (ls -t sorts by modification time)
    ${latest_file}=    Execute Command    ls -t /tmp/${pi_ip}_*_UE_Serial.log | head -1
    ${latest_file}=    Strip String    ${latest_file}
    ${time}=     Get Current Date    result_format=%H-%M
    ${DEST}=    Set Variable    ${RESULT_PATH}/${pi_ip}_${time}_ac.log
    SSHLibrary.Get File    ${latest_file}    ${DEST}
    Sleep    10s
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    ${status}=    Run Keyword And Return Status    Read Until    password for svg:
    IF    ${status}
        Write    ${pi_svg_password}
    END

attach_detach_during_TA_RSRP
    [Documentation]    Attaches and detaches the UE every ${cycle_interval} seconds
    ...    (attach at 0s, detach at 60s, attach at 120s, ...) for the whole ${DURATION}.
    ...    TA/RSRP sweep is expected to run in parallel from the pi machine.
    [Arguments]    ${pi_ip}    ${cycle_interval}=60
    IF      $pi_ip == $enb8_pi1
            ${PI_USER}=    Set Variable    ${pi_svg_username}
            ${PI_PASS}=    Set Variable    ${pi_svg_password}
    ELSE IF     $pi_ip == $enb7_pi
            ${PI_USER}=    Set Variable    ${pi_admin_username}
            ${PI_PASS}=    Set Variable    ${pi_admin_password}
    ELSE IF     $pi_ip == $enb6_pi
            ${PI_USER}=    Set Variable    ${pi_swuser_username}
            ${PI_PASS}=    Set Variable    ${pi_swuser_password}
    ELSE IF     $pi_ip == $enb9_pi
            ${PI_USER}=    Set Variable    ${pi_ssingh_username}
            ${PI_PASS}=    Set Variable    ${pi_ssingh_password}
    ELSE
            ${PI_USER}=    Set Variable    ${pi_airspan_username}
            ${PI_PASS}=    Set Variable    ${pi_airspan_password}
    END
    LOG    Selected user: ${PI_USER}
    SSHLibrary.Open Connection    ${pi_ip}
    Login    ${PI_USER}    ${PI_PASS}
    Set Client Configuration    prompt=>
    Write    ssh ${AC_USER}@${AC_IP}
    Read Until    password:
    Write    ${AC_PASS}
    Read Until    $
    Write    cd /bs/ && ./tnet
    Write    info-x
    Read Until    tnet >
    ${syslog_enbale}=   Set Variable    set logging [1] 7=[08 00]
    Write    ${syslog_enbale}
    Write    ${provide_lat_long}
    #Start from a clean detached state in case UE was attached by a previous run.
    Write    ${dettach_cmd}
    Read    delay=2s
    ${start_time}=    Get Current Date
    ${end_time}=      Add Time To Date    ${start_time}    ${DURATION}
    ${cycle}=    Set Variable    ${0}
    ${CURRENT}=    Get Current Date
    WHILE    '${CURRENT}' < '${end_time}'
        ${cycle}=    Evaluate    ${cycle} + 1
        ${elapsed}=    Subtract Date From Date    ${CURRENT}    ${start_time}
        Log With Color    \n========== Cycle ${cycle} (t=${elapsed}s): Attaching UE ${pi_ip} ==========\n    green
        Write    ${attach_cmd}
        Read    delay=2s
        Sleep    ${cycle_interval}
        Write    ${get_cmd}
        ${get_cmd_output}=    Read Until Prompt
        IF    'established' in """${get_cmd_output}"""
            Log With Color    ========== Cycle ${cycle}: ${pi_ip} UE is established ==========    green
        ELSE
            Log With Color    ========== Cycle ${cycle}: ${pi_ip} UE is not attached ==========    red
        END
        Log With Color    \n========== Cycle ${cycle}: Detaching UE ${pi_ip} ==========\n    yellow
        Write    ${dettach_cmd}
        Read    delay=2s
        Sleep    ${cycle_interval}
        ${CURRENT}=    Get Current Date
    END
    Log With Color    \n========== attach/detach cycling completed: ${cycle} cycles in ${DURATION}s ==========\n    green
