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

local function convertRowDataTextTableToNumberIfPossible(rowDataInText)
	
	local rowData = {}
	
	local splitRowDataInText = string.split(rowDataInText, ",")
	
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

local function loadDataFromCSV(dataToLoad, hasHeader)
	
	local headerTable
	
	local dataMatrix = {}
	
	local headerString
	
	local dataString = dataToLoad
	
	local dataStringTable
	
	local dataStringLength = string.len(dataString)
	
	if hasHeader then
		
		headerString = string.split(dataToLoad, "\n")[1]
		
		headerTable = string.split(headerString, ",")
		
		local stringLengthToRemove = string.len(headerString) + 1
		
		dataString = string.sub(dataToLoad, stringLengthToRemove, dataStringLength)
		
	end
	
	dataStringTable = string.split(dataToLoad, "\n")
	
	for i, rowDataInText in ipairs(dataStringTable) do
		
		local rowData = convertRowDataTextTableToNumberIfPossible(rowDataInText)
		
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

local loadDataDictionary = {
	
	["csv"] = loadDataFromCSV,
	
	["MatrixL"] = loadDataFromMatrixTable,
	
}

function DataCritic.new(dataToLoad, hasHeader, fileType)
	
	local NewDataCritic = {}

	setmetatable(NewDataCritic, DataCritic)
	
	local header
	
	local data
	
	local success = pcall(function()
		
		header, data = loadDataDictionary[fileType](dataToLoad, hasHeader)
		
	end)
	
	if not success then error("Could not open " .. dataToLoad .. " file type!") end
	
	NewDataCritic.Header = header
	
	NewDataCritic.Data = data
	
	return NewDataCritic
	
end

return DataCritic
