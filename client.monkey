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
Interface ClientApplication Extends NetApplication
	' Methods:
	
	' The return-value indicates if 'C' should start receiving messages.
	Method OnClientBound:Bool(C:Client, Port:Int, Response:Bool)
End

' Classes:

' This is used to connect to a 'Server'; not to be confused with 'NetHandle'.
Class Client Extends NetManager<ClientApplication> Implements IOnConnectComplete, IOnSendComplete, IOnReceiveComplete ' Final
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
	
	' Destructor(s):
	Method Close:Void()
		Super.Close()
		
		' Restore the correct flags:
		AcceptingMessages = False
		
		Return
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
	
	' This method's return-value indicates if we successfully started accepting messages.
	' If we are already accepting, this will return 'False'.
	' Usage of this method is not safe unless 'IsOpen' is 'True'.
	Method AcceptMessages:Bool()
		If (AcceptingMessages) Then
			Return False
		Endif
		
		Local P:= Allocate()
		
		Connection.ReceiveAsync(P.Data, P.Offset, , onComplete:IOnReceiveComplete )
		
		' Return the default response.
		Return True
	End
	
	Method Send:Int(P:Packet)
		Connection.Send(P.Data, P.Offset, P.Length)
		
		Return 0
	End
	
	Method SendAsync:Void(P:Packet)
		MarkTransmission(P)
		
		Connection.SendAsync(P.Data, P.Offset, P.Length, Self)
		
		Return
	End
	
	' Methods (Protected):
	Protected
	
	Method OnConnectComplete:Void(Success:Bool, Source:Socket)
		' Tell our parent what's going on.
		Local Response:= Parent.OnClientBound(Self, Port, Success)
		
		If (Success) Then
			Self.Connection = Source
			
			If (Response) Then
				AcceptMessages()
			Endif
		Endif
		
		Return
	End
	
	Method OnSendComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		' Finish the transmission, then keep the 'Packet' object. ('Null' safe operation)
		Free(FinishTransmission(Data, False)) ' True
		
		Return
	End
	
	Method OnReceiveComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		If (IsOpen) Then
			Local P:= __UseInboundPacket()
			
			Connection.ReceiveAsync(P.Data, P.Offset, P.Length, Self)
		Else
			__ClearInboundPacket()
		Endif
	End
	
	Public
	
	' Fields (Protected):
	Protected
	
	' Booleans / Flags:
	Field AcceptingMessages:Bool = False
	
	Public
End