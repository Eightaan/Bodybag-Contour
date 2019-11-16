if RequiredScript == "lib/managers/menumanager" then

local bodybag_color = tweak_data.screen_colors.regular_color 
local lootbag_color = tweak_data.contour.character_interactable.standard_color 



function SetContourColors()
	for carry_id, data in pairs(tweak_data.carry) do
		if data.type then
			tweak_data.contour.interactable[carry_id] = lootbag_color
		end
	end

	for carry_id, data in pairs(tweak_data.carry) do
		if data.type == 'being' then
			tweak_data.contour.interactable[carry_id] = bodybag_color 
		end
	end
end
SetContourColors()

function CanHideBodyBagContour()
	if Global.game_settings.level_id == 'mad' then
		return false
	end
	return managers.groupai:state()._police_called
end

elseif RequiredScript == "lib/managers/objectinteractionmanager" then
function ObjectInteractionManager:remove_contour(carry_id)
	for _, unit in pairs(self._interactive_units) do
		if unit and alive(unit) and unit:carry_data() and unit:carry_data():carry_id() == carry_id then
			unit:interaction():set_contour("standard_color", 0)
		end
	end
end

elseif RequiredScript == "lib/managers/group_ai_states/groupaistatebase" then
local original_groupaistatebase_onpolicecalled = GroupAIStateBase.on_police_called
function GroupAIStateBase:on_police_called(called_reason)
	original_groupaistatebase_onpolicecalled(self, called_reason)
	if CanHideBodyBagContour() then
		managers.interaction:remove_contour("person")
	end
end
local original_groupaistatebase_syncevent = GroupAIStateBase.sync_event
function GroupAIStateBase:sync_event(event_id, blame_id)
	original_groupaistatebase_syncevent(self, event_id, blame_id)
	if self.EVENT_SYNC[event_id] == "police_called" and CanHideBodyBagContour() then
		managers.interaction:remove_contour("person")
	end
end

elseif RequiredScript == "lib/units/interactions/interactionext" then
local original_baseinteractionext_setcontour = BaseInteractionExt.set_contour
function BaseInteractionExt:set_contour(color, opacity)
	if not tweak_data.contour.interactable.money then
		SetContourColors()
	end
	
	if color ~= 'selected_color' and alive(self._unit) and self._unit:carry_data() then
		local carry_id = self._unit:carry_data():carry_id()
		color = tweak_data.contour.interactable[carry_id] and carry_id or color
		if carry_id == 'person' and CanHideBodyBagContour() then
			opacity = 0
		end
	end
	original_baseinteractionext_setcontour(self, color, opacity)
end

elseif RequiredScript == "lib/managers/playermanager" then
local original_playermanager_serverdropcarry = PlayerManager.server_drop_carry
function PlayerManager:server_drop_carry(carry_id, ...)
	local unit = original_playermanager_serverdropcarry(self, carry_id, ...)
	if unit then
		unit:interaction():set_contour(carry_id, 1)
	end
	return unit
end

local original_playermanager_synccarrydata = PlayerManager.sync_carry_data
function PlayerManager:sync_carry_data(unit, carry_id, ...)
	original_playermanager_synccarrydata(self, unit, carry_id, ...)
	unit:interaction():set_contour(carry_id, 1)
end
end