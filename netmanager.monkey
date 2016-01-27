Strict

Public

' Imports (Public):
Import packetmanager
Import packet
Import user

' Imports (Private):
Private

Import brl.socket
Import brl.databuffer

Public

' Interfaces:
Interface NetApplication
	' Methods:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
	Method OnPacketReceived:Void(Data:Packet, From:NetUserHandle)
	Method OnUnknownPacket:Void(UnknownData:DataBuffer, Offset:Int, Count:Int)
End

' Classes:

' This class covers common functionality between 'Server' and 'Client'.
Class NetManager<ParentType> Extends PacketManager Implements IOnSendComplete, IOnReceiveComplete Abstract
	' Constant variable(s):
	Const PORT_AUTO:= 0
	
	' Constructor(s):
	
	' This constructor does not initiate anything.
	Method New(Parent:ParentType, PacketPoolSize:Int=Defaulk_PacketPoolSize)
		Super.New(PacketPoolSize)
		
		Self.Parent = Parent
	End
	
	' Destructor(s):
	
	' Please call-up to this destructor when extending this class.
	Method Close:Void()
		' Close our connection.
		Connection.Close()
		
		' Restore default values:
		Connection = Null
		Port = PORT_AUTO
		
		Return
	End
	
	' Methods (Public):
	
	' These messages send 'P' directly to 'S'.
	' These overloads are protocol specific,
	' and as such, are not future-proof at all:
	
	' The return-value of this method indicates
	' the underlying 'Socket.Send' method's result.
	Method RawSendPacketTo:Int(S:Socket, P:Packet)
		' Since we're not using asynchronous behavior,
		' we don't need to mark this 'Packet' object.
		Return S.Send(P.Data, P.Offset, P.Length)
	End
	
	Method RawSendPacketToAsync:Void(S:Socket, P:Packet)
		' Mark 'P', so we can take care of it later.
		MarkTransmission(P)
		
		' Send 'P' to 'S' asynchronously.
		S.SendAsync(P.Data, P.Offset, P.Length, Self)
		
		Return
	End
	
	' Methods (Protected):
	Protected
	
	Method AcceptMessagesWith:Bool(S:Socket)
		Return AcceptMessagesWith(S, Allocate())
	End
	
	' If the 'MarkPacket' argument is set to 'False',
	' this method may provide undefined behavior.
	Method AcceptMessagesWith:Bool(S:Socket, P:Packet, MarkPacket:Bool=True)
		If (MarkPacket) Then
			MarkTransmission(P)
		Endif
		
		S.ReceiveAsync(P.Data, P.Offset, P.Length, Self)
		
		' Return the default response.
		Return True
	End
	
	' This represents 'S' using a 'NetUserHandle' object.
	Method Represent:NetUserHandle(S:Socket)
		' Not very efficient, but it works for now.
		Return New NetUserHandle(S, S.RemoteAddress)
	End
	
	Method Represent:NetUserHandle(S:Socket, Address:SocketAddress)
		' Once again, not very efficient, but it works for now.
		Return New NetUserHandle(S, Address)
	End
	
	' BRL:
	Method OnSendComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		' Kill the transmission; finish the transmission, and if
		' successful, give the associated 'Packet' object back.
		KillTransmission(Data, False)
		
		Return
	End
	
	Method OnReceiveComplete:Void(Data:DataBuffer, Offset:Int, Count:Int, Source:Socket)
		If (Source <> Connection) Then
			Return
		Endif
		
		If (IsOpen) Then
			Local P:= GetTransmission(Data, False)
			
			If (P <> Null) Then
				Parent.OnPacketReceived(P, Represent(Source))
				
				' Start receiving again. (Do not mark this packet again)
				AcceptMessagesWith(Source, P, False)
			Else
				Parent.OnUnknownPacket(Data, Offset, Count)
			Endif
		Else
			' Kill the transmission, and if we don't
			' recognize the enclosed data, throw it out.
			' This behavior may change in the future.
			KillTransmission(Data, True)
		Endif
	End
	
	Public
	
	' Properties (Public):
	Method Port:Int() Property
		Return Self._Port
	End
	
	Method Connection:Socket() Property
		Return Self._Connection
	End
	
	Method IsOpen:Bool() Property
		Return (Connection <> Null)
	End
	
	' Properties (Protected):
	Protected
	
	Method Port:Void(Input:Int) Property
		Self._Port = Input
		
		Return
	End
	
	Method Connection:Void(Input:Socket) Property
		Self._Connection = Input
		
		Return
	End
	
	Public
	
	' Fields (Protected):
	Protected
	
	' This acts as our "parent application".
	Field Parent:ParentType
	
	' Networking-related:
	
	' This is the socket we use most networking operations. (Protocol-specific)
	Field _Connection:Socket
	
	' Meta:
	Field _Port:Int = PORT_AUTO
	
	Public
End