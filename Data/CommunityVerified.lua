local _, ns = ...
-- Reviewed community records. Only confirmed creature-to-ability evidence belongs here.
-- Contributions are stored separately until reviewed. No player identifiers.
ns.CommunityVerified = {
    [0] = nil, -- reserved; numeric NPC IDs are required for published records
}
-- Giant Moss Creeper was directly tamed and Bite 4 + Web 2 observed by a
-- tester in Forever beta, but its NPC ID has NOT been captured. It is therefore
-- deliberately excluded from the keyed production table until ID verification.
ns.CommunityPendingVerification = {
    {name="Giant Moss Creeper", minLevel=24, maxLevel=25,
     abilities={{ability="Bite",rank=4},{ability="Web",rank=2}},
     evidence="direct-tame-user-report", status="needs-npc-id"}
}
