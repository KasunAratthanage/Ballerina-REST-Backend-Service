// Scenario - Bank Account Management System

// Import Ballerina http library packages
// Package contains fuctions annotaions and connectores

import ballerina/http;
import ballerina/io;


// This service is accessible at port no 9096

endpoint http:Listener listener {
    port:9098
};

// Implementation of REST service using memory map.

map<json> bankDetails;

// RESTful service.
// A service is a network accessible API
// Resource is a invokable API method
// Accessible at a '/accountmgt' base path
// accountMgt bound to the listener on port

@http:ServiceConfig { basePath: "/accountmgt" }
service<http:Service> accountMgt bind listener {

//-----------------------------------------------POST--------------------------------------------------

// Implemet HTTP POST request for insert Account Deatils
// Can access '/account' path to insert account details
// Resource controll the POST request

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/account"
    }
	
    //Create Account 

    createAccount(endpoint client, http:Request req) {
        json accountReq = check req.getJsonPayload();
        json Bank_Account_No = accountReq.Account_Details.Bank_Account_No;
        
	// Check the Bank_Account_No is null or not entered 	
	if(Bank_Account_No == null || Bank_Account_No.toString().length() == 0)	{
		json payload = { status: " Please Enter Your Bank Account Number "};
        http:Response response;
        response.setJsonPayload(payload);

    	// Set 204 "No content" response code in the response message.
		response.statusCode = 204;
		_ = client->respond(response);
	}

	else {

        string accountId = Bank_Account_No.toString();
        bankDetails[accountId] = accountReq;
	  
        // Create response message.
        json payload = { status: " Account has been created sucessfully ", Bank_Account_No: accountId};
        http:Response response;
        response.setJsonPayload(payload);

        // Set 201 "Created new account" response code in the response message.
        response.statusCode = 201;

        // Set 'Location' header in the response message.This can be used by the client to locate the newly added details.
        response.setHeader("Location", "http://localhost:9094/accountmgt/account/" +accountId);
	
        // Send response to the client.
        _ = client->respond(response);
	}

		

    }

	// curl command for POST method
	// curl -v -X POST -d '{ "Account_Details": { "Bank_Account_No": "12345", "Name": "Kasun","Account_type":"Savings","Branch":"Colombo"}}'
	// "http://localhost:9091/accountmgt/account" -H "Content-Type:application/json"


    //-----------------------------------------------GET--------------------------------------------------------

    // Implemet HTTP GET request for retrive Account Deatils
    // Can access '/account/<accountId> path

    // Resource controll the GET request
    @http:ResourceConfig {
        methods: ["GET"],
        path: "/account/{accountId}"
    }

    //retrive Account Details
    retriveBankAccountDetails(endpoint client, http:Request req, string accountId) {
        // Find the requested accountId from the map and retrieve it in JSON format.

        //json? payload = bankDetails[accountId];
	
        http:Response response;
       	// Find the accountId is exists or not
	if (bankDetails.hasKey(accountId)) {
	json? payload = bankDetails[accountId];

	// Set the JSON payload to outgoing response message.
        response.setJsonPayload(payload);
        
        // Send response to the client.
        _ = client->respond(response);
	
	}

	else{

		json payload = "accountId : " + accountId + " This account is cannot be found.";
		response.setJsonPayload(payload);
                
        	// Send response to the client.
        	_ = client->respond(response);

	    }
   }

	//curl command for GET method
	//curl "http://localhost:9091/accountmgt/account/12345" 


//---------------------------------------------------PUT-------------------------------------------------


	//Implemet HTTP PUT request for update inserted Account Deatils
   	//Can access '/account/<accountId> path	

	@http:ResourceConfig {
        methods: ["PUT"],
        path: "/account/{accountId}"
    	}
	
	//update Account Details
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

    	//Curl commands for PUT method 	
	//curl -X PUT -d '{ "Account_Details": {"Name": "KasunDantha"}}' "http://localhost:9091/accountmgt/account/12345" -H "Content-Type:application/json"

//---------------------------------------------------------DELETE-----------------------------------------------

@http:ResourceConfig {
        methods: ["DELETE"],
        path: "/account/{accountId}"
    }
    deleteAccount(endpoint client, http:Request req, string accountId) {
                    
       
	http:Response response;
    
        //Find the accountId is exists or not 
	if(bankDetails.hasKey(accountId)){
	
        // Remove the requested order from the map.
        _ = bankDetails.remove(accountId);

        json payload = "Account_Details : " + accountId + " Deleted.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);
	}
	
	else{
	 json payload = "Account : " + accountId + " not found.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client.
        _ = client->respond(response);

	}
    	
	}

	//curl command for DELETE
	//curl -X DELETE "http://localhost:9091/accountmgt/account/12345"

}

