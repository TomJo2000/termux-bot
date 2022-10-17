local pp = require("pretty-print")
local sandbox = setmetatable({}, { __index = _G })

local function printLine(...)
  local ret = {}
  for i = 1, select('#', ...) do
    local arg = tostring(select(i, ...))
    table.insert(ret, arg)
  end
  return table.concat(ret, '\t')
end

local function prettyLine(...)
  local ret = {}
  for i = 1, select('#', ...) do
    local arg = pp.strip(pp.dump(select(i, ...)))
    table.insert(ret, arg)
  end
  return table.concat(ret, '\t')
end

local function code(str)
  return string.format('```\n%s```', str)
end

local function evalCommand(message, args, meta)
  local arg = meta.rawArgs:gsub('```\n?', '') -- strip markdown codeblocks
  local lines = {}

  sandbox.message = message
  sandbox.require = require
  sandbox.meta = meta

  sandbox.print = function(...)
    table.insert(lines, printLine(...))
  end

  sandbox.p = function(...)
    table.insert(lines, prettyLine(...))
  end

  local fn, syntaxError = load(arg, 'DiscordBot', 't', sandbox)
  if not fn then return message:reply(code(syntaxError)) end

  local success, runtimeError = pcall(fn)
  if not success then return message:reply(code(runtimeError)) end

  lines = table.concat(lines, '\n')

  if #lines > 1990 then -- truncate long messages
    lines = lines:sub(1, 1990)
  end

  return message:reply(code(lines))
end

return {
  run = evalCommand,
  aliases = {"lua"},
  ownerOnly = true
}