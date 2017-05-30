local config = require 'config'
local u = require 'utilities'
local api = require 'methods'

local plugin = {}

function plugin.onTextMessage(msg, blocks)
	if msg.chat.type == 'private' then return end
	
	if u.is_allowed('texts', msg.chat.id, msg.from) then
		if not blocks[2] then
			local pin_id = db:get('chat:'..msg.chat.id..':pin')
			if pin_id then
			    api.sendMessage(msg.chat.id, _('Last message generated by `/pin` ^'), true, nil, pin_id)
			end
			return
		end
		
		local pin_id = db:get('chat:'..msg.chat.id..':pin')
		local was_deleted
		if pin_id then --try to edit the old message
			local reply_markup, new_text = u.reply_markup_from_text(blocks[2])
			local res, code = api.editMessageText(msg.chat.id, pin_id, new_text:replaceholders(msg.from, 'rules', 'title'), true, reply_markup)
			if not res then
				if code == 155 then
			    	--the old message doesn't exist. Send a new one in the chat --> set pin_id to false, so the code will enter the next if
			    	was_deleted = true
			    	pin_id = nil
				else
					api.sendMessage(msg.chat.id, u.get_sm_error_string(code), true)
		    	end
		    else
		    	db:set('chat:'..msg.chat.id..':pin', res.result.message_id)
	    		api.sendMessage(msg.chat.id, _("Message edited. Check it here"), nil, nil, pin_id)
	    	end
		end
		if not pin_id then
			local reply_markup, new_text = u.reply_markup_from_text(blocks[2])
			local res, code = api.sendMessage(msg.chat.id, new_text:replaceholders(msg, 'rules', 'title'), true, reply_markup)
			if not res then
				api.sendMessage(msg.chat.id, u.get_sm_error_string(code), true)
    		else --if the message has been sent, then set its ID as new pinned message 
    			db:set('chat:'..msg.chat.id..':pin', res.result.message_id)
    			local text
    			if was_deleted then
    				text = _("The old message generated with `/pin` does not exist anymore, so I can't edit it. This is the new message that can be now pinned")
    			else
    				text = _("This message can now be pinned. Use `/pin [new text]` to edit it without having to send it again")
    			end
				api.sendMessage(msg.chat.id, text, true, nil, res.result.message_id)
			end
		end
	end
end

plugin.triggers = {
	onTextMessage = {
		config.cmd..'(pin)$',
        config.cmd..'(pin) (.*)$'
	}
}

return plugin
