--《天涯旅店》丢失物品找回功能
--QQ技术交流群：755082209

local Quality=4 --可以找回的物品的最低品质
local FindCD=86400 --找回物品功能cd（秒）
local itemCache={}
local lastFindAt={}

function OnChat(event, player, msg, Type, lang)
	if player == nil then
		return
	end
	local msgLen=string.len(msg)
	if msg == "findbacklist" then
		sendFindbackList(player)
	elseif msgLen>=10 then  --"findback 1" 至少10个字符
		if string.sub(msg,0,8)=="findback" then
			local idStr=string.sub(msg,9,msgLen)
			local id=tonumber(idStr)
			if id==nil then
				player:SendBroadcastMessage("物品找回请求格式不正确，请正确输入findback id")
				return
			end
			findback(player,id)
		end
	end
end

function sendFindbackList(player)
	-- 找回物品查询列表
	local guid = player:GetGUIDLow()
	local result = CharDBQuery("SELECT a.guid,a.itemEntry FROM acore_characters.item_instance a left join acore_world.item_template b on a.itemEntry= b.entry \
		where a.guid not in (select item from acore_characters.character_inventory where guid="..guid..") \
		and a.guid not in (select itemguid from acore_characters.auctionhouse where itemowner="..guid..")\
		and a.guid not in (select item_guid from acore_characters.mail_items where receiver="..guid..")  \
		and a.owner_guid="..guid.." and b.Quality>="..Quality)
	if result then
		player:SendBroadcastMessage("疑似丢失物品列表：")
		repeat
			local itemGuid=result:GetUInt32(0)
			local itemEntry=result:GetUInt32(1)
			itemCache[itemGuid]=guid
			player:SendBroadcastMessage("id:"..itemGuid.." "..GetItemLink(itemEntry,4))
		until not result:NextRow()
		player:SendBroadcastMessage("可以通过聊天输入findback id进行找回，同时请保证背包第一格为空")
	else
		player:SendBroadcastMessage("未找到紫色品质以上疑似丢失物品")
	end
end

function findback(player,id)
	local guid = player:GetGUIDLow()
	local lastAt = lastFindAt[guid]
	if lastAt ~= nil and os.time() - lastAt < FindCD then
		player:SendBroadcastMessage("找回功能每24小时只能找回1次，请稍后再试")
		return
	end
	if itemCache[id]==guid then
		if player:GetItemByPos(255, 23) ~= nil then 
			player:SendBroadcastMessage("请保证背包第一格为空")
			return
		end
		player:SaveToDB()
		CharDBExecute("insert into character_inventory (guid,bag,slot,item)values("..guid..",0,23,"..id..")")
		lastFindAt[guid] = os.time()
		player:SendBroadcastMessage("找回成功，请不要进行任何物品动作，并返回角色选择界面重新进入游戏！！！")
	else 
		player:SendBroadcastMessage("找回物品请求的id有误，请查询并请求正确的id")
	end
end


RegisterPlayerEvent(18, OnChat) --聊天的时候