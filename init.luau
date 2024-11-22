type TokenType = "stringliteral" | "intliteral" | "lbrace" 
| "rbrace" | "lsqbracket" | "rsqbracket" | "boolliteral" | "null"
| "colon" | "comma"

type Token = {
    pos: number,
    finish: number,
    type: TokenType
}

local function findFirstOf(str, chars, begin)
    local characters = {}
    for i = 1, #chars, 1 do
        table.insert(characters, chars:sub(i,i))
    end

    begin = begin or 1
    for i = begin, #str, 1 do
        if i ~= begin and table.find(characters, str:sub(i,i)) then
            return i
        end
    end
    return nil
end

local function findLastOf(str, chars, begin)
    local characters = {}
    for i = 1, #chars, 1 do
        table.insert(characters, chars:sub(i,i))
    end

    begin = begin or 1
    for i = begin, #str, 1 do
        if i ~= begin and table.find(characters, str:sub(i,i)) then
            if i == #str or not table.find(characters, str:sub(i+1, i+1)) then
                return i
            end
        end
    end
    return nil
end

local function findFirstNotOf(str, chars, begin)
    local characters = {}
    for i = 1, #chars, 1 do
        table.insert(characters, chars:sub(i,i))
    end

    begin = begin or 1
    for i = begin, #str, 1 do
        if i ~= begin and not table.find(characters, str:sub(i,i)) then
            return i
        end
    end
    return nil
end

local function isDigit(chars)
    local digits = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
    for i = 1, #chars, 1 do
        if not table.find(digits, chars:sub(i,i)) then
            return false
        end
    end
    return true
end

local Parser = {}
Parser.__index = Parser

function Parser.new(str)
    local self = setmetatable({}, Parser)
    self.str = str
    self.pos = nil
    self.finish = 0
    self.cursor = 1
    return self
end

function Parser:peekNext()
    if self.cursor ~= #self.str then
        return self.str:sub(self.cursor+1, self.cursor+1)
    end
    return nil
end

function Parser:peek()
    return self.str:sub(self.cursor, self.cursor)
end

function Parser:advance()
    local current = self:peek()
    if self.cursor ~= #self.str then
        self.cursor += 1
    end
    return current
end

function Parser:startsFrom(str, begin)
    local finish = self:findFirstOf(str:sub(#str, #str), begin)
    local sub = self.str:sub(begin, finish)
    if sub == str then
        return finish
    end
    return nil
end

function Parser:findFirstOf(chars, begin)
    return findFirstOf(self.str, chars, begin)
end

function Parser:findFirstNotOf(chars, begin)
    return findFirstNotOf(self.str, chars, begin)
end

function Parser:findLastOf(chars, begin)
    return findLastOf(self.str, chars, begin)
end

function Parser:parseTokens()
    local tokens: {Token} = {}

    while true do
        if self:peek() == "\"" then
            self.pos = self.cursor
            self.finish = self:findFirstOf("\"", self.pos)
            
            if self.finish then
                table.insert(tokens, {
                    pos = self.pos,
                    finish = self.finish,
                    type = "stringliteral"
                })
                self.cursor = self.finish+1
                continue
            end
        end

        if isDigit(self:peek()) then
            self.pos = self.cursor
            self.finish = self:findLastOf("1234567890", self.pos)
            
            if self.finish then
                table.insert(tokens, {
                    pos = self.pos,
                    finish = self.finish,
                    type = "intliteral"
                })
                self.cursor = self.finish
                continue
            end
        end

        self.finish = self:startsFrom("true", self.cursor)
        if self.finish then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.finish,
                type = "boolliteral"
            })
            self.cursor = self.finish
        end

        self.finish = self:startsFrom("false", self.cursor)
        if self.finish then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.finish,
                type = "boolliteral"
            })
            self.cursor = self.finish
        end

        self.finish = self:startsFrom("null", self.cursor)
        if self.finish then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.finish,
                type = "null"
            })
            self.cursor = self.finish
        end

        if self:peek() == "{" then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "lbrace"
            })
        end

        if self:peek() == "}" then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "rbrace"
            })
        end

        if self:peek() == "[" then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "lsqbracket"
            })
        end

        if self:peek() == "]" then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "rsqbracket"
            })
        end

        if self:peek() == ":" then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "colon"
            })
        end

        if self:peek() == "," then
            self.pos = self.cursor
            table.insert(tokens, {
                pos = self.pos,
                finish = self.pos,
                type = "comma"
            })
        end
        
        if self.cursor >= #self.str then
            break
        end
        self:advance()
        
    end
    self.tokens = tokens
    return tokens
end

function Parser:parseString(literal: Token)
    return self.str:sub(literal.pos+1, literal.finish-1)
end

function Parser:parseNumber(literal: Token)
    return tonumber(self.str:sub(literal.pos, literal.finish))
end

function Parser:parseBool(literal: Token)
    print(self.str:sub(literal.pos, literal.finish))
    if self.str:sub(literal.pos, literal.finish) == "true" then
        return true
    end
    return false
end

function Parser:parseLiteral(literal: Token)
    if literal.type == "intliteral" then
        return self:parseNumber(literal)
    elseif literal.type == "stringliteral" then
        return self:parseString(literal)
    elseif literal.type == "null" then
        return nil
    elseif literal.type == "boolliteral" then
        return self:parseBool(literal)
    end
    return
end

function Parser:parseArray(begin, finish)
    local result = {}

    local i = begin
    while true do
        if self.tokens[i].type == "stringliteral"
        or self.tokens[i].type == "intliteral" then
            table.insert(result, self:parseLiteral(self.tokens[i]))
        end

        if self.tokens[i].type == "lsqbracket" and i ~= begin then
            for j = i, finish, 1 do
                if self.tokens[j].type == "rsqbracket" then
                    local res = self:parseArray(i, j)
                    table.insert(result, res)
                    break
                end
            end
        end

        if self.tokens[i].type == "lbrace" then
            for j = i, finish, 1 do
                if self.tokens[j].type == "rbrace" then
                    local res = self:parseObject(i, j)
                    table.insert(result, res)
                    break
                end
            end
        end


        if i == finish then
            break
        end
        i+=1
    end

    return result
end

function Parser:parseObject(begin, finish)
    local result = {}

    local i = begin
    while true do
        --print(self.tokens[i].type)
        if self.tokens[i].type == "colon" then
            local left = self:parseLiteral(self.tokens[i-1])
            local right = self.tokens[i+1]

            if right.type == "lbrace" then
                for j = i+1, finish, 1 do
                    if self.tokens[j].type == "rbrace" then
                        right = self:parseObject(i+1, j)
                        i = j
                        break
                    end
                end
            elseif right.type == "lsqbracket" then
                for j = i+1, finish, 1 do
                    if self.tokens[j].type == "rsqbracket" then
                        right = self:parseArray(i+1, j)
                        i = j
                        break
                    end
                end
            else
                right = self:parseLiteral(right)
            end

            result[left] = right
        end

        if i == finish then
            break
        end
        i += 1
    end
    return result
end

return Parser