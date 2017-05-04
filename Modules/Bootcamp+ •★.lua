bootcampp = {
	translations = {
		en = {
			welcome = "Welcome to #bootcamp+",
		},
		br = {
			welcome = "Bem-vindo ao #bootcamp+",
		},
	},
	langue = "en",
	maps = {6501305,6118143,2604997,2836937,6921682,3339586,5776126,5678468,3588850,5731571,6531399,6794559,5847160,5745650,7091808,7000003,6999993,5475528,4559999,3783671,2194497,3636264,4559344,4784241,4892845,3883780,5819565,6229884,6367688,4976520,4854044,6374076,3636206,3883883,6793803,4499335,4694197,5485847,6258690,3938895,1719709,4267610,4209243,764650},
	info = {},
	groundsData = {},
	mapData = {},
	init = function()
		bootcampp.translations.pt = bootcampp.translations.br
		bootcampp.langue = bootcampp.translations[tfm.get.room.community] and tfm.get.room.community or "en"

		for _,f in next,{"AutoShaman","AutoTimeLeft","AutoNewGame","PhysicalConsumables","AfkDeath"} do
			tfm.exec["disable"..f]()
		end

		tfm.exec.newGame(bootcampp.maps[math.random(#bootcampp.maps)])
	end,
	rank = function(players,fromValue,showPos,showPoints,pointsName,lim)
		local p,rank = {},""
		fromValue,lim = fromValue or {tfm.get.room.playerList,"score"},tonumber(lim) or 100
		for n in next,players do
			p[#p+1] = {name=n,v=fromValue[1][n][fromValue[2]]}
		end
		table.sort(p,function(f,s) return f.v>s.v end)
		for o,n in next,p do
			if o <= lim then
				rank = rank .. (showPos and "<J>"..o..". " or "") .. "<V>" .. n.name .. (showPoints and " <BL>- <VP>" .. n.v .. " "..(pointsName or "points") .."\n" or "\n")
			end
		end
		return rank
	end,
	eventNewGame = function()
		bootcampp.groundsData = {}
		bootcampp.mapData = {}
		for k,v in next,bootcampp.info do
			v.cheese = false
			v.checkpoint = {false,0,0}
			ui.removeTextArea(1,n)
		end
		local xml = tfm.get.room.xmlMapInfo.xml
		if xml then
			local grounds = xml:match("<S>(.-)</S>")
			local properties = xml:match("<C><P (.-)/>.*<Z>")
			if properties then
				bootcampp.mapData = {
					width = properties:match('L="(%d+)"') or 800,
					heigth = properties:match('H="(%d+)"') or 400,
				}
			else
				bootcampp.mapData = {
					width = 800,
					heigth = 400,
				}
			end

			local data = {}
			grounds:gsub("<S (.-)/>",function(attributes)
				data[#data + 1] = attributes
			end)
			for i = 1,#data do
				bootcampp.groundsData[i] = {}
				
				local type = data[i]:match('T="(%d+)"')
				bootcampp.groundsData[i].type = type and tonumber(type) or -1

				local x = data[i]:match('X="(%d+)"')
				bootcampp.groundsData[i].x = x and tonumber(x) or 0

				local y = data[i]:match('Y="(%d+)"')
				bootcampp.groundsData[i].y = y and tonumber(y) or 0

				local width = data[i]:match('L="(%d+)"')
				bootcampp.groundsData[i].width = width and tonumber(width) or 0

				local heigth = data[i]:match('H="(%d+)"')
				bootcampp.groundsData[i].heigth = heigth and tonumber(heigth) or 0

				local info = data[i]:match('P="(.*)"')
				info = string.split(info,"[^,]+")

				bootcampp.groundsData[i].friction = info[3] and tonumber(info[3]) or .3
				bootcampp.groundsData[i].restitution = info[3] and tonumber(info[4]) or .2
				bootcampp.groundsData[i].angle = info[3] and tonumber(info[5]) or 0
			end
		end
	end,
	eventNewPlayer = function(n)
		if not bootcampp.info[n] then
			bootcampp.info[n] = {
				shift = false,
				checkpoint = {false,0,0},
				cheese = false,
			}
		end
		system.bindMouse(n,true)
		for i = 1,2 do
			system.bindKeyboard(n,16,i==1,true)
			system.bindKeyboard(n,string.byte("K"),i==1,true)
		end
		system.bindKeyboard(n,string.byte("E"),true,true)
	end,
	eventMouse = function(n,x,y)
		if bootcampp.info[n].shift then
			for i = #bootcampp.groundsData,1,-1 do
				local g = bootcampp.groundsData[i]
				local rad = math.rad(g.angle)
				local ax = {math.cos(rad),math.sin(rad)}

				local gX = g.x + ax[1] * (x - g.x) - ax[2] * (y - g.y)
				local gY = g.y + ax[2] * (x - g.x) + ax[1] * (y - g.y)

				if (g.type == 13 and math.pythag(x,y,g.x,g.y,g.width/2) or (math.abs(gX - g.x) < g.width/2 and math.abs(gY - g.y) < g.heigth/2)) then
					local properties = {"Type","ID","X","Y","Heigth","Width","Friction","Restitution","Angle"}
					local info = ""

					for k,v in next,properties do
						info = info .. string.format("<N>%s : <V>%s\n",v,(v == "ID" and i or v == "Type" and (({[0] = "Unknown","Wood","Ice","Trampoline","Lava","Chocolate","Earth","Grass","Sand","Cloud","Water","Stone","Snow","Rectangle","Circle","Spiderweb"})[g.type + 1]) or tostring(g[v:lower()])))
					end

					local mapW = tonumber(bootcampp.mapData.width)
					local mapH = tonumber(bootcampp.mapData.heigth)
					ui.addTextArea(0,info,n,(x + 150 <= mapW and x) or (x < 0 and 0) or (mapW - 150),(y + 180 <= mapH and y > 20 and y) or (y < 20 and 25) or (mapH - 180),nil,nil,nil,nil,.8,false)
				end
			end
		else
			ui.removeTextArea(0,n)
		end
	end,
	eventKeyboard = function(n,k,d,x,y)
		if k == 16 then
			bootcampp.info[n].shift = d
		elseif k == string.byte("E") then
			if bootcampp.info[n].shift then
				bootcampp.info[n].checkpoint = {false,0,0}
				ui.removeTextArea(1,n)
			else
				bootcampp.info[n].checkpoint = {true,x,y}
				ui.addTextArea(1,"",n,x-5,y-5,10,10,0x56A75A,0x56A75A,.5,true)
			end
		elseif k == string.byte("K") then
			if d then
				ui.addTextArea(2,bootcampp.rank(tfm.get.room.playerList,{tfm.get.room.playerList,"score"},true,true,"points",20),n,5,30,nil,200,nil,nil,.8,true)
			else
				ui.removeTextArea(2,n)
			end
		end
	end,
	eventPlayerDied = function(n)
		tfm.exec.respawnPlayer(n)
		if bootcampp.info[n].checkpoint[1] then
			tfm.exec.movePlayer(n,bootcampp.info[n].checkpoint[2],bootcampp.info[n].checkpoint[3])
		end
		if bootcampp.info[n].cheese then
			tfm.exec.giveCheese(n)
		end
		tfm.exec.setPlayerScore(n,-1,true)
	end,
	eventPlayerWon = function(n)
		bootcampp.info[n].cheese = false
		bootcampp.info[n].checkpoint = {false,0,0}
		ui.removeTextArea(1,n)

		bootcampp.eventPlayerDied(n)
	end,
	eventPlayerGetCheese = function(n)
		bootcampp.info[n].cheese = true
	end,
	eventChatCommand = function(n,c)
		local p = string.split(c,"[^%s]+")
		if system.roomAdmins[n] then
			if p[1] == "next" then
				tfm.exec.newGame(bootcampp.maps[math.random(#bootcampp.maps)])
			elseif p[1] == "again" then
				tfm.exec.newGame(tfm.get.room.currentMap)
			elseif p[1] == "np" or p[1] == "map" then
				tfm.exec.newGame(p[2])
			elseif p[1] == "time" then
				tfm.exec.setGameTime(p[2] * 60)
			end
		end
	end,
	eventLoop = function()
		if _G.leftTime < 1 then
			tfm.exec.newGame(bootcampp.maps[math.random(#bootcampp.maps)])
		end
	end
}

system.isRoom=tfm.get.room.name:byte(2)~=3;system.roomAdmins={}system.miscAttrib=0;system.roomSettings={["#"]=function(a)system.miscAttrib=tonumber(a)or 1;system.miscAttrib=math.max(1,math.min(system.miscAttrib,99))end}system.roomAttributes=system.isRoom and tfm.get.room.name:match("%*?#"..system.module.."%d+(.*)")or""system.isPlayer=function(a)if tfm.get.room.playerList[a]then if a:sub(1,1)=="*"then return false end;if tfm.get.room.playerList[a].registrationDate then if os.time()-(tfm.get.room.playerList[a].registrationDate or 0)<432e6 then return false end else return false end;return true else return false end end;system.loadTable=function(b)local c;for d in b:gmatch("[^%.]+")do d=tonumber(d)and tonumber(d)or d;c=c and c[d]or _G[d]end;return c end;system.players=function(e)local f,g=0,0;if e then f={}end;for h,i in next,tfm.get.room.playerList do if system.isPlayer(h)then if not i.isDead and not i.isVampire then if e then f[#f+1]=h else f=f+1 end end;g=g+1 end end;if e then return f else return f,g end end;string.split=function(j,k,l)local m={}for i in j:gmatch(k)do m[#m+1]=l and l(i)or i end;return m end;string.nick=function(n)return n:lower():gsub('%a',string.upper,1)end;math.isNegative=function(o,p,q)return o<0 and p or q end;math.percent=function(o,r,i)i=i or 100;local s=o/r*i;return math.min(s,i)end;math.pythag=function(t,u,v,w,x)return(t-v)^2+(u-w)^2<=x^2 end;table.find=function(c,j,y)for h,i in next,c do if y then if i[y]==j then return true,h end else if i==j then return true,h end end end;return false end;table.turnTable=function(o)return type(o)=="table"and o or{o}end;table.random=function(z)return type(z)=="table"and z[math.random(#z)]or math.random()end;table.concat=function(c,A,l,B,C)local D=""A=A or""B,C=B or 1,C or#c;for h,i in next,c do if h>=B and h<=C then D=D..(l and l(h,i)or i)..A end end;return D:sub(1,-1-#A)end;do local E=string.byte;string.byte=function(F)return E(F,1,#F)end end;deactivateAccents=function(F)local G={a={"á","â","à","å","ã","ä"},e={"é","ê","è","ë"},i={"í","î","ì","ï"},o={"ó","ô","ò","õ","ö"},u={"ú","û","ù","ü"}}for h,i in next,G do for B=1,#i do F=F:gsub(i[B],tostring(h))end end;return F end;xml={}xml.parse=function(H)H=H:match("<P (.-)/>")or""local m={}for I,J,j in H:gmatch("([%-%w]+)=([\"'])(.-)%2")do m[I]=j end;return m end;xml.attribFunc=function(H,K)local L=xml.parse(H)for h,i in next,K do if L[i.attribute]then i.func(L[i.attribute])end end end;xml.addAttrib=function(H,m,M)local N=H:match("<P (.-)/>")or""for h,i in next,m do if not N:find(i.tag)then H=H:gsub("<P (.-)/>",function(O)return string.format("<P %s=\"%s\" %s/>",i.tag,i.value,O)end)end end;if M then tfm.exec.newGame(H)else return H end end;normalizedTime=function(P)return math.floor(P)+(P-math.floor(P)>=.5 and.5 or 0)end;disableChatCommand=function(Q)system.disableChatCommandDisplay(Q,true)system.disableChatCommandDisplay(Q:lower(),true)system.disableChatCommandDisplay(Q:upper(),true)end;

for k,evento in next,{"NewGame","PlayerDied","PlayerGetCheese","PlayerVampire","PlayerWon","PlayerLeft","EmotePlayed","Keyboard","Mouse","PopupAnswer","TextAreaCallback","ChatCommand","ChatMessage","SummoningStart","SummoningEnd","SummoningCancel","NewPlayer","PlayerRespawn","ColorPicked"} do
	if bootcampp["event" .. evento] then
		_G["event" .. evento] = function(...)
			bootcampp["event" .. evento](...)
		end
	end
end
if _G["eventNewPlayer"] then
	table.foreach(tfm.get.room.playerList,eventNewPlayer)
end

eventLoop = function(currentTime,leftTime)
	_G.currentTime = normalizedTime(currentTime/1e3)
	_G.leftTime = normalizedTime(leftTime/1e3)
	if bootcampp.loop then
		bootcampp.init(currentTime,leftTime)
	end
end

bootcampp.init()
