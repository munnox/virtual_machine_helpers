# This is a super **SIMPLE** example of how to create a very basic powershell webserver
# 2019-05-18 UPDATE — Created by me and and evalued by @jakobii and the comunity.
# Source from https://gist.githubusercontent.com/19WAS85/5424431/raw/3a827c9f4e4065fd4550421fbbc4ad68ddf2adab/powershell-web-server.ps1


# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on
$http.Prefixes.Add("http://localhost:8080/")

# Start the Http Server 
$http.Start()

$text = "content text string"



# Log ready message to terminal 
if ($http.IsListening) {
    write-host " HTTP Server Ready!  " -f 'black' -b 'gre'
    write-host "now try going to $($http.Prefixes)" -f 'y'
    write-host "then try going to $($http.Prefixes)other/path" -f 'y'
    write-host "then to exit go to $($http.Prefixes)quit" -f 'y'
}

function query_unpacker {
    # From https://stackoverflow.com/questions/53766303/how-do-i-split-parse-a-url-string-into-an-object
    param($query_string);
    # Type fix from https://stackoverflow.com/questions/38408729/unable-to-find-type-system-web-httputility-in-powershell
    Add-Type -AssemblyName System.Web
    $ParsedQueryString = [System.Web.HttpUtility]::ParseQueryString($query_string)

    $i = 0
    $queryParams = @()
    foreach($QueryStringObject in $ParsedQueryString){
        $queryObject = New-Object -TypeName psobject
        $queryObject | Add-Member -MemberType NoteProperty -Name Query -Value $QueryStringObject
        $queryObject | Add-Member -MemberType NoteProperty -Name Value -Value $ParsedQueryString[$i]
        $queryParams += $queryObject
        $i++
    }
    return $queryParams;
}


# INFINTE LOOP
# Used to listen for requests
while ($http.IsListening) {



    # Get Request Url
    # When a request is made in a web browser the GetContext() method will return a request object
    # Our route examples below will use the request object properties to decide how to respond
    $context = $http.GetContext()


    # ROUTE EXAMPLE 1
    # http://127.0.0.1/
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        # the html/data you want to send to the browser
        # you could replace this with: [string]$html = Get-Content "C:\some\path\index.html" -Raw
        [string]$html = "
        <h1>A Powershell Webserver</h1>
        <p>home page</p>
        <p>$text</p>
        <a href='/some/form'>form</a>
        <a href='/quit'>quit</a>
        " 
        
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
        $context.Response.OutputStream.Close() # close the response
    
    }



    # ROUTE EXAMPLE 2
    # http://127.0.0.1/some/form'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/some/form') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        [string]$html = "
        <h1>A Powershell Webserver</h1>
        <form action='/some/post' method='post'>
            <p>A Basic Form</p>
            <p>fullname</p>
            <input type='text' name='fullname'>
            <p>message</p>
            <textarea rows='4' cols='50' name='message'></textarea>
            <br>
            <input type='submit' value='Submit'>
        </form>
        "

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
    }

    # ROUTE EXAMPLE 3
    # http://127.0.0.1/some/post'
    if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/some/post') {

        # decode the form post
        # html form members need 'name' attributes as in the example!
        $FormContent = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
        Write-Host $FormContent -f 'Green'

        $query = query_unpacker($FormContent)
        Write-host $query

        # the html/data
        [string]$html = "<h1>A Powershell Webserver</h1><p>Post Successful!</p><p>$FormContent</p>" 

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.OutputStream.Close() 
    }


    # powershell will continue looping and listen for new requests...

    # ROUTE EXAMPLE 4
    # http://localhost:8080/quit'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/quit')
    {
        $http.Close()
    }

}

Write-Host "Server Finished" -f 'Green'
$http.Dispose()
Remove-Variable http

# Note:
# To end the loop you have to kill the powershell terminal. ctrl-c wont work :/