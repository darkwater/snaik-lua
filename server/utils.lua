ccodes = {}
ccodes[00] = "NUL"   ccodes[16] = "DLE"
ccodes[01] = "SOH"   ccodes[17] = "DC1"
ccodes[02] = "STX"   ccodes[18] = "DC2"
ccodes[03] = "ETX"   ccodes[19] = "DC3"
ccodes[04] = "EOT"   ccodes[20] = "DC4"
ccodes[05] = "ENQ"   ccodes[21] = "NAK"
ccodes[06] = "ACK"   ccodes[22] = "SYN"
ccodes[07] = "BEL"   ccodes[23] = "ETB"
ccodes[08] = "BS "   ccodes[24] = "CAN"
ccodes[09] = "HT "   ccodes[25] = "EM "
ccodes[10] = "LF "   ccodes[26] = "SUB"
ccodes[11] = "VT "   ccodes[27] = "ESC"
ccodes[12] = "FF "   ccodes[28] = "FS "
ccodes[13] = "CR "   ccodes[29] = "GS "
ccodes[14] = "SO "   ccodes[30] = "RS "
ccodes[15] = "SI "   ccodes[31] = "US "

function getccode(byte)
    if type(byte) ~= "number" then
        byte = string.byte(byte)
    end
    return ccodes[byte] or byte
end

function print_r(tbl, pre)
    if not pre then pre = "" end
    for k,v in pairs(tbl) do
        if type(v) == "table" then
            print(k .. ":")
            print_r(v, pre .. "    ")
        else
            print(pre .. k, v)
        end
    end
end
