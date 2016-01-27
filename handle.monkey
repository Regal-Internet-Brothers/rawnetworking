Strict

Public

' Friends:
Friend rawnetworking.server
Friend rawnetworking.client

' Imports (Public):
' Nothing so far.

' Imports (Private):
Private

Import brl.socket

Public

' Classes:
Class NetHandle Final
	' Constructor(s):
	Method New(Connection:Socket)
		Self.Connection = Connection
	End
	
	' Fields (Protected):
	Protected
	
	Field Connection:Socket
	
	Public
End