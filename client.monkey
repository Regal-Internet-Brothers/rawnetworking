Strict

Public

' Imports (Public):
Import packet
Import handle

' Imports (Private):
Private

Import brl.socket

Public

' Interfaces:
Interface ClientApplication
	' Methods:
	Method OnClientBound:Void(C:Client, Port:Int, Response:Bool)
End

' Classes:

' This is used to connect to a 'Server'; not to be confused with 'NetHandle'.
Class Client Extends NetManager<ClientApplication> Implements IOnConnectComplete ' Final
	' Constructor(s):
	
	' This overload automatically calls 'Begin'.
	Method New(Hostname:String, Port:Int, Parent:ClientApplication, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketPoolSize)
		
		Begin(Hostname, Port)
	End
	
	' This overload does not call 'Begin'.
	Method New(Parent:ClientApplication, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketPoolSize)
	End
	
	' Methods (Public):
	
	' This connects to a remote 'Server' using 'Hostname' and 'Port' over 'Protocol'.
	Method Begin:Void(Hostname:String, Port:Int, Protocol:String="stream")
		' Set the internal port. (Done first for safety)
		Port = RemotePort
		
		' Allocate a 'Socket' using 'Protocol'.
		Local S:= New Socket(Protocol)
		
		' Attempt to connect to 'Hostname' using 'Port'.
		' If this is successful, 'S' will become 'Connection'.
		S.ConnectAsync(Hostname, Port, Self)
		
		Return
	End
	
	Method Send:Int(P:Packet)
		Return 0
	End
	
	Method SendAsync:Void()
		Return
	End
	
	' Methods (Protected):
	Protected
	
	Method OnConnectComplete:Void(Success:Bool, Source:Socket)
		' Tell our parent what's going on.
		Parent.OnClientBound(Self, Port, Success)
		
		Return
	End
	
	Public
End