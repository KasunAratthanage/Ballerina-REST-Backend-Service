# Ballerina REST API-Backend-Service : Scenario - Bank Account Management Model

Invoking the REST Services- Execute the following commands

Create a new bank account

curl -v -X POST -d '{ "Account_Details": { "Bank_Account_No": "ACC001", "Name": "Kasun","Account_type":"Savings","Branch":"Colombo"}}' "http://localhost:9098/accountmgt/account" -H "Content-Type:application/json"


Retrive the existing bank accounts details 

curl "http://localhost:9098/accountmgt/account/ACC001" 


Update the existing bank account details

curl -X PUT -d '{ "Account_Details": { "Bank_Account_No": "ACC001", "Name": "Kasun Updated","Account_type":"Mobile","Branch":"Galle"}}' "http://localhost:9098/accountmgt/account/ACC001" -H "Content-Type:application/json"


Delete the existing bank accounts

curl -X DELETE "http://localhost:9098/accountmgt/account/ACC001"
