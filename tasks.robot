*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archives of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download order file
    Get order and submit the order
    Create ZIP packages from receipt PDF
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Download order file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Get order and submit the order
    ${orders}=    Get orders    orders.csv
    FOR    ${order}    IN    @{orders}
        Submit the order and save the receipt    ${order}
    END

Get orders
    [Arguments]    ${csv}
    ${item}=    Read table from CSV    ${csv}    header:${True}
    RETURN    ${item}

Submit the order and save the receipt
    [Arguments]    ${item}
    Select From List By Value    id:head    ${item}[Head]
    Select Radio Button    body    ${item}[Body]
    Input Text    id:address    ${item}[Address]
    Input Text
    ...    css:[placeholder="Enter the part number for the legs"]
    ...    ${item}[Legs]
    Click Button    preview
    Wait Until Keyword Succeeds    3x    1s
    ...    Click Button    id:order
    ${count}=    Get Element Count    id:receipt

    WHILE    ${count} < 1
        Wait Until Keyword Succeeds    3x    1s
        ...    Click Button    id:order
        ${count}=    Get Element Count    id:receipt
    END
    ${pdf}=    Store the receipt as a PDF file    ${item}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${item}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    id:order-another
    Wait Until Element Is Visible    css:.modal-content
    Click Button    OK

Store the receipt as a PDF file
    [Arguments]    ${order_no}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}/receipt/${order_no}.pdf
    RETURN    ${OUTPUT_DIR}/receipt/${order_no}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_no}

    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/screenshot/${order_no}.png
    RETURN    ${OUTPUT_DIR}/screenshot/${order_no}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}    ${receipt_pdf}
    ${image_list}=    Create List    ${image}
    Open Pdf    ${receipt_pdf}
    Add Files To Pdf    ${image_list}    ${receipt_pdf}    append=${True}

Close the browser
    Close Browser

Create ZIP packages from receipt PDF
    ${zip_file}=    Set Variable    ${OUTPUT_DIR}/receipt.zip
    Archive Folder With Zip    ${OUTPUT_DIR}/receipt    ${zip_file}
