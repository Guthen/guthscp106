ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "SCP-106 Sinkhole"
ENT.Spawnable = false

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "QueueRemoveTime" )

	if SERVER then
		self:SetQueueRemoveTime( -1.0 )
	end
end

function ENT:IsQueueRemoved()
	return self:GetQueueRemoveTime() > -1.0
end