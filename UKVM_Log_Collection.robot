*** Settings ***
Documentation    Log collection that stores bs / ac / L1 logs directly on the UK VM
...              (${UK_VM}:${UK_VM_BASE_DIR}/<date>/<tag>/), fetched by the UK VM itself,
...              so the files never travel to the Bangalore VM.
Resource    /home/kvramesh/automation/Latest/Regression/Variables.robot
Resource    /home/kvramesh/automation/Latest/Regression/RaspberryPi_Aircard_SSH.robot
Library    /home/kvramesh/automation/Latest/Regression/UKVMLogs.py
Library    SSHLibrary
Library    String
Library    Collections
Library    DateTime

*** Variables ***
${UK_VM}              kvramesh@10.80.1.77
${UK_VM_BASE_DIR}     /home/kvramesh/automation/Latest/Results

*** Keywords ***
UK_VM Log Path
    [Documentation]    Same <date>/<tag> layout as ATG_4G_Create Log Path, but on the UK VM.
    ${date}=    Get Current Date    result_format=%Y-%m-%d
    ${tag}=    Get From List    ${TEST TAGS}    0
    ${tag}=    Replace String    ${tag}    ${SPACE}    _
    ${tag}=    Replace String    ${tag}    /    _
    RETURN    ${UK_VM_BASE_DIR}/${date}/${tag}

UK_VM bs log collection
    [Arguments]    ${bbu_ip}    ${tag}
    ${dest_dir}=    UK_VM Log Path
    ${time}=     Get Current Date    result_format=%H-%M
    Pull Logs To UK VM    ${UK_VM}    ${bbu_ip}    ${BBU_username}    ${BBU_password}
    ...    ls /var/log/bs.log    ${dest_dir}    rename=${bbu_ip}_${time}_bs.log

UK_VM L1 log collection
    [Arguments]    ${bbu_ip}    ${tag}
    ${dest_dir}=    UK_VM Log Path
    ${date}=     Get Current Date    result_format=%Y-%m-%d
    Pull Logs To UK VM    ${UK_VM}    ${bbu_ip}    ${BBU_username}    ${BBU_password}
    ...    ls /tmp/phy_logs/l1app_output_${date}* | tail -n 2    ${dest_dir}

UK_VM Stop UE log collection
    [Documentation]    Stops netcat on the Pi, has the UK VM fetch the newest UE serial log as
    ...                <pi_ip>_<HH-MM>_ac.log, then removes it from the Pi.
    [Arguments]    ${pi_ip}    ${pi_user}=${None}    ${pi_pass}=${None}
    # Default credentials follow the same Pi -> user mapping as Login Pi
    IF    $pi_user is None
        IF    $pi_ip == $enb9_pi
            ${pi_user}    ${pi_pass}=    Set Variable    ${pi_ssingh_username}    ${pi_ssingh_password}
        ELSE IF    $pi_ip == $enb8_pi1
            ${pi_user}    ${pi_pass}=    Set Variable    ${pi_svg_username}    ${pi_svg_password}
        ELSE IF    $pi_ip == $enb6_pi
            ${pi_user}    ${pi_pass}=    Set Variable    ${pi_swuser_username}    ${pi_swuser_password}
        ELSE IF    $pi_ip == $enb7_pi
            ${pi_user}    ${pi_pass}=    Set Variable    ${pi_admin_username}    ${pi_admin_password}
        ELSE
            ${pi_user}    ${pi_pass}=    Set Variable    ${pi_airspan_username}    ${pi_airspan_password}
        END
    END
    Login Pi   ${pi_ip}
    # Kill netcat / nc so the current log file is closed before copying (Pis use either binary)
    # [n] keeps the pattern from matching this sudo/pkill command line itself
    Write    sudo pkill -9 -f '[n]etcat -l|[n]c -u -l'
    ${status}=    Run Keyword And Return Status    Read Until    password for ${pi_user}:
    IF    ${status}
        Write    ${pi_pass}
    END
    Sleep    2s
    ${dest_dir}=    UK_VM Log Path
    ${time}=     Get Current Date    result_format=%H-%M
    Pull Logs To UK VM    ${UK_VM}    ${pi_ip}    ${pi_user}    ${pi_pass}
    ...    ls -t /tmp/${pi_ip}_*_UE_Serial.log | head -1    ${dest_dir}    rename=${pi_ip}_${time}_ac.log
    Write    sudo rm -f /tmp/${pi_ip}_*_UE_Serial.log
    ${status}=    Run Keyword And Return Status    Read Until    password for ${pi_user}:
    IF    ${status}
        Write    ${pi_pass}
    END
