Strict

Public

' Imports (Public):
Import core
Import packet
Import user

' Imports (Private):
Private

Import brl.socket

Public

' Interfaces:
Interface ServerApplication Extends NetApplication
	' Methods:
	
	' The return-value of this method indicates if the server should start accepting "clients" ('NetworkUsers').
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
	
	' This is called when a "user" disconnects from a 'Server'.
	Method OnDisconnection:Void(Host:Server, User:NetworkUser)
	
	' The return-value indicates if more "clients" should be accepted.
	Method OnServerUserAccepted:Bool(Host:Server, User:NetworkUser)
End

' Classes:
Class Server Extends NetworkManager<ServerApplication> Implements IOnBindComplete, IOnAcceptComplete ' Final
	' Functions:
	Function GetProtocol:String(Protocol:ProtocolType)
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				Return "server"
			Case TRANSPORT_PROTOCOL_UDP
				Return "datagram"
		End Select
		
		Return ""
	End
	
	Function GetProtocol:ProtocolType(Protocol:String)
		Select Protocol
			Case "datagram"
				Return TRANSPORT_PROTOCOL_UDP
			Default ' Case "server"
				Return TRANSPORT_PROTOCOL_TCP
		End Select
	End
	
	' Constructor(s):
	
	' This overload automatically calls 'Begin' using 'Port'.
	Method New(Port:Int, Parent:ServerApplication, Protocol:ProtocolType=TRANSPORT_PROTOCOL_TCP, PacketSize:Int=Default_PacketSize, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketSize, PacketPoolSize)
		
		Begin(Port, Protocol)
	End
	
	' This overload does not call 'Begin'.
	Method New(Parent:ServerApplication, PacketSize:Int=Default_PacketSize, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketSize, PacketPoolSize)
	End
	
	' Destructor(s):
	Method Close:Void()
		Super.Close()
		
		' Restore the correct flags:
		Accepting = False
		
		Return
	End
	
	' Methods (Public):
	Method Begin:Void(RemotePort:Int, Protocol:ProtocolType)
		Self.Protocol = Protocol
		
		RawBegin(RemotePort, GetProtocol(Protocol))
		
		Return
	End
	
	Method Begin:Void(RemotePort:Int, Protocol:String="server")
		Self.Protocol = GetProtocol(Protocol)
		
		RawBegin(RemotePort, Protocol)
		
		Return
	End
	
	#Rem
		This is used to begin accepting "clients" ('NetworkUsers').
		The return-value of this method indicates if we could start accepting clients again.
		If we are already accepting "clients", this will return 'False'.
		
		Usage of this method is not safe unless 'IsOpen' is 'True'.
	#End
	
	Method AcceptClients:Bool(Force:Bool=False)
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				If (Accepting And Not Force) Then
					Return False
				Endif
				
				Connection.AcceptAsync(Self)
				
				Accepting = True
				
				Return True ' Accepting
		End Select
		
		' Return the default response.
		Return False
	End
	
	Method Send:Int(P:Packet, U:NetworkUser)
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				Return RawSendPacketTo(U.Connection, P)
			Case TRANSPORT_PROTOCOL_UDP
				Return RawSendPacketTo(Connection, U.Address, P)
		End Select
		
		Return 0
	End
	
	Method SendAsync:Void(P:Packet, U:NetworkUser)
		Select Protocol
			Case TRANSPORT_PROTOCOL_TCP
				RawSendPacketToAsync(U.Connection, P)
			Case TRANSPORT_PROTOCOL_UDP
				RawSendPacketToAsync(Connection, U.Address, P)
		End Select
		
		Return
	End
	
	' Methods (Protected):
	Protected
	
	Method OnDisconnectMessage:Void(S:Socket) ' Final
		' Notify the user.
		Parent.OnDisconnection(Self, Represent(S, IsTCPSocket))
		
		Return
	End
	
	Method RawBegin:Void(RemotePort:Int, Protocol:String="server")
		' Allocate a 'Socket' using 'Protocol'.
		Local S:= New Socket(Protocol)
		
		' Attempt to bind 'S'. If successful,
		' 'S' will become 'Connection'.
		S.BindAsync("", RemotePort, Self)
		
		Return
	End
	
	' BRL:
	Method OnBindComplete:Void(Bound:Bool, HostSocket:Socket)
		Self.Port = HostSocket.LocalAddress.Port ' RemoteAddress
		
		If (Bound) Then
			Self.Connection = HostSocket
		Endif
		
		' Tell our parent what's going on.
		Local Response:= Parent.OnServerBound(Self, Self.Port, Bound)
		
		If (Not Bound) Then
			Close()
			
			Return
		Endif
		
		' Check if our parent wants us to accept "clients" initially.
		If (Response) Then
			' They said yes, start accepting.
			AcceptClients()
		Endif
	End
	
	Method OnAcceptComplete:Void(NewConnection:Socket, Source:Socket)
		' Ask our parent if we should continue accepting "clients" (If available. - 'NetworkUsers').
		If (Parent.OnServerUserAccepted(Self, Represent(NewConnection, True))) Then
			' Our parent said yes, accept more.
			AcceptClients(True)
		Else
			Accepting = False
		Endif
		
		' Start accepting messages from 'NewConnection'. (Remote user)
		AcceptMessagesWith(NewConnection)
		
		Return
	End
	
	Public
	
	' Properties:
	' Nothing so far.
	
	' Fields (Protected):
	Protected
	
	' Booleans / Flags:
	Field Accepting:Bool = False
	
	Public
End