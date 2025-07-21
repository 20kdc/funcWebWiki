-- Shunt because 'hidden file'.
-- Also contains the Redbean configuration (for easier updates)
ProgramMaxPayloadSize(0x1000000)
return load(LoadAsset("kernel.lua"))(...)
