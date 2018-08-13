# Project Title

Ballerina-Scenario-Test-Backend-Services.

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

1. RESTful backend service<br />
Important : Let’s see the following curl commands.<br />

Invoking the RESTful service<br />

**Create Bank Account**

To create a bank account we can use HTTP POST request with all details need to send.The service should respond with a 201 Created HTTP response.<br />

Example:

curl -vk -X POST -d '{"Account_Details": { "Bank_Account_No": "ACC01", "Name": "Bob"}}' "https://localhost:9090/banktest/resttestaccount" -H "Content-Type:application/json"

Output
< HTTP/1.1 201 Created<br />
< content-type: application/json<br />
< content-length: 77<br />
< server: wso2-http-transport<br />







