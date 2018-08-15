# Ballerina-Scenario-Test-Backend-Services.

## Getting Started

This implementation consist of one service with multiple resources.Each of these resources can be used for the testing of following Ballerina scenarios.

1. RESTful backend service 
2. Secure service invoke and verification backend service 
3. Slow backend service
4. Content type conversion backend service 
5. Invoke different payload sizes backend service 
6. Event handling backend service (Invoking subscription notification Backend Service) 
7. Email verification backend service implementation

### Prerequisites

Ballerina Distribution  
Text editor or and IDE  

## Running the tests

1. Invoking the RESTful service</br>
Important : Let’s see the following curl commands.</br>

**Create Bank Account**
To create a bank account we can use HTTP POST request with all details need to send.</br>
The service should respond with a 201 Created HTTP response. </br>

Example:</br>
curl -vk -X POST -d '{"Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob"}}' "https<span></span>://localhost:9090/banktest/resttestaccount" -H "Content-Type:application/json"

Output</br>
< HTTP/1.1 201 Created</br>
< content-type: application/json</br>
< content-length: 77</br>
< server: wso2-http-transport</br>

{"status":" Account has been created successfully ","Bank_Account_No":"ACC01"}</br>

**Retrieve Bank Account Details**
To retrieve bank account details, send an HTTP GET request to the appropriate URL.</br>

Example:</br>
curl -vK https://localhost:9090/banktest/resttestaccount/ACC01</br>

Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 52</br>
< server: wso2-http-transport</br>

{"Account_Details":{"Bank_Account_No":"ACC01","Name":"Bob"}}</br>

**Update the Bank Account Details**
To update an existing order, we need to send an HTTP PUT request.</br>

Example: 
 curl -vk -X PUT -d '{ "Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob_Updated"}}' "https://localhost:9094/banktest/resttestaccount/ACC01" -H "Content-Type:application/json"</br>

Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 94</br>
< server: wso2-http-transport</br>

{"Account_Details":{"Bank_Account_No":"ACC01","Name":"Updated Name - Bob_Updated"}}</br>

**Delete Existing Bank Account**
To delete an existing order, we need to send an HTTP DELETE request.</br>

Example:</br>
 curl -vk -X DELETE "https://localhost:9090/banktest/resttestaccount/ACC01"</br>

Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 34</br>
< server: wso2-http-transport</br>

"Account_Details : ACC01 Deleted."</br>

2. Invoking the secure service

Important : Bellow resources are secured by basic authentication. To invoke these we have to insert valid user names and passwords which are defined in TOML file. Let’s see the following curl commands

**Create Bank Account**
To create a bank account we can use HTTP POST request with all details need to send.The service should respond with a 201 Created HTTP response.</br>

Example:</br>
curl -vk -u admin:pass1 POST -d '{ "Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob"}}' "https://localhost:9090/banktest/account" -H "Content-Type:application/json"</br>

Output</br>
< HTTP/1.1 201 Created</br>
< content-type: application/json</br>
< content-length: 77</br>
< server: wso2-http-transport</br>

{"status":" Account has been created successfully ","Bank_Account_No":"ACC01"}</br>

**Retrieve Bank Account Details**
To retrieve bank account details, send an HTTP GET request to the appropriate URL.</br>

Example:</br>
Admin can access </br>
curl -vk -u admin:pass1 https://localhost:9090/banktest/account/ACC01</br>
Or 
User can access bellow curl command.(Authorized User)</br>
curl -vk -u user:pass2 https://localhost:9090/banktest/account/ACC01</br>


Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 52</br>
< server: wso2-http-transport</br>

{"Account_Details":{"Bank_Account_No":"ACC01","Name":"Bob"}}</br>



**Update the Bank Account Details**
To update an existing order, we need to send an HTTP PUT request.</br>

Example: </br>
curl -vk -u admin:pass1 -X PUT -d '{ "Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob_Updated"}}' "https://localhost:9090/banktest/account/ACC01" -H "Content-Type:application/json"</br>

Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 94</br>
< server: wso2-http-transport</br>

{"Account_Details":{"Bank_Account_No":"ACC01","Name":"Updated Name - Bob_Updated"}}</br>
Update the Bank Account Details</br>
To update an existing order, we need to send an HTTP PUT request.</br>

Example: </br>
curl -vk -u admin:pass1 -X PUT -d '{ "Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob_Updated"}}' "https://localhost:9090/banktest/account/ACC01" -H "Content-Type:application/json"</br>

Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 94</br>
< server: wso2-http-transport</br>

{"Account_Details":{"Bank_Account_No":"ACC01","Name":"Updated Name - Bob_Updated"}}</br>

**Delete Existing Bank Account**
To delete an existing order, we need to send an HTTP DELETE request.</br>

Example:</br>
 curl -vk -u admin:pass1 -X DELETE "https://localhost:9090/banktest/account/12345"</br>

 Output</br>
< HTTP/1.1 200 OK</br>
< content-type: application/json</br>
< content-length: 34</br>
< server: wso2-http-transport</br>

"Account_Details : ACC01 Deleted."</br>




