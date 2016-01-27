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
Class NetManager<ParentType> Abstract
	' Destructor(s):
	Method Close:Void() Abstract
	
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