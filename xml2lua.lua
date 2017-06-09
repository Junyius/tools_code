saveDirPath = "/xxx/"   --- 保存转好的lua文件路劲(其中xxx代表的是路径，下同)  
xmlDirPath  = "/xxx/" --- 待转的xml文件路径  
require "lfs"   
function SaveTableContent(file, obj)  
      local szType = type(obj);  
      if szType == "number" then  
            file:write(obj);  
      elseif szType == "string" then  
            file:write(string.format("%q", obj));  
      elseif szType == "table" then  
            --把table的内容格式化写入文件  
            -- print(obj.nodeFlag)  
            if obj.nodeFlag ~= nil then  
                if obj:numProperties() == 0 and obj:numChildren() == 0 then   
                    SaveTableContent(file, obj:value() or "");  
                else  
                    file:write("{");  
                    if obj:numProperties() ~= 0 then  
                        -- print(obj)  
                        file:write("[\"$\"]={");  
                        local pTable = {}  
                        local properties = obj:properties()  
                        for i=1, #properties do  
                           local propertie = properties[i]  
                            local propertieName  = propertie.name  
                            local propertieValue = propertie.value  
                            -- print("")  
                                file:write("[");  
                                SaveTableContent(file, propertieName);  
                                file:write("]=");  
                                SaveTableContent(file, propertieValue);  
                                if i ~= #properties then file:write(", ") end  
  
  
                        end  
                        file:write("}");  
                        if obj:numChildren() ~= 0 then file:write(",") end  
                    end  
                    if obj:numChildren() ~= 0 then  
                         -- print("numChildren:"..tostring(obj:numChildren()))  
                        local allChildrenTable = {}  
                        local children = obj:children()  
                        local nextChildName = ""  
                        local lastChildName = ""  
                        for i=1,obj:numChildren() do  
                            local child = children[i]       
                            nextChildName = child:name()  
                            -- print("lastChildName1-----------:"..lastChildName)  
                            if nextChildName ~= lastChildName then  
                                -- print("lastChildName2-----------:"..lastChildName)  
                                allChildrenTable[nextChildName] = {}  
                                lastChildName = nextChildName  
                                -- print("lastChildName4-----------:"..lastChildName)  
                            end  
                            table.insert(allChildrenTable[nextChildName], child)  
                        end  
                        for i,v in pairs(allChildrenTable) do  
                            file:write("[");  
                            SaveTableContent(file, i);  
                            file:write("]=");  
                            SaveTableContent(file, v);  
                            file:write(", ");  
                             -- print("key:"..i..#v)  
                        end  
                        -- SaveTableContent(file, allChildrenTable, fileName);  
                    end  
                    file:write("}");  
                end  
            else  
                file:write("{");  
                for i, v in pairs(obj) do  
                   local vType = type(v)  
                    if vType ~= "function" then  
                        file:write("[");  
                        SaveTableContent(file, i);  
                        file:write("]=");  
                        SaveTableContent(file, v );  
                        file:write(", ");  
                    end  
                end  
                file:write("}");  
            end  
      else  
      -- error("can't serialize a "..szType);  
      end  
end  
  
function SaveTable(fileName,obj)  
      -- print(path);  
      -- printLog();  
      local fileNewName = string.gsub(fileName, ".xml", ".lua");  
      local savePath = saveDirPath..fileNewName  
      local file = io.open(savePath, "w");  
      file:write("local "..string.gsub(fileName, ".xml", "").." = \n");  
      -- print(fileName);  
      SaveTableContent(file, obj);  
      file:write("\nreturn  "..string.gsub(fileName, ".xml", "") );  
      file:close();  
end  
function newParser()  
  
  
    XmlParser = {};  
  
  
    function XmlParser:ToXmlString(value)  
        value = string.gsub(value, "&", "&"); -- '&' -> "&"  
        value = string.gsub(value, "<", "<"); -- '<' -> "<"  
        value = string.gsub(value, ">", ">"); -- '>' -> ">"  
        value = string.gsub(value, "\"", """); -- '"' -> """  
        value = string.gsub(value, "([^%w%&%;%p%\t% ])",  
            function(c)  
                print("c::::------->>>>>"..string.byte(c))  
                return string.format("&#x%X;", string.byte(c))  
            end);  
        return value;  
    end  
  
  
    function XmlParser:FromXmlString(value)  
        value = string.gsub(value, "&#x([%x]+)%;",  
            function(h)  
                print("h::::------->>>>>"..string.char(tonumber(h, 16)))  
                return string.char(tonumber(h, 16))  
            end);  
        value = string.gsub(value, "&#([0-9]+)%;",  
            function(h)  
                print("h::::------->>>>>"..string.char(tonumber(h, 10)))  
                return string.char(tonumber(h, 10))  
            end);  
        value = string.gsub(value, """, "\"");  
        value = string.gsub(value, "'", "'");  
        value = string.gsub(value, ">", ">");  
        value = string.gsub(value, "<", "<");  
        value = string.gsub(value, "&", "&");  
        return value;  
    end  
  
  
    function XmlParser:ParseArgs(node, s)  
        string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a)  
            node:addProperty(w, self:FromXmlString(a))  
        end)  
    end  
  
  
    function XmlParser:ParseXmlText(xmlText)  
        local stack = {}  
        local top = newNode()  
        table.insert(stack, top)  
        local ni, c, label, xarg, empty  
        local i, j = 1, 1  
        while true do  
            ni, j, c, label, xarg, empty = string.find(xmlText, "<(%/?)([%w_:]+)(.-)(%/?)>", i)  
            if not ni then break end  
            local text = string.sub(xmlText, i, ni - 1);  
            if not string.find(text, "^%s*$") then  
                local lVal = (top:value() or "") .. self:FromXmlString(text)  
                stack[#stack]:setValue(lVal)  
            end  
            if empty == "/" then -- empty element tag  
                local lNode = newNode(label)  
                self:ParseArgs(lNode, xarg)  
                top:addChild(lNode)  
            elseif c == "" then -- start tag  
                local lNode = newNode(label)  
                self:ParseArgs(lNode, xarg)  
                table.insert(stack, lNode)  
            top = lNode  
            else -- end tag  
                local toclose = table.remove(stack) -- remove top  
  
  
                top = stack[#stack]  
                if #stack < 1 then  
                    error("XmlParser: nothing to close with " .. label)  
                end  
                if toclose:name() ~= label then  
                    error("XmlParser: trying to close " .. toclose.name .. " with " .. label)  
                end  
                top:addChild(toclose)  
            end  
            i = j + 1  
        end  
        local text = string.sub(xmlText, i);  
        if #stack > 1 then  
            error("XmlParser: unclosed " .. stack[#stack]:name())  
        end  
        return top  
    end  
  
  
    function XmlParser:loadFile(xmlFilename, base)  
        if not base then  
            base = system.ResourceDirectory  
        end  
  
  
        local path = system.pathForFile(xmlFilename, base)  
        local hFile, err = io.open(path, "r");  
  
  
        if hFile and not err then  
            local xmlText = hFile:read("*a"); -- read file content  
            io.close(hFile);  
            return self:ParseXmlText(xmlText), nil;  
        else  
            print(err)  
            return nil  
        end  
    end  
  
  
    return XmlParser  
end  
  
  
function newNode(name)  
    local node = {}  
    node.___nodeFlag = true  
    node.___value = nil  
    node.___name = name  
    node.___children = {}  
    node.___props = {}  
  
  
    function node:nodeFlag() return self.___nodeFlag end  
    function node:value() return self.___value end  
    function node:setValue(val) self.___value = val end  
    function node:name() return self.___name end  
    function node:setName(name) self.___name = name end  
    function node:children() return self.___children end  
    function node:numChildren() return #self.___children end  
    function node:addChild(child)  
        if self[child:name()] ~= nil then  
            if type(self[child:name()].name) == "function" then  
                local tempTable = {}  
                table.insert(tempTable, self[child:name()])  
                self[child:name()] = tempTable  
            end  
            table.insert(self[child:name()], child)  
        else  
            self[child:name()] = child  
        end  
        table.insert(self.___children, child)  
    end  
  
  
    function node:properties() return self.___props end  
    function node:numProperties() return #self.___props end  
    function node:addProperty(name, value)  
        local lName = "@" .. name  
        if self[lName] ~= nil then  
            if type(self[lName]) == "string" then  
                local tempTable = {}  
                table.insert(tempTable, self[lName])  
                self[lName] = tempTable  
            end  
            table.insert(self[lName], value)  
        else  
            self[lName] = value  
        end  
        table.insert(self.___props, { name = name, value = value })  
    end  
  
  
    return node  
end  
  
function getpathes(rootpath, pathes)  
    pathes = pathes or {}  
  
  
    ret, files, iter = pcall(lfs.dir, rootpath)  
    if ret == false then  
        return pathes  
    end  
    for entry in files, iter do  
        local next = false  
        if entry ~= '.' and entry ~= '..' then  
            local path = rootpath .. entry  
            -- print (path)  
            local attr = lfs.attributes(path)  
            if attr == nil then  
                next = true  
            end  
  
  
            if next == false then   
                if attr.mode == 'directory' then  
                    getpathes(path, pathes)  
                else  
                    --进行数据组织  
                    i, j =string.find(path,"%.xml")  
                    if i ~= nil then  
                        local hFile, err = io.open(path, "r");  
                        if hFile and not err then  
                              local xmlText = hFile:read("*a"); -- read file content  
                              io.close(hFile);  
                              -- xmlText = string.gsub(xmlText, "<?xml version=\"1.0\" encoding=\"utf-8\"?>", "")  
                              xmlText = string.gsub(xmlText, "<!%-%-(.-)%-%->", "")  
                              -- print("xmlText:"..xmlText)  
                              local textObj = parser.ParseXmlText(parser, xmlText)  
                              SaveTable(entry, textObj);  
                              --local flag = true  
                              --for i,v in ipairs(exclude2MapArr) do  
                              --      if v == string.gsub(entry, ".xml", "") then  
                              --          flag = false  
                              --          break  
                              --      end  
                              --end  
                              --if flag then createSimpleXml(entry , dofile(saveDirPath..string.gsub(entry, ".xml", ".lua"))); end  
                              print(entry.."-------------------->"..string.gsub(entry, ".xml", ".lua"))  
                              -- return xmlSimple.ParseXmlText(xmlText), nil;  
                        end  
                    end  
                end  
            end  
        end  
        next = false  
    end  
    return pathes  
end  
  
-- function createSimpleXml(entry, obj)  
--     -- name = name.split('_')[0];  
--     local name =  string.upper(string.sub(entry, 1, 1))..string.sub(entry, 2, string.len(entry));  
--     name = string.gsub(name, ".xml", "")  
--     -- print('data[name]:'..obj[name..'s']..'----------------');  
--     local arr = obj[name..'s'][1][name];  
--     local map = {};  
--     print('===========[ '..name..' ] ==========');  
--     if name == 'Lang' then  
--         for i=1,#arr do  
--             map[tostring(arr[i]['$']['key'])] = arr[i];  
--         end  
--     else   
--         for i=1,#arr do  
--             map[tostring(arr[i]['$']['id'])] = arr[i];  
--         end  
          
--     end  
--     SaveTable(entry, map);  
--     -- return map;  
-- end  
  
if lfs == nil then return end  
  
  
pathes = {}  
parser = newParser()  
getpathes(xmlDirPath, pathes)  