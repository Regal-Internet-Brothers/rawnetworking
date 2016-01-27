Strict

Public

' Imports (Public):
Import packet
Import handle

' Imports (Private):
Private

Import brl.socket
'Import brl.databuffer

Public

' Interfaces:
Interface NetApplication
	' Methods:
	Method CanSwitchParent:Bool(CurrentParent:NetApplication, NewParent:NetApplication)
	Method OnPacketReceived:Void(Data:Packet, From:NetUserHandle)
End

' Classes:

' This class covers common functionality between 'Server' and 'Client'.
Class NetManager<ParentType> Extends PacketManager Abstract
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
	' Nothing so far.
	
	' Methods (Protected):
	Protected
	
	Method __ClearInboundPacket:Void(P:Packet)
		If (P <> Null) Then
			Free(FinishTransmission(P))
		Endif
	End
	
	Method __ClearInboundPacket:Void()
		__ClearInboundPacket(__InboundPacket)
		__InboundPacket = Null
		
		Return
	End
	
	' This enables the use of '__InboundPacket'.
	Method __UseInboundPacket:Packet()
		If (__InboundPacket = Null) Then
			__InboundPacket = __AllocateInboundPacket()
		Endif
		
		Return __AllocateInboundPacket
	End
	
	' This allocates an "inbound packet", then returns it.
	' To use '__InboundPacket', please call '__UseInboundPacket'.
	Method __AllocateInboundPacket:Packet()
		Local P:= Allocate()
		
		MarkTransmission(P)
		
		Return P
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
	
	' This is used constantly to receive information.
	' The state of this object is implementation-defined.
	Field __InboundPacket:Packet
	
	' Meta:
	Field _Port:Int = PORT_AUTO
	
	Public
End