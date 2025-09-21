keys = {0xf9673a09,0x3ad6543a,0x5772040b,0xa163933a,0x2d46ede3,0x8e07280a,0xb1c6c69d,0x8565c997}
lastNonce = nil
lastContent = nil
state = 0
lC = false
disconnectTimeout = 0

-- Version is used to identify, if the other side uses a similar protocol, in order to avoid conflicting interpretations
-- of siinput.getNumberals. It is chosen to be very unlikely to appear by chance
VERSION = 1923131
require("chacha20")

function generateRandStr()
	local a,b;a=math.random(1,2^32-1);
	return (string.pack("I4",a))
end

function encrypt(nonce, content)
	local keyEnc, res
	keyEnc = string.pack("I4I4I4I4I4I4I4I4", table.unpack(keys))
	res = chacha20(keyEnc, 0, nonce, content)
	return res
end


-- tumfl: preserve
function onTick()
	local nonce, content, res, current
	output.setBool(1, false)
	output.setBool(10, false)
	output.setBool(11, false)
	for i=1,20 do
		output.setNumber(i, 0)
	end
	if disconnectTimeout > 0 then
		disconnectTimeout = disconnectTimeout - 1
		output.setBool(10,true)
	end
	if state < 0 then
		state = state + 1
	elseif state == 0 then
		if input.getBool(10) and not lC then
			lC = true
			state = 1
			output.setNumber(20, VERSION)
			if input.getBool(11) then
				output.setBool(1, true)
				nonce = ""
				content = ""
				for i=1,19 do
					current = generateRandStr()
					if i <= 3 then
						nonce = nonce .. current
					else
						content = content .. current
					end
					output.setNumber(i, (string.unpack("f", current)))
				end
				lastNonce = nonce
				lastContent = content
			end
		end
	elseif state <= 3 then
		state = state + 1
	elseif state == 4 then
		state = 5
		output.setNumber(20, VERSION)
		if input.getBool(1) then
			nonce = ""
			content = ""
			for i=1,19 do
				current = string.pack("f", input.getNumber(i))
				if i <= 3 then
					nonce = nonce .. current
				else
					content = content .. current
				end
			end
			res = table.pack(string.unpack("ffffffffffffffff", encrypt(nonce, content)))
			for i=1,16 do
				output.setNumber(i, res[i])
			end
		end
	elseif state <= 7 then
		state = state + 1
	elseif state == 8 then
		if input.getBool(11) then
			res = ""
			for i=1,16 do
				current = input.getNumber(i)
				res = res .. (string.pack("f", current))
			end
			if res == encrypt(lastNonce, lastContent) then
				state = 9
			else
				state = -10
				disconnectTimeout = 1000
			end
		else
			if input.getNumber(20) == VERSION then
				state = 9
			else
				state = 10
			end
		end
	elseif state == 9 then
		if input.getBool(10) then
			output.setBool(11, true)
		else
			state = 0
		end
	else
		if not input.getBool(10) then
			state = 0
		end
	end
	if not input.getBool(10) then
		lC = false
	end
end
