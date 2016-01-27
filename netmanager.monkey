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
	
	
	' Fields (Protected):
	Protected
	
	' This acts as our "parent application".
	Field Parent:ParentType
	
	' This is the socket we use most networking operations. (Protocol-specific)
	Field _Connection:Socket
	
	Public
End