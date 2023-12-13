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

	else

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
	
	NewDataCritic.PreviousData = nil
	
	NewDataCritic.AlwaysSavePreviousData = false
	
	return NewDataCritic
	
end

function DataCritic:setAlwaysSavePreviousData(isPreviousDataAlwaysSaved)
	
	self.AlwaysSavePreviousData = isPreviousDataAlwaysSaved
	
end

function DataCritic:setHeader(headerTable)
	
	self.Header = headerTable
	
end

function DataCritic:setColumnHeader(columnHeaderValue, column)
	
	self.Header[column] = columnHeaderValue
	
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

function DataCritic:setValue(value, row, column)
	
	self.Data[row][column] = value
	
end

function DataCritic:replaceMissingDataWithValue(value, rowIndex, columnIndex)
	
	local rowIndexValueType = type(rowIndex)
	
	local columnIndexValueType = type(columnIndex)
	
	if (rowIndexValueType == "number") and (columnIndexValueType == "number") then
		
		local selectedValue = self.Data[rowIndex][columnIndex]
		
		if (type(selectedValue) == "nil") then self.Data[rowIndex][columnIndex] = value end
		
	elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then
		
		for i = 1, #self.Data, 1 do
			
			if (type(self.Data[rowIndex][i]) == "nil") then self.Data[rowIndex][i] = value end
			
		end
		
	elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then
		
		for i = 1, #self.Data[1], 1 do

			if (type(self.Data[i][columnIndex]) == "nil") then self.Data[i][columnIndex] = value end

		end
		
	else
		
		error("Invalid row or column index values.")
		
	end
	
end

function DataCritic:replaceMissingDataWithFunction(functionToApply, rowIndex, columnIndex)
	
	local rowIndexValueType = type(rowIndex)

	local columnIndexValueType = type(columnIndex)
	
	if (rowIndexValueType == "number") and (columnIndexValueType == "number") then

		local selectedValue = self.Data[rowIndex][columnIndex]

		if (type(selectedValue) == "nil") then 
			
			self.Data[rowIndex][columnIndex] = functionToApply(self.Data[rowIndex][columnIndex]) 
			
		end

	elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then

		for i = 1, #self.Data, 1 do

			if (type(self.Data[rowIndex][i]) == "nil") then self.Data[rowIndex][i] = functionToApply(self.Data[rowIndex][i]) end

		end

	elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then

		for i = 1, #self.Data[1], 1 do

			if (type(self.Data[i][columnIndex]) == "nil") then self.Data[i][columnIndex] = functionToApply(self.Data[rowIndex][i]) end

		end

	else

		error("Invalid row or column index values.")

	end
	
end

function DataCritic:extractRows(startingIndex, finalIndex)
	
	return AqwamMatrixLibrary:extractRows(self.Data, startingIndex, finalIndex)
	
end

function DataCritic:extractColumns(startingIndex, finalIndex)
	
	return AqwamMatrixLibrary:extractColumns(self.Data, startingIndex, finalIndex)
	
end

function DataCritic:addNewColumn(dataVector, columnIndex, columnHeaderValue)
	
	local columnIndexValueType = type(columnIndex)

	if (columnIndexValueType ~= "number") and (columnIndexValueType ~= "nil") then error("Invalid column index value.") end
	
	local numberOfColumns =  #self.Data[1]
	
	columnIndex = columnIndex or numberOfColumns
	
	if (columnIndex <= 0) then error("The column index cannot be less than or equal to zero.") end
	
	if (columnIndex == numberOfColumns) then
		
		self.Data = AqwamMatrixLibrary:horizontalConcatenate(self.Data, dataVector)
		
	elseif (columnIndex == 1) then
		
		self.Data = AqwamMatrixLibrary:horizontalConcatenate(dataVector, self.Data)
		
	else
		
		local leftColumnVector = AqwamMatrixLibrary:extractColumns(1, columnIndex)
		
		local rightColumnVector = AqwamMatrixLibrary:extractColumns(columnIndex + 1, numberOfColumns)
		
		self.Data = AqwamMatrixLibrary:horizontalConcatenate(leftColumnVector, dataVector, rightColumnVector)
				
	end
	
	if columnHeaderValue then table.insert(self.Header, columnIndex, columnHeaderValue) end
	
end

return DataCritic
