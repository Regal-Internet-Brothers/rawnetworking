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
Interface ServerApplication Extends NetApplication
	' Methods:
	
	' The return-value of this methods indicates if the server should start accepting "clients" ('NetUserHandles').
	Method OnServerBound:Bool(Host:Server, Port:Int, Response:Bool)
	
	' The return-value indicates if more "clients" should be accepted.
	Method OnServerUserAccepted:Bool(Host:Server, User:NetUserHandle)
End

' Classes:
Class Server Extends NetManager<ServerApplication> Implements IOnBindComplete, IOnAcceptComplete ' Final
	' Constructor(s):
	
	' This overload automatically calls 'Begin' using 'Port'.
	Method New(Parent:ServerApplication, Port:Int, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketPoolSize)
		
		Begin(Port)
	End
	
	' This overload does not call 'Begin'.
	Method New(Parent:ServerApplication, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(Parent, PacketPoolSize)
	End
	
	' Destructor(s):
	Method Close:Void()
		Super.Close()
		
		' Restore the correct flags:
		Accepting = False
		
		Return
	End
	
	' Methods (Public):
	Method Begin:Void(RemotePort:Int, Protocol:String="server")
		' Set the internal port. (Done first for safety)
		Port = RemotePort
		
		' Allocate a 'Socket' using 'Protocol'.
		Local S:= New Socket(Protocol)
		
		' Attempt to bind 'S'. If successful,
		' 'S' will become 'Connection'.
		S.BindAsync("", RemotePort, Self)
		
		Return
	End
	
	#Rem
		This is used to begin accepting "clients" ('NetUserHandles').
		The return-value of this method indicates if we could start accepting clients again.
		If we are already accepting "clients", this will return 'False'.
		
		Usage of this method is not safe unless 'IsOpen' is 'True'.
	#End
	
	Method AcceptClients:Bool()
		If (Accepting) Then
			Return False
		Endif
		
		Connection.AcceptAsync(Self)
		
		' Return the default response.
		Return True
	End
	
	' Methods (Protected):
	Protected
	
	Method OnBindComplete:Void(Bound:Bool, Source:Socket)
		' Tell our parent what's going on.
		Local Response:= Parent.OnServerBound(Self, Port, Bound)
		
		If (Not Bound) Then
			Return
		Endif
		
		Self.Connection = Source
		
		' Check if our parent wants us to accept "clients" initially.
		If (Response) Then
			' They said yes, start accepting.
			AcceptClients()
		Endif
	End
	
	Method OnAcceptComplete:Void(Connection:Socket, Source:Socket)
		If (Connection <> Self.Connection) Then
			Return
		Endif
		
		' Ask our parent if we should continue accepting "clients" (If available. - 'NetUserHandles').
		If (Parent.OnServerUserAccepted(Self, New NetUserHandle(Source))) Then
			' Our parent said yes, accept more.
			AcceptClients()
		Endif
		
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