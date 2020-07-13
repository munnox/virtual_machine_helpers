# This is a super **SIMPLE** example of how to create a very basic powershell webserver
# 2019-05-18 UPDATE — Created by me and and evalued by @jakobii and the comunity.
# Source from https://gist.githubusercontent.com/19WAS85/5424431/raw/3a827c9f4e4065fd4550421fbbc4ad68ddf2adab/powershell-web-server.ps1
# Been updated and tweaked by Robert Munnoch to server as a simple web agent for hyper-V

# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on
$http.Prefixes.Add("http://localhost:8080/")

# Start the Http Server 
$http.Start()

$text = "content text string"
function Get-ScriptPath
{
    Split-Path $myInvocation.ScriptName
}

$script_path = Get-ScriptPath;


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

$segment_filename = $script_path + "/current_segment.json"
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json?view=powershell-7
$segment_json = Get-Content -Path $segment_filename | ConvertFrom-Json | ConvertTo-Json

$script_path = Get-ScriptPath;
$vmlib = $script_path + "\VirtualisationLib.psm1"
Write-Host "Importing my VM module from path: " $vmlib
Import-Module $vmlib
# . .\VirtualisationLib.ps1


# INFINTE LOOP
# Used to listen for requests
while ($http.IsListening) {



    # Get Request Url
    # When a request is made in a web browser the GetContext() method will return a request object
    # Our route examples below will use the request object properties to decide how to respond
    $context = $http.GetContext()


    # ROUTE Hyper-V Index
    # http://127.0.0.1/
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url) ($($context.Request.Headers))" -f 'mag'

        # the html/data you want to send to the browser
        # you could replace this with: [string]$html = Get-Content "C:\some\path\index.html" -Raw
        [string]$html = "
        <h1>A Powershell Webserver</h1>
        <p>home page</p>
        <p>$text</p>
        <div><a href='/segment/form' target='_blank'>Write Segment</a></div>
        <div><a href='/sync/form' target='_blank'>Sync Segment</a></div>
        <div><a href='/quit' target='_blank'>Quit Server</a></div>
        " 
        
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
        $context.Response.OutputStream.Close() # close the response
    
    }



    # ROUTE segment form to write the current segment json
    # http://127.0.0.1/some/form'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/segment/form') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'


        $fromhtml = @"
<h1>A Powershell Webserver</h1>
<form action="/segment/post" method="post">
    <p>A Basic Form</p>
    <p>fullname</p>
    <input type="text" name="fullname" value="current_segment.json">
    <p>message</p>
    <textarea rows='80' cols='200' name='message'>
$segment_json
    </textarea>
    <br>
    <input type='submit' value='Submit'>
</form>
"@

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($fromhtml) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
    }

    # ROUTE segment form post
    # http://127.0.0.1/some/post'
    if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/segement/post') {

        # decode the form post
        # html form members need 'name' attributes as in the example!
        $FormContent = [System.IO.StreamReader]::new($context.Request.InputStream).ReadToEnd()

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'
        Write-Host $FormContent -f 'Green'

        $query = query_unpacker($FormContent)

        $filename = "./" + $query[0].Value
        $message = [System.Web.HttpUtility]::UrlDecode($query[1].Value)


        Write-host $query -f 'Magenta'
        Write-host "Result: Filename: " $query[0].Query $query[0].Value $filename
        Write-host "Message: " $query[1].Query $query[1].Value $message


        # Save json in file
        # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-json?view=powershell-7
        #  ConvertFrom-Json
        $filename = $script_path + "\" + $query[0].Value
        Set-Content -Path $filename -Value $query[1].Value


        # the html/data
        [string]$html = "<h1>A Powershell Webserver</h1><p>Post Successful!</p><p>$FormContent</p>" 

        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.OutputStream.Close() 
    }


    # ROUTE RAM VM host mods
    # ROUTE mode Form
    # http://127.0.0.1/some/form'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/sync/form') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        [string]$syncform = "<h1>A Powershell Webserver</h1> <form action='/sync/segment' method='post'> <p>A Basic Form</p> <input type='submit' value='Submit'> </form>"


        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($syncform) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
    }

    # http://127.0.0.1/sync/segment'
    if ($context.Request.HttpMethod -eq 'POST' -and $context.Request.RawUrl -eq '/sync/segment') {

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        $segment_filename = $script_path + "\current_segment.json"

        $new_segment = Get-Content -Path $segment_filename | ConvertFrom-Json
        # Ensure-VMSwitch $seg_network_name $seg_network_type
        Clone-VMs "$PSScriptRoot\Unattend.xml" `
            $PSScriptRoot `
            $new_segment.machines `
            $new_segment.admin_credentials.username `
            $new_segment.admin_credentials.password
        $done = "ok"
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($done) 
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) 
        $context.Response.OutputStream.Close()
    }

    # http://127.0.0.1/get_vm'
    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/get_vm') {
        
        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        $url = [url]$context.Request.RawUrl

        Write-Host $url

        $vms = Get-VM | ConvertTo-Json
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($vms) 
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