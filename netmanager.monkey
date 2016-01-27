Strict

Public

' Imports (Public):
Import packet
Import handle

' Imports (Private):
Private

Import brl.socket

Public

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
	
	' Methods:
	' Nothing so far.
	
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