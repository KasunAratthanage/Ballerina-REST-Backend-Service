import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/log;
import ballerina/config;

//Configured File paths
string filePath = config:getAsString("FILEPATH");
string filePath1 = config:getAsString("FILEPATH1");
string filePath4 = config:getAsString("FILEPATH4");

//This service is accessible at port
//Ballerina client can be used to connect to the created HTTPS listener
endpoint http:SecureListener ep {
    port: 9090,

    //The client needs to provide values for 'trustStoreFile' and 'trustStorePassword'
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

//Bckend Services is done using an in memory map.
map<json> bankDetails;

//authConfiguration comprise Authentication and Authorization
//Authentication can set as 'enable' 
//Authorization based on scpoe
@http:ServiceConfig {
    basePath: "/banktest",
    authConfig: {
        authentication: { enabled: true },
        scopes: ["scope1"]
    }
}

//accMGT service
service<http:Service> accountMgt bind ep {

    //POST Resource that handles the HTTP POST requests
    //That are directed to the specified path

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/account",
        authConfig: {
            scopes: ["scope2"]
        }
    }
    //Create Account

    createAccount(endpoint client, http:Request req) {
        http:Response response;
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered
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
                http:Response response;

                // Set 201 "Created new account" response code in the response message.
                response.statusCode = 201;
                response.setJsonPayload(payload);

                // Send response to the client.
                _ = client->respond(response);
            } else {
                json payload = { status: " Wrong Account length ", Bank_Account_No: accountId };
                http:Response response;

                response.setJsonPayload(payload);
                // Send response to the client.
                _ = client->respond(response);
            }
        }
    }

    //GET Resource that handles the HTTP GET requests

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2", "scope1"]
        }
    }

    //Retrive Account Details

    getBankAccountDetails(endpoint client, http:Request req, string accountId) {
        // Find the requested accountId from the map and send back it in JSON format.

        http:Response response;
        // Find the accountId is exists or not in the memory map
        if (bankDetails.hasKey(accountId)) {
            json? payload = bankDetails[accountId];

            // Set the JSON payload to outgoing response message.
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "accountId : " + accountId + " This account is cannot be found.";
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Update the Account Details

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    //Update Account Details
    updateAccountDetails(endpoint client, http:Request req, string accountId) {
        json updatedAccount = check req.getJsonPayload();

        // Find the Account Details using AccountId
        json existingAccount = bankDetails[accountId];

        // Updating inserted Account Details
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

        http:Response response;
        // Set the JSON payload to outgoing response message.
        response.setJsonPayload(existingAccount);
        // Send response to the client.
        _ = client->respond(response);
    }
    //Delete Account

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/account/{accountId}",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    deleteAccount(endpoint client, http:Request req, string accountId) {

        http:Response response;
        //Find the accountId is exists or not
        if (bankDetails.hasKey(accountId)){
            // Remove the requested account from the memory map.
            _ = bankDetails.remove(accountId);

            json payload = "Account_Details : " + accountId + " Deleted.";
            // Set a generated payload with status.
            response.setJsonPayload(payload);
            // Send response to the client.
            _ = client->respond(response);
        }

        else {
            json payload = "Account : " + accountId + " not found.";
            // Set a generated payload with order status.
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Slow backend service
    //Read file with delay
    @http:ResourceConfig {
        methods: ["GET"],
        path: "readJSONFile",
        authConfig: {
            authentication: { enabled: false }
           
        }
    }

    readAccountDetailsLogFile(endpoint client, http:Request req) {

        http:Request newRequest = new;
        //Check whether 'sleeptime' header exisits in the invoking request
        if (!req.hasHeader("sleeptime")) {
            http:Response errorResponse = new;
            //If not included 'sleeptime' in header print this as a error message
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'sleeptime' header is not found" };
            errorResponse.setPayload(errMsg);
            client->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        //String to integer type conversion
        string nameString = req.getHeader("sleeptime");

        int delay = 0;
        var intResult = <int>nameString;
        match intResult {
            int value => delay = value;
            error err => io:println("error: " + err.message);
        }

        http:Response response;

        //Create the byte channel for file path
        io:ByteChannel byteChannel = io:openFile(filePath, io:READ);
        //Derive the character channel for the above byte channel
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        match ch.readJson() {
            json result => {
                runtime:sleep(delay);

                //Close the charcter channel after reading process
                ch.close() but {
                    error e =>
                    log:printError("Error occurred while closing character stream",
                        err = e)
                };
                response.setJsonPayload(result);
                _ = client->respond(response);

                io:println(result);
            }
            error err => {
                response.statusCode = 404;
                json payload = " JSON file cannot read ";
                response.setJsonPayload(payload);

                _ = client->respond(response);
                //characterChannel.close();
            }
        }
    }

    //Write file with delay

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

        //Check whether 'sleeptime' header exisits in the invoking request
        if (!req.hasHeader("sleeptime")) {
            http:Response errorResponse = new;
            //If not included 'sleeptime' in header print this as a error message
            errorResponse.statusCode = 500;
            json errMsg = { "error": "'sleeptime' header is not found" };
            errorResponse.setPayload(errMsg);
            client->respond(errorResponse) but {
                error e => log:printError("Error sending response", err = e)
            };
            done;
        }

        //String to integer type conversion
        string nameString = req.getHeader("sleeptime");

        int delay = 0;
        var intResult = <int>nameString;
        match intResult {
            int value => delay = value;
            error err => io:println("error: " + err.message);
        }

        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered
        if (Bank_Account_No.toString().length() == 0)    {
            json payload = { status: " Please Enter Your Bank Account Number " };
            http:Response response;
            response.setJsonPayload(payload);

            // Set 204 "No content" response code in the response message.
            response.statusCode = 204;
            _ = client->respond(response);
        }

        else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;

            //string filePath = "./files/test1.json";
            //Create the byte channel for file path
            io:ByteChannel byteChannel = io:openFile(filePath1, io:WRITE);
            //Derive the character channel for the above byte channel
            io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

            match ch.writeJson(accountReq) {
                error err => {
                    io:println(accountReq);
                    //throw err;
                }
                () => {
                    runtime:sleep(delay);

                    //close the charcter channel after writing process
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

    //Content Type Conversion    
    //XML to JSON conversion service
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/xmltojson",
        authConfig: {
            authentication: { enabled: false }
            //scopes: ["scope2"]
        }
    }

    xmltojsonconversion(endpoint client, http:Request req) {
        http:Response response;

        var payload = req.getXmlPayload();

        //Read XML file
        match payload {
            xml result => {
                json j1 = result.toJSON({});

                string x = j1.toString();

                response.setTextPayload(untaint x);
                _ = client->respond(response);

                //io:println(j1);
            }
            error err => {
                response.statusCode = 404;
                json payload1 = " XML file cannot read ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }

        }
    }

    //JSON to XML conversion service
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/jsontoxml",
        authConfig: {
            authentication: { enabled: false }
            //scopes: ["scope2"]
        }
    }

    conversion(endpoint client, http:Request req) {
        http:Response response;
        var payload = req.getJsonPayload();
        match payload {
            json result => {
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

    // API - Subscription Notification
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notification",
        authConfig: {
            authentication: { enabled: false }
            //scopes: ["scope2"]
        }
    }

    getsubscriptionNotification(endpoint client, http:Request req) {
        http:Response response;
        //xml payload = check req.getXmlPayload();
        var payload = req.getXmlPayload();

        //Read XML file
        match payload {
            xml result => {
                json j1 = result.toJSON({});
                string x = j1.toString();
                string[] array = x.split(" ");

                int i = 0;
                string output = "";

                while (i < lengthof array) {
                    //io:println("  " + array[i]);
                    output += array[i] + "  \n  ";
                    i = i + 1;
                }

                response.setTextPayload(untaint output);
                _ = client->respond(response);
                //io:println(output);              
                //io:println(j1);
            }
            error err => {
                response.statusCode = 404;
                json payload1 = " XML file cannot read ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }
        }
    }

    //API - Subcription Notification Write into File
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notificationwritetofile",
        authConfig: {
            authentication: { enabled: false }
            //scopes: ["scope2"]
        }
    }

    getsubscriptionandwriteNotification(endpoint client, http:Request req) {
        http:Response response;
        //xml payload = check req.getXmlPayload();
        var payload = req.getXmlPayload();

        //Read XML file
        match payload {
            xml result => {
                json j1 = result.toJSON({});
                string x = j1.toString();

                string[] array = x.split(" ");

                int i = 0;

                string output = "";

                while (i < lengthof array) {
                    //io:println("  " + array[i]);
                    output += array[i] + "  \n  ";
                    i = i + 1;
                }

                //string filePath4 = "./files/test.txt";
                //Create the byte channel for file path
                io:ByteChannel byteChannel = io:openFile(filePath4, io:WRITE);
                //Derive the character channel for the above byte channel
                io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

                match ch.writeJson(output) {
                    error err => {
                        response.statusCode = 400;
                        json payload1 = " Error occurred writing character stream ";
                        response.setJsonPayload(payload1);
                        _ = client->respond(response);

                    }
                    () => {
                        response.setTextPayload("Content written Sucessfully:" + untaint output);
                        _ = client->respond(response);
                    } }

            }
            error err => {
                response.statusCode = 404;
                json payload1 = " XML file cannot read ";
                response.setJsonPayload(payload1);
                _ = client->respond(response);
            }
        }
    }


    //REST SERVICES FOR SCENARIO TESTING
    @http:ResourceConfig {
        methods: ["POST"],
        path: "/resttestaccount",
        authConfig: {
             authentication: { enabled: false }
        }
    }
    //Create Account

    createAccount_test_rest_servivice(endpoint client, http:Request req) {
        http:Response response;
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered
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
                http:Response response;

                // Set 201 "Created new account" response code in the response message.
                response.statusCode = 201;
                response.setJsonPayload(payload);

                // Send response to the client.
                _ = client->respond(response);
            } else {
                json payload = { status: " Wrong Account length ", Bank_Account_No: accountId };
                http:Response response;

                response.setJsonPayload(payload);
                // Send response to the client.
                _ = client->respond(response);
            }
        }
    }

    //GET Resource that handles the HTTP GET requests

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    //Retrive Account Details

    getBankAccountDetails_test_rest_servivice(endpoint client, http:Request req, string accountId) {
        // Find the requested accountId from the map and send back it in JSON format.

        http:Response response;
        // Find the accountId is exists or not in the memory map
        if (bankDetails.hasKey(accountId)) {
            json? payload = bankDetails[accountId];

            // Set the JSON payload to outgoing response message.
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
        else {
            json payload = "accountId : " + accountId + " This account is cannot be found.";
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
    }

    //Update the Account Details

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    //Update Account Details
    updateAccountDetails_test_rest_servivice(endpoint client, http:Request req, string accountId) {
        json updatedAccount = check req.getJsonPayload();

        // Find the Account Details using AccountId
        json existingAccount = bankDetails[accountId];

        // Updating inserted Account Details
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

        http:Response response;
        // Set the JSON payload to outgoing response message.
        response.setJsonPayload(existingAccount);
        // Send response to the client.
        _ = client->respond(response);
    }
    //Delete Account

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/resttestaccount/{accountId}",
        authConfig: {
            authentication: { enabled: false }
        }
    }

    deleteAccount_test_rest_servivice(endpoint client, http:Request req, string accountId) {

        http:Response response;
        //Find the accountId is exists or not
        if (bankDetails.hasKey(accountId)){
            // Remove the requested account from the memory map.
            _ = bankDetails.remove(accountId);

            json payload = "Account_Details : " + accountId + " Deleted.";
            // Set a generated payload with status.
            response.setJsonPayload(payload);
            // Send response to the client.
            _ = client->respond(response);
        }

        else {
            json payload = "Account : " + accountId + " not found.";
            // Set a generated payload with order status.
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
        }
    }
}
