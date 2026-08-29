--MTG Sheoldred, the Apocalypse
--"MTG" custom set
Duel.LoadScript("mtg_common.lua")
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	c:EnableUnsummonable()
	c:EnableReviveLimit()
	MTG.AddExtraBanishSummonProcedure(c,2,CARD_MTG_SWAMP)
	--"At the end of the Damage Step, if this card battled a monster: Destroy
	--that monster."
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_BATTLED)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	--"Each time a card(s) is added to your hand, gain 800 LP for each card
	--added." Likewise 800 damage for the opponent's hand.
	--
	--Continuous, not a trigger. The printed text has no colon, which in PSCT is
	--exactly the difference: this applies as the cards arrive rather than
	--activating, so it takes no chain link and cannot be responded to. Red-Eyes
	--Flare Metal Dragon (44405066) is the reference -- its burn is
	--EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS for the same reason. Built as a
	--TRIGGER_F first, which put it on the chain and let the opponent respond to
	--every draw.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.handop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_MTG}
s.listed_names={CARD_MTG_SWAMP}

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	return bc~=nil and bc:IsRelateToBattle()
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local bc=e:GetHandler():GetBattleTarget()
	if chk==0 then return bc~=nil end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		Duel.Destroy(bc,REASON_EFFECT)
	end
end

--Counted per card, not per event: the author's original wording ended "inflict
--800 damage to them for each", so two cards drawn is 1600, not 800.
function s.handfilter(c,tp)
	return c:IsLocation(LOCATION_HAND) and c:IsControler(tp)
end
--Both halves in one operation, since a single event can add cards to both
--hands and each side is paid separately.
function s.handop(e,tp,eg,ep,ev,re,r,rp)
	local mine=eg:FilterCount(s.handfilter,nil,tp)
	local theirs=eg:FilterCount(s.handfilter,nil,1-tp)
	if mine>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Recover(tp,800*mine,REASON_EFFECT)
	end
	if theirs>0 then
		Duel.Hint(HINT_CARD,0,id)
		Duel.Damage(1-tp,800*theirs,REASON_EFFECT)
	end
end
