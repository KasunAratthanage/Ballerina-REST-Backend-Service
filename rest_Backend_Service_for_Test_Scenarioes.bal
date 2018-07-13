//Scenario - Bank Account Management Bckend Services

//Import Ballerina http library packages
//Package contains fuctions annotaions and connectores
import ballerina/http;
import ballerina/io;
import ballerina/runtime;
import ballerina/log;


//This service is accessible at port
//Ballerina client can be used to connect to the created HTTPS listener
endpoint http:SecureListener ep {
    port: 9098,

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

        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;

        // Check the Bank_Account_No is null or not entered
        if (Bank_Account_No == null || Bank_Account_No.toString().length() == 0)    {
            json payload = { status: " Please Enter Your Bank Account Number " };

            http:Response response;
            response.setJsonPayload(payload);
            // Set 204 "No content" response code in the response message.
            response.statusCode = 204;
            _ = client->respond(response);
        } else {
            string accountId = Bank_Account_No.toString();
            bankDetails[accountId] = accountReq;

            // Create response message.
            json payload = { status: " Account has been created sucessfully ", Bank_Account_No: accountId };
            http:Response response;

            // Set 201 "Created new account" response code in the response message.
            response.statusCode = 201;
            response.setJsonPayload(payload);

            // Send response to the client.
            _ = client->respond(response);
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
            scopes: ["scope2"]
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
        string filePath = "./files/test.json";

        //Create the byte channel for file path
        io:ByteChannel byteChannel = io:openFile(filePath, io:READ);
        //Derive the character channel for the above byte channel
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        match ch.readJson() {
            json result => {

                int j = 0;
                while (j < 10) {
                    runtime:sleep(delay);
                    io:println(j + " Waiting ");

                    j = j + 1;

                    if (j == 1) {
                        break;
                    }
                }

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
                throw err;
            }
        }
    }

    //Write file with delay

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/writeJSONFile",
        authConfig: {
            scopes: ["scope2"]
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
        if (Bank_Account_No == null || Bank_Account_No.toString().length() == 0)    {
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

            string filePath = "./files/test1.json";
            //Create the byte channel for file path
            io:ByteChannel byteChannel = io:openFile(filePath, io:WRITE);
            //Derive the character channel for the above byte channel
            io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

            match ch.writeJson(accountReq) {
                error err => {
                    io:println(accountReq);
                    throw err;
                }
                () => {

                    int j = 0;
                    while (j < 10) {
                        runtime:sleep(delay);
                        io:println(j + " Waiting ");

                        j = j + 1;

                        if (j == 1) {
                            break;
                        }
                    }

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
                    //io:println("Content written successfully");
                }
            }
        }
    }

    // Provide defferent content types service

    //XML to JSON conversion
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/readxmltojson",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    readBankAccountDetailsXML(endpoint client, http:Request req) {
        http:Response response;
        string filePath = "./files/test.xml";

        //Create the byte channel for file path
        io:ByteChannel byteChannel = io:openFile(filePath, io:READ);
        //Derive the character channel for the above byte channel
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        //Read XML file
        match ch.readXml() {
            xml result => {
                json j1 = result.toJSON({});

                io:println(j1);
                response.setJsonPayload(j1);
                _ = client->respond(response);

                io:println(result);
            }
            error err => {
                response.statusCode = 404;
                json payload = " XML file cannot read ";
                response.setJsonPayload(payload);

                _ = client->respond(response);

                throw err;
            }
        }
    }

    //JSON to XML conversion
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/readjsontoxml",
        authConfig: {
            scopes: ["scope2"]
        }
    }

    readBankAccountDetailsJSON(endpoint client, http:Request req) {
        http:Response response;
        string filePath = "./files/test.json";

        //Create the byte channel for file path
        io:ByteChannel byteChannel = io:openFile(filePath, io:READ);
        //Derive the character channel for the above byte channel
        io:CharacterChannel ch = new io:CharacterChannel(byteChannel, "UTF8");

        match ch.readJson() {
            json result => {
                //Read JSON and provide XML
                var j1 = result.toXML({});
                match j1 {
                    xml value => {
                        response.setXmlPayload(value);
                        _ = client->respond(response);
                    }
                    error err => {
                        response.statusCode = 500;
                        response.setPayload(err.message);
                        _ = client->respond(response);
                        throw err;
                    }
                }
            }
            error err => {
                response.statusCode = 404;
                json payload = " XML file cannot read ";
                response.setJsonPayload(payload);
                _ = client->respond(response);
                throw err;
            }
        }
    }
}
