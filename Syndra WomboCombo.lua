if myHero.charName ~= "Syndra" then return end
function OnLoad()
	LoadMenu()
	LoadVariables()
	LoadSkillRanges()
	LoadVIPPrediction()
	LoadMinions()
	LoadSummonerSpells()
	LoadEnemies()
end
function OnUnload()
	PrintFloatText(myHero,2,"Syndra WomboCombo UnLoaded!")
end
function LoadMenu()
	Config = scriptConfig("Syndra WomboCombo", "Syndra WomboCombo")
	Config:addParam("stunCombo", "Stun Combo (X)", SCRIPT_PARAM_ONKEYDOWN, false, 88)
	Config:addParam("teamFight", "TeamFight (SpaceBar)", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("farm", "Farm (Z)", SCRIPT_PARAM_ONKEYTOGGLE, false, 90)
	Config:addParam("DrawCircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("DrawArrow", "Draw Arrow", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("MinionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("creeps", "Creeps (J)", SCRIPT_PARAM_ONKEYDOWN, false, 74)
	Config:addParam("harass", "Harass (T)", SCRIPT_PARAM_ONKEYDOWN, false, 84)
	Config:permaShow("harass")
	Config:permaShow("stunCombo")
	Config:permaShow("teamFight")
	Config:permaShow("farm")
	PrintFloatText(myHero,2,"Syndra WomboCombo Loaded!")
end
function LoadVariables()
	ignite = nil
	enemyHeros = {}
	enemyHerosCount = 0
	NextShot = 0
	aaTime = 0
	minionRange = false
	tick = 0
	igniteTick = 0
	orbs = {}
	orbCount = 0
	orbTick = 0
	ksDamages = {}
	newTarget = nil
end
function LoadSkillRanges()
	rangeQ = 825
	rangeW = 1000
	rangeE = 625
	rangeR = 675
	killRange = 1000
end
function LoadVIPPrediction()
	tpQ = TargetPredictionVIP(rangeQ, 1650, 0.25)
	tpE = TargetPredictionVIP(rangeE, 2000, 0.25)
	tpW = TargetPredictionVIP(rangeW, 1500, 0.25)
	tpS = TargetPredictionVIP(1350, 2000, 0.25)
end
function LoadMinions()
	enemyMinion = minionManager(MINION_ENEMY, rangeW, player, MINION_SORT_HEALTH_ASC)
	jungleMinion = minionManager(MINION_JUNGLE, rangeQ, player, MINION_SORT_HEALTH_ASC)
end
function LoadSummonerSpells()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then 
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	else 
		ignite = nil
  	end
end
function LoadEnemies()
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team ~= player.team then
			local enemyCount = enemyHerosCount + 1
			enemyHeros[enemyCount] = {object = hero, waittxt = 0, killable = 0 }
			enemyHerosCount = enemyCount
		end
	end
end
function OnTick()
	if not myHero.dead then
		QREADY = (myHero:CanUseSpell(_Q) == READY)
		WREADY = (myHero:CanUseSpell(_W) == READY)
		EREADY = (myHero:CanUseSpell(_E) == READY)
		RREADY = (myHero:CanUseSpell(_R) == READY)
		IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
		checkKillRange()
		removeOrbs()
		execute()
		orbWalk()
		jungleFarm()
		if Config.farm and not Config.teamFight and not Config.stunCombo and not Config.harass then
			farmKey()
		end
		if Config.harass then
			harassKey()
		end
		if Config.stunCombo then
			stunComboKey()
		end
	end
end
function checkKillRange()
	local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
	if QREADY and EREADY and stunMana<=myHero.mana then 
		killRange = 1350
	elseif WREADY then
		killRange = 1000
	else
		killRange = 825
	end
	if myHero:GetSpellData(_R).level == 3 then
		rangeR = 750
	end
end
function Target()
	local currentTarget = nil
	local killMana = 0
	if ValidTarget(newTarget) then
		if GetDistance(newTarget)>killRange then
			newTarget = nil
		end
	else
		newTarget = nil
	end
	for i = 1, enemyHerosCount do
		local Enemy = enemyHeros[i].object
		if ValidTarget(Enemy) then
			local pdmg = getDmg("P", Enemy, myHero, 3)
			local qdmg = getDmg("Q", Enemy, myHero, 3)
			local wdmg = getDmg("W", Enemy, myHero, 3)
			local edmg = getDmg("E", Enemy, myHero, 3)
			local rdmg = getDmg("R", Enemy, myHero, 1)
			local ADdmg = getDmg("AD", Enemy, myHero, 3)
			local dfgdamage = (GetInventoryItemIsCastable(3128) and getDmg("DFG",Enemy,myHero) or 0) -- Deathfire Grasp
			local hxgdamage = (GetInventoryItemIsCastable(3146) and getDmg("HXG",Enemy,myHero) or 0) -- Hextech Gunblade
			local bwcdamage = (GetInventoryItemIsCastable(3144) and getDmg("BWC",Enemy,myHero) or 0) -- Bilgewater Cutlass
			local botrkdamage = (GetInventoryItemIsCastable(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0) --Blade of the Ruined King
			local onhitdmg = (GetInventoryHaveItem(3057) and getDmg("SHEEN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY",Enemy,myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE",Enemy,myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN",Enemy,myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK",Enemy,myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD",Enemy,myHero) or 0)
			local onspelldamage = (GetInventoryHaveItem(3151) and getDmg("LIANDRYS",Enemy,myHero) or 0) + (GetInventoryHaveItem(3188) and getDmg("BLACKFIRE",Enemy,myHero) or 0)
			local sunfiredamage = (GetInventoryHaveItem(3068) and getDmg("SUNFIRE",Enemy,myHero) or 0)
			local comboKiller = pdmg + qdmg + wdmg + edmg + rdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			local killHim = pdmg + onhitdmg + onspelldamage + sunfiredamage + hxgdamage + bwcdamage + botrkdamage
			if IREADY then
				local idmg = getDmg("IGNITE",Enemy,myHero, 3)
				comboKiller = comboKiller + idmg
				killHim = killHim + idmg
				if GetDistance(Enemy)< 600 then
					if idmg>=Enemy.health then
						CastSpell(ignite, Enemy)
					end
				end
			end
			if QREADY then	
				killMana = killMana + myHero:GetSpellData(_Q).mana
				if GetDistance(Enemy)<=rangeQ then
					killHim = killHim + qdmg
					if qdmg >=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, qdmg)
					end
				end
			end
			if WREADY then
				killMana = killMana + myHero:GetSpellData(_W).mana	
				if GetDistance(Enemy)<=rangeW then
					killHim = killHim + wdmg
					if wdmg >=Enemy.health and not IsIgnited() and wUsed() then
						table.insert(ksDamages, wdmg)
						orbTick = GetTickCount()
					end
				end
			end
			if EREADY then
				killMana = killMana + myHero:GetSpellData(_E).mana
				if GetDistance(Enemy)<=rangeE then
					killHim = killHim + edmg
					if edmg>=Enemy.health and not IsIgnited() then
						table.insert(ksDamages, edmg)
						orbTick = GetTickCount()
					end
				end
			end
			if RREADY then
				killMana = killMana + myHero:GetSpellData(_R).mana	
				if GetDistance(Enemy)<=rangeR then
					if orbCount>0 then
						if rdmg*3+(rdmg*orbCount) >= Enemy.health and not IsIgnited() then
							table.insert(ksDamages, rdmg*3+(rdmg*orbCount))
						end
					else
						if rdmg*3>=Enemy.health and not IsIgnited() then
							table.insert(ksDamages, rdmg*3)
						end
					end
				end
			end
			if next(ksDamages)~=nil then
				table.sort(ksDamages, function (a, b) return a<b end)
				local lowestKSDmg = ksDamages[1]
				if qdmg == lowestKSDmg then
					CastQ(Enemy)
				elseif wdmg == lowestKSDmg then
					CastW(Enemy)
				elseif edmg == lowestKSDmg then
					CastE(Enemy)
				elseif orbCount>0 then
					if rdmg*3+(rdmg*orbCount) == lowestKSDmg then
						CastR(Enemy)
					end
				else
					if rdmg*3==lowestKSDmg then
						CastR(Enemy)
					end
				end
				table.clear(ksDamages)
			end
			if GetInventoryItemIsCastable(3128) then  -- DFG      
				comboKiller = comboKiller + dfgdamage + (comboKiller*0.2)
				killHim = killHim + dfgdamage + (killHim*0.2) 
				if GetInventoryItemIsCastable(3146) then -- Hxg
					comboKiller = comboKiller + (hxgdamage*0.2)
					killHim = killHim + (hxgdamage*0.2)
				end
				if GetInventoryItemIsCastable(3144) then -- bwc
					comboKiller = comboKiller + (bwcdamage*0.2)
					killHim = killHim + (bwcdamage*0.2)
				end
				if GetInventoryItemIsCastable(3153) then -- botrk
					comboKiller = comboKiller + (botrkdamage*0.2)
					killHim = killHim + (botrkdamage*0.2)
				end
			end
			currentTarget = Enemy
			if killHim >= currentTarget.health and killMana<= myHero.mana then
				enemyHeros[i].killable = 3
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > killHim then
						newTarget = currentTarget
					else
						local currentTargetDmg = currentTarget.health - killHim
						local newTargetDmg = newTarget.health - killHim
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						killTarget(newTarget)
					end
				end
			elseif comboKiller >= currentTarget.health then
				enemyHeros[i].killable = 2
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > comboKiller then
						newTarget = currentTarget
					else
						local currentTargetDmg = currentTarget.health - comboKiller
						local newTargetDmg = newTarget.health - comboKiller
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						comboTarget(newTarget)
					end
				end
			else
				enemyHeros[i].killable = 1
				if GetDistance(currentTarget) <= killRange then
					if newTarget == nil then
						newTarget = currentTarget
					elseif newTarget.health > comboKiller then
						local currentTargetDmg = currentTarget.health - comboKiller
						local newTargetDmg = newTarget.health - comboKiller
						if currentTargetDmg < newTargetDmg then
							newTarget = currentTarget
						end
					end
					if ValidTarget(newTarget) then
						harassTarget(newTarget)
					end
				end	
			end
		else
			killable = 0
		end
	end
end

function execute()
	Target()
end
function IsIgnited(target)
	if TargetHaveBuff("SummonerDot", target) then
		igniteTick = GetTickCount()
		return true
	elseif igniteTick == nil or GetTickCount()-igniteTick>500 then
		return false
	end
end
function farmKey()
	enemyMinion:update()
	if next(enemyMinion.objects)~= nil then
		for j, minion in pairs(enemyMinion.objects) do
			if minion.valid then	
				if GetDistance(minion)<=myHero.range +65 then
					local ADdmg = getDmg("AD", minion, myHero, 3)
					if ADdmg>=minion.health then
						if GetTickCount() > NextShot then
							myHero:Attack(minion)
						end
					elseif GetDistance(minion)<=rangeQ then
						local qDmg = getDmg("Q", minion, myHero, 3)
						if qDmg>=minion.health then
							CastQ(minion)
						end
					end
				elseif GetDistance(minion)<=rangeQ then
					local qDmg = getDmg("Q", minion, myHero, 3)
					if qDmg>=minion.health then
						CastQ(minion)
					end
				end
			end
		end
	end
end
function jungleFarm()
	if not ValidTarget(newTarget) then
		jungleMinion:update()
		if next(jungleMinion.objects)~= nil then
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if Config.creeps then
						CastQ(minion)
						CastW(minion)
					end
				end
			end
		end
	else
		return
	end
end
function harassKey()
	if ValidTarget(newTarget) then
		CastQ(newTarget)
	end
end
function removeOrbs()
	if next(orbs)~=nil then
		for i, obj in pairs(orbs) do
			if not obj.valid then
				table.remove(orbs, i)
				orbCount = orbCount - 1
			end
		end
	end
end
function stunComboKey()
	if ValidTarget(newTarget) then
		if Config.stunCombo then
			local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
			if stunMana<=myHero.mana then
				if QREADY and EREADY then
					local stunPos = tpS:GetPrediction(newTarget)
					if GetDistance(stunPos)>=rangeE then
						local dist = GetDistance(myHero, stunPos)
						local EnemyPos = Vector(stunPos.x, stunPos.y, stunPos.z)
						local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
						local Pos = HeroPos + (HeroPos-EnemyPos)*(-rangeE/GetDistance(stunPos))
						if GetDistance(Pos, myHero)< dist and GetDistance(Pos, stunPos) < dist then
							local _, p2, isOnLineSegment = VectorPointProjectionOnLineSegment(myHero, stunPos, Pos)
							if isOnLineSegment and GetDistance(Pos, p2)<= 105 then
								if GetDistance(Pos)<=rangeQ then
									CastSpell(_Q, Pos.x, Pos.z)
								end
								if GetDistance(Pos)<=rangeE then
									CastSpell(_E, Pos.x, Pos.z)
									orbTick = GetTickCount()
								end
							end
						end
					else
						CastSpell(_Q, stunPos.x, stunPos.z)
						CastSpell(_E, stunPos.x, stunPos.z)
					end
				else
					return
				end
			else
				return
			end
		end
	end
end
function killTarget(target)
	if ValidTarget(target) and not IsIgnited() then
		if Config.teamFight then
			CastItems(target, true)
			if not WREADY or GetDistance(target)>rangeW or myHero.maxMana*0.4<=myHero.mana then
				CastE(target)
			end
			CastQ(target)
			CastW(target)
		end
	end
end
function comboTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target, true)
			if not WREADY or GetDistance(target)>rangeW or myHero.maxMana*0.4<=myHero.mana then
				CastE(target)
			end
			CastQ(target)
			CastW(target)
		end
	end
end
function harassTarget(target)
	if ValidTarget(target) then
		if Config.teamFight then
			CastItems(target)
			if not WREADY or GetDistance(target)>rangeW or myHero.maxMana*0.4<=myHero.mana then
				CastE(target)
			end
			CastQ(target)
			CastW(target)
		end
	end
end
function CastQ(target)
	if not QREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeQ and QREADY then
			local QPos = tpQ:GetPrediction(target)
			if QPos and GetDistance(QPos)<=rangeQ then
				CastSpell(_Q, QPos.x, QPos.z)
			else
				return
			end
		end
	else
		return
	end
end
function CastW(target)
	if not WREADY then return end
	if ValidTarget(target) then
		if not wUsed() then
			if WREADY then
				if next(orbs)~= nil then
					for i, obj in pairs(orbs) do
						if obj.valid then
							if GetDistance(obj)<= rangeW and (orbTick == nil or GetTickCount()-orbTick>=1000) then
								CastSpell(_W, obj.x, obj.z)
							else
								return
							end
						else
							table.remove(orbs, i)
							orbCount = orbCount - 1
						end
					end
				elseif QREADY then
					CastQ(target)
				else
					local nearestMinion = nil
					enemyMinion:update()
					if next(enemyMinion.objects)~=nil then
						for m, minion in pairs(enemyMinion.objects) do
							if minion.valid then
								local wdamage = getDmg("W", minion, myHero, 3)
								local currentMinion = minion
								if wdamage>=minion.health then
									if GetDistance(minion)<rangeW then
										CastSpell(_W, minion.x, minion.z)
									end
								else
									if nearestMinion == nil then
										nearestMinion = currentMinion
									elseif GetDistance(currentMinion)< GetDistance(nearestMinion) then
										nearestMinion = currentMinion
									end
									if GetDistance(nearestMinion)<=rangeW then
										CastSpell(_W, minion.x, minion.z)
									end
								end	
							end
						end
					end
				end
			end
		elseif wUsed() then
			if GetDistance(target)<=rangeW then
				local WPos = tpW:GetPrediction(target)
				if WPos and GetDistance(WPos)<=rangeW then
					CastSpell(_W, WPos.x, WPos.z)
					orbTick = GetTickCount()
				end
			end
		end
	else
		return
	end
end
function CastE(target)
	if not EREADY then return end
	if ValidTarget(target) and (orbTick == nil or GetTickCount()-orbTick>=1000) then
		if next(orbs)~= nil then
			for i, obj in pairs(orbs) do
				if obj.valid then
					local stunPos = tpS:GetPrediction(target)
					if stunPos then
						local dist = GetDistance(myHero, stunPos)
						if GetDistance(obj, myHero)< dist and GetDistance(obj, stunPos) < dist then
							local _, p2, isOnLineSegment = VectorPointProjectionOnLineSegment(myHero, stunPos, obj)
							if isOnLineSegment and GetDistance(obj, p2)<= 105 then
								if GetDistance(obj)<=rangeE then
									CastSpell(_E, obj.x, obj.z)
									orbTick = GetTickCount()
								end
							else
								if GetDistance(stunPos)>=rangeE then
									if QREADY then
										local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
										if stunMana<=myHero.mana then
											local dist = GetDistance(myHero, stunPos)
											local EnemyPos = Vector(stunPos.x, stunPos.y, stunPos.z)
											local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
											local Pos = HeroPos + (HeroPos-EnemyPos)*(-rangeE/GetDistance(stunPos))
											if GetDistance(Pos, myHero)< dist and GetDistance(Pos, stunPos) < dist then
												local _, p2, isOnLineSegment = VectorPointProjectionOnLineSegment(myHero, stunPos, Pos)
												if isOnLineSegment and GetDistance(Pos, p2)<= 105 then
													if GetDistance(Pos)<=rangeQ then
														CastSpell(_Q, Pos.x, Pos.z)
													end
													if GetDistance(Pos)<=rangeE then
														CastSpell(_E, Pos.x, Pos.z)
														orbTick = GetTickCount()
													end
												end
											end
										else 
											return
										end
									end
								else
									if QREADY then
										local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
										if stunMana<=myHero.mana then
											CastSpell(_Q, target.x, target.z)
										else 
											return
										end
									end
								end
							end
						end
					end
				else
					table.remove(orbs, i)
					orbCount = orbCount - 1
				end
			end
		else
			if GetDistance(target)>=rangeE then
				if QREADY then
					local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
					if stunMana<=myHero.mana then
						local stunPos = target
						local dist = GetDistance(myHero, stunPos)
						local EnemyPos = Vector(stunPos.x, stunPos.y, stunPos.z)
						local HeroPos = Vector(myHero.x, myHero.y, myHero.z)
						local Pos = HeroPos + (HeroPos-EnemyPos)*(-rangeE/GetDistance(stunPos))
						if GetDistance(Pos, myHero)< dist and GetDistance(Pos, stunPos) < dist then
							local _, p2, isOnLineSegment = VectorPointProjectionOnLineSegment(myHero, stunPos, Pos)
							if isOnLineSegment and GetDistance(Pos, p2)<= 105 then
								if GetDistance(Pos)<=rangeQ then
									CastSpell(_Q, Pos.x, Pos.z)
								end
								if GetDistance(Pos)<=rangeE then
									CastSpell(_E, Pos.x, Pos.z)
									orbTick = GetTickCount()
								end
							end
						end
					else
						return
					end
				end
			else
				if QREADY then
					local stunMana = myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_E).mana
					if stunMana<=myHero.mana then
						CastSpell(_Q, target.x, target.z)
					else 
						return
					end
				end
			end
		end
	else
		return
	end
end
function CastR(target)
	if not RREADY then return end
	if ValidTarget(target) then
		if GetDistance(target) <= rangeR and RREADY then
			CastSpell(_R, target)
		end
	else
		return
	end
end
function wUsed() 
	wData = myHero:GetSpellData(_W)
	if wData.name == "syndrawcast" then 
		return true 
	else 
		return false
	end
end
function CastItems(target, allItems)
	if not ValidTarget(target) then 
		return
	else
		if GetDistance(target) <=800 and allItems == true then
			CastItem(3144, target) --Bilgewater Cutlass
			CastItem(3153, target) --Blade Of The Ruin King
			CastItem(3128, target) --Deathfire Grasp
			CastItem(3146, target) --Hextech Gunblade
			CastItem(3188, target) --Blackfire Torch  
		end
		if GetDistance(target) <= 275 then
			CastItem(3184, target) --Entropy
			CastItem(3143, target) --Randuin's Omen
			CastItem(3074, target) --Ravenous Hydra
			CastItem(3131, target) --Sword of the Devine
			CastItem(3077, target) --Tiamat
			CastItem(3142, target) --Youmuu's Ghostblade
		end
		if GetDistance(target) <= 1000 then
			CastItem(3023, target) --Twin Shadows
		end
	end
end
function orbWalk()		
	if GetTickCount() > NextShot then
		if ValidTarget(newTarget) then
			if GetDistance(newTarget)<=myHero.range +70 and Config.teamFight then
				myHero:Attack(newTarget)
			else
				if Config.teamFight and Config.moveToMouse then
					myHero:MoveTo(mousePos.x, mousePos.z)
				end
			end
		elseif not ValidTarget(newTarget) then
			minionRange = false
			enemyMinion:update()
			jungleMinion:update()
			for i, minion in pairs(enemyMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+70 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
			for j, minion in pairs(jungleMinion.objects) do
				if minion.valid then
					if GetDistance(minion)<=myHero.range+70 and Config.creeps then
						myHero:Attack(minion)
						minionRange = true
					else
						minionRange = false
					end
				end
			end
		end
		if not minionRange and not ValidTarget(newTarget) and Config.moveToMouse then
			if Config.teamFight then
				myHero:MoveTo(mousePos.x, mousePos.z)
			end
		end
	elseif GetTickCount() > aaTime then
		if Config.teamFight and Config.moveToMouse then
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	end
end
function OnCreateObj(obj)	
	if obj~= nil and obj.name:find("Syndra_DarkSphere5_idle.troy") then
			table.insert(orbs, obj)
			orbCount = orbCount + 1
	end	
	if obj~= nil and obj.name:find("Syndra_DarkSphere_idle.troy") then
			table.insert(orbs, obj)
			orbCount = orbCount + 1
	end
end
function OnDraw()
	if not myHero.dead then
		if ValidTarget(newTarget) and Config.DrawArrow then
			DrawArrows(myHero, newTarget, 30, 0x099B2299, 50)
		end
		if Config.DrawCircles then
			DrawCircle(myHero.x, myHero.y, myHero.z, killRange, ARGB(87,183,60,244))
		end
		for i = 1, enemyHerosCount do
			local Enemy = enemyHeros[i].object
			local killable = enemyHeros[i].killable
			if ValidTarget(Enemy) then
				if killable == 4 then
					DrawText3D(tostring("Ks him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,10,20), true)
				elseif killable == 3 then
					DrawText3D(tostring("killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,255,143,20), true)
				elseif killable == 2 then
					DrawText3D(tostring("Combo killer"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,248,255,20), true) 
				elseif killable == 1 then
					DrawText3D(tostring("Harass Him"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(255,10,255,20), true)
				else
					DrawText3D(tostring("Not killable"),Enemy.x,Enemy.y, Enemy.z,16,ARGB(244,66,155,255), true)
				end
			end
		end 
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and unit.valid and spell.name:lower():find("attack") and spell.animationTime then
		aaTime = GetTickCount() + spell.windUpTime * 1000 - GetLatency() / 2 + 10 + 50
		NextShot = GetTickCount() + spell.animationTime * 1000
	end
end
