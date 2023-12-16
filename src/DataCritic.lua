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
	
	["matrix"] = loadDataFromMatrixTable,
	
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
	
	NewDataCritic.PreviousHeader = nil
	
	NewDataCritic.PreviousData = nil
	
	NewDataCritic.AlwaysSavePreviousDataAndHeader = false
	
	NewDataCritic.RevertToPreviousDataAndHeaderIfError = true
	
	return NewDataCritic
	
end

function DataCritic:wrapFunctionInProtectedCall(functionToRun)
	
	local previousData = deepCopyTable(self.Data)
	
	local previousHeader = deepCopyTable(self.Header)
	
	if (self.AlwaysSavePreviousDataAndHeader) then
		
		self.PreviousHeader = previousHeader
		self.PreviousData = previousData

	end
	
	local success = pcall(functionToRun)
	
	if (not success) and (self.RevertToPreviousDataAndHeaderIfError) then 
		
		self.Header = previousHeader
		self.Data = previousData
		
	end
	
	return success
	
end

function DataCritic:setAlwaysSavePreviousData(isEnabled)

	self.AlwaysSavePreviousData = isEnabled

end

function DataCritic:setRevertToPreviousDataAndHeaderIfError(isEnabled)
	
	self.RevertToPreviousDataAndHeaderIfError = isEnabled
	
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

function DataCritic:printDataFrame()
	
	local maxLengthArray = {}
	
	local maxRowIndexLength = string.len(tostring(#self.Data))

	for i = 1, #self.Header, 1 do
		
		table.insert(maxLengthArray, string.len(tostring(self.Header[i])))
		
	end

	for column = 1, #self.Data[1], 1 do
		
		for row = 1, #self.Data, 1 do
			
			local value = self.Data[row][column]
			
			local stringValue
			
			if (type(value) == "nil") then
				
				stringValue = "nil"
				
			else
				
				stringValue = tostring(value)
				
			end
			
			maxLengthArray[column] = math.max(maxLengthArray[column], string.len(stringValue))
			
		end
		
	end

	local stringToPrint = "\n\n" .. string.rep(" ", maxRowIndexLength + 3) .. "+"

	for i = 1, #self.Header, 1 do
		
		stringToPrint = stringToPrint .. string.rep("-", maxLengthArray[i] + 2) .. "+"
		
	end
	
	stringToPrint = stringToPrint .. "\n" .. string.rep(" ", maxRowIndexLength + 3) .. "| "

	for i = 1, #self.Header, 1 do
		
		stringToPrint = stringToPrint .. string.format("%" .. maxLengthArray[i] .. "s", self.Header[i]) .. " | "
		
	end

	stringToPrint = stringToPrint .. "\n+" .. string.rep("-", maxRowIndexLength + 2) .. "+"

	for i = 1, #self.Header, 1 do
		
		stringToPrint = stringToPrint .. string.rep("-", maxLengthArray[i] + 2) .. "+"
		
	end

	stringToPrint = stringToPrint .. "\n"

	for row = 1, table.maxn(self.Data), 1 do
		
		stringToPrint = stringToPrint .. "| " .. string.format("%" .. maxRowIndexLength .. "s", row) .. " | "
		
		for column = 1, table.maxn(self.Data[row]), 1 do
			
			local value = self.Data[row][column]
			
			local stringToConcatenate
			
			if (type(value) == "nil") then
				
				stringToConcatenate = "nil"
				
			else
				
				stringToConcatenate = tostring(value)
				
			end
			
			stringToPrint = stringToPrint .. string.format("%" .. maxLengthArray[column] .. "s", stringToConcatenate) .. " | "
			
		end
		
		stringToPrint = stringToPrint .. "\n"
		
	end

	stringToPrint = stringToPrint .. "+" .. string.rep("-", maxRowIndexLength + 2) .. "+"

	for i = 1, #self.Header, 1 do

		stringToPrint = stringToPrint .. string.rep("-", maxLengthArray[i] + 2) .. "+"

	end
	
	stringToPrint = stringToPrint .. "\n\n"

	print(stringToPrint)
	
end

function DataCritic:getHeader()
	
	return self.Header
	
end

function DataCritic:getPreviousHeader()
	
	return self.PreviousHeader
	
end

function DataCritic:getData()
	
	return self.Data
	
end

function DataCritic:getPreviousData()

	return self.PreviousData

end

function DataCritic:setValue(value, row, column)
	
	self.Data[row][column] = value
	
end

function DataCritic:revertToPreviousDataFrame()
	
	local success = pcall(function()
		
		local currentHeader = self.Header

		local currentData = self.Data

		self.Header = self.PreviousHeader

		self.Data = self.PreviousData

		self.PreviousHeader = currentHeader

		self.PreviousData = currentData
		
	end)
	
	return success
	
end

function DataCritic:replaceMissingValuesWithValue(value, rowIndex, columnIndex)
	
	return self:wrapFunctionInProtectedCall(function()
		
		local rowIndexValueType = type(rowIndex)

		local columnIndexValueType = type(columnIndex)

		if (rowIndexValueType == "number") and (columnIndexValueType == "number") then

			local selectedValue = self.Data[rowIndex][columnIndex]

			if (type(selectedValue) == "nil") then self.Data[rowIndex][columnIndex] = value end

		elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then

			for i = 1, #self.Data[1], 1 do

				if (type(self.Data[rowIndex][i]) == "nil") then self.Data[rowIndex][i] = value end

			end

		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then

			for i = 1, #self.Data, 1 do

				if (type(self.Data[i][columnIndex]) == "nil") then self.Data[i][columnIndex] = value end

			end
			
		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "nil") then
			
			for i = 1, #self.Data, 1 do
				
				for j = 1, #self.Data[1] do
					
					if (type(self.Data[i][j]) == "nil") then self.Data[i][j] = value end
					
				end
				
			end

		else

			error("Invalid row or column index values.")

		end
		
	end)
	
end

function DataCritic:replaceMissingValuesWithFunction(functionToApply, rowIndex, columnIndex)
	
	return self:wrapFunctionInProtectedCall(function()
		
		local rowIndexValueType = type(rowIndex)

		local columnIndexValueType = type(columnIndex)

		if (rowIndexValueType == "number") and (columnIndexValueType == "number") then

			local selectedValue = self.Data[rowIndex][columnIndex]

			if (type(selectedValue) == "nil") then 

				self.Data[rowIndex][columnIndex] = functionToApply(self.Data[rowIndex][columnIndex]) 

			end

		elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then

			for i = 1, #self.Data[1], 1 do

				if (type(self.Data[rowIndex][i]) == "nil") then self.Data[rowIndex][i] = functionToApply(self.Data[rowIndex][i]) end

			end

		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then

			for i = 1, #self.Data, 1 do

				if (type(self.Data[i][columnIndex]) == "nil") then self.Data[i][columnIndex] = functionToApply(self.Data[i][columnIndex]) end

			end
			
		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "nil") then

			for i = 1, #self.Data, 1 do

				for j = 1, #self.Data[1] do

					if (type(self.Data[i][j]) == "nil") then self.Data[i][j] = functionToApply(self.Data[i][j]) end

				end

			end
			
		else

			error("Invalid row or column index values.")

		end
		
	end)
	
end

function DataCritic:applyFunction(functionToApply, rowIndex, columnIndex)

	return self:wrapFunctionInProtectedCall(function()

		local rowIndexValueType = type(rowIndex)

		local columnIndexValueType = type(columnIndex)

		if (rowIndexValueType == "number") and (columnIndexValueType == "number") then

			local selectedValue = self.Data[rowIndex][columnIndex]

			if (type(selectedValue) ~= "nil") then 

				self.Data[rowIndex][columnIndex] = functionToApply(self.Data[rowIndex][columnIndex]) 

			end

		elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then

			for i = 1, #self.Data[1], 1 do

				if (type(self.Data[rowIndex][i]) ~= "nil") then self.Data[rowIndex][i] = functionToApply(self.Data[rowIndex][i]) end

			end

		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then

			for i = 1, #self.Data, 1 do

				if (type(self.Data[i][columnIndex]) ~= "nil") then self.Data[i][columnIndex] = functionToApply(self.Data[i][columnIndex]) end

			end
			
			
		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "nil") then

			for i = 1, #self.Data, 1 do

				for j = 1, #self.Data[1] do

					if (type(self.Data[i][j]) ~= "nil") then self.Data[i][j] = functionToApply(self.Data[i][j]) end

				end

			end
			
		else

			error("Invalid row or column index values.")

		end

	end)

end

function DataCritic:extractRows(startingIndex, finalIndex)
	
	return AqwamMatrixLibrary:extractRows(self.Data, startingIndex, finalIndex)
	
end

function DataCritic:extractColumns(startingIndex, finalIndex)
	
	return AqwamMatrixLibrary:extractColumns(self.Data, startingIndex, finalIndex)
	
end

function DataCritic:addColumn(dataColumnVector, columnIndex, columnHeaderValue)
	
	return self:wrapFunctionInProtectedCall(function()
		
		local columnIndexValueType = type(columnIndex)

		if (columnIndexValueType ~= "number") and (columnIndexValueType ~= "nil") then error("Invalid column index value.") end

		local numberOfColumns =  #self.Data[1]

		columnIndex = columnIndex or numberOfColumns

		if (columnIndex <= 0) then error("The column index cannot be less than or equal to zero.") end
		
		if (#dataColumnVector ~= #self.Data) then error("Incompatible number of rows!") end

		if (columnIndex == numberOfColumns) then

			self.Data = AqwamMatrixLibrary:horizontalConcatenate(self.Data, dataColumnVector)

		elseif (columnIndex == 1) then

			self.Data = AqwamMatrixLibrary:horizontalConcatenate(dataColumnVector, self.Data)

		else

			local leftColumnVector = AqwamMatrixLibrary:extractColumns(self.Data, 1, columnIndex)

			local rightColumnVector = AqwamMatrixLibrary:extractColumns(self.Data, columnIndex + 1, numberOfColumns)

			self.Data = AqwamMatrixLibrary:horizontalConcatenate(leftColumnVector, dataColumnVector, rightColumnVector)

		end

		if columnHeaderValue then table.insert(self.Header, columnIndex, columnHeaderValue) end
		
	end)
	
end

function DataCritic:addRow(dataRowVector, rowIndex)

	return self:wrapFunctionInProtectedCall(function()

		local rowIndexValueType = type(rowIndex)

		if (rowIndexValueType ~= "number") and (rowIndexValueType ~= "nil") then error("Invalid column index value.") end

		local numberOfRows = #self.Data

		rowIndex = rowIndex or numberOfRows

		if (rowIndex <= 0) then error("The column index cannot be less than or equal to zero.") end
		
		if (#dataRowVector[1] ~= #self.Data[1]) then error("Incompatible number of columns!") end

		if (rowIndex == numberOfRows) then

			self.Data = AqwamMatrixLibrary:verticalConcatenate(self.Data, dataRowVector)

		elseif (rowIndex == 1) then

			self.Data = AqwamMatrixLibrary:verticalConcatenate(dataRowVector, self.Data)

		else

			local upRowVector = AqwamMatrixLibrary:extractRows(self.Data, 1, rowIndex)

			local bottomRowVector = AqwamMatrixLibrary:extractRows(self.Data, rowIndex + 1, numberOfRows)

			self.Data = AqwamMatrixLibrary:verticalConcatenate(upRowVector, dataRowVector, bottomRowVector)

		end

	end)

end

function DataCritic:deleteColumn(columnIndex)

	return self:wrapFunctionInProtectedCall(function()

		local columnIndexValueType = type(columnIndex)

		if (columnIndexValueType ~= "number") and (columnIndexValueType ~= "nil") then error("Invalid column index value.") end

		local numberOfColumns =  #self.Data[1]

		columnIndex = columnIndex or numberOfColumns

		if (columnIndex <= 0) then error("The column index cannot be less than or equal to zero.") end
		
		if (columnIndex > numberOfColumns) then error("The column index exceeds the number of columns.") end

		if (columnIndex == numberOfColumns) then

			self.Data = AqwamMatrixLibrary:extractColumns(self.Data, 1, numberOfColumns - 1)

		elseif (columnIndex == 1) then

			self.Data = AqwamMatrixLibrary:extractColumns(self.Data, 2, numberOfColumns)

		else

			local leftColumnVector = AqwamMatrixLibrary:extractColumns(self.Data, 1, columnIndex - 1)

			local rightColumnVector = AqwamMatrixLibrary:extractColumns(self.Data, columnIndex + 1, numberOfColumns)

			self.Data = AqwamMatrixLibrary:horizontalConcatenate(leftColumnVector, rightColumnVector)

		end

		table.remove(self.Header, columnIndex)

	end)

end

function DataCritic:deleteRow(rowIndex)

	return self:wrapFunctionInProtectedCall(function()

		local rowIndexValueType = type(rowIndex)

		if (rowIndexValueType ~= "number") and (rowIndexValueType ~= "nil") then error("Invalid column index value.") end

		local numberOfRows =  #self.Data

		rowIndex = rowIndex or numberOfRows

		if (rowIndex <= 0) then error("The column index cannot be less than or equal to zero.") end

		if (rowIndex > numberOfRows) then error("The row index exceeds the number of rows.") end

		if (rowIndex == numberOfRows) then

			self.Data = AqwamMatrixLibrary:extractRows(self.Data, 1, numberOfRows - 1)

		elseif (rowIndex == 1) then

			self.Data = AqwamMatrixLibrary:extractRows(self.Data, 2, numberOfRows)

		else

			local upRowVector = AqwamMatrixLibrary:extractRows(self.Data, 1, rowIndex - 1)

			local bottomRowVector = AqwamMatrixLibrary:extractRows(self.Data, rowIndex + 1, numberOfRows)

			self.Data = AqwamMatrixLibrary:verticalConcatenate(upRowVector, bottomRowVector)

		end

	end)

end

function DataCritic:selectRowsWithValuesOf(valueTable, columnIndex)
	
	if (type(valueTable) ~= "table") then valueTable = {valueTable} end
	
	if (columnIndex > #self.Data[1]) then error("The column index exceeds the number of columns.") end
	
	local selectedRows = {}
	
	for rowIndex = 1, #self.Data, 1 do
		
		if table.find(valueTable, self.Data[rowIndex][columnIndex]) then table.insert(selectedRows, rowIndex) end
		
	end
	
	return selectedRows
	
end

function DataCritic:exportDataFrame(fileType, separator)
	
	fileType = fileType or "csv"
	
	if (fileType == "matrix") then
		
		return AqwamMatrixLibrary:verticalConcatenate({self.Header}, self.Data)
		
	elseif (fileType == "csv") or (fileType == "text") then
		
		local stringToExport = ""
		
		separator = separator or ","
		
		for i, headerValue in ipairs(self.Header) do
			
			stringToExport = stringToExport .. headerValue
			
			if (i < #self.Header) then stringToExport = stringToExport .. separator .. " " end
			
		end
		
		stringToExport = stringToExport .. "\n"

		for _, dataRow in ipairs(self.Data) do
			
			for i, dataValue in ipairs(dataRow) do
				
				stringToExport = stringToExport .. dataValue
				
				if (i < #dataRow) then stringToExport = stringToExport .. separator .. " " end
				
			end
			
			stringToExport = stringToExport .. "\n"
			
		end

		return stringToExport
		
	end
	
end

function DataCritic:findRowsWithMissingValues(columnIndexTable)
	
	if (type(columnIndexTable) ~= "table") then columnIndexTable = {columnIndexTable} end
	
	local rowIndexTable = {}
	
	for rowIndex, rowData in ipairs(self.Data) do
		
		for _, columnIndex in ipairs(columnIndexTable) do
			
			if (rowData[columnIndex] == nil) or (rowData[columnIndex] == "") then
				
				table.insert(rowIndexTable, rowIndex)
				
				break
				
			end
			
		end
		
	end
	
	return rowIndexTable
	
end

function DataCritic:findColumnsWithMissingValues(rowIndexTable)
	
	local columnIndexTable = {}

	for _, columnIndex in ipairs(rowIndexTable) do
		
		for rowIndex = 1, #self.Data do
			
			if (self.Data[rowIndex][columnIndex] == nil) or (self.Data[rowIndex][columnIndex] == "") then
				
				table.insert(columnIndexTable, columnIndex)
				
				break
			end
		end
		
	end

	return columnIndexTable
	
end

function DataCritic:removeMissingValues(rowIndex, columnIndex)
	
	return self:wrapFunctionInProtectedCall(function()
		
		local newData = {}

		local rowIndexValueType = type(rowIndex)

		local columnIndexValueType = type(columnIndex)

		if (rowIndexValueType == "number") and (columnIndexValueType == "number") then

			local value = self.Data[rowIndex][columnIndex]
			
			if (type(value) == "nil") then table.remove(newData, self.Data[rowIndex]) end

		elseif (rowIndexValueType == "number") and (columnIndexValueType == "nil") then
			
			local isRowRemoved = false
			
			for i = 1, #self.Data[1], 1 do
				
				if (type(self.Data[rowIndex][i]) ~= "nil") then continue end
				
				isRowRemoved = true
				break
				
			end
			
			for i = 1, #self.Data, 1 do
				
				if (i == rowIndex) and isRowRemoved then continue end
				
				table.insert(newData, self.Data[i])
				
			end

		elseif (rowIndexValueType == "nil") and (columnIndexValueType == "number") then

			for i = 1, #self.Data, 1 do
				
				local value = self.Data[i][columnIndex]
				
				if (type(value) ~= "nil") then table.insert(newData, self.Data[i]) end

			end

		else

			error("Invalid row or column index values.")

		end
		
		self.Data = newData

	end)
	
end

return DataCritic
