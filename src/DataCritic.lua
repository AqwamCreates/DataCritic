local AqwamMatrixLibrary = require(script.AqwamMatrixLibraryLinker.Value)

DataCritic = {}

DataCritic.__index = DataCritic

local function deepCopyTable(original, copies)

	copies = copies or {}

	local originalType = type(original)

	local copy

	if (originalType == 'table') then

		if copies[original] then

			copy = copies[original]

		else

			copy = {}

			copies[original] = copy

			for originalKey, originalValue in next, original, nil do

				copy[deepCopyTable(originalKey, copies)] = deepCopyTable(originalValue, copies)

			end

			setmetatable(copy, deepCopyTable(getmetatable(original), copies))

		end

	else -- number, string, boolean, etc

		copy = original

	end

	return copy

end

local function convertRowDataTextTableToNumberIfPossible(rowDataInText, separator)
	
	local rowData = {}
	
	local splitRowDataInText = string.split(rowDataInText, separator)
	
	for i, value in ipairs(splitRowDataInText) do
		
		
		
		local numberValue = tonumber(value)
		
		if numberValue then
			
			table.insert(rowData, numberValue)
			
		else
			
			table.insert(rowData, value)
			
		end
		
	end
	
	return rowData
	
end

local function loadDataFromText(dataToLoad, hasHeader, separator)
	
	separator = separator or ","
	
	local patternToRemoveSpace =  separator .. "%s*"
	
	dataToLoad = string.gsub(dataToLoad, patternToRemoveSpace, separator)
	
	local headerTable
	
	local dataMatrix = {}
	
	local headerString
	
	local dataString = dataToLoad
	
	local dataStringTable
	
	local dataStringLength = string.len(dataString)
	
	if hasHeader then
		
		headerString = string.split(dataToLoad, "\n")[1]
		
		headerTable = string.split(headerString, separator)
		
		local stringLengthToRemove = string.len(headerString) + 2
		
		dataString = string.sub(dataToLoad, stringLengthToRemove, dataStringLength)
		
	end
	
	dataStringTable = string.split(dataString, "\n")
	
	for i, rowDataInText in ipairs(dataStringTable) do
		
		local rowData = convertRowDataTextTableToNumberIfPossible(rowDataInText, separator)
		
		table.insert(dataMatrix, rowData)
		
	end
	
	return headerTable, dataMatrix
	
end

local function loadDataFromMatrixTable(dataToLoad, hasHeader)
	
	local headerTable
	
	local dataMatrix = deepCopyTable(dataToLoad)
	
	if hasHeader then
		
		headerTable = dataToLoad[1]
		
		table.remove(dataMatrix, 1)
		
	end
	
	return headerTable, dataMatrix
	
end

local loadDataFunctionList = {
	
	["csv"] = loadDataFromText,
	
	["txt"] = loadDataFromText,
	
	["Matrix"] = loadDataFromMatrixTable,
	
}

local function generateCapitalAlphabetHeaderTable(length)
	
	local headerTable = {}
	
	local startAscii = string.byte('A')
	
	local endAscii = string.byte('Z')

	for i = 1, length do
		
		local index = i - 1
		
		local sequence = ""

		repeat
			
			local remainder = (index % 26)
			
			sequence = string.char(startAscii + remainder) .. sequence
			
			index = math.floor(index / 26)
			
		until (index == 0)

		table.insert(headerTable, sequence)
	end

	return headerTable
end

function DataCritic.new(dataToLoad, hasHeader, fileType, separator)
	
	local NewDataCritic = {}

	setmetatable(NewDataCritic, DataCritic)
	
	local headerTable
	
	local dataMatrix
	
	local success = pcall(function()
		
		headerTable, dataMatrix = loadDataFunctionList[fileType](dataToLoad, hasHeader, separator)
		
	end)
	
	if not success then error("Could not open " .. dataToLoad .. " file type!") end
	
	if not headerTable then headerTable = generateCapitalAlphabetHeaderTable(#dataMatrix[1]) end
	
	NewDataCritic.Header = headerTable
	
	NewDataCritic.Data = dataMatrix
	
	return NewDataCritic
	
end

function DataCritic:printHeader()
	
	print(self.Header)
	
end

function DataCritic:printData()
	
	AqwamMatrixLibrary:printMatrix(self.Data)
	
end

function DataCritic:getHeader()
	
	return self.Header
	
end

function DataCritic:getData()
	
	return self.Data
	
end

return DataCritic
