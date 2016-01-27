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
Class NetUserHandle Final
	' Constructor(s):
	Method New(Connection:Socket, Address:SocketAddress=Null)
		Self.Connection = Connection
		Self.Address = Address
	End
	
	' Fields (Protected):
	Protected
	
	Field Connection:Socket
	Field Address:SocketAddress
	
	Public
End