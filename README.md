# Ballerina REST API-Backend-Service : Scenario - Bank Account Management Model


curl command for POST method

curl -v -X POST -d '{ "Account_Details": { "Bank_Account_No": "ACC001", "Name": "Kasun","Account_type":"Savings","Branch":"Colombo"}}' "http://localhost:9098/accountmgt/account" -H "Content-Type:application/json"


curl command for GET method

curl "http://localhost:9098/accountmgt/account/ACC001" 


Curl commands for PUT method 	

curl -X PUT -d '{ "Account_Details": { "Bank_Account_No": "ACC001", "Name": "Kasun Updated","Account_type":"Mobile","Branch":"Galle"}}' "http://localhost:9098/accountmgt/account/ACC001" -H "Content-Type:application/json"


curl command for DELETE

curl -X DELETE "http://localhost:9098/accountmgt/account/ACC001"
