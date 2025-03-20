--Overview of exactly what my app does
-- Emerald App is a banking app for minecraft
-- It allows you to create a bank account 
-- Deposit and withdraw money
-- Check your balance
-- Send money to other players
-- Check your transaction history
-- Check your account information

-- How it works
-- The app uses a central server to store all the data
-- The server is a separate program that runs on a seperate computer
-- The server uses a database to store all the data
-- The client app will connect to the server
-- The Client app will only make requests to the server
-- The server will handle all the requests and return the data to the client app
-- The server will also handle all the transactions and update the database
-- The Client app will funtion using commands 
-- Command 1. Create account = emapp create <username> <password>
-- Response = "Confirm Password: "
-- If the password is correct, the account will be created
-- Response = "Account created successfully"
-- Command 2. Login = emapp login <username> <password>
-- Response = "Login successful"
-- Response = "Is this your home computer? Would you like to stay logged in? (y/n)"
-- If the user is logged in, the app will store the session token
-- Command 3. Deposit = emapp deposit
-- Response = "Please visit your local Emerald App Institution to deposit your emeralds!"
-- Command 4. Withdraw = emapp withdraw
-- Response = "Please visit your local Emerald App Bank to withdraw your emeralds!"
-- (side note: The Emerald App Bank will have a special computer that will allow you to withdraw and deposit emeralds)
-- Command 5. Balance = emapp balance
-- Response = "Your current balance is: <balance>"
-- Command 6. Send = emapp pay <username> <amount>
-- Response = "Are you sure you want to send <amount> emeralds to <username>? (y/n)"
-- If the user confirms, the transaction will be processed
-- Response = "Transaction successful"
-- Command 7. Request = emapp request <username> <amount>
-- Response = "Are you sure you want to request <amount> emeralds from <username>? (y/n)"
-- If the user confirms, the request will be sent to the other user
-- Response = "Request sent successfully"
-- Command 8. Notifications = emapp noti
-- Response = "You have <number> notifications"
-- Response = list of notifications
-- Command 9 . History = emapp history
-- Response = "Your transaction history is: <history>"
-- Command 10. Account = emapp account
-- Response = "Your account information is: <account>"
-- Command 11. Change Password = emapp changepass <oldpassword> <newpassword>
-- Response = "Confirm new password: "
-- If the password is correct, the password will be changed
-- Response = "Password changed successfully"
-- Command 11. Change Username = emapp changeuser <oldusername> <newusername>
-- Response = "Confirm new username: "
-- If the username is correct, the username will be changed
-- Response = "Username changed successfully"
-- Command x. Logout = emapp logout
-- Response = "Logout successful"

-- The Client app will store session data
-- The Client app will store the username
-- The Client app will store the password

-- Handeling Requests
-- The server will handle all the requests and return the data to the client app as a notification
-- Emerald Banking App Client
local args = {...}

-- Configuration
local CONFIG_FILE = "emerald_config"
local SERVER_ID = 1  -- Change this to your server computer ID

-- Session data
local session = {
    loggedIn = false,
    username = nil,
    token = nil
}

-- Load saved session
local function loadSession()
    if fs.exists(CONFIG_FILE) then
        local file = fs.open(CONFIG_FILE, "r")
        local data = textutils.unserialize(file.readAll())
        file.close()
        if data then
            session = data
        end
    end
end

-- Save session
local function saveSession()
    local file = fs.open(CONFIG_FILE, "w")
    file.write(textutils.serialize(session))
    file.close()
end

-- Send request to server
local function sendRequest(action, data)
    rednet.open("back")  -- Adjust modem side as needed
    rednet.send(SERVER_ID, {
        action = action,
        data = data,
        token = session.token
    }, "emerald_bank")
    local sender, response = rednet.receive("emerald_bank", 5)
    rednet.close()
    return response
end

-- Command handlers
local commands = {
    create = function(username, password)
        if not username or not password then
            print("Usage: emapp create <username> <password>")
            return
        end
        
        write("Confirm Password: ")
        local confirm = read("*")
        if confirm ~= password then
            print("Passwords do not match!")
            return
        end
        
        local response = sendRequest("create", {
            username = username,
            password = password
        })
        print(response.message)
    end,
    
    login = function(username, password)
        if not username or not password then
            print("Usage: emapp login <username> <password>")
            return
        end
        
        local response = sendRequest("login", {
            username = username,
            password = password
        })
        
        if response and response.success then
            print("Login successful")
            local answer = read()
            
            session.loggedIn = true
            session.username = username
            session.token = response.token

            saveSession()
        else
            print(response and response.message or "Failed to connect to server")
        end
    end,

    account = function()
        if not session.loggedIn then
            print("Please login first")
            return
        end
        
        local response = sendRequest("account", {})
        print("Your account information is: " .. response.account)
    end,
    
    balance = function()
        if not session.loggedIn then
            print("Please login first")
            return
        end
        local response = sendRequest("balance", {})
        print("Your current balance is: " .. response.balance .. " emeralds")
    end,
    
    pay = function(recipient, amount)
        if not session.loggedIn then
            print("Please login first")
            return
        end
        
        if not recipient or not amount then
            print("Usage: emapp pay <username> <amount>")
            return
        end
        
        amount = tonumber(amount)
        if not amount then
            print("Invalid amount")
            return
        end
        
        write("Are you sure you want to send " .. amount .. " emeralds to " .. recipient .. "? (y/n): ")
        local confirm = read():lower()
        
        if confirm == "y" then
            local response = sendRequest("transfer", {
                recipient = recipient,
                amount = amount
            })
            print(response.message)
        else
            print("Transaction cancelled")
        end
    end,

    help = function(page)
        pagenumber = tonumber(page)
        if not page then
            pagenumber = 1
        end
        if pagenumber == 1 then
            print("---------------------------")
            print("Welcome to the Emerald \nBanking App!")
            print("")
            print(" This app allows you to \nmanage your bank account.")
            print(" To get started, please \nlogin or create an account.")
            print(" You can use \n'emapp help <page number>'\nto move to another page.")
            print("")
            print("page 1/5")
            print("--------------------------")
        else if pagenumber == 2 then
            print("--------------------------")
            print("* create <username> <password> - Create a new \n  account")
            print("* login <username> <password> - Login to your \n  account")
            print("* balance - Check your balance")
            print("* pay <username> <amount> - Send money to another \n  user")
            print("# request <username> <amount> - Request money from \n  another user")
            print("")
            print("page 2/5")
            print("--------------------------")
        else if pagenumber == 3 then
            print("--------------------------")
            print("# addfav <username> - Add a user to your favorites")
            print("# removefav <username> - Remove a user from your \n  favorites")
            print("# favs - Check your favorites")
            print("# deposit - Deposit money into your account")
            print("# withdraw - Withdraw money from your account")
            print("")
            print("page 3/5")
            print("--------------------------")
        else if pagenumber == 4 then
            print("--------------------------")
            print("# noti - Check your notifications")
            print("# history - Check your transaction history")
            print("# account - Check your account information")
            print("# changepass <oldpassword> <newpassword> - Change \n  your password")
            print("# changeuser <oldusername> <newusername> - Change \n  your username")
            print("")
            print("page 4/5")
            print("--------------------------")
        else if pagenumber == 5 then
            print("--------------------------")
            print("* logout - Logout of your\naccount")
            print("")
            print("page 5/5")
            print("--------------------------")
        end
        end
        end
        end
        end
    end,
    
    logout = function()
        session.loggedIn = false
        session.username = nil
        session.token = nil
        fs.delete(CONFIG_FILE)
        print("Logout successful")
    end
}

-- Main program
loadSession()

if #args == 0 then
    print("---------------------------")
    print("Welcome to the Emerald \nBanking App!")
    print("")
    print(" This app allows you to \nmanage your bank account.")
    print(" To get started, please \nlogin or create an account.")
    print(" You can use \n'emapp help <page number>'\nto move to another page.")
    print("")
    print("page 1/5")
    print("--------------------------")
    return
end

local command = args[1]
table.remove(args, 1)

if commands[command] then
    commands[command](table.unpack(args))
else
    print("Unknown command: " .. command)
end