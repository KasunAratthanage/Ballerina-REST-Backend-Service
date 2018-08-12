import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/log;
import ballerina/config;
import wso2/gmail;

string filePath4 = config:getAsString("FILEPATH4");
string filePath6 = config:getAsString("FILEPATH6");

//Ballerina Gmail connector configurations.
string accessToken = config:getAsString("ACCESS_TOKEN");
string clientId = config:getAsString("CLIENT_ID");
string clientSecret = config:getAsString("CLIENT_SECRET");
string refreshToken = config:getAsString("REFRESH_TOKEN");
string userId = config:getAsString("USER_ID");
string senderEmail = config:getAsString("SENDER");
string recipientEmail = config:getAsString("RECIPIENT");
string subject = config:getAsString("SUBJECT");
string messageBody = config:getAsString("MESSAGEBODY");
string contentType = config:getAsString("CONTENTTYPE");
string labelId = config:getAsString("LABELID");

//Credentials for HTTP client config for gmail connector.
//Gmail uses OAuth 2.0 to authenticate and authorize requests. 
endpoint gmail:Client gmailEP {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            clientId: clientId,
            clientSecret: clientSecret,
            refreshToken: refreshToken            
        }
    }
};

//This service is accessible at port 9090.
//The endpoint used here is defaults tries to authenticate and authorize each request.
endpoint http:SecureListener ep {
    port: 9094,

    //Ballerina client can be used to connect to the created HTTPS listener.
    //The client needs to provide values for 'trustStoreFile' and 'trustStorePassword'.
    //keyStore and trustStore are used to store SSL Certificates.
    //keyStore store private key certificates and trustStore store public key certificates of client or server.
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        },
        trustStore: {
            path: "${ballerina.home}/bre/security/ballerinaTruststore.p12",
            password: "ballerina"
        }
    }
};

//Service is done using an in memory map.
map<json> bankDetails;

//authConfiguration comprise Authentication and Authorization.
//Authentication can set as 'enable' at service level.Authentication and authorization setting can be overridden at resource level.
//Authorization based on scope.
//banktest is basepath of service.
@http:ServiceConfig {
    basePath: "/banktest",
    authConfig: {
        authentication: { enabled: true },
        scopes: ["scope1"]
    }
}

//accMGT Service.
service<http:Service> accountMgt bind ep {

    //Secure backend service - A service can be secured using basic authentication.
    //This service consist of POST/GET/PUT/DELETE methods to handle the resources.
    //POST Resource that handles the HTTP POST requests.That are directed to the specified path.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/account",
        authConfig: {
            scopes: ["scope2"]
        }
    }
    
    //Create bank account using POST method 
    createAccount(endpoint client, http:Request req) {
        http:Response response;
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered.
        if (Bank_Account_No.toString().length() == 0){
            json payload = { status: " Please Enter Your Bank Account Number " };
            response.setJsonPayload(payload);
            _ = client->respond(response);
        } else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;
            if (accountId.length() == 5){
                // Create response message.
                json payload = { status: " Account has been created sucessfully ", Bank_Account_No: accountId };
                // Set 201 "Created new account" response code in the response message.
                response.statusCode = 201;
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            } else {
                json payload = { status: " Wrong Account length ", Bank_Account_No: accountId };
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            }
        }
    }

    //Retrive Bank account details that handles the HTTP GET requests.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2", "scope1"]
        }
    }

    //Find the requested accountId from the map and send back it in JSON format.
    getBankAccountDetails(endpoint client, http:Request req, string accountId) {        

        http:Response response;
        // Find the accountId is exists or not in the memory map
        if (bankDetails.hasKey(accountId)) {
            json? payload = bankDetails[accountId];
            // Set the JSON payload to outgoing response message.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "accountId : " + accountId + " This account is cannot be found.";
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Update the bccount details using the PUT method.
    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    updateAccountDetails(endpoint client, http:Request req, string accountId) {
        
        http:Response response;
        json updatedAccount = check req.getJsonPayload();
        // Find the Account Details using AccountId.
        json existingAccount = bankDetails[accountId];
        // Updating inserted Account Details.
        if (existingAccount != null) {
            existingAccount.Account_Details.Bank_Account_No = updatedAccount.Account_Details.Bank_Account_No;
            existingAccount.Account_Details.Name = updatedAccount.Account_Details.Name;
            existingAccount.Account_Details.Account_type = updatedAccount.Account_Details.Account_type;
            existingAccount.Account_Details.Branch = updatedAccount.Account_Details.Branch;
            bankDetails[accountId] = existingAccount;
        }
        else {
            existingAccount = "Account : " + accountId + " is invalid. Plese create a account.";
        }
        // Set the JSON payload to outgoing response message.
        response.setJsonPayload(untaint existingAccount);
        // Send response to the client.
        _ = client->respond(response);
    }

    //Delete bank account details using DELETE method.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    deleteAccount(endpoint client, http:Request req, string accountId) {
        http:Response response;

        //Find the accountId is exists or not.
        if (bankDetails.hasKey(accountId)){
            // Remove the requested account from the memory map.
            _ = bankDetails.remove(accountId);
            json payload = "Account_Details : " + accountId + " Deleted.";
            // Set a generated payload with status.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "Account : " + accountId + " not found.";
            // Set a generated payload with order status.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Handlling different Payload sizes backend service.In this service different file sizes are used as payloads.
    //This consist of file read and write operations.
    //Different Payload sizes read from the specified file. 
    @http:ResourceConfig {
        methods: ["GET"],
        path: "readJSONFile",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    readAccountDetailsLogFile(endpoint client, http:Request req) {
        http:Request newRequest = new;
        http:Response response;
         
        //Check whether 'path_for_read' header exisits in the invoking request.
        if (!req.hasHeader("path_for_read")) {
            http:Response errorResponse = new;
            //If not included 'path_for_read' in header print this as a error message.
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'path_for_read' header is not found" };
            errorResponse.setPayload(errMsg);
            client->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        //String to integer type conversion.
        string filepath = req.getHeader("path_for_read");
        
        //Create the byte channel for file path.
        io:ByteChannel byteChannel = io:openFile(untaint filepath, io:READ);
        //Derive the character channel for the above byte channel.
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");
        match ch.readJson() {
            json result => {
                //Close the charcter channel after reading process.
                ch.close() but {
                    error e =>
                    log:printError("Error occurred while closing character stream",
                        err = e)
                };
                response.setJsonPayload(untaint result);
                _ = client->respond(response);                
            }
            error err => {
                response.statusCode = 404;
                json payload = " JSON file cannot read ";
                response.setJsonPayload(payload);
                _ = client->respond(response);        
            }
        }
    }

    //Different Payload sizes write to the specified file. 
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/writeJSONFile",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    writeAccountDetailsLogFile(endpoint client, http:Request req) {
        http:Response response;
        http:Request newRequest = new;
         
        //Check whether 'path_for_write' header exisits in the invoking request.
        if (!req.hasHeader("path_for_write")) {
            http:Response errorResponse = new;
            //If not included 'path_for_write' in header print this as a error message.
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'path_for_write' header is not found" };
            errorResponse.setPayload(errMsg);
            client->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        //String to integer type conversion.
        string filePath1 = req.getHeader("path_for_write");

        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;
        // Check the Bank_Account_No is null or not entered.
        if (Bank_Account_No.toString().length() == 0)    {
            json payload = { status: " Please Enter Your Bank Account Number " };            
            response.setJsonPayload(payload);
            // Set 204 "No content" response code in the response message.
            response.statusCode = 204;
            _ = client->respond(response);
        }
        else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;
            //Create the byte channel for file path.
            io:ByteChannel byteChannel = io:openFile(untaint filePath1, io:WRITE);
            //Derive the character channel for the above byte channel.
            io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

            match ch.writeJson(accountReq) {
                error err => {
                    io:println(accountReq);                 
                }
                () => {
                    //close the charcter channel after writing process.
                    ch.close() but {
                        error e =>
                        log:printError("Error occurred while closing character stream",
                            err = e)
                    };
                    json payload = " Content written successfully ";
                    //response.statusCode = 201;
                    response.setJsonPayload(payload);
                    _ = client->respond(response);
                }
            }
        }
    }

    //Content Type Conversion Backend service.
    //Original request submits data using XML, we can attempt to convert the data to JSON and JSON to XML.
    //XML to JSON conversion. 
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/xmltojson",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    xmltojsonconversion(endpoint client, http:Request req) {
        http:Response response;
        var payload = req.getXmlPayload();

        //Read XML file.
        match payload {
            xml result => {
                //Convert XML file into JSON.
                json j1 = result.toJSON({});
                string x = j1.toString();

                response.setTextPayload(untaint x);
                _ = client->respond(response);               
            }
            error err => {
                response.statusCode = 404;
                json payload1 = " XML file cannot read ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }
        }
    }

    //JSON to XML conversion. 
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/jsontoxml",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    conversion(endpoint client, http:Request req) {
        http:Response response;
        var payload = req.getJsonPayload();
        match payload {
            json result => {
                //Convert JSON to XML. 
                var j1 = result.toXML({});
                match j1 {
                    xml value => {
                        response.setXmlPayload(untaint value);
                        _ = client->respond(response);
                    }
                    error => {
                        response.statusCode = 404;
                        json payload1 = " Conversion error";
                        response.setPayload(payload1);
                    }
                }
            }
            error => {
                response.statusCode = 404;
                json payload1 = " JSON file Error ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }
        }
    }

    //REST backend service.
    //This service consist of POST/GET/PUT/DELETE methods to handle the resources.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/resttestaccount",
        authConfig: {
            authentication: { enabled: false }
        }
    }
    
    //Create bank account using POST method. 
    createAccount_test_rest_servivice(endpoint client, http:Request req) {
        http:Response response;
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered.
        if (Bank_Account_No.toString().length() == 0)    {
            json payload = { status: " Please Enter Your Bank Account Number " };
            response.setJsonPayload(payload);
            _ = client->respond(response);
        } else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;
            if (accountId.length() == 5){
                // Create response message.
                json payload = { status: " Account has been created sucessfully ", Bank_Account_No: accountId };
                // Set 201 "Created new account" response code in the response message.
                response.statusCode = 201;
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            } else {
                json payload = { status: " Wrong Account length ", Bank_Account_No: accountId };
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            }
        }
    }

    //Retrive Bank account details that handles the HTTP GET requests.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    getBankAccountDetails_test_rest_servivice(endpoint client, http:Request req, string accountId) {
        // Find the requested accountId from the map and send back it in JSON format.
        http:Response response;
        // Find the accountId is exists or not in the memory map.
        if (bankDetails.hasKey(accountId)) {
            json? payload = bankDetails[accountId];
            // Set the JSON payload to outgoing response message.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "accountId : " + accountId + " This account is cannot be found.";
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Update the bccount details using the PUT method.
    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }
    
    updateAccountDetails_test_rest_servivice(endpoint client, http:Request req, string accountId) {
        http:Response response;

        json updatedAccount = check req.getJsonPayload();
        // Find the Account Details using AccountId.
        json existingAccount = bankDetails[accountId];

        // Updating inserted Account Details.
        if (existingAccount != null) {
            existingAccount.Account_Details.Bank_Account_No = updatedAccount.Account_Details.Bank_Account_No;
            existingAccount.Account_Details.Name = updatedAccount.Account_Details.Name;
            bankDetails[accountId] = existingAccount;
        }
        else {
            existingAccount = "Account : " + accountId + " is invalid. Plese create a account.";
        }        
        //Set the JSON payload to outgoing response message.
        response.setJsonPayload(untaint existingAccount);
        //Send response to the client.
        _ = client->respond(response);
    }
    
    //Delete bank account details using DELETE method.
    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    deleteAccount_test_rest_servivice(endpoint client, http:Request req, string accountId) {
        http:Response response;
        
        //Find the accountId is exists or not.
        if (bankDetails.hasKey(accountId)){
            // Remove the requested account from the memory map.
            _ = bankDetails.remove(accountId);
            json payload = "Account_Details : " + accountId + " Deleted.";
            // Set a generated payload with status.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "Account : " + accountId + " not found.";
            // Set a generated payload with order status.
            response.setJsonPayload(untaint payload);
            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Slow backend services. 
    //Ballerina runtime package used for implement this resource based on the sleep time.
    //User need to insert the 'sleeptime' as a parameter.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/slowbackend",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    //Create bank account using POST method. 
    createAccountforslow(endpoint client, http:Request req) {
        http:Response response;

        http:Request newRequest = new;
        //Check whether 'sleeptime' header exisits in the invoking request.
        if (!req.hasHeader("sleeptime")) {
            http:Response errorResponse = new;
            //If not included 'sleeptime' in header print this as a error message.
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'sleeptime' header is not found" };
            errorResponse.setPayload(errMsg);
            client->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        //String to integer type conversion.
        string nameString = req.getHeader("sleeptime");
        int delay = 0;
        var intResult = <int>nameString;
        match intResult {
            int value => delay = value;
            error err => io:println("error: " + err.message);
        }
        
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered.
        if (Bank_Account_No.toString().length() == 0){
            runtime:sleep(delay);
            json payload = { status: " Please Enter Your Bank Account Number " };
            response.setJsonPayload(payload);
            _ = client->respond(response);
        } else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;
            if (accountId.length() == 5){
                // Create response message.
                runtime:sleep(delay);
                json payload = { status: " Account has been created sucessfully ", Bank_Account_No: accountId };
                // Set 201 "Created new account" response code in the response message.
                response.statusCode = 201;
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            } else {
                runtime:sleep(delay);
                json payload = { status: " Wrong Account length ", Bank_Account_No: accountId };
                response.setJsonPayload(untaint payload);
                // Send response to the client.
                _ = client->respond(response);
            }
        }
    }

    //Event handlling backend service.
    //This service is captured by the subscription notifications from APIM and write into the file.
    //Change the API status to all the available life-cycle status subscription notifications triggered.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notifyxmlwrite",
        authConfig: {
            authentication: { enabled: false }
        } 
    }

    writenotification(endpoint client, http:Request req) {
        http:Response response;
        
        xml payload = check req.getXmlPayload();
        //Create the byte channel for file path.
        io:ByteChannel byteChannel = io:openFile(filePath6, io:WRITE);
        //Derive the character channel for the above byte channel.
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        match ch.writeXml(payload) {
            error err => {
            }
            () => {
                //close the charcter channel after writing process.
                ch.close() but {
                    error e => log:printError("Error occurred while closing character stream",
                        err = e)
                };
                json payload1 = " Content written successfully ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }
        }
    }
    
    //This service read saved subscription notification. 
    @http:ResourceConfig {
        methods: ["GET"],
        path: "readnotificationxml",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    readnotification(endpoint client, http:Request req) {
        http:Response response;

        //Create the byte channel for file path.
        io:ByteChannel byteChannel = io:openFile(filePath6, io:READ);
        //Derive the character channel for the above byte channel.
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        match ch.readXml() {
            xml result => {
                json j1 = result.toJSON({ attributePrefix: "#", preserveNamespaces: false });                        
                //Close the charcter channel after reading process.
                ch.close() but {
                    error e =>
                    log:printError("Error occurred while closing character stream",
                        err = e)
                };              
                string payload = "Event Type : "+j1.Event.Details.Operation.EventType.toString() + "\n" + "Old lifecycle State : "+ j1.Event.Details.Operation.
                    OldLifecycleState.toString() + "\n" +"New Lifecycle State : "+ j1.Event.Details.Operation.NewLifecycleState.toString();
                
                response.setTextPayload(untaint payload);
                _ = client->respond(response);               
            }
            error err => {
                response.statusCode = 404;
                json payload = " JSON file cannot read ";
                response.setJsonPayload(payload);
                _ = client->respond(response);               
            }
        }
    }

    //GMAIL Connector.
    //The Gmail connector allows you to send, read, and delete emails through the Gmail REST API. It handles OAuth 2.0 authentication.     
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/getlabel",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    //Get label and shows unread messages.
    getmaillabel(endpoint caller, http:Request request)
    {
        http:Response response1;        
        string messagesUnread;
        string id;
        string ownerType;
        int messagesTotal;
        int threadsTotal;
        int threadsUnread;
        string name;

        var response = gmailEP->getLabel(userId, labelId);
        match response {
            gmail:Label x => {
                //If successful, returns payload.
                string payload = " id: " + x.id + " \n " + "labelname: " + x.name + " \n " + "ownertype: " + x.ownerType
                    + " \n "
                    + "messagesTotal: " + x.messagesTotal + " \n " + "Unread Messages: " + x.messagesUnread + " \n " +
                    "threadsTotal: " + x.threadsTotal + " \n " + "threadsUnread: " + x.threadsUnread + " \n ";
                response1.statusCode = 200;
                response1.setTextPayload(untaint payload);
                _ = caller->respond(response1);
            }
            //Unsuccessful attempts return a Gmail error.
            gmail:GmailError e => {
                response1.statusCode = 404;
                string payload = " Not Found";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
        }
    }

    //Create label.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/createlabel",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    createmaillabel(endpoint caller, http:Request request)
    {
        http:Response response1;
        string messageListVisibility;        
        string labelShowIfUnread;        
        string labelListVisibility;        
        string name;       

        var response = gmailEP->createLabel(userId, name, labelListVisibility, messageListVisibility);
        match response {
            string x => {
                //If successful, returns payload.
                string payload = "Label " + name + " created ";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
            //Unsuccessful attempts return a Gmail error.
            gmail:GmailError e => {
                string payload = "Invalid value for parameters :  is not a valid values";
                response1.setJsonPayload(payload);
                _ = caller->respond(response1);
            }
        }
    }

    //Get email messages using the messageId and read.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/listemailmessages",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    listEmailMessagesAndRead(endpoint caller, http:Request request)
    {
        http:Response response;        
        string messageId;
        string threadId;

        var response1 = gmailEP->listMessages(userId);
        match response1 {            
            gmail:MessageListPage x => {
                any firstmessageid = x.messages[0].messageId;
                string stringVal = <string>firstmessageid;
                var response2 = gmailEP->readMessage(userId, untaint stringVal);
                io:println(response2);
                match response2 {
                    gmail:Message m =>
                    {   
                        //If successful, returns payload.
                        any emailmsg = "Subject : " + m.headerSubject + " \n"
                            + "snippet : " + m.snippet + " \n" + "From : "
                            + m.headerFrom + " \n" + "Header Date : " + m.headerDate;
                        string stringVal2 = <string>emailmsg;
                        response.setTextPayload(untaint stringVal2);
                        _ = caller->respond(response);
                        io:println(m);
                    }
                     //Unsuccessful attempts return a Gmail error.
                    gmail:GmailError e => io:println(e);
                }
            }
            gmail:GmailError e => {
                io:println(e);
            }
        }
    }

    //Send email.
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/sendmessage",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    sendEmailMessage(endpoint caller, http:Request request) {
        http:Response response;        
        gmail:MessageRequest messageRequest;
        messageRequest.recipient = recipientEmail;
        messageRequest.sender = senderEmail;
        //messageRequest.cc = "cc@mail.com";
        messageRequest.subject = subject;
        messageRequest.messageBody = messageBody;
        //Set the content type of the mail as TEXT_PLAIN or TEXT_HTML.
        messageRequest.contentType = gmail:TEXT_PLAIN;
        
        var sendMessageResponse = gmailEP->sendMessage(userId, messageRequest);
        string messageId;
        string threadId;
        match sendMessageResponse {
            (string, string) sendStatus => {
                //If successful, returns the message ID and thread ID.
                (messageId, threadId) = sendStatus;                
                any emailmsg = "Sent Message ID : " + messageId + " \n"
                    + "Sent Thread ID : " + threadId;

                string stringVal2 = <string>emailmsg;
                response.setTextPayload(untaint stringVal2);
                _ = caller->respond(response);
            }
            //unsuccessful attempts return a Gmail error.
            gmail:GmailError e => {
                io:println(e);
                string payload = "Sending unsuccessful";
                response.setJsonPayload(payload);
                _ = caller->respond(response);
            }
        }

    }

    //View user profile. 
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/viewuserprofile",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    viewUserEmailProfile(endpoint caller, http:Request request) {
        http:Response response;

        var response3 = gmailEP->getUserProfile(userId);
        match response3 {
            gmail:UserProfile x => {                
                any emailmsg = x;
                string stringVal2 = <string>emailmsg;
                //If successful, returns the user profile.
                response.setTextPayload(untaint stringVal2);
                _ = caller->respond(response);
            }
            //unsuccessful attempts return a Gmail error.
            gmail:GmailError e => {
                string payload = "Please enter valid userId";
                response.setJsonPayload(payload);
                _ = caller->respond(response);
            }
        }
    }

    //List email messages.
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/listmessages",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    listEmailMessages1(endpoint caller, http:Request request)
    {
        http:Response response;

        var response1 = gmailEP->listMessages(userId);
        match response1 {
            gmail:MessageListPage x => {
                any emailmsg = x;
                string stringVal2 = <string>emailmsg;
                //If successful, returns listemail messages.
                response.setTextPayload(untaint stringVal2);
                _ = caller->respond(response);
            }
            //unsuccessful attempts return a Gmail error.
            gmail:GmailError e => {
                string payload = "Please enter valid userId";
                response.setJsonPayload(payload);
                _ = caller->respond(response);
            }
        }
    }
}
