--"MTG" shared library
--Loaded by every card in the set with Duel.LoadScript("mtg_common.lua").
--
--The whole set runs on one idea: cards from your Extra Deck are banished
--face-up as a cost, and the five "lands" pay you back for being banished, then
--return on your Standby Phase. That makes the Extra Deck a renewable resource
--rather than a toolbox, which is why almost everything here is about banishing
--from LOCATION_EXTRA and reading LOCATION_REMOVED.
--
--Deliberately independent of aerol8_common.lua. The two sets share no
--semantics, and inheriting "mech" predicates by accident would be worse than
--repeating a couple of small helpers.

MTG = MTG or {}

--Setcode 0xa57, verified unused across 22,689 cards and 741 setcodes in every
--shipped database, checked on the low 12 bits so all 16 subtype nibbles are
--covered. Flat, with no sub-archetypes: the cards name individual lands rather
--than treating "land" as a group.
SET_MTG = 0xa57

--Reusing 0xa57 as the counter code -- free there too. Declared in strings.conf.
COUNTER_WANDERING_EMPEROR = 0xa57

CARD_MTG_ISLAND    = 900000711
CARD_MTG_MOUNTAIN  = 900000712
CARD_MTG_FOREST    = 900000713
CARD_MTG_PLAINS    = 900000714
CARD_MTG_SWAMP     = 900000715
CARD_SAMURAI_TOKEN = 900000791

--Flag codes get their own values rather than reusing a passcode: SetCountLimit
--registers its counter under the passcode, and a flag keyed to the same number
--fights it.
MTG_FLAG_BANISHED_THIS_TURN = 0x9a570001

------------------------------------------------------------------------------
-- Banishing from the Extra Deck
------------------------------------------------------------------------------

function MTG.RemovableFilter(c)
	return c:IsAbleToRemoveAsCost()
end

function MTG.NamedRemovableFilter(c,code)
	return c:IsCode(code) and c:IsAbleToRemoveAsCost()
end

--"banish `ct` cards from your Extra Deck face-up, including 1 `code`"
--
--Checked as two questions rather than one, because the named card is also one
--of the `ct`: there must be a copy of `code` available, and enough banishable
--cards in total. Asking only the second lets a hand with no land pass.
function MTG.CanPayExtra(tp,ct,code)
	return Duel.IsExistingMatchingCard(MTG.NamedRemovableFilter,tp,LOCATION_EXTRA,0,1,nil,code)
		and Duel.GetMatchingGroupCount(MTG.RemovableFilter,tp,LOCATION_EXTRA,0,nil)>=ct
end

--Returns the chosen group without banishing it, so callers can use this both
--as a cost and inside a summon procedure, which banish at different moments.
--The named card is picked first so the player cannot select their way into a
--set of `ct` cards that happens to contain no land.
function MTG.SelectExtra(tp,ct,code)
	local named=Duel.GetMatchingGroup(MTG.NamedRemovableFilter,tp,LOCATION_EXTRA,0,nil,code)
	if #named==0 then return nil end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=named:Select(tp,1,1,nil)
	if ct>1 then
		local rest=Duel.GetMatchingGroup(MTG.RemovableFilter,tp,LOCATION_EXTRA,0,g)
		if #rest<ct-1 then return nil end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		g:Merge(rest:Select(tp,ct-1,ct-1,nil))
	end
	return g
end

--Cost form, for the Spells and Traps that open with "To activate this card,
--you must banish...".
function MTG.ExtraBanishCost(ct,code)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return MTG.CanPayExtra(tp,ct,code) end
		local g=MTG.SelectExtra(tp,ct,code)
		if g then Duel.Remove(g,POS_FACEUP,REASON_COST) end
	end
end

--Summon procedure form, for "Must first be Special Summoned (from your hand)
--by banishing...".
--
--Shaped after aux.AddMaleficSummonProcedure, which is the engine's own version
--of this for Malefic monsters. That one banishes exactly one named card; these
--cards banish several of which one must be named, so the procedure is spelled
--out here rather than reused. The condition/target/operation split, the
--KeepAlive on the selected group and the LabelObject handoff are all from that
--pattern -- EFFECT_SPSUMMON_PROC selects during target and pays during
--operation, so the group has to survive between the two.
function MTG.AddExtraBanishSummonProcedure(c,ct,code)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(function(e,c)
		if c==nil then return true end
		local tp=c:GetControler()
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and MTG.CanPayExtra(tp,ct,code)
	end)
	e1:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk,c)
		local g=MTG.SelectExtra(tp,ct,code)
		if not g or #g==0 then return false end
		g:KeepAlive()
		e:SetLabelObject(g)
		return true
	end)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp,c)
		local g=e:GetLabelObject()
		if not g then return end
		Duel.Remove(g,POS_FACEUP,REASON_COST)
		g:DeleteGroup()
	end)
	c:RegisterEffect(e1)
end

------------------------------------------------------------------------------
-- The lands
------------------------------------------------------------------------------

--"if there are 3 <name> banished"
--
--Counts your own banished copies. These only ever reach the banish zone from
--your Extra Deck, so there is no need to look at your opponent's.
function MTG.BanishedCount(tp,code)
	return Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_REMOVED,0,nil,code)
end

--"During your Standby Phase, if this card is banished: Shuffle it into the
--Extra Deck."
--
--Identical on all five lands, so it lives here. Mandatory: the printed text has
--no "You can", though the card still has to be relevant to the effect when it
--resolves, since it may have left the banish zone in between.
--
--EFFECT_TYPE_**FIELD**, not SINGLE. A phase change is a field event, so a
--single-card trigger never receives it -- registered as SINGLE this fired for
--none of the five lands and none of them ever came back. Every shipped card
--that triggers on a phase uses FIELD with a range saying where the card must
--be; Ghost Reaper equivalents in the banish zone are written exactly this way.
--The mistake is invisible to both validation passes: it is real API, correctly
--spelled, and it loads without complaint.
function MTG.AddStandbyReturn(c,strid)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(strid)
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_REMOVED)
	e1:SetCountLimit(1)
	--"During your Standby Phase" -- the turn player check is what makes it
	--yours rather than either player's.
	--
	--The turn-ID guard is borrowed from Metaphys Nephthys (72355272), which
	--tests GetTurnCount()==GetTurnID()+1 so a card cannot come back during the
	--same turn it left. Normal play never reaches that here, since the Standby
	--Phase precedes the Main Phase these are banished in -- but a land banished
	--during your own Draw or Standby Phase would otherwise bounce straight back.
	e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		return Duel.GetTurnPlayer()==tp and c:IsLocation(LOCATION_REMOVED)
			and c:GetTurnID()~=Duel.GetTurnCount()
	end)
	e1:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return e:GetHandler():IsAbleToExtra() end
		Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,tp,LOCATION_REMOVED)
	end)
	e1:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) then
			Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end)
	c:RegisterEffect(e1)
end

------------------------------------------------------------------------------
-- Turn tracking
------------------------------------------------------------------------------

--"cards banished this turn", which Memory Deluge counts.
--
--The engine has no running total for this, so a global watcher registers one
--flag per card banished and the count is read back with GetFlagEffect. Flags
--reset at the End Phase, which is what "this turn" means here.
function MTG.InstallTrackers()
	if MTG.trackers_installed then return end
	MTG.trackers_installed=true
	local ge1=Effect.GlobalEffect()
	ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	ge1:SetCode(EVENT_REMOVE)
	ge1:SetOperation(MTG.TrackBanish)
	Duel.RegisterEffect(ge1,0)
end

--Counted duel-wide on player 0: the printed text says "the number of cards
--banished this turn" without naming an owner, so every banish counts.
function MTG.TrackBanish(e,tp,eg,ep,ev,re,r,rp)
	for _ in aux.Next(eg) do
		Duel.RegisterFlagEffect(0,MTG_FLAG_BANISHED_THIS_TURN,RESET_PHASE|PHASE_END,0,1)
	end
end

function MTG.BanishedThisTurn()
	return Duel.GetFlagEffect(0,MTG_FLAG_BANISHED_THIS_TURN)
end
