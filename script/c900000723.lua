--MTG Elesh Norn, Grand Cenobite
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	c:EnableUnsummonable()
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,2,CARD_MTG_PLAINS)
	--"Other monsters you control gain 800 ATK/DEF."
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.othertarget)
	e1:SetValue(800)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e2)
	--"Monsters your opponent controls lose 800 ATK/DEF."
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetValue(-800)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)
	--"When a monster's ATK or DEF becomes 0 by this effect: Send it to the GY."
	--
	--Written as a trigger on the moments a value can actually reach 0 -- a
	--monster arriving on the opponent's board, or this card arriving and pushing
	--the existing board down. This was an EVENT_ADJUST trigger first and did
	--nothing: EVENT_ADJUST is the engine's internal re-evaluation pass, not an
	--event that drives trigger effects. King Tiger Wanghu (83986578) is the
	--model -- same shape, TRIGGER_F on the summon events with a MZONE range.
	--
	--This card's own EVENT_SPSUMMON_SUCCESS is deliberately not excluded, unlike
	--Wanghu's: its arrival is exactly when the opponent's existing monsters drop
	--to 0, so it has to sweep them.
	--
	--Caveat: once a value is clamped at 0 the engine cannot say whether it
	--started above 0, so a monster printed with 0 ATK is also sent.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_TOGRAVE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_SUMMON_SUCCESS)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCondition(s.tgcon)
	e5:SetTarget(s.tgtg)
	e5:SetOperation(s.tgop)
	c:RegisterEffect(e5)
	for _,code in ipairs({EVENT_SPSUMMON_SUCCESS,EVENT_FLIP_SUMMON_SUCCESS,
	                      EVENT_FLIP,EVENT_CHANGE_POS}) do
		local ec=e5:Clone()
		ec:SetCode(code)
		c:RegisterEffect(ec)
	end
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_PLAINS}

function s.othertarget(e,c)
	return c~=e:GetHandler()
end

function s.tgfilter(c)
	return c:IsFaceup() and (c:GetAttack()==0 or c:GetDefense()==0) and c:IsAbleToGrave()
end
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsFaceup()
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,0,LOCATION_MZONE,1,nil)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end
--Recomputed at resolution rather than reusing the group from the condition:
--the board can change between the two, and a monster that is no longer at 0
--should not be swept.
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsFacedown() then return end
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then Duel.SendtoGrave(g,REASON_EFFECT) end
end
