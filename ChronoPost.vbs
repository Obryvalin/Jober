if Wscript.Arguments.Length <> 3  then 
	wscript.echo "USAGE Server,type, MSG"
	wscript.quit -1
end if

SERV = Wscript.Arguments(0)
MSGTYPE = Wscript.Arguments(1)
MSG  = Wscript.Arguments(2)

DSN = "PGSQL_sw0834"
DBUSER = "postgres"
DBPASS = "postgres"
Set conn = CreateObject("ADODB.Connection")
conn.Open dsn, dbuser, dbpass

insert = "insert into log values(current_timestamp,'" & SERV & "','" & MSGTYPE & "','" & MSG & "')"
set lol = conn.Execute(insert)
If conn.errors.Count > 0 Then
    Dim counter
    WScript.echo "Error during insert"
    For counter = 0 To conn.errors.Count
        WScript.echo "Error #" & DataConn.errors(counter).Number
        WScript.echo "  Description(" & DataConn.errors(counter).Description & ")"
    Next

End If