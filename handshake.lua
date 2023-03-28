i=input;o=output;gn=i.getNumber;gb=i.getBool;sn=o.setNumber;sb=o.setBool
keys = {{key}}
lastNonce = nil
lastContent = nil
state = 0
lC = false
disconnectTimeout = 0

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

function onTick()
	local nonce, content, res, current
	sb(1, false)
	sb(10, false)
	sb(11, false)
	for i=1,20 do
		sn(i, 0)
	end
	if disconnectTimeout > 0 then
		disconnectTimeout = disconnectTimeout - 1
		sb(10,true)
	end
	if state < 0 then
		state = state + 1
	elseif state == 0 then
		if gb(10) and not lC then
			lC = true
			state = 1
			sn(20, VERSION)
			if gb(11) then
				sb(1, true)
				nonce = ""
				content = ""
				for i=1,19 do
					current = generateRandStr()
					if i <= 3 then
						nonce = nonce .. current
					else
						content = content .. current
					end
					sn(i, (string.unpack("f", current)))
				end
				lastNonce = nonce
				lastContent = content
			end
		end
	elseif state <= 3 then
		state = state + 1
	elseif state == 4 then
		state = 5
		if gb(1) then
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
		if gb(11) then
			res = ""
			for i=1,16 do
				current = gn(i)
				res = res .. (string.pack("f", current))
			end
			if res == encrypt(lastNonce, lastContent) then
				state = 9
			else
				state = -10
				disconnectTimeout = 1000
			end
		else
			if gn(20) == VERSION then
				state = 9
			else
				state = 10
			end
		end
	elseif state == 9 then
		if gb(10) then
			sb(11, true)
		else
			state = 0
		end
	else
		if not gb(10) then
			state = 0
		end
	end
	if not gb(10) then
		lC = false
	end
end
