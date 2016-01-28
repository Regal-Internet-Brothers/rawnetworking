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
Class NetworkUser ' Final
	' Functions:
	Function Equal:Bool(X:NetworkUser, Y:NetworkUser)
		If (X = Y) Then
			Return True
		Endif
		
		Return ((X.Connection = Y.Connection) And (X.Address = Y.Address))
	End
	
	' Constructor(s):
	
	' The 'Connection' argument represents a 'Socket' usable
	' to contact the entity this object represents.
	' The 'Address' argument is only technically required
	' for UDP, but is supplied regardless. (May or may not be 'Null')
	Method New(Connection:Socket, Address:SocketAddress)
		Self.Connection = Connection
		Self.Address = Address
	End
	
	Method New(Connection:Socket)
		Self.Connection = Connection
		Self.Address = Connection.RemoteAddress
	End
	
	' Methods:
	Method Equals:Bool(U:NetworkUser)
		Return Equal(Self, U)
	End
	
	' Properties (Public):
	Method Connection:Socket() Property
		Return Self._Connection
	End
	
	Method Address:SocketAddress() Property
		Return Self._Address
	End
	
	' Properties (Protected):
	Protected
	
	Method Connection:Void(Input:Socket) Property
		Self._Connection = Input
		
		Return
	End
	
	Method Address:Void(Input:SocketAddress) Property
		Self._Address = Input
		
		Return
	End
	
	Public
	
	' Fields (Protected):
	Protected
	
	Field _Connection:Socket
	Field _Address:SocketAddress
	
	Public
End